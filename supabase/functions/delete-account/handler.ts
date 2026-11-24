// Deleting the signed-in account. Its profile, goals, weigh-ins, meals,
// health readings and AI call counts all go with it, by their foreign keys
// (on delete cascade); the app then clears its own copy.
import { fail } from "../_shared/http.ts";

export interface Deps {
  /** Deletes the account; false when Auth refuses. */
  deleteUser(userId: string): Promise<boolean>;
  log(event: Record<string, unknown>): void;
}

export async function deleteAccount(
  req: Request,
  userId: string,
  deps: Deps,
): Promise<Response> {
  if (req.method !== "POST") return fail(405, "method_not_allowed");
  if (!(await deps.deleteUser(userId))) {
    deps.log({ event: "not_deleted" });
    return fail(502, "not_deleted");
  }
  deps.log({ event: "deleted" });
  return Response.json({ deleted: true });
}
