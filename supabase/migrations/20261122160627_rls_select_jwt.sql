-- The "not an anonymous sign-in" check read the JWT inside a cast:
-- (select (auth.jwt() ->> 'is_anonymous')::boolean). Postgres already ran
-- that once per query, but Supabase's linter only recognises
-- (select auth.jwt()), so it warned that all 15 policies re-read the login
-- for every row. The JWT now sits in its own subquery. Who can do what is
-- unchanged.
do $$
declare
  t text;
  own constant text :=
    'user_id = (select auth.uid()) '
    'and ((select auth.jwt()) ->> ''is_anonymous'')::boolean is not true';
begin
  foreach t in array array[
    'profiles', 'goals', 'weight_logs', 'meal_entries', 'health_samples'
  ] loop
    execute format(
      'alter policy "Own rows, signed in" on public.%I using (%s)', t, own);
    execute format(
      'alter policy "Add own rows, signed in" on public.%I with check (%s)',
      t, own);
    execute format(
      'alter policy "Change own rows, signed in" on public.%I '
      'using (%s) with check (%s)', t, own, own);
  end loop;
end;
$$;
