-- Checks the server rules the phone's sync relies on
-- (app/lib/data/sync/sync_engine.dart), with each write shaped as
-- PostgREST sends the phone's upsert: rows from a JSON array, in order,
-- matched on (user_id, id), and only the rows written come back. It runs
-- in one transaction that is rolled back, so it leaves nothing behind:
--
-- * in CI, on plain Postgres after supabase_shim.sql and security_test.sql
--   (see .github/workflows/app-tests.yml);
-- * on a Supabase project, pasted into the SQL editor.
--
-- Any failed check stops it with an error that says what went wrong.

begin;

insert into auth.users (id) values ('00000000-0000-4000-8000-0000000000c1');

set local role authenticated;
set local request.jwt.claims to
  '{"sub": "00000000-0000-4000-8000-0000000000c1", "role": "authenticated"}';

-- A goal as onboarding saves it, at 09:00.
insert into public.goals (
  id, goal_type, basis_weight_kg, calories_kcal, protein_g, carbs_g, fat_g,
  water_ml, steps, formula_version, started_at, created_at, updated_at
) values (
  '019a8c3e-6a00-7000-8000-0000000000c1', 'lose_fat', 50, 1200, 90, 120, 40,
  1750, 8000, 'v1', '2026-11-22T03:30:00Z', '2026-11-22T03:30:00Z',
  '2026-11-22T03:30:00Z'
);

-- The same weigh-in sent twice, as when the reply to the first is lost on
-- the way: one row, which keeps its change number.
do $$
declare
  written integer;
  first_seq bigint;
begin
  for attempt in 1..2 loop
    insert into public.weight_logs
      (id, day, weight_kg, created_at, updated_at, deleted_at)
    select * from json_to_recordset('[{
        "id": "019a8c3e-6a00-7000-8000-0000000000c2",
        "day": "2026-11-22", "weight_kg": 50,
        "created_at": "2026-11-22T03:30:00Z",
        "updated_at": "2026-11-22T03:30:00Z", "deleted_at": null}]')
      as x(id uuid, day date, weight_kg numeric, created_at timestamptz,
           updated_at timestamptz, deleted_at timestamptz)
    on conflict (user_id, id) do update set
      weight_kg = excluded.weight_kg,
      updated_at = excluded.updated_at,
      deleted_at = excluded.deleted_at;
    get diagnostics written = row_count;
    if attempt = 1 then
      assert written = 1, 'the first send should write the weigh-in';
      first_seq := (select seq from public.weight_logs);
    else
      assert written = 0,
        'the same edit sent again should write nothing, so it comes back '
        'as refused and the phone takes the copy''s, which is the same';
    end if;
  end loop;
  assert (select count(*) from public.weight_logs) = 1,
    'sending a row twice should never make two';
  assert (select seq from public.weight_logs) = first_seq,
    'a resend should not take a new change number';
end;
$$;

-- Changing details ends the old goal and starts a new one. Sent ended goal
-- first, as the phone sends retired rows, the batch goes in.
do $$
declare
  written integer;
begin
  insert into public.goals (
    id, goal_type, basis_weight_kg, calories_kcal, protein_g, carbs_g,
    fat_g, water_ml, steps, formula_version, started_at, ended_at,
    created_at, updated_at, deleted_at
  )
  select * from json_to_recordset('[
      {"id": "019a8c3e-6a00-7000-8000-0000000000c1", "goal_type": "lose_fat",
       "basis_weight_kg": 50, "calories_kcal": 1200, "protein_g": 90,
       "carbs_g": 120, "fat_g": 40, "water_ml": 1750, "steps": 8000,
       "formula_version": "v1", "started_at": "2026-11-22T03:30:00Z",
       "ended_at": "2026-11-22T04:30:00Z",
       "created_at": "2026-11-22T03:30:00Z",
       "updated_at": "2026-11-22T04:30:00Z", "deleted_at": null},
      {"id": "019a8c3e-6a00-7000-8000-0000000000c3", "goal_type": "lose_fat",
       "basis_weight_kg": 56, "calories_kcal": 1220, "protein_g": 101,
       "carbs_g": 117, "fat_g": 41, "water_ml": 1960, "steps": 8000,
       "formula_version": "v1", "started_at": "2026-11-22T04:30:00Z",
       "ended_at": null, "created_at": "2026-11-22T04:30:00Z",
       "updated_at": "2026-11-22T04:30:00Z", "deleted_at": null}]')
    as x(id uuid, goal_type text, basis_weight_kg numeric,
         calories_kcal integer, protein_g integer, carbs_g integer,
         fat_g integer, water_ml integer, steps integer,
         formula_version text, started_at timestamptz, ended_at timestamptz,
         created_at timestamptz, updated_at timestamptz,
         deleted_at timestamptz)
  on conflict (user_id, id) do update set
    ended_at = excluded.ended_at,
    updated_at = excluded.updated_at,
    deleted_at = excluded.deleted_at;
  get diagnostics written = row_count;
  assert written = 2, 'both goals should be written';
  assert (select id from public.goals where ended_at is null)
    = '019a8c3e-6a00-7000-8000-0000000000c3',
    'the new goal should be the active one';
