// Shared Gemini adapter. Every AI feature calls Gemini through this one file
// so switching model or provider is a single-file change (PRD Architecture).

export interface GeminiTextRequest {
  apiKey: string;
  model: string;
  systemInstruction: string;
  userText: string;
  responseSchema: Record<string, unknown>;
  timeoutMs?: number;
  fetchFn?: typeof fetch;
}

export type GeminiFailureKind = "timeout" | "upstream_error" | "bad_json";

export class GeminiError extends Error {
  readonly kind: GeminiFailureKind;

  constructor(kind: GeminiFailureKind, message: string) {
    super(message);
    this.kind = kind;
    this.name = "GeminiError";
  }
}

export interface GeminiJsonResult<T> {
  data: T;
  model: string;
  responseMs: number;
  costUsd: number;
}

// Gemini 2.5 Flash-Lite list pricing ($0.10 / 1M input, $0.40 / 1M output).
const INPUT_USD_PER_TOKEN = 0.10 / 1_000_000;
const OUTPUT_USD_PER_TOKEN = 0.40 / 1_000_000;

export async function generateStructuredJson<T>(
  req: GeminiTextRequest,
): Promise<GeminiJsonResult<T>> {
  const started = performance.now();
  const timeoutMs = req.timeoutMs ?? 15_000;
  const fetchImpl = req.fetchFn ?? fetch;
  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/` +
    `${encodeURIComponent(req.model)}:generateContent`;

  let response: Response;
  try {
    response = await fetchImpl(url, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-goog-api-key": req.apiKey,
      },
      body: JSON.stringify({
        systemInstruction: {
          parts: [{ text: req.systemInstruction }],
        },
        contents: [
          {
            role: "user",
            parts: [{ text: req.userText }],
          },
        ],
        generationConfig: {
          temperature: 0.1,
          maxOutputTokens: 1024,
          responseMimeType: "application/json",
          responseSchema: req.responseSchema,
        },
      }),
      signal: AbortSignal.timeout(timeoutMs),
    });
  } catch (error) {
    if (
      error instanceof DOMException &&
      (error.name === "TimeoutError" || error.name === "AbortError")
    ) {
      throw new GeminiError("timeout", "gemini_timeout");
    }
    throw new GeminiError("upstream_error", "gemini_unreachable");
  }

  const responseMs = Math.max(0, Math.round(performance.now() - started));
  if (!response.ok) {
    throw new GeminiError("upstream_error", `gemini_http_${response.status}`);
  }

  let payload: Record<string, unknown>;
  try {
    payload = (await response.json()) as Record<string, unknown>;
  } catch {
    throw new GeminiError("bad_json", "gemini_envelope_not_json");
  }

  const candidates = payload.candidates;
  const first = Array.isArray(candidates) ? candidates[0] : undefined;
  const parts = first?.content?.parts;
  const rawText = Array.isArray(parts) && typeof parts[0]?.text === "string"
    ? parts[0].text
    : undefined;
  if (!rawText) {
    throw new GeminiError("bad_json", "gemini_empty_candidate");
  }

  let parsed: T;
  try {
    parsed = JSON.parse(rawText) as T;
  } catch {
    throw new GeminiError("bad_json", "gemini_candidate_not_json");
  }

  const usage = (payload.usageMetadata ?? {}) as Record<string, unknown>;
  const inTokens = typeof usage.promptTokenCount === "number"
    ? usage.promptTokenCount
    : 0;
  const outTokens = typeof usage.candidatesTokenCount === "number"
    ? usage.candidatesTokenCount
    : 0;
  const costUsd = Number(
    (inTokens * INPUT_USD_PER_TOKEN + outTokens * OUTPUT_USD_PER_TOKEN)
      .toFixed(6),
  );

  return {
    data: parsed,
    model: req.model,
    responseMs,
    costUsd,
  };
}
