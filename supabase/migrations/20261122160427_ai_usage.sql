-- How many AI calls of each kind each person made today, for the daily
-- limits in the PRD: meal scans, text parsing and the coach each have
-- their own. Days run on India time, the launch market's. Nothing about
-- the call itself is kept here.
create table public.ai_usage (
  user_id uuid not null references auth.users (id) on delete cascade,
  day date not null,
  kind text not null check (kind in ('scan', 'parse', 'chat')),
  calls integer not null default 0 check (calls >= 0),
  primary key (user_id, day, kind)
);
comment on table public.ai_usage is
  'AI calls per person per day and kind (India time). Only Edge Functions touch it.';

-- take_ai_call adds up one kind's calls across everyone for a day; the
-- primary key can't find those rows, this can.
create index ai_usage_day_kind on public.ai_usage (day, kind);

-- RLS with no policies: apps can neither read nor write it. Edge Functions
-- use the secret key, which bypasses RLS.
alter table public.ai_usage enable row level security;
revoke all on table public.ai_usage from anon, authenticated;

-- Counts one call of p_kind for today. Returns the calls of that kind the
-- person has left after this one, -1 when they are at their daily limit,
-- or -2 when everyone together is at the app's daily limit.
create function public.take_ai_call(
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
begin
  -- One call of a kind at a time per day, so two at once can't both slip
  -- under a limit.
  perform pg_advisory_xact_lock(
    hashtext('aurafit.ai_usage:' || p_kind || ':' || today::text)
  );

  if (
    select coalesce(sum(calls), 0)
    from public.ai_usage
    where day = today and kind = p_kind
  ) >= p_total_limit then
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
  return p_user_limit - used;
end;
$$;

-- Gives back a call that the AI failed to answer, so it isn't counted.
create function public.refund_ai_call(p_user_id uuid, p_kind text)
returns void
language sql
set search_path = ''
as $$
  update public.ai_usage
  set calls = calls - 1
  where user_id = p_user_id
    and day = (now() at time zone 'Asia/Kolkata')::date
    and kind = p_kind
    and calls > 0;
$$;

revoke all on function public.take_ai_call(uuid, text, integer, integer)
  from public, anon, authenticated;
revoke all on function public.refund_ai_call(uuid, text)
  from public, anon, authenticated;
grant execute on function public.take_ai_call(uuid, text, integer, integer)
  to service_role;
grant execute on function public.refund_ai_call(uuid, text) to service_role;