end;
$$;

-- The same change in the other order is refused whole: the new goal meets
-- the old one still active. This is why the phone sends retired rows first.
do $$
begin
  insert into public.goals (
    id, goal_type, basis_weight_kg, calories_kcal, protein_g, carbs_g,
    fat_g, water_ml, steps, formula_version, started_at, ended_at,
    created_at, updated_at, deleted_at
  )
  select * from json_to_recordset('[
      {"id": "019a8c3e-6a00-7000-8000-0000000000c4", "goal_type": "maintain",
       "basis_weight_kg": 56, "calories_kcal": 1720, "protein_g": 90,
       "carbs_g": 220, "fat_g": 50, "water_ml": 1960, "steps": 8000,
       "formula_version": "v1", "started_at": "2026-11-22T05:30:00Z",
       "ended_at": null, "created_at": "2026-11-22T05:30:00Z",
       "updated_at": "2026-11-22T05:30:00Z", "deleted_at": null},
      {"id": "019a8c3e-6a00-7000-8000-0000000000c3", "goal_type": "lose_fat",
       "basis_weight_kg": 56, "calories_kcal": 1220, "protein_g": 101,
       "carbs_g": 117, "fat_g": 41, "water_ml": 1960, "steps": 8000,
       "formula_version": "v1", "started_at": "2026-11-22T04:30:00Z",
       "ended_at": "2026-11-22T05:30:00Z",
       "created_at": "2026-11-22T04:30:00Z",
       "updated_at": "2026-11-22T05:30:00Z", "deleted_at": null}]')
    as x(id uuid, goal_type text, basis_weight_kg numeric,
         calories_kcal integer, protein_g integer, carbs_g integer,
         fat_g integer, water_ml integer, steps integer,
         formula_version text, started_at timestamptz, ended_at timestamptz,
         created_at timestamptz, updated_at timestamptz,
         deleted_at timestamptz)
  on conflict (user_id, id) do update set
    ended_at = excluded.ended_at,
    updated_at = excluded.updated_at,
    deleted_at = excluded.deleted_at;
  raise exception 'a new active goal sent before the old one ends should be refused';
exception when unique_violation then
  assert (select count(*) from public.goals) = 2,
    'nothing of a refused batch should be written';
end;
$$;

-- The profile has no id: it's matched on the account, which the server
-- fills in. A second phone's newer profile replaces it; an older one is
-- refused.
do $$
declare
  written integer;
begin
  for edit in 1..3 loop
    insert into public.profiles (
      birth_date, sex, height_cm, activity_level, created_at, updated_at,
      deleted_at
    )
    select * from json_to_recordset(format('[{
        "birth_date": "1996-05-10", "sex": "female", "height_cm": %s,
        "activity_level": "sedentary",
        "created_at": "2026-11-22T03:30:00Z",
        "updated_at": "%s", "deleted_at": null}]',
        (array[155, 158, 160])[edit],
        (array['2026-11-22T03:30:00Z', '2026-11-22T05:30:00Z',
               '2026-11-22T04:30:00Z'])[edit])::json)
      as x(birth_date date, sex text, height_cm numeric,
           activity_level text, created_at timestamptz,
           updated_at timestamptz, deleted_at timestamptz)
    on conflict (user_id) do update set
      height_cm = excluded.height_cm,
      updated_at = excluded.updated_at;
    get diagnostics written = row_count;
    assert written = (array[1, 1, 0])[edit],
      format('profile edit %s should %s', edit,
        (array['be written', 'win, being newer', 'be refused, being older'])[edit]);
  end loop;
  assert (select count(*) from public.profiles) = 1, 'one profile per account';
  assert (select height_cm from public.profiles) = 158,
    'the newest edit should be the one kept';
end;
$$;

-- An entry naming a food the catalogue doesn't have yet is refused, so a
-- catalogue batch reaches the server before any app build carries it.
do $$
begin
  insert into public.meal_entries (
    id, food_id, name, meal, grams, kcal, protein_g, carbs_g, fat_g,
    eaten_at, source, created_at, updated_at
  ) values (
    '019a8c3e-6a00-7000-8000-0000000000c5',
    '019a8c3e-6a00-7000-8000-0000000000ff', 'Dal', 'lunch', 150, 180, 9, 25,
    4, now(), 'search', now(), now()
  );
  raise exception 'an entry naming a food the catalogue lacks should be refused';
exception when foreign_key_violation then
  null;
end;
$$;

-- What a phone fetches is every change after its last change number,
-- oldest first, and the ended goal is among them.
do $$
declare
  seqs bigint[] := (select array_agg(seq order by seq) from public.goals);
begin
  assert array_length(seqs, 1) = 2, 'both goals should be there to fetch';
  assert seqs[1] < seqs[2], 'every change should have its own number';
  assert (select ended_at from public.goals
    where id = '019a8c3e-6a00-7000-8000-0000000000c1') is not null,
    'the ended goal should travel as a change, never a delete';
end;
$$;

reset role;
rollback;

-- Only reached when every check above passed, and after the rollback, so
-- it is the last thing a run shows.
select 'All sync checks passed' as result;
