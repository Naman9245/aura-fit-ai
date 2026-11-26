// parse-meal: server-side natural-language meal parser (PRD N2).
// Verifies the user's JWT, rejects anonymous sessions, enforces daily per-user
// and app-wide caps in Postgres, and calls Gemini Flash-Lite through the
// shared adapter. Prompt text is never logged.
import { withSupabase } from "npm:@supabase/server@1.9.2";
import { generateStructuredJson } from "../_shared/gemini.ts";
import { fail, messageOf } from "../_shared/http.ts";
import {
  PARSE_MEAL_SCHEMA,
  PARSE_MEAL_SYSTEM_PROMPT,
  type ParsedMealItem,
  parseMeal,
} from "./handler.ts";

const log = (event: Record<string, unknown>) =>
  console.log(JSON.stringify({ fn: "parse-meal", ...event }));

function envInt(name: string, fallback: number): number {
  const raw = Deno.env.get(name);
  if (!raw) return fallback;
  const parsed = Number.parseInt(raw, 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

Deno.serve(
  withSupabase({ auth: "user", cors: false }, async (req, ctx) => {
    const claims = ctx.userClaims as
      | { id?: string; is_anonymous?: boolean }
      | undefined;
    const userId = claims?.id;
    if (!userId || claims?.is_anonymous === true) {
      return fail(401, "signed_out");
    }

    const apiKey = Deno.env.get("GEMINI_API_KEY") ?? "";
    if (!apiKey) {
      log({ event: "missing_gemini_key" });
      return fail(503, "ai_unavailable");
    }
    // Google serves the 2.5 models only to projects that already used them,
    // so new keys need a 3.x model. The price in _shared/gemini.ts goes
    // with this model.
    const model = Deno.env.get("GEMINI_MODEL") ?? "gemini-3.5-flash-lite";
    const userDailyLimit = envInt("AI_PARSE_USER_LIMIT", 25);
    const totalDailyLimit = envInt("AI_PARSE_TOTAL_LIMIT", 20_000);
    const admin = ctx.supabaseAdmin;

    return await parseMeal(req, userId, {
      model,
      userDailyLimit,
      totalDailyLimit,
      takeCall: async (uid, uLimit, tLimit) => {
        const { data, error } = await admin.rpc("take_ai_call", {
          p_user_id: uid,
          p_kind: "parse",
          p_user_limit: uLimit,
          p_total_limit: tLimit,
        });
        if (error || typeof data !== "number") {
          log({ event: "quota_rpc_error", message: messageOf(error) });
          return -2;
        }
        return data;
      },
      refundCall: async (uid) => {
        const { error } = await admin.rpc("refund_ai_call", {
          p_user_id: uid,
          p_kind: "parse",
        });
        if (error) log({ event: "refund_rpc_error", message: messageOf(error) });
      },
      recordCall: async (entry) => {
        const { error } = await admin.rpc("record_ai_call", {
          p_user_id: entry.userId,
          p_kind: "parse",
          p_model: entry.model,
          p_response_ms: entry.responseMs,
          p_cost_usd: entry.costUsd,
          p_outcome: entry.outcome,
        });
        if (error) log({ event: "record_rpc_error", message: messageOf(error) });
      },
      parseWithAi: async (text) => {
        const res = await generateStructuredJson<{ items: ParsedMealItem[] }>({
          apiKey,
          model,
          systemInstruction: PARSE_MEAL_SYSTEM_PROMPT,
          userText: text,
          responseSchema: PARSE_MEAL_SCHEMA,
          timeoutMs: 15_000,
        });
        return {
          items: res.data.items,
          model: res.model,
          responseMs: res.responseMs,
          costUsd: res.costUsd,
        };
      },
      log,
    });
  }),
);
