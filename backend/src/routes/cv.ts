
import { Router, Request, Response } from "express";
import { pool } from "../database";
import { authenticateToken } from "../middleware/auth";

const router = Router();

router.use(authenticateToken);

// GET ALL USER CVS
router.get("/", async (req: Request, res: Response) => {
  try {
    const result = await pool.query(
      `SELECT
         id,
         title,
         cv_type,
         template_name,
         content,
         pdf_storage_key,
         created_at,
         updated_at
       FROM cvs
       WHERE user_id = $1
       ORDER BY updated_at DESC`,
      [req.user!.id]
    );

    return res.status(200).json({
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

// CREATE NEW CV
router.post("/", async (req: Request, res: Response) => {
  try {
    const {
      title,
      cv_type,
      template_name,
      content
    } = req.body;

    const allowedTypes = [
      "fresh_graduate",
      "experienced",
      "banking"
    ];

    if (
      typeof title !== "string" ||
      title.trim().length < 2 ||
      title.trim().length > 150
    ) {
      return res.status(400).json({
        success: false,
        message: "CV title must be between 2 and 150 characters"
      });
    }

    if (
      typeof cv_type !== "string" ||
      !allowedTypes.includes(cv_type)
    ) {
      return res.status(400).json({
        success: false,
        message: "CV type must be fresh_graduate, experienced or banking"
      });
    }

    if (
      template_name !== undefined &&
      (typeof template_name !== "string" ||
       template_name.length > 100)
    ) {
      return res.status(400).json({
        success: false,
        message: "Invalid CV template name"
      });
    }

    if (
      content !== undefined &&
      (typeof content !== "object" ||
       content === null ||
       Array.isArray(content))
    ) {
      return res.status(400).json({
        success: false,
        message: "CV content must be a valid JSON object"
      });
    }

    const result = await pool.query(
      `INSERT INTO cvs (
         user_id,
         title,
         cv_type,
         template_name,
         content
       )
       VALUES ($1, $2, $3, $4, $5::jsonb)
       RETURNING
         id,
         title,
         cv_type,
         template_name,
         content,
         created_at,
         updated_at`,
      [
        req.user!.id,
        title.trim(),
        cv_type,
        template_name || null,
        JSON.stringify(content || {})
      ]
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

// UPDATE EXISTING CV
router.put("/:id", async (req: Request, res: Response) => {
  try {
    const cvId = Number(req.params.id);
    const { title, cv_type, template_name, content } = req.body;

    if (!Number.isSafeInteger(cvId) || cvId < 1) {
      return res.status(400).json({
        success: false,
        message: "Invalid CV ID"
      });
    }

    const allowedTypes = [
      "fresh_graduate",
      "experienced",
      "banking"
    ];

    if (
      typeof title !== "string" ||
      title.trim().length < 2 ||
      title.trim().length > 150 ||
      typeof cv_type !== "string" ||
      !allowedTypes.includes(cv_type) ||
      typeof content !== "object" ||
      content === null ||
      Array.isArray(content)
    ) {
      return res.status(400).json({
        success: false,
        message: "Valid title, CV type and content are required"
      });
    }

    if (
      template_name !== undefined &&
      (typeof template_name !== "string" ||
       template_name.length > 100)
    ) {
      return res.status(400).json({
        success: false,
        message: "Invalid CV template name"
      });
    }

    const result = await pool.query(
      `UPDATE cvs
       SET title = $1,
           cv_type = $2,
           template_name = $3,
           content = $4::jsonb,
           updated_at = NOW()
       WHERE id = $5 AND user_id = $6
       RETURNING
         id,
         title,
         cv_type,
         template_name,
         content,
         created_at,
         updated_at`,
      [
        title.trim(),
        cv_type,
        template_name || null,
        JSON.stringify(content),
        cvId,
        req.user!.id
      ]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "CV not found"
      });
    }

    return res.status(200).json({
      success: true,
      message: "CV updated successfully",
      cv: result.rows[0]
    });
  } catch (error) {
    console.error("CV update error:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to update CV"
    });
  }
});

// DELETE EXISTING CV
router.delete("/:id", async (req: Request, res: Response) => {
  try {
    const cvId = Number(req.params.id);

    if (!Number.isSafeInteger(cvId) || cvId < 1) {
      return res.status(400).json({
        success: false,
        message: "Invalid CV ID"
      });
    }

    const result = await pool.query(
      `DELETE FROM cvs
       WHERE id = $1 AND user_id = $2
       RETURNING id`,
      [cvId, req.user!.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "CV not found"
      });
    }

    return res.status(200).json({
      success: true,
      message: "CV deleted successfully"
    });
  } catch (error) {
    console.error("CV deletion error:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to delete CV"
    });
  }
});

export default router;
