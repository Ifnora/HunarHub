import { pool } from "./database";

type JobItem = {
  title: string;
  employer: string | null;
  location: string | null;
  country: string;
  description: string | null;
  qualification: string | null;
  experience: string | null;
  salary_information: string | null;
  official_apply_url: string;
  deadline: Date | null;
  external_id: string;
};

type SourceSettings = {
  feed_url?: string;
  format?: string;
  category_id?: number;
  country?: string;
  field_map?: Record<string, string>;
};

function cleanText(value: unknown): string | null {
  if (value === null || value === undefined) return null;

  return String(value)
    .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, "$1")
    .replace(/<[^>]*>/g, " ")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/\s+/g, " ")
    .trim() || null;
}

function getXmlValue(
  block: string,
  names: string[]
): string | null {
  for (const name of names) {
    const escaped = name.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

    const pattern = new RegExp(
      `<${escaped}(?:\\s[^>]*)?>([\\s\\S]*?)<\\/${escaped}\\s*>`,
      "i"
    );

    const match = block.match(pattern);

    if (match) {
      const value = cleanText(match[1]);
      if (value) return value;
    }
  }

  return null;
}

function getXmlLink(block: string): string | null {
  const linkTag = block.match(/<link\b([^>]*)\/?>/i);

  if (linkTag) {
    const href = linkTag[1].match(
      /\bhref=["']([^"']+)["']/i
    );

    if (href) return href[1];

    const text = linkTag[0].match(
      /<link\b[^>]*>([\s\S]*?)<\/link>/i
    );

    if (text) return cleanText(text[1]);
  }

  return null;
}

function parseXmlFeed(xml: string): JobItem[] {
  const blocks = [
    ...xml.matchAll(/<item\b[^>]*>([\s\S]*?)<\/item>/gi),
    ...xml.matchAll(/<entry\b[^>]*>([\s\S]*?)<\/entry>/gi)
  ];

  const jobs: JobItem[] = [];

  for (const match of blocks) {
    const block = match[1];

    const title = getXmlValue(block, ["title"]);
    const link = getXmlLink(block);

    if (!title || !link) continue;

    const guid =
      getXmlValue(block, ["guid", "id"]) || link;

    const rawDate = getXmlValue(
      block,
      ["pubDate", "published", "updated", "date"]
    );

    const parsedDate = rawDate
      ? new Date(rawDate)
      : null;

    jobs.push({
      title,
      employer: getXmlValue(
        block,
        ["author", "dc:creator", "company", "employer"]
      ),
      location: getXmlValue(
        block,
        ["location", "job:location"]
      ),
      country: "Pakistan",
      description: getXmlValue(
        block,
        ["content:encoded", "description", "summary", "content"]
      ),
      qualification: null,
      experience: null,
      salary_information: null,
      official_apply_url: link,
      deadline: null,
      external_id: guid.slice(0, 500)
    });
  }

  return jobs;
}

function getJsonPath(
  item: Record<string, unknown>,
  path: string
): unknown {
  return path.split(".").reduce<unknown>((value, key) => {
    if (
      value &&
      typeof value === "object" &&
      key in value
    ) {
      return (value as Record<string, unknown>)[key];
    }

    return undefined;
  }, item);
}

function parseJsonFeed(
  data: unknown,
  settings: SourceSettings
): JobItem[] {
  if (!data || typeof data !== "object") return [];

  const object = data as Record<string, unknown>;

  const items = Array.isArray(object.items)
    ? object.items
    : Array.isArray(object.jobs)
      ? object.jobs
      : [];

  const map = settings.field_map || {};

  function field(
    item: Record<string, unknown>,
    key: string,
    fallback: string
  ): string | null {
    const path = map[key] || fallback;
    return cleanText(getJsonPath(item, path));
  }

  const jobs: JobItem[] = [];

  for (const raw of items) {
    if (!raw || typeof raw !== "object") continue;

    const item = raw as Record<string, unknown>;

    const title = field(item, "title", "title");
    const link = field(item, "url", "url") ||
      field(item, "url", "link");

    if (!title || !link) continue;

    const dateText = field(item, "deadline", "deadline");
    const parsedDate = dateText
      ? new Date(dateText)
      : null;

    jobs.push({
      title,
      employer: field(item, "employer", "employer"),
      location: field(item, "location", "location"),
      country: settings.country || "Pakistan",
      description: field(item, "description", "description"),
      qualification: field(item, "qualification", "qualification"),
      experience: field(item, "experience", "experience"),
      salary_information: field(
        item,
        "salary_information",
        "salary"
      ),
      official_apply_url: link,
      deadline:
        parsedDate && !Number.isNaN(parsedDate.getTime())
          ? parsedDate
          : null,
      external_id:
        field(item, "id", "id") || link
    });
  }

  return jobs;
}

