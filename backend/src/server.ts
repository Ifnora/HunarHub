
import express from "express";
import cors from "cors";
import helmet from "helmet";
import dotenv from "dotenv";
import { pool } from "./database";

dotenv.config();

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: "1mb" }));

// Home route
app.get("/", (_req, res) => {
  res.status(200).json({
    success: true,
    message: "Welcome to HunarHub Pakistan API"
  });
});

// API health check
app.get("/health", (_req, res) => {
  res.status(200).json({
    success: true,
    service: "HunarHub Pakistan",
    status: "running"
  });
});

// Database health check
app.get("/health/database", async (_req, res) => {
  try {
    await pool.query("SELECT 1");

    res.status(200).json({
      success: true,
      database: "connected"
    });
  } catch (error) {
    console.error("Database health check failed:", error);

    res.status(503).json({
      success: false,
      database: "unavailable"
    });
  }
});

// Job categories
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
    console.error("Job categories error:", error);

    res.status(500).json({
      success: false,
      message: "Unable to fetch job categories"
    });
  }
});

// Start API server
const PORT = Number(process.env.PORT) || 3000;

const server = app.listen(PORT, () => {
  console.log(`HunarHub API running on port ${PORT}`);
});

// Graceful shutdown
process.on("SIGTERM", () => {
  server.close(async () => {
    await pool.end();
    process.exit(0);
  });
});
