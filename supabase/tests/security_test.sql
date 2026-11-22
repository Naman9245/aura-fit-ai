-- Checks the security rules, the sync trigger and the AI limits after the
-- migrations. It runs in one transaction that is rolled back, so it leaves
-- nothing behind:
--
-- * in CI, on plain Postgres after supabase_shim.sql (see
--   .github/workflows/app-tests.yml);
-- * on a Supabase project, pasted into the SQL editor.
--
-- Any failed check stops it with an error that says what went wrong.

begin;

-- Every table of a person's own data has row-level security, the three
-- policies and the sync trigger. The checks below try them on three of
-- the tables; this makes sure the other two got the same.
do $$
declare
  t text;
begin
  foreach t in array array[
    'profiles', 'goals', 'weight_logs', 'meal_entries', 'health_samples'
  ] loop
    assert (select relrowsecurity from pg_class
      where oid = ('public.' || t)::regclass),
      format('%s should have row-level security', t);
    assert (select count(*) from pg_policies
      where schemaname = 'public' and tablename = t) = 3,
      format('%s should have its three policies', t);
    assert exists (select from pg_trigger
      where tgrelid = ('public.' || t)::regclass
        and tgname = t || '_sync_stamp'),
      format('%s should run sync_stamp', t);
  end loop;
end;
$$;

-- Two throwaway accounts, A and B.
insert into auth.users (id) values
  ('00000000-0000-4000-8000-00000000000a'),
  ('00000000-0000-4000-8000-00000000000b');

-- ---------------------------------------------------------------- A writes
set local role authenticated;
set local request.jwt.claims to
  '{"sub": "00000000-0000-4000-8000-00000000000a", "role": "authenticated"}';

insert into public.profiles
  (birth_date, sex, height_cm, activity_level, created_at, updated_at)
values ('1998-03-14', 'female', 158.5, 'lightly_active', now(), now());

insert into public.goals (
  id, goal_type, basis_weight_kg, calories_kcal, protein_g, carbs_g, fat_g,
  water_ml, steps, formula_version, started_at, created_at, updated_at
) values (
  '019a0000-0000-7000-8000-0000000000a1', 'lose_fat', 61.2, 1514, 110, 160,
  42, 2140, 9000, 'v1', now(), now(), now()
);

insert into public.weight_logs (id, day, weight_kg, created_at, updated_at)
values ('019a0000-0000-7000-8000-0000000000a2', '2026-11-22', 61.2, now(), now());

do $$
begin
  assert (select user_id from public.profiles)
    = '00000000-0000-4000-8000-00000000000a',
    'A''s profile should belong to A without A sending user_id';
  assert (select seq from public.goals) is not null,
    'sync_stamp should number every new row';
end;
$$;

-- An older edit loses to the newer one already saved.
do $$
declare
  changed integer;
begin
  update public.goals
  set steps = 1, updated_at = updated_at - interval '1 minute';
  get diagnostics changed = row_count;
  assert changed = 0, 'an older edit should be dropped';
  assert (select steps from public.goals) = 9000, 'the newer edit should stay';
end;
$$;

-- A newer edit wins and takes a new number; the row can't change account.
do $$
declare
  before_seq bigint := (select seq from public.goals);
begin
  update public.goals
  set steps = 10000,
      user_id = '00000000-0000-4000-8000-00000000000b',
      updated_at = updated_at + interval '1 minute';
  assert (select steps from public.goals) = 10000, 'a newer edit should win';
  assert (select seq from public.goals) > before_seq,
    'an edit should take a new sync number';
  assert (select user_id from public.goals)
    = '00000000-0000-4000-8000-00000000000a',
    'a row should never move to another account';
end;
$$;

-- Only one active goal.
do $$
begin
  insert into public.goals (
    id, goal_type, basis_weight_kg, calories_kcal, protein_g, carbs_g,
    fat_g, water_ml, steps, formula_version, started_at, created_at,
    updated_at
  ) values (
    '019a0000-0000-7000-8000-0000000000a3', 'maintain', 61.2, 1800, 98, 240,
    50, 2140, 9000, 'v1', now(), now(), now()
  );
  raise exception 'a second active goal should be refused';
exception
  when unique_violation then null;
end;
$$;

-- The database refuses a target below the safe floor, whatever a bug sends.
do $$
begin
  insert into public.goals (
    id, goal_type, basis_weight_kg, calories_kcal, protein_g, carbs_g,
    fat_g, water_ml, steps, formula_version, started_at, ended_at,
    created_at, updated_at
  ) values (
    '019a0000-0000-7000-8000-0000000000a4', 'lose_fat', 50, 889, 90, 77, 25,
    1750, 8000, 'v1', now(), now(), now(), now()
  );
  raise exception 'an 889 kcal target should be refused';
exception
  when check_violation then null;
