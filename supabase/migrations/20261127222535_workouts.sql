-- Workouts (PRD T1-T3).
--
-- * profiles.training_days: how many days a week to train, 3 to 6. Sunday
--   is always rest. training_place and experience were already here.
-- * workout_sessions: each workout done, with every set as JSON text, so
--   the next one can start from the last one's numbers. Synced like the
--   other tables of a person's own data: row-level security, the three
--   policies, and the sync trigger.

alter table public.profiles
  add column training_days smallint
    check (training_days between 3 and 6);

create table public.workout_sessions (
  id uuid not null,
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  day date not null,
  -- The plan day, like 'upper_a', or 'custom'.
  workout_key text not null check (char_length(workout_key) between 1 and 40),
  title text not null check (char_length(title) between 1 and 80),
  -- [{"exercise": "goblet_squat", "reps": 10, "kg": 12, "seconds": null,
  --   "done": true}, ...]
  sets text not null default '[]' check (char_length(sets) <= 20000),
  sets_done smallint not null check (sets_done between 0 and 200),
  sets_planned smallint not null check (sets_planned between 0 and 200),
  duration_min smallint check (duration_min between 0 and 600),
  started_at timestamptz not null,
  finished_at timestamptz,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  seq bigint not null,
  primary key (user_id, id)
);
comment on table public.workout_sessions is
  'Workouts done, with their sets, synced per account.';

create index workout_sessions_user_day
  on public.workout_sessions (user_id, day);

do $$
declare
  own constant text :=
    'user_id = (select auth.uid()) '
    'and ((select auth.jwt()) ->> ''is_anonymous'')::boolean is not true';
begin
  alter table public.workout_sessions enable row level security;
  revoke all on table public.workout_sessions from anon;
  revoke delete, truncate, references, trigger
    on table public.workout_sessions from authenticated;
  execute format(
    'create policy "Own rows, signed in" on public.workout_sessions '
    'for select to authenticated using (%s)', own);
  execute format(
    'create policy "Add own rows, signed in" on public.workout_sessions '
    'for insert to authenticated with check (%s)', own);
  execute format(
    'create policy "Change own rows, signed in" on public.workout_sessions '
    'for update to authenticated using (%s) with check (%s)', own, own);
end;
$$;

create trigger workout_sessions_sync_stamp
  before insert or update on public.workout_sessions
  for each row execute function public.sync_stamp();

create index workout_sessions_user_seq
  on public.workout_sessions (user_id, seq);
