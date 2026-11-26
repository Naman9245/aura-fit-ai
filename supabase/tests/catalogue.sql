-- The server's food catalogue as one JSON array, in the shape of
-- app/assets/foods.json, for check_catalogue.py to compare. Run after every
-- migration:
--
--   psql -At -f supabase/tests/catalogue.sql > server_foods.json
select coalesce(json_agg(json_build_object(
  'id', id,
  'name', name,
  'aliases', aliases,
  'kcal_per_100g', kcal_per_100g,
  'protein_g_per_100g', protein_g_per_100g,
  'carbs_g_per_100g', carbs_g_per_100g,
  'fat_g_per_100g', fat_g_per_100g,
  'portions', portions,
  'assumption', assumption,
  'source', source,
  'seq', seq
) order by seq), '[]')
from public.foods
where deleted_at is null;
