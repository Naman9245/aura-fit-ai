// delete-account: removes the signed-in account and everything it synced,
// at once, as the sign-in consent promises and Google Play requires of
// apps with accounts. Needs no secrets of its own.
import { withSupabase } from "npm:@supabase/server@1.9.2";
import { messageOf } from "../_shared/http.ts";
import { deleteAccount } from "./handler.ts";

const log = (event: Record<string, unknown>) =>
  console.log(JSON.stringify({ fn: "delete-account", ...event }));

Deno.serve(
  withSupabase({ auth: "user", cors: false }, async (req, ctx) => {
    const userId = ctx.userClaims?.id;
    if (!userId) return Response.json({ error: "signed_out" }, { status: 401 });
    const admin = ctx.supabaseAdmin;
    return await deleteAccount(req, userId, {
      deleteUser: async (id) => {
        const { error } = await admin.auth.admin.deleteUser(id);
        if (error) log({ event: "auth_error", message: messageOf(error) });
        return error == null;
      },
      log,
    });
  }),
);
