// Small helpers every function uses.

/** A JSON error reply, `{ error, ...extra }`. */
export function fail(
  status: number,
  error: string,
  extra: Record<string, unknown> = {},
): Response {
  return Response.json({ error, ...extra }, { status });
}

export function messageOf(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
