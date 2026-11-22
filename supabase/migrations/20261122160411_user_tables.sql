-- The tables that hold one person's own data, as the PRD's data model sets
-- them out for launch. Each row belongs to one account: user_id defaults to
-- the signed-in user, and the phone never sends it. The phone makes the
-- ids (UUIDv7), so an entry logged offline keeps its id on the way up, and
-- sending it twice can't make two.
--
-- Option columns hold the same fixed strings as the app's StoredOption
-- values (app/lib/models/options.dart).
--
-- Workout tables wait for the training milestone, so nothing here sits
-- unused for months.

-- One per account. Keyed by the account rather than an id, so two phones
-- that each made a profile before signing in end up with one.
create table public.profiles (
  user_id uuid primary key default auth.uid()
    references auth.users (id) on delete cascade,
  birth_date date not null check (birth_date >= date '1900-01-01'),
  -- Null when the person would rather not say.
  sex text check (sex in ('female', 'male')),
  height_cm numeric(4, 1) not null check (height_cm between 100 and 250),
  activity_level text not null
    check (activity_level in ('sedentary', 'lightly_active', 'active', 'athlete')),
  -- The next three can be skipped in onboarding.
  diet_type text check (diet_type in ('veg', 'egg', 'non_veg', 'vegan')),
  training_place text check (training_place in ('gym', 'dumbbells', 'home')),
  experience text
    check (experience in ('beginner', 'intermediate', 'advanced')),
  -- Where "today" is for this person. The phone doesn't send it yet, so it
  -- is the launch market's until it does.
  time_zone text not null default 'Asia/Kolkata'
    check (char_length(time_zone) between 1 and 64),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  -- Set when the account is to be deleted; everything goes within 30 days.
  deleted_at timestamptz,
  seq bigint not null
);
comment on table public.profiles is
  'One per account: what the targets are worked out from, apart from weight.';

-- The targets someone works to, and the ones before. A new goal ends the
-- old one, which stays with the formula version it was worked out with.
create table public.goals (
  id uuid not null,
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  goal_type text not null check (
    goal_type in ('lose_fat', 'gain_muscle', 'recomposition', 'maintain', 'performance')
  ),
  target_weight_kg numeric(4, 1) check (target_weight_kg between 20 and 400),
  -- The weight the targets were worked out from, so they can be explained.
  basis_weight_kg numeric(4, 1) not null
    check (basis_weight_kg between 20 and 400),
  -- Never below the lowest safe floor, whatever a bug sends.
  calories_kcal integer not null check (calories_kcal between 1200 and 10000),
  protein_g integer not null check (protein_g >= 0),
  carbs_g integer not null check (carbs_g >= 0),
  fat_g integer not null check (fat_g >= 0),
  water_ml integer not null check (water_ml > 0),
  steps integer not null check (steps > 0),
  formula_version text not null check (formula_version ~ '^v[0-9]+$'),
  started_at timestamptz not null,
  ended_at timestamptz check (ended_at >= started_at),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  seq bigint not null,
  primary key (user_id, id)
);
comment on table public.goals is
  'Daily targets: the active one has no ended_at. Old ones are kept.';

create unique index goals_one_active on public.goals (user_id)
  where ended_at is null and deleted_at is null;

-- One weight a day, on the day as the person lived it.
create table public.weight_logs (
  id uuid not null,
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  day date not null,
  weight_kg numeric(4, 1) not null check (weight_kg between 20 and 400),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  seq bigint not null,
  primary key (user_id, id)
);
comment on table public.weight_logs is 'One weight per account per day.';

create unique index weight_logs_one_a_day on public.weight_logs (user_id, day)
  where deleted_at is null;

-- Everything eaten: a catalogue food, an AI estimate the person confirmed,
-- or a dish typed in by hand. Nutrients are for the amount eaten.
create table public.meal_entries (
  id uuid not null,
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  food_id uuid references public.foods (id),
  name text not null check (char_length(name) between 1 and 200),
  meal text not null check (meal in ('breakfast', 'lunch', 'dinner', 'snack')),
  grams numeric(6, 1) not null check (grams > 0 and grams <= 5000),
  kcal numeric(6, 1) not null check (kcal between 0 and 10000),
  protein_g numeric(5, 1) not null check (protein_g >= 0),
  carbs_g numeric(5, 1) not null check (carbs_g >= 0),
  fat_g numeric(5, 1) not null check (fat_g >= 0),
  eaten_at timestamptz not null,
  source text not null
    check (source in ('search', 'text', 'photo', 'repeat', 'manual')),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  seq bigint not null,
  primary key (user_id, id)
);
comment on table public.meal_entries is
  'What each person ate. Daily totals are worked out from these, never stored.';

create index meal_entries_user_eaten_at on public.meal_entries (user_id, eaten_at);
create index meal_entries_food on public.meal_entries (food_id)
  where food_id is not null;

-- Water and steps, typed in by hand at launch; sleep, glucose and Health
-- Connect readings later, with no new table. The unit is part of the
-- metric's name, so no row can mix them up.
create table public.health_samples (
  id uuid not null,
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  metric text not null check (metric in ('water_ml', 'steps')),
  value numeric(10, 2) not null check (value >= 0),
  measured_at timestamptz not null,
  source text not null check (source in ('manual')),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  seq bigint not null,
  primary key (user_id, id),
  -- Catches a mistyped extra zero.
  check (
    (metric = 'water_ml' and value <= 5000)
    or (metric = 'steps' and value <= 100000)
  )
);
comment on table public.health_samples is
  'Water, steps and later other readings: one row per reading.';

create index health_samples_user_metric_time
  on public.health_samples (user_id, metric, measured_at);

-- The same rules, trigger and index for every one of these tables: only
-- the account itself can read or write its rows, an anonymous sign-in
-- can't at all, and nothing is deleted except by deleting the account.
do $$
declare
  t text;
  own constant text :=
    'user_id = (select auth.uid()) '
    'and (select (auth.jwt() ->> ''is_anonymous'')::boolean) is not true';
begin
  foreach t in array array[
    'profiles', 'goals', 'weight_logs', 'meal_entries', 'health_samples'
  ] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on table public.%I from anon', t);
    execute format(
      'revoke delete, truncate, references, trigger on table public.%I '
      'from authenticated', t);
    execute format(
      'create policy "Own rows, signed in" on public.%I '
      'for select to authenticated using (%s)', t, own);
    execute format(
      'create policy "Add own rows, signed in" on public.%I '
      'for insert to authenticated with check (%s)', t, own);
    execute format(
      'create policy "Change own rows, signed in" on public.%I '
      'for update to authenticated using (%s) with check (%s)', t, own, own);
    execute format(
      'create trigger %I before insert or update on public.%I '
      'for each row execute function public.sync_stamp()',
      t || '_sync_stamp', t);
    execute format(
      'create index %I on public.%I (user_id, seq)', t || '_user_seq', t);
  end loop;
end;
$$;
