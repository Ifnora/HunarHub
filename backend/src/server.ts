
import express from "express";
import cors from "cors";
import helmet from "helmet";
import dotenv from "dotenv";
import { pool } from "./database";
import authRouter from "./auth";
import profileRouter from "./routes/profile";
import cvRouter from "./routes/cv";
import applicationsRouter from "./routes/applications";
import adminRouter from "./routes/admin";

dotenv.config();

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: "1mb" }));

// AUTHENTICATION ROUTES
app.use("/auth", authRouter);

// USER PROFILE ROUTES
app.use("/profile", profileRouter);

// CV BUILDER ROUTES
app.use("/cv", cvRouter);

// SAVED JOBS AND APPLICATION TRACKING
app.use("/applications", applicationsRouter);

// ADMIN JOB MANAGEMENT ROUTES
app.use("/admin", adminRouter);

// HOME
app.get("/", (_req, res) => {
  res.status(200).json({
    success: true,
    message: "Welcome to HunarHub Pakistan API"
  });
});

// API HEALTH
app.get("/health", (_req, res) => {
  res.status(200).json({
    success: true,
    service: "HunarHub Pakistan",
    status: "running"
  });
});

// DATABASE HEALTH
app.get("/health/database", async (_req, res) => {
  try {
    await pool.query("SELECT 1");

    res.status(200).json({
      success: true,
      database: "connected"
    });
  } catch (error) {
    console.error("Database health error:", error);

    res.status(503).json({
      success: false,
      database: "unavailable"
    });
  }
});

// JOB CATEGORIES
app.get("/job-categories", async (_req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, name
       FROM job_categories
       ORDER BY name ASC`
    );

    res.status(200).json({
      success: true,
      count: result.rows.length,
      categories: result.rows
    });
  } catch (error) {
    console.error("Categories error:", error);

    res.status(500).json({
      success: false,
      message: "Unable to fetch job categories"
    });
  }
});

// JOB LISTING, SEARCH AND FILTERS
app.get("/jobs", async (req, res) => {
  try {
    const search = String(req.query.search || "").trim();
    const country = String(req.query.country || "").trim();
    const categoryId = String(req.query.category_id || "").trim();

    const page = Math.max(
      1,
      Number.parseInt(String(req.query.page || "1"), 10) || 1
    );

    const limit = Math.min(
      50,
      Math.max(
        1,
        Number.parseInt(String(req.query.limit || "10"), 10) || 10
      )
    );

    const offset = (page - 1) * limit;

    const conditions: string[] = ["j.status = 'published'"];
    const values: (string | number)[] = [];

    if (search) {
      values.push(`%${search}%`);
      conditions.push(
        `(j.title ILIKE $${values.length}
          OR j.employer ILIKE $${values.length})`
      );
    }

    if (country) {
      values.push(country);
      conditions.push(`j.country ILIKE $${values.length}`);
    }

    if (categoryId) {
      const parsedCategoryId = Number(categoryId);

      if (
        !Number.isSafeInteger(parsedCategoryId) ||
        parsedCategoryId < 1
      ) {
        return res.status(400).json({
          success: false,
          message: "Invalid category_id"
        });
      }

      values.push(parsedCategoryId);
      conditions.push(`j.category_id = $${values.length}`);
    }

    const whereClause = conditions.join(" AND ");

    const countResult = await pool.query(
      `SELECT COUNT(*)::int AS total
       FROM jobs j
       WHERE ${whereClause}`,
      values
    );

    const total = countResult.rows[0].total;

    const jobsResult = await pool.query(
      `SELECT
          j.id,
          j.title,
          j.employer,
          j.location,
          j.country,
          j.description,
          j.qualification,
          j.experience,
          j.salary_information,
          j.official_apply_url,
          j.deadline,
          j.category_id,
          c.name AS category_name,
          j.created_at
       FROM jobs j
       LEFT JOIN job_categories c
         ON c.id = j.category_id
       WHERE ${whereClause}
       ORDER BY j.created_at DESC
       LIMIT $${values.length + 1}
       OFFSET $${values.length + 2}`,
      [...values, limit, offset]
    );

    res.status(200).json({
      success: true,
      pagination: {
        page,
        limit,
        total,
        total_pages: Math.ceil(total / limit)
      },
      jobs: jobsResult.rows
    });
  } catch (error) {
    console.error("Jobs listing error:", error);

    res.status(500).json({
      success: false,
      message: "Unable to fetch jobs"
    });
  }
});

// INDIVIDUAL JOB DETAILS
app.get("/jobs/:id", async (req, res) => {
  try {
    const jobId = Number(req.params.id);

    if (!Number.isSafeInteger(jobId) || jobId < 1) {
      return res.status(400).json({
        success: false,
        message: "Invalid job ID"
      });
    }

    const result = await pool.query(
      `SELECT
          j.id,
          j.title,
          j.employer,
          j.location,
          j.country,
          j.description,
          j.qualification,
          j.experience,
          j.salary_information,
          j.official_apply_url,
          j.deadline,
          j.category_id,
          c.name AS category_name,
          j.created_at
       FROM jobs j
       LEFT JOIN job_categories c
         ON c.id = j.category_id
       WHERE j.id = $1
         AND j.status = 'published'
       LIMIT 1`,
      [jobId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Job not found"
      });
    }

    res.status(200).json({
      success: true,
      job: result.rows[0]
    });
  } catch (error) {
    console.error("Job details error:", error);

    res.status(500).json({
      success: false,
      message: "Unable to fetch job details"
    });
  }
});

// START SERVER
const PORT = Number(process.env.PORT) || 3000;

const server = app.listen(PORT, () => {
  console.log(`HunarHub API running on port ${PORT}`);
});

// GRACEFUL SHUTDOWN
process.on("SIGTERM", () => {
  server.close(async () => {
    await pool.end();
    process.exit(0);
  });
});

export default app;
