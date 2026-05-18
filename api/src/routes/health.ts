import { Router } from "express";
import { pingDb } from "../db.js";

export const healthRouter = Router();

healthRouter.get("/health", async (_req, res) => {
  const db = await pingDb();
  res.json({ ok: true, db });
});
