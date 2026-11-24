import assert from "node:assert/strict";
import { deleteAccount, type Deps } from "./handler.ts";

function deps(deleted = true) {
  const asked: string[] = [];
  const events: Record<string, unknown>[] = [];
  const fake: Deps = {
    deleteUser: (userId) => {
      asked.push(userId);
      return Promise.resolve(deleted);
    },
    log: (event) => events.push(event),
  };
  return { fake, asked, events };
}

const post = () =>
  new Request("http://localhost/delete-account", { method: "POST" });

Deno.test("deletes the signed-in account, and only that one", async () => {
  const { fake, asked, events } = deps();
  const reply = await deleteAccount(post(), "user-1", fake);
  assert.equal(reply.status, 200);
  assert.deepEqual(await reply.json(), { deleted: true });
  assert.deepEqual(asked, ["user-1"]);
  assert.deepEqual(events, [{ event: "deleted" }]);
});

Deno.test("says so when Auth refuses", async () => {
  const { fake, events } = deps(false);
  const reply = await deleteAccount(post(), "user-1", fake);
  assert.equal(reply.status, 502);
  assert.deepEqual(await reply.json(), { error: "not_deleted" });
  assert.deepEqual(events, [{ event: "not_deleted" }]);
});

Deno.test("only a POST deletes", async () => {
  const { fake, asked } = deps();
  const reply = await deleteAccount(
    new Request("http://localhost/delete-account"),
    "user-1",
    fake,
  );
  assert.equal(reply.status, 405);
  assert.deepEqual(asked, []);
});
