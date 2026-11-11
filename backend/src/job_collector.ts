
import { pool } from "./database";
import { load } from "cheerio";

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

type HtmlSelectors = {
  item?: string;
  title?: string;
  link?: string;
  description?: string;
  employer?: string;
  location?: string;
  deadline?: string;
  external_id?: string;
  external_id_attribute?: string;
  qualification?: string;
  experience?: string;
  salary_information?: string;
};

type SourceSettings = {
  feed_url?: string;
  format?: string;
  date_format?: "DMY" | "MDY" | "YMD";
  category_id?: number;
  country?: string;
  field_map?: Record<string, string>;
  selectors?: HtmlSelectors;
};

function cleanText(value: unknown): string {
  if (typeof value !== "string") return "";

  return value
    .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, "$1")
    .replace(/<[^>]*>/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;|&apos;/g, "'")
    .replace(/\s+/g, " ")
    .trim();
}

function getErrorMessage(error: unknown): string {
  if (!(error instanceof Error)) {
    return String(error);
  }

  const details: string[] = [error.message];

  const cause = (error as Error & {
    cause?: {
      message?: string;
      code?: string;
      errno?: string | number;
      syscall?: string;
      hostname?: string;
    };
  }).cause;

  if (cause) {
    if (cause.message) details.push(cause.message);
    if (cause.code) details.push(`code=${cause.code}`);
    if (cause.errno) details.push(`errno=${cause.errno}`);
    if (cause.syscall) details.push(`syscall=${cause.syscall}`);
    if (cause.hostname) details.push(`hostname=${cause.hostname}`);
  }

  return [...new Set(details)].join(" | ");
}

function getXmlValue(
  block: string,
  tag: string
): string | null {
  const escapedTag = tag.replace(
    /[.*+?^${}()|[\]\\]/g,
    "\\$&"
  );

  const match = block.match(
    new RegExp(
      `<${escapedTag}\\b[^>]*>([\\s\\S]*?)<\\/${escapedTag}>`,
      "i"
    )
  );

  return match ? cleanText(match[1]) : null;
}

function getXmlLink(block: string): string | null {
  const atomLink = block.match(
    /<link\b[^>]*\bhref=["']([^"']+)["'][^>]*\/?>/i
  );

  if (atomLink) return cleanText(atomLink[1]);

  const rssLink = block.match(
    /<link\b[^>]*>([\s\S]*?)<\/link>/i
  );

  if (rssLink) return cleanText(rssLink[1]);

  return null;
}

/**
 * Parses common date formats.
 *
 * DMY = 09/11/2026
 * MDY = 11/09/2026
 * YMD = 2026/11/09
 *
 * Default slash-date format is MDY.
 */
function parseDate(
  value: string | null,
  dateFormat: "DMY" | "MDY" | "YMD" = "MDY"
): Date | null {
  if (!value) return null;

  const trimmed = value.trim();

  if (!trimmed) return null;

  const slashDate = trimmed.match(
    /^(\d{1,4})[/-](\d{1,2})[/-](\d{1,4})$/
  );

  if (slashDate) {
    let year: number;
    let month: number;
    let day: number;

    if (dateFormat === "YMD") {
      year = Number(slashDate[1]);
      month = Number(slashDate[2]);
      day = Number(slashDate[3]);
    } else if (dateFormat === "DMY") {
      day = Number(slashDate[1]);
      month = Number(slashDate[2]);
      year = Number(slashDate[3]);
    } else {
      month = Number(slashDate[1]);
      day = Number(slashDate[2]);
      year = Number(slashDate[3]);
    }

    if (year < 1000 || year > 9999) return null;

    const date = new Date(
      Date.UTC(year, month - 1, day)
    );

    if (
      date.getUTCFullYear() !== year ||
      date.getUTCMonth() !== month - 1 ||
      date.getUTCDate() !== day
    ) {
      return null;
    }

    return date;
  }

  // Handles dates such as 09-Nov-2026 and ISO dates.
  const parsed = new Date(trimmed);

  return Number.isNaN(parsed.getTime())
    ? null
    : parsed;
}

/**
 * Compare dates using Pakistan local calendar date.
 * Jobs closing today remain eligible for collection.
 */
function isExpired(deadline: Date | null): boolean {
  if (!deadline) return false;

  const options: Intl.DateTimeFormatOptions = {
    timeZone: "Asia/Karachi",
    year: "numeric",
    month: "2-digit",
    day: "2-digit"
  };

  const todayKey = new Intl.DateTimeFormat(
    "en-CA",
    options
  ).format(new Date());

  const deadlineKey = new Intl.DateTimeFormat(
    "en-CA",
    options
  ).format(deadline);

  return deadlineKey < todayKey;
}