end;
$$;

-- Nothing is deleted except with the account.
do $$
begin
  delete from public.weight_logs;
  raise exception 'deleting a row should be refused';
exception
  when insufficient_privilege then null;
end;
$$;

-- A can't put rows in B's account.
do $$
begin
  insert into public.weight_logs (id, user_id, day, weight_kg, created_at, updated_at)
  values ('019a0000-0000-7000-8000-0000000000a5',
    '00000000-0000-4000-8000-00000000000b', '2026-11-21', 60, now(), now());
  raise exception 'A should not be able to write to B''s account';
exception
  when insufficient_privilege then null;
end;
$$;

-- ---------------------------------------------------------- B looks at A's
set local request.jwt.claims to
  '{"sub": "00000000-0000-4000-8000-00000000000b", "role": "authenticated"}';

do $$
declare
  changed integer;
begin
  assert (select count(*) from public.profiles) = 0, 'B should not see A''s profile';
  assert (select count(*) from public.goals) = 0, 'B should not see A''s goals';
  assert (select count(*) from public.weight_logs) = 0, 'B should not see A''s weight';
  update public.goals set steps = 1, updated_at = now() + interval '1 day';
  get diagnostics changed = row_count;
  assert changed = 0, 'B should not be able to change A''s goal';
end;
$$;

-- --------------------------------------------- An anonymous sign-in can't
set local request.jwt.claims to
  '{"sub": "00000000-0000-4000-8000-00000000000b", "role": "authenticated", "is_anonymous": true}';

do $$
begin
  insert into public.weight_logs (id, day, weight_kg, created_at, updated_at)
  values ('019a0000-0000-7000-8000-0000000000b1', '2026-11-22', 70, now(), now());
  raise exception 'an anonymous sign-in should not be able to save data';
exception
  when insufficient_privilege then null;
end;
$$;

-- ------------------------------------------------------ Signed out (anon)
reset request.jwt.claims;
set local role anon;

do $$
begin
  perform count(*) from public.goals;
  raise exception 'a signed-out request should not read anyone''s goals';
exception
  when insufficient_privilege then null;
end;
$$;

-- Anyone can read the food catalogue, and nobody can write it.
select count(*) as foods_readable_signed_out from public.foods;

do $$
begin
  insert into public.foods (
    id, name, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g,
    fat_g_per_100g, source
  ) values (gen_random_uuid(), 'Dal', 116, 9, 20, 0.4, 'test');
  raise exception 'apps should not be able to write the catalogue';
exception
  when insufficient_privilege then null;
end;
$$;

-- --------------------------------------------------------------- AI limits
set local role authenticated;
set local request.jwt.claims to
  '{"sub": "00000000-0000-4000-8000-00000000000a", "role": "authenticated"}';

do $$
begin
  perform count(*) from public.ai_usage;
  raise exception 'apps should not be able to read AI usage';
exception
  when insufficient_privilege then null;
end;
$$;

do $$
begin
  perform public.take_ai_call('00000000-0000-4000-8000-00000000000a', 'scan', 2, 100);
  raise exception 'apps should not be able to count their own AI calls';
exception
  when insufficient_privilege then null;
end;
$$;

set local role service_role;

do $$
declare
  a constant uuid := '00000000-0000-4000-8000-00000000000a';
  b constant uuid := '00000000-0000-4000-8000-00000000000b';
begin
  assert public.take_ai_call(a, 'scan', 2, 3) = 1, 'first scan: 1 left';
  assert public.take_ai_call(a, 'scan', 2, 3) = 0, 'second scan: none left';
  assert public.take_ai_call(a, 'scan', 2, 3) = -1, 'third scan: over the limit';
  assert public.take_ai_call(a, 'chat', 2, 3) = 1, 'chats have their own limit';
  assert public.take_ai_call(b, 'scan', 2, 3) = 1, 'B has their own limit';
  assert public.take_ai_call(b, 'scan', 2, 3) = -2,
    'everyone together is at the day''s limit of 3 scans';
  perform public.refund_ai_call(a, 'scan');
  assert (select calls from public.ai_usage where user_id = a and kind = 'scan') = 1,
    'a refunded call should not count';
end;
$$;

reset role;

-- ----------------------------------------- Deleting the account removes all
delete from auth.users where id = '00000000-0000-4000-8000-00000000000a';

do $$
begin
  assert (select count(*) from public.profiles) = 0, 'the profile should go with the account';
  assert (select count(*) from public.goals) = 0, 'goals should go with the account';
  assert (select count(*) from public.weight_logs) = 0, 'weights should go with the account';
  assert (select count(*) from public.ai_usage
    where user_id = '00000000-0000-4000-8000-00000000000a') = 0,
    'AI usage should go with the account';
end;
$$;

select 'All security checks passed' as result;

rollback;
