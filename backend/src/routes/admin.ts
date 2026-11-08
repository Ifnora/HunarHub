import { Router, Request, Response, NextFunction } from "express";
import { pool } from "../database";
import { authenticateToken } from "../middleware/auth";

const router = Router();

// ADMIN ACCESS CONTROL
function requireAdmin(
  req: Request,
  res: Response,
  next: NextFunction
) {
  if (!req.user || req.user.role !== "admin") {
    return res.status(403).json({
      success: false,
      message: "Admin access required"
    });
  }

  next();
}

router.use(authenticateToken);
router.use(requireAdmin);

// GET ALL JOBS FOR ADMIN REVIEW
router.get("/jobs", async (req: Request, res: Response) => {
  try {
    const status = req.query.status as string | undefined;

    const allowedStatuses = [
      "pending",
      "approved",
      "published",
      "rejected",
      "expired"
    ];

    if (status && !allowedStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: "Invalid job status"
      });
    }

    const result = await pool.query(
      `SELECT *
       FROM jobs
       WHERE ($1::text IS NULL OR status = $1)
       ORDER BY created_at DESC
       LIMIT 100`,
      [status || null]
    );

    return res.json({
      success: true,
      count: result.rows.length,
      jobs: result.rows
    });
  } catch (error) {
    console.error("Admin jobs error:", error);
    return res.status(500).json({
      success: false,
      message: "Unable to fetch jobs"
    });
  }
});

// CREATE JOB
router.post("/jobs", async (req: Request, res: Response) => {
  try {
    const {
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
      category_id
    } = req.body;

    if (
      !title ||
      !employer ||
      !description ||
      !official_apply_url ||
      !category_id
    ) {
      return res.status(400).json({
        success: false,
        message: "Required job fields are missing"
      });
    }

    let applyUrl: URL;

    try {
      applyUrl = new URL(official_apply_url);
    } catch {
      return res.status(400).json({
        success: false,
        message: "Invalid official application URL"
      });
    }

    if (applyUrl.protocol !== "https:") {
      return res.status(400).json({
        success: false,
        message: "Application URL must use HTTPS"
      });
    }

    const result = await pool.query(
      `INSERT INTO jobs (
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
        category_id,
        status
      )
      VALUES (
        $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,'pending'
      )
      RETURNING *`,
      [
        title,
        employer,
        location || null,
        country || "Pakistan",
        description,
        qualification || null,
        experience || null,
        salary_information || null,
        applyUrl.toString(),
        deadline || null,
        category_id
      ]
    );

    return res.status(201).json({
      success: true,
      message: "Job submitted for review",
      job: result.rows[0]
    });
  } catch (error) {
    console.error("Admin create job error:", error);
    return res.status(500).json({
      success: false,
      message: "Unable to create job"
    });
  }
});

// APPROVE JOB
router.patch("/jobs/:id/approve", async (req: Request, res: Response) => {
  try {
    const result = await pool.query(
      `UPDATE jobs
       SET status = 'approved'
       WHERE id = $1
       RETURNING *`,
      [req.params.id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        success: false,
        message: "Job not found"
      });
    }

    return res.json({
      success: true,
      message: "Job approved",
      job: result.rows[0]
    });
  } catch (error) {
    console.error("Approve job error:", error);
    return res.status(500).json({
      success: false,
      message: "Unable to approve job"
    });
  }
});

// PUBLISH APPROVED JOB
router.patch("/jobs/:id/publish", async (req: Request, res: Response) => {
  try {
    const result = await pool.query(
      `UPDATE jobs
       SET status = 'published'
       WHERE id = $1 AND status = 'approved'
       RETURNING *`,
      [req.params.id]
    );

    if (result.rowCount === 0) {
      return res.status(400).json({
        success: false,
        message: "Job not found or not approved"
      });
    }

    return res.json({
      success: true,
      message: "Job published successfully",
      job: result.rows[0]
    });
  } catch (error) {
    console.error("Publish job error:", error);
    return res.status(500).json({
      success: false,
      message: "Unable to publish job"
    });
  }
});

// REJECT JOB
router.patch("/jobs/:id/reject", async (req: Request, res: Response) => {
  try {
    const result = await pool.query(
      `UPDATE jobs
       SET status = 'rejected'
       WHERE id = $1
       RETURNING *`,
      [req.params.id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        success: false,
        message: "Job not found"
      });
    }

    return res.json({
      success: true,
      message: "Job rejected",
      job: result.rows[0]
    });
  } catch (error) {
    console.error("Reject job error:", error);
    return res.status(500).json({
      success: false,
      message: "Unable to reject job"
    });
  }
});

export default router;
