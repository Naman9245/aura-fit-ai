-- Just enough of a Supabase database for the migrations and
-- security_test.sql to run on plain Postgres, in CI: the API roles, an
-- auth.users table, auth.uid() and auth.jwt() reading the request's JWT
-- claims as PostgREST sets them, and Supabase's default grants on new
-- tables, which the migrations then take back.
--
-- Never run this on Supabase, which has all of it already.

create role anon nologin noinherit;
create role authenticated nologin noinherit;
create role service_role nologin noinherit bypassrls;

create schema auth;
grant usage on schema auth to anon, authenticated, service_role;

create table auth.users (
  id uuid primary key,
  email text
);

create function auth.jwt()
returns jsonb
language sql
stable
as $$
  select coalesce(
    nullif(current_setting('request.jwt.claims', true), ''),
    '{}'
  )::jsonb
$$;

create function auth.uid()
returns uuid
language sql
stable
as $$
  select nullif(auth.jwt() ->> 'sub', '')::uuid
$$;

grant execute on function auth.jwt(), auth.uid()
  to anon, authenticated, service_role;

grant usage on schema public to anon, authenticated, service_role;
alter default privileges in schema public
  grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public
  grant all on sequences to anon, authenticated, service_role;
alter default privileges in schema public
  grant all on functions to anon, authenticated, service_role;
