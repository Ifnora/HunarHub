import { Router, Request, Response } from "express";
import { pool } from "../database";
import { authenticateToken } from "../middleware/auth";

const router = Router();

// GET USER PROFILE
router.get(
  "/",
  authenticateToken,
  async (req: Request, res: Response) => {
    try {
      const userId = req.user!.id;

      await pool.query(
        `INSERT INTO user_profiles (user_id)
         VALUES ($1)
         ON CONFLICT (user_id) DO NOTHING`,
        [userId]
      );

      const result = await pool.query(
        `SELECT
           u.id,
           u.full_name,
           u.email,
           u.phone,
           p.city,
           p.country,
           p.education,
           p.skills,
           p.experience,
           p.updated_at
         FROM app_users u
         LEFT JOIN user_profiles p ON p.user_id = u.id
         WHERE u.id = $1 AND u.is_active = TRUE`,
        [userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          success: false,
          message: "User profile not found"
        });
      }

      return res.status(200).json({
        success: true,
        profile: result.rows[0]
      });
    } catch (error) {
      console.error("Get profile error:", error);

      return res.status(500).json({
        success: false,
        message: "Unable to fetch profile"
      });
    }
  }
);

// UPDATE USER PROFILE
router.put(
  "/",
  authenticateToken,
  async (req: Request, res: Response) => {
    try {
      const { city, country, education, skills, experience } = req.body;

      if (
        city !== undefined &&
        (typeof city !== "string" || city.length > 100)
      ) {
        return res.status(400).json({
          success: false,
          message: "Invalid city"
        });
      }

      if (
        country !== undefined &&
        (typeof country !== "string" || country.length > 100)
      ) {
        return res.status(400).json({
          success: false,
          message: "Invalid country"
        });
      }

      for (const [field, value] of Object.entries({
        education,
        skills,
        experience
      })) {
        if (value !== undefined && !Array.isArray(value)) {
          return res.status(400).json({
            success: false,
            message: `${field} must be an array`
          });
        }
      }

      const userId = req.user!.id;

      const result = await pool.query(
        `INSERT INTO user_profiles (
           user_id, city, country, education, skills, experience, updated_at
         )
         VALUES (
           $1, $2, COALESCE($3, 'Pakistan'),
           $4::jsonb, $5::jsonb, $6::jsonb, NOW()
         )
         ON CONFLICT (user_id)
         DO UPDATE SET
           city = COALESCE($2, user_profiles.city),
           country = COALESCE($3, user_profiles.country),
           education = COALESCE($4::jsonb, user_profiles.education),
           skills = COALESCE($5::jsonb, user_profiles.skills),
           experience = COALESCE($6::jsonb, user_profiles.experience),
           updated_at = NOW()
         RETURNING user_id, city, country, education, skills, experience, updated_at`,
        [
          userId,
          city ?? null,
          country ?? null,
          education === undefined ? null : JSON.stringify(education),
          skills === undefined ? null : JSON.stringify(skills),
          experience === undefined ? null : JSON.stringify(experience)
        ]
      );

      return res.status(200).json({
        success: true,
        message: "Profile updated successfully",
        profile: result.rows[0]
      });
    } catch (error) {
      console.error("Update profile error:", error);

      return res.status(500).json({
        success: false,
        message: "Unable to update profile"
      });
    }
  }
);

export default router;
