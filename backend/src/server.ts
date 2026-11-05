import express from "express";
import cors from "cors";
import helmet from "helmet";
import dotenv from "dotenv";

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

const PORT = Number(process.env.PORT) || 3000;

app.listen(PORT, () => {
  console.log(`HunarHub API running on port ${PORT}`);
});