function validateJobUrl(url: string): boolean {
  try {
    const parsed = new URL(url);

    return (
      parsed.protocol === "https:" &&
      !parsed.username &&
      !parsed.password
    );
  } catch {
    return false;
  }
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

/**
 * Fetches a source page.
 * Redirects must remain HTTPS and on the approved hostname.
 */


async function fetchSourcePage(
  feedUrl: string,
  websiteUrl: string
): Promise<string> {
  const approvedHost = new URL(websiteUrl).hostname;
  let currentUrl = new URL(feedUrl);

  const controller = new AbortController();

  const timeout = setTimeout(() => {
    controller.abort();
  }, 15000);

  try {
    for (let attempt = 0; attempt <= 5; attempt++) {
      if (
        currentUrl.protocol !== "https:" ||
        currentUrl.hostname !== approvedHost ||
        currentUrl.username ||
        currentUrl.password
      ) {
        throw new Error(
          "Redirect rejected: destination is not the approved HTTPS host"
        );
      }

      let response: Response;

      try {
        response = await fetch(currentUrl.toString(), {
          method: "GET",
          redirect: "manual",
          signal: controller.signal,
          headers: {
            "User-Agent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36",
            Accept:
              "text/html,application/xhtml+xml,application/rss+xml,application/atom+xml,application/json,text/xml,*/*",
            "Accept-Language": "en-PK,en;q=0.9"
          }
        });
      } catch (error) {
        throw new Error(
          `Network request failed for ${currentUrl.hostname}: ${getErrorMessage(error)}`
        );
      }

      const isRedirect = [
        301,
        302,
        303,
        307,
        308
      ].includes(response.status);

      if (isRedirect) {
        const location = response.headers.get("location");

        if (!location) {
          throw new Error(
            `Source returned HTTP ${response.status} without a redirect location`
          );
        }

        if (attempt === 5) {
          throw new Error(
            "Source exceeded the maximum redirect limit"
          );
        }

        let nextUrl: URL;

        try {
          nextUrl = new URL(location, currentUrl);
        } catch {
          throw new Error(
            "Source returned an invalid redirect URL"
          );
        }

        if (
          nextUrl.protocol !== "https:" ||
          nextUrl.hostname !== approvedHost ||
          nextUrl.username ||
          nextUrl.password
        ) {
          throw new Error(
            "Source redirect rejected because it changed the approved hostname or HTTPS protocol"
          );
        }

        currentUrl = nextUrl;
        continue;
      }

      if (!response.ok) {
        throw new Error(
          `Source returned HTTP ${response.status} ${response.statusText}`
        );
      }

      const contentType =
        response.headers.get("content-type") || "unknown";

      const contentLength = Number(
        response.headers.get("content-length") || 0
      );

      if (contentLength > 1_000_000) {
        throw new Error(
          "Source response exceeds the 1 MB limit"
        );
      }

      const body = await response.text();

      const bodySize =
        new TextEncoder().encode(body).length;

      if (bodySize > 1_000_000) {
        throw new Error(
          "Source response exceeds the 1 MB limit"
        );
      }

      const normalizedBody = body.toLowerCase();

      console.log("JOB SOURCE FETCH DIAGNOSTICS:", {
        host: currentUrl.hostname,
        status: response.status,
        contentType,
        bodySize,
        containsHtml: normalizedBody.includes("<html"),
        containsTable: normalizedBody.includes("<table"),
        containsKnownVacancy:
          normalizedBody.includes("regional audit head"),
        containsCloudflare:
          normalizedBody.includes("cloudflare"),
        containsCaptcha:
          normalizedBody.includes("captcha"),
        containsAccessDenied:
          normalizedBody.includes("access denied")
      });

      return body;
    }

    throw new Error("Unable to retrieve source page");
  } finally {
    clearTimeout(timeout);
  }
}

      
      
function parseXmlFeed(
  xml: string,
  sourceName: string,
  country: string,
  dateFormat: "DMY" | "MDY" | "YMD"
): JobItem[] {
  const blocks = xml.match(
    /<(item|entry)\b[^>]*>[\s\S]*?<\/\1>/gi
  ) || [];

  const jobs: JobItem[] = [];

  for (const block of blocks) {
    const title = getXmlValue(block, "title");
    const link = getXmlLink(block);

    if (!title || !link) continue;

    const externalId =
      getXmlValue(block, "guid") ||
      getXmlValue(block, "id") ||
      link;

    const deadlineText =
      getXmlValue(block, "deadline") ||
      getXmlValue(block, "closingDate") ||
      getXmlValue(block, "pubDate");

    jobs.push({
      title,
      employer: sourceName,
      location: null,
      country,
      description:
        getXmlValue(block, "description") ||
        getXmlValue(block, "summary") ||
        getXmlValue(block, "content"),
      qualification: null,
      experience: null,
      salary_information: null,
      official_apply_url: link,
      deadline: parseDate(deadlineText, dateFormat),
      external_id: externalId
    });
  }

  return jobs;
}

function getJsonField(
  item: Record<string, unknown>,
  field: string | undefined
): string | null {
  if (!field) return null;

  const value = item[field];

  if (
    typeof value === "string" ||
    typeof value === "number"
  ) {
    return String(value).trim() || null;
  }

  return null;
}

function parseJsonFeed(
  json: unknown,
  sourceName: string,
  country: string,
  fieldMap: Record<string, string> = {},
  dateFormat: "DMY" | "MDY" | "YMD" = "MDY"
): JobItem[] {
  if (!json || typeof json !== "object") return [];

  const data = json as Record<string, unknown>;

  const items = Array.isArray(data.items)
    ? data.items
    : Array.isArray(data.jobs)
      ? data.jobs
      : [];

  const jobs: JobItem[] = [];

  for (const rawItem of items) {
    if (!rawItem || typeof rawItem !== "object") {
      continue;
    }

    const item = rawItem as Record<string, unknown>;

    const title = getJsonField(
      item,
      fieldMap.title || "title"
    );

    const link = getJsonField(
      item,
      fieldMap.link || "url"
    );

    if (!title || !link) continue;

    const externalId =
      getJsonField(
        item,
        fieldMap.external_id || "id"
      ) || link;

    const deadlineText = getJsonField(
      item,
      fieldMap.deadline || "deadline"
    );

    jobs.push({
      title,
      employer:
        getJsonField(
          item,
          fieldMap.employer || "employer"
        ) || sourceName,
      location: getJsonField(
        item,
        fieldMap.location || "location"
      ),
      country:
        getJsonField(
          item,
          fieldMap.country || "country"
        ) || country,
      description: getJsonField(
        item,
        fieldMap.description || "description"
      ),
      qualification: getJsonField(
        item,
        fieldMap.qualification || "qualification"
      ),
      experience: getJsonField(
        item,
        fieldMap.experience || "experience"
      ),
      salary_information: getJsonField(
        item,
        fieldMap.salary_information || "salary"
      ),
      official_apply_url: link,
      deadline: parseDate(deadlineText, dateFormat),
      external_id: externalId
    });
  }

  return jobs;
}

function parseHtmlPage(
  html: string,
  sourceName: string,
  country: string,
  baseUrl: string,
  selectors: HtmlSelectors,
  dateFormat: "DMY" | "MDY" | "YMD"
): JobItem[] {
  if (!selectors.item || !selectors.title || !selectors.link) {
    throw new Error(
      "HTML source requires item, title and link selectors"
    );
  }

  const $ = load(html);
  const jobs: JobItem[] = [];

  let rowsFound = 0;
  let titlesFound = 0;
  let linksFound = 0;
  let invalidUrls = 0;
  let rowsSkipped = 0;

  const getElement = (item: any, selector: string): any => {
    if (item.is(selector)) return item;
    return item.find(selector).first();
  };

  $(selectors.item).each((_index, element) => {
    rowsFound++;

    const item = $(element);

    const titleElement = getElement(item, selectors.title!);
    const title = cleanText(titleElement.text());

    if (!title) {
      rowsSkipped++;
      return;
    }

    titlesFound++;

    const linkElement = getElement(item, selectors.link!);
    const rawLink = linkElement.attr("href");

    if (!rawLink) {
      rowsSkipped++;
      return;
    }

    linksFound++;

    let applyUrl: string;

    try {
      applyUrl = new URL(rawLink, baseUrl).toString();
    } catch {
      invalidUrls++;
      rowsSkipped++;
      return;
    }

    if (!validateJobUrl(applyUrl)) {
      invalidUrls++;
      rowsSkipped++;
      return;
    }

    const getText = (selector?: string): string | null => {
      if (!selector) return null;

      const field = getElement(item, selector);
      const value = cleanText(field.text());

      return value || null;
    };

    let externalId: string | null = null;

    if (selectors.external_id) {
      externalId = getText(selectors.external_id);
    }

    if (!externalId && selectors.external_id_attribute) {
      externalId =
        linkElement.attr(selectors.external_id_attribute) ||
        item.attr(selectors.external_id_attribute) ||
        null;
    }

    jobs.push({
      title,
      employer: getText(selectors.employer) || sourceName,
      location: getText(selectors.location),
      country,
      description: getText(selectors.description),
      qualification: getText(selectors.qualification),
      experience: getText(selectors.experience),
      salary_information: getText(
        selectors.salary_information
      ),
      official_apply_url: applyUrl,
      deadline: parseDate(
        getText(selectors.deadline),
        dateFormat
      ),
      external_id: externalId || applyUrl
    });
  });

  console.log("HTML parser diagnostics:", {
    source: sourceName,
    rowsFound,
    titlesFound,
    linksFound,
    invalidUrls,
    rowsSkipped,
    jobsParsed: jobs.length
  });

  return jobs;
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
      "SELECT pg_advisory_xact_lock($1::bigint)",
      [sourceId]
    );

    const existing = await client.query(
      `SELECT id
       FROM jobs
       WHERE source_id = $1
         AND external_id = $2
       LIMIT 1`,
      [sourceId, job.external_id]
    );

    if (existing.rows.length > 0) {
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
        collected_at
      )
      VALUES (
        $1, $2, $3, $4, $5, $6, $7,
        $8, $9, $10, $11, $12, $13,
        'pending', NOW()
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
  const result = await pool.query(
    `SELECT
       id,
       name,
       website_url,
       source_type,
       is_active,
       fetch_settings
     FROM job_sources
     WHERE is_active = true
     ORDER BY id`
  );

  const summary = {
    sources_checked: 0,
    jobs_found: 0,
    jobs_added: 0,
    duplicates: 0,
    expired: 0,
    errors: 0
  };

  for (const source of result.rows) {
    summary.sources_checked++;

    try {
      const settings = (
        source.fetch_settings || {}
      ) as SourceSettings;

      const feedUrl = settings.feed_url;

      const format = (
        settings.format ||
        source.source_type ||
        ""
      ).toLowerCase();

      const dateFormat =
        settings.date_format || "MDY";

      if (
        !feedUrl ||
        !validateFeedUrl(
          feedUrl,
          source.website_url
        )
      ) {
        throw new Error(
          "Invalid or unapproved source URL"
        );
      }

      if (
        !["rss", "atom", "json", "html"].includes(
          format
        )
      ) {
        throw new Error(
          `Unsupported source format: ${format}`
        );
      }

      const body = await fetchSourcePage(
        feedUrl,
        source.website_url
      );

      let jobs: JobItem[];

      if (format === "json") {
        let parsed: unknown;

        try {
          parsed = JSON.parse(body);
        } catch {
          throw new Error(
            "Source returned invalid JSON"
          );
        }

        jobs = parseJsonFeed(
          parsed,
          source.name,
          settings.country || "Pakistan",
          settings.field_map,
          dateFormat
        );
      } else if (format === "html") {
        jobs = parseHtmlPage(
          body,
          source.name,
          settings.country || "Pakistan",
          feedUrl,
          settings.selectors || {},
          dateFormat
        );
      } else {
        jobs = parseXmlFeed(
          body,
          source.name,
          settings.country || "Pakistan",
          dateFormat
        );
      }

      summary.jobs_found += jobs.length;

      for (const job of jobs) {
        if (!job.title || !job.external_id) {
          continue;
        }

        if (isExpired(job.deadline)) {
          summary.expired++;
          continue;
        }

        if (
          !validateJobUrl(
            job.official_apply_url
          )
        ) {
          summary.errors++;
          continue;
        }

        const added = await saveJob(
          Number(source.id),
          settings.category_id ?? null,
          job
        );

        if (added) {
          summary.jobs_added++;
        } else {
          summary.duplicates++;
        }
      }

      console.log(
        `Job source completed: ${source.name}; parsed ${jobs.length} jobs`
      );
    } catch (error) {
      summary.errors++;

      console.error(
        `Job collection failed for source ${source.name}:`,
        getErrorMessage(error)
      );
    }
  }

  return {
    success: true,
    message: "Job collection completed",
    summary
  };
}
