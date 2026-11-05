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

app.get("/", (_req, res) => {
  res.json({
    success: true,
    message: "Welcome to HunarHub Pakistan API"
  });
});

app.get("/health", (_req, res) => {
  res.status(200).json({
    success: true,
    service: "HunarHub Pakistan",
    status: "running"
  });
});

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

const PORT = Number(process.env.PORT) || 3000;

const server = app.listen(PORT, () => {
  console.log(`HunarHub API running on port ${PORT}`);
});

process.on("SIGTERM", () => {
  server.close(async () => {
    await pool.end();
    process.exit(0);
  });
});
