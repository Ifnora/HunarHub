import { Router, Request, Response } from "express";
import { pool } from "../database";
import { authenticateToken } from "../middleware/auth";

const router = Router();

router.use(authenticateToken);

// GET SAVED JOBS
router.get("/saved", async (req: Request, res: Response) => {
  try {
    const result = await pool.query(
      `SELECT
         j.id,
         j.title,
         j.employer,
         j.location,
         j.country,
         j.official_apply_url,
         j.deadline,
         s.saved_at
       FROM saved_jobs s
       JOIN jobs j ON j.id = s.job_id
       WHERE s.user_id = $1
       ORDER BY s.saved_at DESC`,
      [req.user!.id]
    );

    return res.status(200).json({
      success: true,
      jobs: result.rows
    });
  } catch (error) {
    console.error("Saved jobs error:", error);
    return res.status(500).json({
      success: false,
      message: "Unable to retrieve saved jobs"
    });
  }
});

// SAVE A JOB
router.post("/saved/:jobId", async (req: Request, res: Response) => {
  try {
    const jobId = Number(req.params.jobId);

    if (!Number.isSafeInteger(jobId) || jobId < 1) {
      return res.status(400).json({
        success: false,
        message: "Invalid job ID"
      });
    }

    const job = await pool.query(
      `SELECT id FROM jobs
       WHERE id = $1 AND status = 'published'`,
      [jobId]
    );

    if (job.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Published job not found"
      });
    }

    await pool.query(
      `INSERT INTO saved_jobs (user_id, job_id)
       VALUES ($1, $2)
       ON CONFLICT (user_id, job_id) DO NOTHING`,
      [req.user!.id, jobId]
    );

    return res.status(200).json({
      success: true,
      message: "Job saved successfully"
    });
  } catch (error) {
    console.error("Save job error:", error);
    return res.status(500).json({
      success: false,
      message: "Unable to save job"
    });
  }
});

// REMOVE SAVED JOB
router.delete("/saved/:jobId", async (req: Request, res: Response) => {
  try {
    const jobId = Number(req.params.jobId);

    if (!Number.isSafeInteger(jobId) || jobId < 1) {
      return res.status(400).json({
        success: false,
        message: "Invalid job ID"
      });
    }

    await pool.query(
      `DELETE FROM saved_jobs
       WHERE user_id = $1 AND job_id = $2`,
      [req.user!.id, jobId]
    );

    return res.status(200).json({
      success: true,
      message: "Saved job removed"
    });
  } catch (error) {
    console.error("Remove saved job error:", error);
    return res.status(500).json({
      success: false,
      message: "Unable to remove saved job"
    });
  }
});

// APPLY FOR A JOB
router.post("/:jobId/apply", async (req: Request, res: Response) => {
  try {
    const jobId = Number(req.params.jobId);

    if (!Number.isSafeInteger(jobId) || jobId < 1) {
      return res.status(400).json({
        success: false,
        message: "Invalid job ID"
      });
    }

    const job = await pool.query(
      `SELECT id FROM jobs
       WHERE id = $1
         AND status = 'published'
         AND (deadline IS NULL OR deadline >= CURRENT_DATE)`,
      [jobId]
    );

    if (job.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Available job not found"
      });
    }

    const result = await pool.query(
      `INSERT INTO applications (
         user_id,
         job_id,
         application_date,
         status
       )
       VALUES ($1, $2, CURRENT_DATE, 'applied')
       ON CONFLICT (user_id, job_id) DO NOTHING
       RETURNING id, job_id, application_date, status`,
      [req.user!.id, jobId]
    );

    if (result.rows.length === 0) {
      return res.status(409).json({
        success: false,
        message: "You have already recorded an application for this job"
      });
    }

    return res.status(201).json({
      success: true,
      message: "Application recorded successfully",
      application: result.rows[0]
    });
  } catch (error) {
    console.error("Job application error:", error);
    return res.status(500).json({
      success: false,
      message: "Unable to record application"
    });
  }
});

// GET APPLICATION TRACKING
router.get("/", async (req: Request, res: Response) => {
  try {
    const result = await pool.query(
      `SELECT
         a.id,
         a.job_id,
         a.application_date,
         a.status,
         a.notes,
         j.title,
         j.employer,
         j.location,
         j.country,
         j.official_apply_url
       FROM applications a
       JOIN jobs j ON j.id = a.job_id
       WHERE a.user_id = $1
       ORDER BY a.created_at DESC`,
      [req.user!.id]
    );

    return res.status(200).json({
      success: true,
      count: result.rows.length,
      applications: result.rows
    });
  } catch (error) {
    console.error("Application tracking error:", error);
    return res.status(500).json({
      success: false,
      message: "Unable to retrieve applications"
    });
  }
});

export default router;
