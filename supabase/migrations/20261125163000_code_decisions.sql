-- Decisions for the code (PRD pages 18-19), settled before food logging
-- builds on them:
--
-- * 64-bit advisory lock keys (hashtextextended) in sync and AI limits.
-- * foods carries its recipe assumption ("30 g wheat atta, no ghee").
-- * meal_entries keeps portion_unit, portion_count, oil_level and diary day.
-- * health_samples keeps its diary day.
-- * saved_meals and saved_meal_items sync with the same RLS and triggers.
-- * AI daily limits use a running total per day and kind (no SUM scan), and
--   ai_calls records model, time taken, cost and outcome — never prompt text.

-- 1. 64-bit lock keys in sync_stamp.
create or replace function public.sync_stamp()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' then
    if new.updated_at <= old.updated_at then
      return null;
    end if;
    new.user_id := old.user_id;
  end if;
  perform pg_advisory_xact_lock(
    hashtextextended('aurafit.sync:' || new.user_id::text, 0)
  );
  new.seq := nextval('public.sync_seq');
  return new;
end;
$$;

-- 2. Recipe assumption on foods.
alter table public.foods
  add column assumption text not null default ''
    check (char_length(assumption) <= 300);

-- 3. Portion, oil level and diary day on meal_entries.
alter table public.meal_entries
  add column portion_unit text
    check (portion_unit is null or char_length(portion_unit) between 1 and 40),
  add column portion_count numeric(6, 2)
    check (portion_count is null or (portion_count > 0 and portion_count <= 5000)),
  add column oil_level text
    check (oil_level in ('low', 'home', 'extra')),
  add column day date;

update public.meal_entries
  set day = (eaten_at at time zone 'Asia/Kolkata')::date
  where day is null;

alter table public.meal_entries
  alter column day set not null;

create index meal_entries_user_day on public.meal_entries (user_id, day);

-- 4. Diary day on health_samples.
alter table public.health_samples
  add column day date;

update public.health_samples
  set day = (measured_at at time zone 'Asia/Kolkata')::date
  where day is null;

alter table public.health_samples
  alter column day set not null;

create index health_samples_user_day_metric
  on public.health_samples (user_id, day, metric);

-- 5. Saved meals and their items (favourites and combos like "Hostel breakfast").
create table public.saved_meals (
  id uuid not null,
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 120),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  seq bigint not null,
  primary key (user_id, id)
);
comment on table public.saved_meals is
  'Favourites and named meal combos, synced per account.';

create table public.saved_meal_items (
  id uuid not null,
  user_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  saved_meal_id uuid not null,
  food_id uuid references public.foods (id),
  name text not null check (char_length(name) between 1 and 200),
  portion_unit text
    check (portion_unit is null or char_length(portion_unit) between 1 and 40),
  portion_count numeric(6, 2)
    check (portion_count is null or (portion_count > 0 and portion_count <= 5000)),
  oil_level text check (oil_level in ('low', 'home', 'extra')),
  grams numeric(6, 1) not null check (grams > 0 and grams <= 5000),
  kcal numeric(6, 1) not null check (kcal between 0 and 10000),
  protein_g numeric(5, 1) not null check (protein_g >= 0),
  carbs_g numeric(5, 1) not null check (carbs_g >= 0),
  fat_g numeric(5, 1) not null check (fat_g >= 0),
  sort_order integer not null default 0 check (sort_order between 0 and 200),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  seq bigint not null,
  primary key (user_id, id),
  foreign key (user_id, saved_meal_id)
    references public.saved_meals (user_id, id) on delete cascade
);
comment on table public.saved_meal_items is
  'Dishes inside a saved meal. Keeps name and nutrients if catalogue changes.';

create index saved_meal_items_meal
  on public.saved_meal_items (user_id, saved_meal_id, sort_order);

do $$
declare
  t text;
  own constant text :=
    'user_id = (select auth.uid()) '
    'and ((select auth.jwt()) ->> ''is_anonymous'')::boolean is not true';
begin
  foreach t in array array['saved_meals', 'saved_meal_items'] loop
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

-- 6. AI running daily totals (no SUM scan) and ai_calls telemetry log.
create table public.ai_daily_totals (
  day date not null,
  kind text not null check (kind in ('scan', 'parse', 'chat')),
  calls integer not null default 0 check (calls >= 0),
  primary key (day, kind)
);
comment on table public.ai_daily_totals is
  'Running total of AI calls across everyone per day and kind (India time).';