function validateFeedUrl(
  feedUrl: string,
  websiteUrl: string
): boolean {
  try {
    const feed = new URL(feedUrl);
    const website = new URL(websiteUrl);

    return (
      feed.protocol === "https:" &&
      website.protocol === "https:" &&
      feed.hostname === website.hostname &&
      !feed.username &&
      !feed.password
    );
  } catch {
    return false;
  }
}

function validateJobUrl(value: string): boolean {
  try {
    const url = new URL(value);

    return (
      url.protocol === "https:" &&
      !url.username &&
      !url.password
    );
  } catch {
    return false;
  }
}

async function saveJob(
  sourceId: number,
  categoryId: number | null,
  job: JobItem
): Promise<boolean> {
  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    await client.query(
      "SELECT pg_advisory_xact_lock(0, hashtext($1))",
      [String(sourceId)]
    );

    const duplicate = await client.query(
      `SELECT id
       FROM jobs
       WHERE source_id = $1
         AND external_id = $2
       LIMIT 1`,
      [sourceId, job.external_id]
    );

    if (duplicate.rows.length > 0) {
      await client.query("COMMIT");
      return false;
    }

    await client.query(
      `INSERT INTO jobs (
        source_id,
        category_id,
        external_id,
        title,
        employer,
        location,
        country,
        description,
        qualification,
        experience,
        salary_information,
        official_apply_url,
        deadline,
        status,
        collected_at,
        created_at,
        updated_at
      )
      VALUES (
        $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,
        $11,$12,$13,'pending',NOW(),NOW(),NOW()
      )`,
      [
        sourceId,
        categoryId,
        job.external_id,
        job.title,
        job.employer,
        job.location,
        job.country,
        job.description,
        job.qualification,
        job.experience,
        job.salary_information,
        job.official_apply_url,
        job.deadline
      ]
    );

    await client.query("COMMIT");
    return true;
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}

export async function collectJobs() {
  const summary = {
    sources_checked: 0,
    jobs_found: 0,
    jobs_added: 0,
    duplicates: 0,
    errors: 0
  };

  const sources = await pool.query(
    `SELECT
       id,
       name,
       website_url,
       source_type,
       fetch_settings
     FROM job_sources
     WHERE is_active = TRUE
     ORDER BY id`
  );

  for (const source of sources.rows) {
    summary.sources_checked++;

    try {
      const settings =
        (source.fetch_settings || {}) as SourceSettings;

      const feedUrl = settings.feed_url;
      const format = (
        settings.format || source.source_type
      ).toLowerCase();

      if (
        !feedUrl ||
        !validateFeedUrl(feedUrl, source.website_url)
      ) {
        throw new Error("Invalid or unconfigured feed URL");
      }

      if (!["rss", "atom", "json"].includes(format)) {
        throw new Error("Unsupported feed format");
      }

      const response = await fetch(feedUrl, {
        method: "GET",
        redirect: "error",
        signal: AbortSignal.timeout(15000),
        headers: {
          Accept:
            "application/rss+xml, application/atom+xml, application/xml, application/json"
        }
      });

      if (!response.ok) {
        throw new Error(`Feed returned HTTP ${response.status}`);
      }

      const contentLength = Number(
        response.headers.get("content-length") || 0
      );

      if (contentLength > 1_000_000) {
        throw new Error("Feed is too large");
      }

      const body = await response.text();

      if (body.length > 1_000_000) {
        throw new Error("Feed is too large");
      }

      const foundJobs = format === "json"
        ? parseJsonFeed(JSON.parse(body), settings)
        : parseXmlFeed(body);

      summary.jobs_found += foundJobs.length;

      const categoryId = Number(settings.category_id);

      const validCategory = Number.isSafeInteger(categoryId) &&
        categoryId > 0
        ? categoryId
        : null;

      for (const job of foundJobs) {
        if (
          !job.title ||
          !job.official_apply_url ||
          !validateJobUrl(job.official_apply_url)
        ) {
          continue;
        }

        job.external_id = job.external_id.trim().slice(0, 500);

        if (!job.external_id) continue;

        const added = await saveJob(
          Number(source.id),
          validCategory,
          job
        );

        if (added) {
          summary.jobs_added++;
        } else {
          summary.duplicates++;
        }
      }
    } catch (error) {
      summary.errors++;

      console.error(
        `Job collection failed for source ${source.name}:`,
        error instanceof Error ? error.message : "Unknown error"
      );
    }
  }

  return {
    success: true,
    message: "Job collection completed",
    summary
  };
    }
      
