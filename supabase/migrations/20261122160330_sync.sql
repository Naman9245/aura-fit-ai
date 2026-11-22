-- Sync between the phone and the account's copy, as Penny does it. Every
-- table of a person's own data has user_id, updated_at, deleted_at and seq,
-- and runs sync_stamp() before each insert and update:
--
-- * Every change takes the next number from sync_seq, so a phone asks for
--   "everything after N".
-- * One account's changes are written one transaction at a time, so its
--   numbers commit in order and a phone never skips one.
-- * The newer edit wins: an update whose updated_at isn't later than the
--   row's is dropped.
-- * Rows never move between accounts, and deletes stay soft (deleted_at),
--   so a delete reaches every phone.

create sequence public.sync_seq;
revoke all on sequence public.sync_seq from public, anon, authenticated;
grant usage on sequence public.sync_seq to authenticated;

create function public.sync_stamp()
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
  perform pg_advisory_xact_lock(hashtext('aurafit.sync:' || new.user_id::text));
  new.seq := nextval('public.sync_seq');
  return new;
end;
$$;

-- It runs as a trigger only; nobody calls it.
revoke all on function public.sync_stamp() from public, anon, authenticated;
