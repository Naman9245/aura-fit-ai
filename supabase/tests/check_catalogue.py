"""Checks the app's bundled food catalogue matches the server's, row for row.

app/assets/foods.json is what a phone searches before it first syncs, and
it fetches only foods with a higher seq than the bundled copy's. So a row
that differs, or a seq the server didn't give, would stay wrong on phones
for good. Usage, after applying every migration:

    psql -At -f supabase/tests/catalogue.sql > server_foods.json
    python3 supabase/tests/check_catalogue.py app/assets/foods.json server_foods.json

To change a food, add a migration and an entry in LATER_FIXES in
app/tool/build_food_catalogue.py, then rerun that script.
"""

from __future__ import annotations

import json
import sys

FIELDS = [
    "name",
    "aliases",
    "kcal_per_100g",
    "protein_g_per_100g",
    "carbs_g_per_100g",
    "fat_g_per_100g",
    "portions",
    "assumption",
    "source",
    "seq",
]


def same(a: object, b: object) -> bool:
    # Postgres prints numeric(5, 1) as 142.0 where the app may have 142.
    if isinstance(a, (int, float)) and isinstance(b, (int, float)):
        return float(a) == float(b)
    # A food with no assumption has '' in the app and may have NULL here.
    if a in (None, "") and b in (None, ""):
        return True
    return a == b


def main(bundled_path: str, server_path: str) -> int:
    with open(bundled_path, encoding="utf-8") as f:
        bundled = {row["id"]: row for row in json.load(f)}
    with open(server_path, encoding="utf-8") as f:
        server = {row["id"]: row for row in json.load(f)}

    problems = [f"only in the app: {i}" for i in sorted(bundled.keys() - server.keys())]
    problems += [f"only on the server: {i}" for i in sorted(server.keys() - bundled.keys())]
    for food_id in sorted(bundled.keys() & server.keys()):
        for field in FIELDS:
            app_value, server_value = bundled[food_id].get(field), server[food_id].get(field)
            if not same(app_value, server_value):
                problems.append(
                    f"{food_id} {field}: app {app_value!r}, server {server_value!r}"
                )

    if problems:
        print("The bundled catalogue and the server's differ:")
        print("\n".join(problems[:50]))
        return 1
    print(f"The bundled catalogue matches the server's: {len(server)} foods.")
    return 0


if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:]))
