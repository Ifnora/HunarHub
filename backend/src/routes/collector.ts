import {
  Router,
  Request,
  Response,
  NextFunction
} from "express";

import { authenticateToken } from "../middleware/auth";
import { collectJobs } from "../job_collector";

const router = Router();

let collectionRunning = false;

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

// RUN AUTOMATIC JOB COLLECTION
router.post("/run", async (_req: Request, res: Response) => {
  if (collectionRunning) {
    return res.status(409).json({
      success: false,
      message: "Job collection is already running"
    });
  }

  collectionRunning = true;

  try {
    const result = await collectJobs();

    return res.status(200).json(result);
  } catch (error) {
    console.error("Job collector route error:", error);

    return res.status(500).json({
      success: false,
      message: "Job collection failed"
    });
  } finally {
    collectionRunning = false;
  }
});

export default router;
