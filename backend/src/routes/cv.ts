import { Router, Request, Response } from "express";
import { pool } from "../database";
import { authenticateToken } from "../middleware/auth";

const router = Router();

router.use(authenticateToken);

// GET: Retrieve user's CVs
router.get("/", async (req: Request, res: Response) => {
  try {
    const result = await pool.query(
      `SELECT id, title, content, created_at, updated_at
       FROM cvs
       WHERE user_id = $1
       ORDER BY updated_at DESC`,
      [req.user!.id]
    );

    return res.json({
      success: true,
      cvs: result.rows
    });
  } catch (error) {
    console.error("CV retrieval error:", error);
    return res.status(500).json({
      success: false,
      message: "Unable to retrieve CVs"
    });
  }
});

// POST: Create a new CV
router.post("/", async (req: Request, res: Response) => {
  try {
    const { title, content } = req.body;

    if (
      typeof title !== "string" ||
      !title.trim() ||
      typeof content !== "object" ||
      content === null ||
      Array.isArray(content)
    ) {
      return res.status(400).json({
        success: false,
        message: "Valid CV title and content are required"
      });
    }

    const result = await pool.query(
      `INSERT INTO cvs (user_id, title, content)
       VALUES ($1, $2, $3)
       RETURNING id, title, content, created_at, updated_at`,
      [req.user!.id, title.trim(), JSON.stringify(content)]
    );

    return res.status(201).json({
      success: true,
      message: "CV created successfully",
      cv: result.rows[0]
    });
  } catch (error) {
    console.error("CV creation error:", error);
    return res.status(500).json({
      success: false,
      message: "Unable to create CV"
    });
  }
});

export default router;