insert into public.ai_daily_totals (day, kind, calls)
select day, kind, coalesce(sum(calls), 0)::integer
from public.ai_usage
group by day, kind
on conflict (day, kind) do update set calls = excluded.calls;

alter table public.ai_daily_totals enable row level security;
revoke all on table public.ai_daily_totals from anon, authenticated;

create table public.ai_calls (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  kind text not null check (kind in ('scan', 'parse', 'chat')),
  model text not null check (char_length(model) between 1 and 80),
  response_ms integer not null check (response_ms >= 0),
  cost_usd numeric(10, 6) not null default 0 check (cost_usd >= 0),
  outcome text not null check (
    outcome in ('ok', 'bad_json', 'timeout', 'upstream_error', 'rate_limited')
  ),
  created_at timestamptz not null default now()
);
comment on table public.ai_calls is
  'AI call telemetry for cost and latency gates. Never holds prompt text.';

create index ai_calls_user_time on public.ai_calls (user_id, created_at);
create index ai_calls_created_at on public.ai_calls (created_at);

alter table public.ai_calls enable row level security;
revoke all on table public.ai_calls from anon, authenticated;
revoke all on sequence public.ai_calls_id_seq from anon, authenticated;

create or replace function public.take_ai_call(
  p_user_id uuid,
  p_kind text,
  p_user_limit integer,
  p_total_limit integer
)
returns integer
language plpgsql
set search_path = ''
as $$
declare
  today date := (now() at time zone 'Asia/Kolkata')::date;
  used integer;
  total_used integer;
begin
  perform pg_advisory_xact_lock(
    hashtextextended(
      'aurafit.ai_user:' || p_user_id::text || ':' || p_kind || ':' || today::text,
      0
    )
  );

  if p_user_limit <= 0 then
    return -1;
  end if;
  if p_total_limit <= 0 then
    return -2;
  end if;

  insert into public.ai_usage as usage (user_id, day, kind, calls)
  values (p_user_id, today, p_kind, 1)
  on conflict (user_id, day, kind) do update
    set calls = usage.calls + 1
    where usage.calls < p_user_limit
  returning calls into used;

  if used is null then
    return -1;
  end if;

  insert into public.ai_daily_totals as totals (day, kind, calls)
  values (today, p_kind, 1)
  on conflict (day, kind) do update
    set calls = totals.calls + 1
    where totals.calls < p_total_limit
  returning calls into total_used;

  if total_used is null then
    update public.ai_usage
    set calls = calls - 1
    where user_id = p_user_id and day = today and kind = p_kind;
    return -2;
  end if;

  return p_user_limit - used;
end;
$$;

create or replace function public.refund_ai_call(p_user_id uuid, p_kind text)
returns void
language plpgsql
set search_path = ''
as $$
declare
  today date := (now() at time zone 'Asia/Kolkata')::date;
  refunded integer;
begin
  perform pg_advisory_xact_lock(
    hashtextextended(
      'aurafit.ai_user:' || p_user_id::text || ':' || p_kind || ':' || today::text,
      0
    )
  );

  update public.ai_usage
  set calls = calls - 1
  where user_id = p_user_id
    and day = today
    and kind = p_kind
    and calls > 0;

  get diagnostics refunded = row_count;
  if refunded > 0 then
    update public.ai_daily_totals
    set calls = greatest(calls - refunded, 0)
    where day = today and kind = p_kind;
  end if;
end;
$$;

create or replace function public.record_ai_call(
  p_user_id uuid,
  p_kind text,
  p_model text,
  p_response_ms integer,
  p_cost_usd numeric,
  p_outcome text
)
returns void
language sql
set search_path = ''
as $$
  insert into public.ai_calls
    (user_id, kind, model, response_ms, cost_usd, outcome)
  values
    (p_user_id, p_kind, p_model, p_response_ms, p_cost_usd, p_outcome);
$$;

revoke all on function public.take_ai_call(uuid, text, integer, integer)
  from public, anon, authenticated;
revoke all on function public.refund_ai_call(uuid, text)
  from public, anon, authenticated;
revoke all on function public.record_ai_call(uuid, text, text, integer, numeric, text)
  from public, anon, authenticated;
grant execute on function public.take_ai_call(uuid, text, integer, integer)
  to service_role;
grant execute on function public.refund_ai_call(uuid, text) to service_role;
grant execute on function public.record_ai_call(uuid, text, text, integer, numeric, text)
  to service_role;
