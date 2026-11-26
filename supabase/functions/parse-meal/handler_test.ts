import assert from "node:assert/strict";
import { GeminiError, generateStructuredJson } from "../_shared/gemini.ts";
import {
  MAX_MEAL_TEXT_CHARS,
  parseMeal,
  type ParseMealDeps,
  type ParseResult,
} from "./handler.ts";

function makeDeps(overrides: Partial<ParseMealDeps> = {}) {
  let refunded = 0;
  const recorded: Array<Record<string, unknown>> = [];
  const events: Array<Record<string, unknown>> = [];

  const sampleResult: ParseResult = {
    model: "gemini-3.5-flash-lite",
    responseMs: 420,
    costUsd: 0.00008,
    items: [
      {
        name: "Phulka (plain wheat roti)",
        search_query: "roti",
        quantity: 2,
        unit: "piece",
        oil_level: "low",
        estimated_grams: 60,
        kcal: 180,
        protein_g: 6,
        carbs_g: 36,
        fat_g: 1.2,
        confidence: "high",
      },
      {
        name: "Moong dal tadka",
        search_query: "moong dal",
        quantity: 1,
        unit: "katori",
        oil_level: "home",
        estimated_grams: 150,
        kcal: 165,
        protein_g: 9,
        carbs_g: 21,
        fat_g: 4.8,
        confidence: "high",
      },
    ],
  };

  const deps: ParseMealDeps = {
    model: "gemini-3.5-flash-lite",
    userDailyLimit: 25,
    totalDailyLimit: 20_000,
    takeCall: () => Promise.resolve(24),
    refundCall: () => {
      refunded += 1;
      return Promise.resolve();
    },
    recordCall: (entry) => {
      recorded.push(entry);
      return Promise.resolve();
    },
    parseWithAi: () => Promise.resolve(sampleResult),
    log: (event) => events.push(event),
    ...overrides,
  };

  return { deps, getRefunded: () => refunded, recorded, events };
}

const postJson = (body: unknown) =>
  new Request("http://localhost/parse-meal", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });

Deno.test("parses a Hinglish meal note, records telemetry, and never logs prompt text", async () => {
  const { deps, getRefunded, recorded, events } = makeDeps();
  const secretNote = "2 roti without ghee aur 1 katori moong dal";
  const res = await parseMeal(postJson({ text: secretNote }), "user-1", deps);

  assert.equal(res.status, 200);
  const body = await res.json();
  assert.equal(body.remaining, 24);
  assert.equal(body.items.length, 2);
  assert.equal(body.items[0].search_query, "roti");
  assert.equal(body.items[0].oil_level, "low");
  assert.equal(getRefunded(), 0);
  assert.equal(recorded.length, 1);
  assert.equal(recorded[0].outcome, "ok");
  assert.equal(JSON.stringify(events).includes(secretNote), false);
});

Deno.test("rejects empty text and text over 300 characters before taking quota", async () => {
  let took = 0;
  const { deps } = makeDeps({
    takeCall: () => {
      took += 1;
      return Promise.resolve(24);
    },
  });

  const empty = await parseMeal(postJson({ text: "   " }), "user-1", deps);
  assert.equal(empty.status, 400);
  assert.deepEqual(await empty.json(), { error: "empty_text" });

  const longText = "a".repeat(MAX_MEAL_TEXT_CHARS + 1);
  const tooLong = await parseMeal(postJson({ text: longText }), "user-1", deps);
  assert.equal(tooLong.status, 400);
  assert.deepEqual(await tooLong.json(), {
    error: "text_too_long",
    max_chars: 300,
  });
  assert.equal(took, 0);
});

Deno.test("returns 429 when user or app daily limit is reached", async () => {
  const userCap = makeDeps({ takeCall: () => Promise.resolve(-1) });
  const r1 = await parseMeal(postJson({ text: "2 idli" }), "user-1", userCap.deps);
  assert.equal(r1.status, 429);
  assert.deepEqual(await r1.json(), { error: "user_daily_limit", remaining: 0 });
  assert.equal(userCap.recorded[0].outcome, "rate_limited");

  const appCap = makeDeps({ takeCall: () => Promise.resolve(-2) });
  const r2 = await parseMeal(postJson({ text: "2 idli" }), "user-1", appCap.deps);
  assert.equal(r2.status, 429);
  assert.deepEqual(await r2.json(), { error: "app_daily_limit", remaining: 0 });
});

Deno.test("refunds quota and records failure when Gemini times out or returns bad JSON", async () => {
  const timedOut = makeDeps({
    parseWithAi: () => Promise.reject(new GeminiError("timeout", "slow")),
  });
  const r1 = await parseMeal(
    postJson({ text: "paneer tikka" }),
    "user-1",
    timedOut.deps,
  );
  assert.equal(r1.status, 504);
  assert.equal(timedOut.getRefunded(), 1);
  assert.equal(timedOut.recorded[0].outcome, "timeout");

  const badJson = makeDeps({
    parseWithAi: () => Promise.reject(new GeminiError("bad_json", "broken")),
  });
  const r2 = await parseMeal(
    postJson({ text: "paneer tikka" }),
    "user-1",
    badJson.deps,
  );
  assert.equal(r2.status, 502);
  assert.equal(badJson.getRefunded(), 1);
  assert.equal(badJson.recorded[0].outcome, "bad_json");
});

Deno.test("shared Gemini adapter parses structured output and computes token cost", async () => {
  const res = await generateStructuredJson<{ items: Array<{ name: string }> }>({
    apiKey: "test-key",
    model: "gemini-3.5-flash-lite",
    systemInstruction: "Extract food",
    userText: "1 boiled egg",
    responseSchema: { type: "OBJECT" },
    fetchFn: () =>
      Promise.resolve(
        Response.json({
          candidates: [
            {
              content: {
                parts: [{ text: JSON.stringify({ items: [{ name: "Boiled egg" }] }) }],
              },
            },
          ],
          usageMetadata: {
            promptTokenCount: 200,
            candidatesTokenCount: 50,
            thoughtsTokenCount: 20,
          },
        }),
      ),
  });
  assert.equal(res.data.items[0].name, "Boiled egg");
  // 200 × $0.30 + (50 + 20 thinking) × $2.50, per million tokens.
  assert.equal(res.costUsd, 0.000235);
});

Deno.test("a refused Gemini call logs its HTTP status, never the meal", async () => {
  const refused = makeDeps({
    parseWithAi: () =>
      Promise.reject(new GeminiError("upstream_error", "gemini_http_404")),
  });
  const res = await parseMeal(
    postJson({ text: "paneer tikka" }),
    "user-1",
    refused.deps,
  );
  assert.equal(res.status, 502);
  const failed = refused.events.find((e) => e.event === "ai_failed");
  assert.equal(failed?.detail, "gemini_http_404");
  assert.ok(!JSON.stringify(refused.events).includes("paneer"));
});

Deno.test("the adapter reads the answer, not the model's thinking", async () => {
  const res = await generateStructuredJson<{ items: unknown[] }>({
    apiKey: "test-key",
    model: "gemini-3.5-flash-lite",
    systemInstruction: "Extract food",
    userText: "1 boiled egg",
    responseSchema: { type: "OBJECT" },
    fetchFn: () =>
      Promise.resolve(
        Response.json({
          candidates: [{
            content: {
              parts: [
                { text: "Thinking about eggs", thought: true },
                { text: JSON.stringify({ items: [] }) },
              ],
            },
          }],
        }),
      ),
  });
  assert.deepEqual(res.data.items, []);
});
