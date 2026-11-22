-- The food catalogue everyone shares: IFCT ingredients and common Indian
-- dishes, with the portions people use (a katori, a piece) as well as
-- grams. The app keeps a copy on the phone so search works offline, and
-- fetches only what changed since its copy, by seq. Apps can only read it;
-- the catalogue is written with the service role.
--
-- It starts empty. Where the first 300 dishes come from is an open
-- question in the PRD.

create sequence public.foods_seq;

create table public.foods (
  id uuid primary key,
  name text not null check (char_length(name) between 1 and 200),
  -- Other names people search by, in Hindi and regional languages.
  aliases text[] not null default '{}' check (cardinality(aliases) <= 20),
  kcal_per_100g numeric(5, 1) not null check (kcal_per_100g between 0 and 900),
  protein_g_per_100g numeric(4, 1) not null
    check (protein_g_per_100g between 0 and 100),
  carbs_g_per_100g numeric(4, 1) not null
    check (carbs_g_per_100g between 0 and 100),
  fat_g_per_100g numeric(4, 1) not null check (fat_g_per_100g between 0 and 100),
  -- Like [{"unit": "katori", "grams": 150}, {"unit": "piece", "grams": 40}].
  portions jsonb not null default '[]'
    check (jsonb_typeof(portions) = 'array'),
  -- Where the numbers come from, like 'ifct2017' or 'recipe'.
  source text not null check (char_length(source) between 1 and 40),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  seq bigint not null default nextval('public.foods_seq'),
  -- 100 g of food can't hold more than 100 g of nutrients.
  check (protein_g_per_100g + carbs_g_per_100g + fat_g_per_100g <= 100)
);
comment on table public.foods is
  'The shared food catalogue. Apps read it; only the service role writes it.';

create index foods_seq_index on public.foods (seq);

-- Every change takes a new number, so phones fetch it.
create function public.foods_stamp()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  new.seq := nextval('public.foods_seq');
  return new;
end;
$$;
revoke all on function public.foods_stamp() from public, anon, authenticated;

create trigger foods_stamp before update on public.foods
  for each row execute function public.foods_stamp();

alter table public.foods enable row level security;
revoke all on table public.foods from anon, authenticated;
grant select on table public.foods to anon, authenticated;
revoke all on sequence public.foods_seq from public, anon, authenticated;
create policy "Anyone can read the catalogue" on public.foods
  for select to anon, authenticated using (true);
