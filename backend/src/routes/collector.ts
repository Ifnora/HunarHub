
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

// SHARED COLLECTION HANDLER
async function runCollection(
  res: Response
) {
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
}

// SECURE AUTOMATIC CRON ENDPOINT
// Must be registered BEFORE user authentication middleware.
router.get(
  "/cron",
  async (req: Request, res: Response) => {
    const cronSecret = process.env.CRON_SECRET;

    if (
      !cronSecret ||
      req.get("authorization") !== `Bearer ${cronSecret}`
    ) {
      return res.status(401).json({
        success: false,
        message: "Unauthorized"
      });
    }

    console.log("Scheduled HunarHub job collection started");

    return runCollection(res);
  }
);

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

// EXISTING ADMIN COLLECTION ENDPOINT
router.post(
  "/run",
  async (_req: Request, res: Response) => {
    console.log("Admin HunarHub job collection started");

    return runCollection(res);
  }
);

export default router;
