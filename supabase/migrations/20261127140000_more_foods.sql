-- More foods, and dishes counted the way people eat them.
--
-- * Plain paratha is renamed so a search for it finds it first.
-- * Egg curry, egg bhurji and the omelettes are counted by the egg, and
--   the chicken, mutton and fish curries and dum aloo by the piece with its
--   gravy, as well as by the katori.
-- * 84 foods people asked for that weren't there: breads, dishes, Indo-
--   Chinese, fast food, snacks, sweets, drinks and fruits.
--
-- Every update takes the next number from foods_seq (foods_stamp), and
-- every insert the one after, so phones fetch all of it with their next
-- catalogue sync. app/assets/foods.json carries the same rows and numbers,
-- from LATER_FIXES and ADDED_FOODS in app/tool/build_food_catalogue.py.
-- The numbers start right after the highest one given out so far.
select setval('public.foods_seq', (select max(seq) from public.foods));

update public.foods set name = 'Plain Paratha (Tawa / Triangle)', aliases = ARRAY['plain paratha', 'sada paratha', 'sada parantha', 'plain parantha', 'tawa paratha', 'triangle paratha', 'parotta home']::text[]
where id = '019a9000-0000-7000-8000-000000000084';
update public.foods set portions = '[{"unit":"egg + gravy","grams":100},{"unit":"katori","grams":150},{"unit":"bowl","grams":220}]'::jsonb, assumption = 'Boiled eggs in home onion-tomato masala gravy; 1 egg with its gravy is about 100 g'
where id = '019a9000-0000-7000-8000-0000000000f1';
update public.foods set portions = '[{"unit":"egg","grams":70},{"unit":"katori","grams":140},{"unit":"plate","grams":200}]'::jsonb, assumption = 'Eggs scrambled with onion, tomato and 2.5 g oil per egg; about 70 g per egg'
where id = '019a9000-0000-7000-8000-0000000000ef';
update public.foods set portions = '[{"unit":"egg","grams":60},{"unit":"omelette (2 eggs)","grams":120}]'::jsonb
where id = '019a9000-0000-7000-8000-0000000000ed';
update public.foods set portions = '[{"unit":"egg white","grams":40},{"unit":"omelette (3 whites)","grams":120}]'::jsonb
where id = '019a9000-0000-7000-8000-0000000000ee';
update public.foods set portions = '[{"unit":"katori","grams":150},{"unit":"piece + gravy","grams":80},{"unit":"bowl","grams":200}]'::jsonb
where id = '019a9000-0000-7000-8000-0000000000f6';
update public.foods set portions = '[{"unit":"katori","grams":150},{"unit":"piece + gravy","grams":70},{"unit":"bowl","grams":200}]'::jsonb
where id = '019a9000-0000-7000-8000-0000000000f8';
update public.foods set portions = '[{"unit":"katori","grams":150},{"unit":"piece + gravy","grams":80},{"unit":"bowl","grams":200}]'::jsonb
where id = '019a9000-0000-7000-8000-0000000000ff';
update public.foods set portions = '[{"unit":"katori","grams":150},{"unit":"piece + gravy","grams":110},{"unit":"bowl","grams":200}]'::jsonb
where id = '019a9000-0000-7000-8000-0000000000fc';
update public.foods set portions = '[{"unit":"katori","grams":150},{"unit":"potato + gravy","grams":60},{"unit":"bowl","grams":250}]'::jsonb
where id = '019a9000-0000-7000-8000-0000000000d5';

insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-000000000197', 'Ajwain Paratha', ARRAY['ajwain parantha', 'carom paratha']::text[], 305.0, 8.4, 47.0, 9.2, '[{"unit":"piece","grams":70}]'::jsonb, 'Whole wheat atta with ajwain, cooked on tawa with 1 tsp ghee or oil', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-000000000198', 'Puran Poli', ARRAY['puranpoli', 'obbattu', 'holige', 'bobbatlu']::text[], 292.0, 7.2, 52.0, 6.2, '[{"unit":"piece","grams":75}]'::jsonb, 'Wheat flatbread stuffed with sweet chana dal and jaggery, 1 tsp ghee', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-000000000199', 'Thalipeeth', ARRAY['bhajani thalipeeth']::text[], 232.0, 7.6, 32.0, 8.2, '[{"unit":"piece","grams":80}]'::jsonb, 'Multigrain bhajani flour flatbread with onion, cooked with 1 tsp oil', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-00000000019a', 'Akki Roti', ARRAY['rice roti', 'akki rotti']::text[], 218.0, 3.9, 38.5, 5.4, '[{"unit":"piece","grams":70}]'::jsonb, 'Rice flour flatbread with onion and coriander, 1 tsp oil', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-00000000019b', 'Neer Dosa', ARRAY['neer dose', 'rice crepe']::text[], 148.0, 2.4, 28.5, 2.6, '[{"unit":"dosa","grams":50}]'::jsonb, 'Thin rice-batter crepe with a smear of oil', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-00000000019c', 'Set Dosa', ARRAY['sponge dosa']::text[], 182.0, 4.2, 30.5, 4.6, '[{"unit":"dosa","grams":70}]'::jsonb, 'Soft thick rice-urad dosa cooked with 0.5 tsp oil', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-00000000019d', 'Baati (with Ghee)', ARRAY['bati', 'dal baati']::text[], 382.0, 8.2, 52.0, 15.6, '[{"unit":"baati","grams":60}]'::jsonb, 'Baked whole wheat dough ball dipped in 1 tsp ghee', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-00000000019e', 'Litti (Sattu Stuffed)', ARRAY['litti chokha', 'litti']::text[], 292.0, 9.6, 45.0, 8.0, '[{"unit":"litti","grams":70}]'::jsonb, 'Baked wheat ball stuffed with spiced sattu, brushed with ghee', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-00000000019f', 'Ghee Rice', ARRAY['neichoru', 'nei choru']::text[], 186.0, 2.8, 27.5, 7.2, '[{"unit":"katori","grams":150},{"unit":"plate","grams":250},{"unit":"bowl","grams":200}]'::jsonb, 'Basmati rice cooked with whole spices and 1.5 tsp ghee per katori', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001a0', 'Coconut Rice', ARRAY['thengai sadam', 'kobbari annam']::text[], 192.0, 3.0, 27.0, 7.9, '[{"unit":"katori","grams":150},{"unit":"plate","grams":250},{"unit":"bowl","grams":200}]'::jsonb, 'Cooked rice tossed with grated coconut, tempering and 1 tsp oil', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001a1', 'Dhuli Urad Dal (Home Style)', ARRAY['urad dal', 'maa ki dal', 'white urad dal']::text[], 122.0, 6.8, 15.2, 3.7, '[{"unit":"katori","grams":150},{"unit":"small katori","grams":100},{"unit":"bowl","grams":250}]'::jsonb, 'Split urad dal cooked with onion-tomato tadka and 1 tsp ghee', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001a2', 'Chole Bhature (Plate)', ARRAY['chole bhature', 'chhole bhature']::text[], 248.1, 7.0, 35.5, 8.7, '[{"unit":"plate (2 bhature)","grams":310}]'::jsonb, '1 katori (150 g) Punjabi chole with 2 bhature (160 g)', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001a3', 'Malai Kofta', ARRAY['malai kofta curry']::text[], 212.0, 5.0, 14.5, 15.0, '[{"unit":"kofta + gravy","grams":90},{"unit":"katori","grams":150},{"unit":"bowl","grams":250}]'::jsonb, 'Fried paneer-potato koftas in cashew-cream tomato gravy', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001a4', 'Lauki Kofta Curry', ARRAY['ghiya kofta', 'veg kofta curry']::text[], 148.0, 3.6, 12.5, 9.4, '[{"unit":"kofta + gravy","grams":80},{"unit":"katori","grams":150},{"unit":"bowl","grams":250}]'::jsonb, 'Fried bottle gourd and besan koftas in onion-tomato gravy', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001a5', 'Navratan Korma', ARRAY['navratna korma', 'veg korma']::text[], 162.0, 4.0, 12.0, 11.0, '[{"unit":"katori","grams":150},{"unit":"bowl","grams":250}]'::jsonb, 'Mixed vegetables and paneer in cashew-cream korma gravy', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001a6', 'Methi Matar Malai', ARRAY['methi malai matar']::text[], 176.0, 5.0, 10.5, 12.8, '[{"unit":"katori","grams":150},{"unit":"bowl","grams":250}]'::jsonb, 'Fenugreek leaves and peas in cream-cashew white gravy', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001a7', 'Aloo Tamatar ki Sabzi (Tari)', ARRAY['aloo tamatar', 'aloo ki sabzi', 'aloo rassa', 'batata bhaji']::text[], 86.0, 1.8, 12.4, 3.3, '[{"unit":"katori","grams":150},{"unit":"bowl","grams":250}]'::jsonb, 'Potatoes in thin tomato gravy with 1 tsp oil per katori', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001a8', 'Gobi Matar / Gobi Masala', ARRAY['gobhi matar', 'gobi masala', 'phool gobi sabzi']::text[], 96.0, 3.2, 9.0, 5.4, '[{"unit":"katori","grams":120},{"unit":"small katori","grams":80},{"unit":"plate","grams":180}]'::jsonb, 'Cauliflower and peas cooked dry with spices and 1 tsp oil', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001a9', 'Gajar Matar', ARRAY['gajar matar sabzi', 'carrot peas']::text[], 86.0, 2.8, 10.2, 3.8, '[{"unit":"katori","grams":120},{"unit":"small katori","grams":80},{"unit":"plate","grams":180}]'::jsonb, 'Carrots and peas cooked with spices and 1 tsp oil', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001aa', 'Arbi Masala / Fry', ARRAY['arbi', 'arvi', 'colocasia', 'seppankizhangu']::text[], 142.0, 2.0, 20.5, 5.8, '[{"unit":"katori","grams":120},{"unit":"small katori","grams":80},{"unit":"plate","grams":180}]'::jsonb, 'Boiled colocasia roasted with ajwain, spices and 1.5 tsp oil', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001ab', 'Kathal ki Sabzi', ARRAY['jackfruit sabzi', 'kathal masala', 'raw jackfruit curry']::text[], 118.0, 2.2, 15.5, 5.2, '[{"unit":"katori","grams":120},{"unit":"small katori","grams":80},{"unit":"plate","grams":180}]'::jsonb, 'Raw jackfruit cooked with onion-tomato masala and 1 tsp oil', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001ac', 'Kaddu ki Sabzi (Khatta Meetha)', ARRAY['pumpkin sabzi', 'petha sabzi', 'sitaphal sabzi']::text[], 78.0, 1.2, 11.6, 3.0, '[{"unit":"katori","grams":120},{"unit":"small katori","grams":80},{"unit":"plate","grams":180}]'::jsonb, 'Pumpkin cooked with methi seeds, a little jaggery and 1 tsp oil', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001ad', 'Chicken 65', ARRAY['chicken sixty five']::text[], 252.0, 20.5, 9.5, 14.8, '[{"unit":"piece","grams":20},{"unit":"katori","grams":120},{"unit":"plate","grams":180}]'::jsonb, 'Boneless chicken marinated in curd and spices, deep fried, tossed with curry leaves', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001ae', 'Chicken Korma', ARRAY['murgh korma', 'chicken kurma']::text[], 202.0, 15.2, 6.2, 13.0, '[{"unit":"katori","grams":150},{"unit":"piece + gravy","grams":80},{"unit":"bowl","grams":200}]'::jsonb, 'Chicken in onion, curd and cashew korma gravy', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001af', 'Mutton Keema', ARRAY['keema', 'kheema', 'gosht keema']::text[], 212.0, 17.0, 5.2, 13.8, '[{"unit":"katori","grams":150},{"unit":"plate","grams":200}]'::jsonb, 'Minced mutton cooked with onion, tomato, peas and 1 tsp oil', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001b0', 'Fish Tikka / Tandoori Fish', ARRAY['tandoori fish', 'fish tikka']::text[], 158.0, 23.0, 3.0, 6.0, '[{"unit":"piece","grams":40},{"unit":"plate","grams":160}]'::jsonb, 'Boneless fish chunks marinated in curd and spices, grilled', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001b1', 'Egg Roll (Kolkata Style)', ARRAY['anda roll', 'egg kathi roll']::text[], 248.0, 8.6, 26.0, 12.2, '[{"unit":"roll","grams":180}]'::jsonb, 'Paratha wrapped around 1 egg, onion and sauces', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001b2', 'Chicken Kathi Roll', ARRAY['chicken roll', 'chicken frankie', 'chicken wrap']::text[], 236.0, 12.4, 24.0, 10.0, '[{"unit":"roll","grams":200}]'::jsonb, 'Paratha wrap with tikka chicken, onion and chutney', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001b3', 'Paneer Kathi Roll / Frankie', ARRAY['paneer roll', 'paneer frankie', 'veg frankie']::text[], 248.0, 9.2, 26.0, 11.8, '[{"unit":"roll","grams":190}]'::jsonb, 'Paratha wrap with paneer tikka, onion and chutney', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001b4', 'Chicken Shawarma', ARRAY['shawarma', 'chicken shawarma roll']::text[], 232.0, 13.0, 22.0, 10.2, '[{"unit":"roll","grams":220},{"unit":"plate","grams":300}]'::jsonb, 'Pita or rumali wrap with grilled chicken, garlic mayo and salad', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001b5', 'Chicken Momos (Steamed)', ARRAY['chicken momo', 'chicken dumplings']::text[], 190.0, 10.0, 22.0, 6.8, '[{"unit":"momo","grams":25},{"unit":"plate (6)","grams":150}]'::jsonb, 'Maida wrappers with minced chicken and onion, steamed', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001b6', 'Veg Momos (Steamed)', ARRAY['veg momo', 'veg dumplings', 'momos']::text[], 158.0, 4.4, 26.0, 4.0, '[{"unit":"momo","grams":25},{"unit":"plate (6)","grams":150}]'::jsonb, 'Maida wrappers with cabbage and carrot, steamed', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001b7', 'Fried Momos (Veg)', ARRAY['fried momo']::text[], 258.0, 4.6, 28.0, 14.0, '[{"unit":"momo","grams":28},{"unit":"plate (6)","grams":170}]'::jsonb, 'Veg momos deep fried', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001b8', 'Veg Hakka Noodles / Chowmein', ARRAY['chowmein', 'chow mein', 'veg noodles', 'hakka noodles']::text[], 166.0, 4.0, 26.0, 5.2, '[{"unit":"plate","grams":250},{"unit":"katori","grams":150}]'::jsonb, 'Boiled noodles stir-fried with vegetables, soy and oil', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001b9', 'Chicken Hakka Noodles', ARRAY['chicken chowmein', 'chicken noodles']::text[], 176.0, 8.6, 23.0, 5.6, '[{"unit":"plate","grams":250},{"unit":"katori","grams":150}]'::jsonb, 'Noodles stir-fried with shredded chicken, vegetables and soy', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001ba', 'Veg Manchurian (Gravy)', ARRAY['manchurian', 'veg manchurian']::text[], 148.0, 3.0, 16.0, 8.0, '[{"unit":"ball + gravy","grams":50},{"unit":"katori","grams":150}]'::jsonb, 'Fried cabbage-carrot balls in soy-garlic gravy', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001bb', 'Gobi Manchurian (Dry)', ARRAY['gobhi manchurian', 'cauliflower manchurian']::text[], 218.0, 4.0, 22.5, 12.5, '[{"unit":"katori","grams":120},{"unit":"plate","grams":180}]'::jsonb, 'Batter-fried cauliflower tossed in soy-chilli sauce', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001bc', 'Chilli Chicken (Dry)', ARRAY['chilli chicken']::text[], 212.0, 17.0, 9.0, 12.0, '[{"unit":"katori","grams":150},{"unit":"piece","grams":25}]'::jsonb, 'Batter-fried chicken tossed with capsicum, onion and soy-chilli sauce', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001bd', 'Veg Spring Roll', ARRAY['spring roll']::text[], 248.0, 4.2, 30.0, 12.4, '[{"unit":"roll","grams":45}]'::jsonb, 'Fried pastry roll with cabbage and carrot', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001be', 'Margherita Pizza', ARRAY['pizza', 'cheese pizza']::text[], 262.0, 11.0, 32.0, 9.8, '[{"unit":"slice","grams":70},{"unit":"regular pizza (4 slices)","grams":280}]'::jsonb, 'Medium crust with tomato sauce and mozzarella', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001bf', 'Veg Burger (Aloo Tikki)', ARRAY['aloo tikki burger', 'veg burger']::text[], 242.0, 6.0, 33.0, 9.4, '[{"unit":"burger","grams":150}]'::jsonb, 'Bun with fried potato patty, mayo and salad', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001c0', 'Chicken Burger', ARRAY['crispy chicken burger']::text[], 248.0, 12.0, 24.0, 11.6, '[{"unit":"burger","grams":180}]'::jsonb, 'Bun with fried chicken patty, mayo and salad', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001c1', 'French Fries', ARRAY['fries', 'finger chips', 'potato fries']::text[], 312.0, 3.4, 41.0, 15.0, '[{"unit":"small","grams":80},{"unit":"medium","grams":115},{"unit":"katori","grams":70}]'::jsonb, 'Deep-fried potato strips, fast-food style (USDA FDC)', 'usda_fdc');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001c2', 'White Sauce Pasta', ARRAY['alfredo pasta', 'white pasta']::text[], 176.0, 5.6, 22.0, 7.2, '[{"unit":"bowl","grams":250},{"unit":"plate","grams":300}]'::jsonb, 'Penne in milk, butter and flour sauce with vegetables and cheese', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001c3', 'Red Sauce Pasta (Indian Style)', ARRAY['red pasta', 'masala pasta', 'arrabbiata']::text[], 150.0, 4.6, 24.0, 4.0, '[{"unit":"bowl","grams":250},{"unit":"plate","grams":300}]'::jsonb, 'Penne in tomato-onion sauce with vegetables and 1 tsp oil', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001c4', 'Moong Dal Kachori', ARRAY['kachori', 'khasta kachori', 'dal kachori']::text[], 412.0, 8.8, 45.0, 21.6, '[{"unit":"piece","grams":50}]'::jsonb, 'Maida pastry stuffed with spiced moong dal, deep fried', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001c5', 'Mathri', ARRAY['mathiya', 'namak para']::text[], 482.0, 8.0, 52.0, 27.0, '[{"unit":"piece","grams":15},{"unit":"handful","grams":30}]'::jsonb, 'Flaky maida and ajwain crackers, deep fried', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001c6', 'Khakhra (Plain)', ARRAY['khakra', 'gujarati khakhra']::text[], 405.0, 11.5, 64.0, 11.6, '[{"unit":"piece","grams":20}]'::jsonb, 'Thin wheat cracker roasted with a little oil', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001c7', 'Murukku / Chakli', ARRAY['chakli', 'murukku', 'chakri']::text[], 518.0, 8.6, 57.0, 28.4, '[{"unit":"piece","grams":15},{"unit":"handful","grams":30}]'::jsonb, 'Rice and urad flour spirals, deep fried', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001c8', 'Banana Chips (Kerala)', ARRAY['kele ke chips', 'nendran chips']::text[], 519.0, 2.3, 58.4, 33.6, '[{"unit":"handful","grams":30},{"unit":"katori","grams":50}]'::jsonb, 'Raw banana slices fried in coconut oil (USDA FDC)', 'usda_fdc');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001c9', 'Sev Puri / Dahi Puri / Papdi Chaat', ARRAY['sev puri', 'dahi puri', 'papdi chaat']::text[], 218.0, 5.0, 30.0, 8.8, '[{"unit":"plate","grams":150}]'::jsonb, 'Crisp puris with potato, chutneys, curd and sev', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001ca', 'Dabeli', ARRAY['kutchi dabeli']::text[], 246.0, 5.6, 37.0, 8.4, '[{"unit":"piece","grams":120}]'::jsonb, 'Pav stuffed with sweet-spicy potato, peanuts and chutneys', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001cb', 'Aloo Bonda / Batata Vada', ARRAY['batata vada', 'aloo bonda', 'potato bonda']::text[], 246.0, 4.6, 30.0, 12.0, '[{"unit":"piece","grams":60}]'::jsonb, 'Spiced potato balls in besan batter, deep fried', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001cc', 'Paneer Pakora', ARRAY['paneer pakoda']::text[], 292.0, 12.4, 15.0, 20.2, '[{"unit":"piece","grams":35}]'::jsonb, 'Paneer slices in besan batter, deep fried', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001cd', 'Mirchi Bajji', ARRAY['mirchi pakora', 'mirapakaya bajji']::text[], 232.0, 4.6, 22.0, 14.0, '[{"unit":"piece","grams":45}]'::jsonb, 'Large green chillies in besan batter, deep fried', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001ce', 'Jalebi', ARRAY['jilebi', 'imarti']::text[], 382.0, 2.6, 64.0, 13.2, '[{"unit":"piece","grams":25},{"unit":"plate (100 g)","grams":100}]'::jsonb, 'Fried maida batter spirals soaked in sugar syrup', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001cf', 'Rasgulla', ARRAY['rosogolla', 'rasagola']::text[], 186.0, 4.4, 37.6, 2.2, '[{"unit":"piece","grams":40}]'::jsonb, 'Chhena balls in sugar syrup, drained weight', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001d0', 'Rasmalai', ARRAY['ras malai']::text[], 232.0, 7.0, 28.0, 10.2, '[{"unit":"piece + rabdi","grams":60}]'::jsonb, 'Chhena discs in sweetened reduced milk', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001d1', 'Kaju Katli', ARRAY['kaju barfi', 'cashew barfi']::text[], 470.0, 9.0, 60.0, 21.6, '[{"unit":"piece","grams":12}]'::jsonb, 'Cashew and sugar fudge, about half cashew', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001d2', 'Motichoor Ladoo', ARRAY['boondi ladoo', 'motichur laddu']::text[], 412.0, 5.4, 55.0, 19.0, '[{"unit":"ladoo","grams":40}]'::jsonb, 'Fried besan boondi bound with sugar syrup and ghee', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001d3', 'Milk Barfi / Khoya Burfi', ARRAY['barfi', 'burfi', 'mawa barfi']::text[], 392.0, 9.0, 50.0, 17.4, '[{"unit":"piece","grams":30}]'::jsonb, 'Khoya cooked with sugar', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001d4', 'Mysore Pak', ARRAY['mysore paak']::text[], 522.0, 6.0, 50.0, 33.6, '[{"unit":"piece","grams":30}]'::jsonb, 'Besan cooked with sugar and plenty of ghee', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001d5', 'Shrikhand', ARRAY['amrakhand', 'kesar shrikhand']::text[], 258.0, 7.0, 40.0, 7.8, '[{"unit":"small katori","grams":80},{"unit":"katori","grams":120}]'::jsonb, 'Hung curd sweetened with sugar, saffron and cardamom', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001d6', 'Kulfi', ARRAY['malai kulfi', 'matka kulfi']::text[], 212.0, 5.6, 24.0, 10.6, '[{"unit":"stick","grams":70},{"unit":"matka","grams":100}]'::jsonb, 'Reduced whole milk with sugar, frozen', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001d7', 'Vanilla Ice Cream', ARRAY['ice cream', 'icecream']::text[], 207.0, 3.5, 23.6, 11.0, '[{"unit":"scoop","grams":65},{"unit":"cup","grams":100}]'::jsonb, 'Regular vanilla ice cream (USDA FDC)', 'usda_fdc');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001d8', 'Sandesh', ARRAY['sondesh']::text[], 332.0, 9.2, 44.0, 13.2, '[{"unit":"piece","grams":35}]'::jsonb, 'Chhena kneaded with sugar', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001d9', 'Peda', ARRAY['pedha', 'doodh peda']::text[], 402.0, 9.2, 52.0, 17.2, '[{"unit":"piece","grams":25}]'::jsonb, 'Khoya cooked with sugar and cardamom', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001da', 'Moong Dal Halwa', ARRAY['moong ka halwa']::text[], 422.0, 8.2, 45.0, 23.2, '[{"unit":"small katori","grams":80},{"unit":"katori","grams":130}]'::jsonb, 'Moong dal roasted in ghee, cooked with milk and sugar', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001db', 'Sugarcane Juice', ARRAY['ganne ka ras', 'ganna juice', 'kabbu juice']::text[], 73.0, 0.2, 18.0, 0.1, '[{"unit":"glass","grams":250}]'::jsonb, 'Fresh pressed sugarcane juice, no added sugar', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001dc', 'Fresh Orange / Mosambi Juice', ARRAY['mosambi juice', 'santra juice', 'orange juice']::text[], 45.0, 0.7, 10.4, 0.2, '[{"unit":"glass","grams":250}]'::jsonb, 'Freshly squeezed orange or sweet lime juice, no sugar (USDA FDC)', 'usda_fdc');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001dd', 'Mango Shake', ARRAY['mango milkshake', 'aam shake']::text[], 112.0, 2.8, 18.0, 3.2, '[{"unit":"glass","grams":250}]'::jsonb, 'Ripe mango blended with whole milk and 1 tsp sugar', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001de', 'Haldi Doodh (Turmeric Milk)', ARRAY['haldi wala doodh', 'golden milk', 'turmeric latte']::text[], 76.0, 3.2, 7.2, 3.6, '[{"unit":"glass","grams":200},{"unit":"cup","grams":150}]'::jsonb, 'Whole milk with turmeric and 1 tsp sugar per glass', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001df', 'Badam Milk', ARRAY['badam doodh', 'almond milk indian']::text[], 116.0, 4.0, 14.0, 5.0, '[{"unit":"glass","grams":200}]'::jsonb, 'Whole milk with ground almonds, saffron and sugar', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001e0', 'Jaljeera', ARRAY['jal jeera']::text[], 22.0, 0.2, 5.2, 0.1, '[{"unit":"glass","grams":250}]'::jsonb, 'Cumin and mint drink with a little sugar and black salt', 'recipe');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001e1', 'Cola / Soft Drink', ARRAY['coke', 'pepsi', 'thums up', 'soda', 'cold drink']::text[], 42.0, 0.0, 10.6, 0.0, '[{"unit":"can","grams":300},{"unit":"glass","grams":250},{"unit":"bottle","grams":600}]'::jsonb, 'Regular sugar-sweetened cola (label)', 'label');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001e2', 'Mango Drink (Frooti / Maaza / Slice)', ARRAY['frooti', 'maaza', 'slice mango']::text[], 64.0, 0.0, 16.0, 0.0, '[{"unit":"tetra pack","grams":160},{"unit":"glass","grams":250},{"unit":"bottle","grams":600}]'::jsonb, 'Packaged mango drink (label)', 'label');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001e3', 'Strawberry', ARRAY['strawberries']::text[], 32.0, 0.7, 7.7, 0.3, '[{"unit":"katori","grams":150},{"unit":"piece","grams":12}]'::jsonb, 'Raw strawberries per 100 g (USDA FDC)', 'usda_fdc');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001e4', 'Kiwi', ARRAY['kiwi fruit']::text[], 61.0, 1.1, 14.7, 0.5, '[{"unit":"piece","grams":70}]'::jsonb, 'Raw green kiwifruit per 100 g (USDA FDC)', 'usda_fdc');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001e5', 'Litchi', ARRAY['lychee', 'lichi']::text[], 66.0, 0.8, 16.5, 0.4, '[{"unit":"piece","grams":10},{"unit":"katori","grams":100}]'::jsonb, 'Raw litchi flesh per 100 g (USDA FDC)', 'usda_fdc');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001e6', 'Custard Apple (Sitaphal)', ARRAY['sitaphal', 'sharifa', 'sugar apple']::text[], 94.0, 2.1, 23.6, 0.3, '[{"unit":"medium","grams":100}]'::jsonb, 'Raw sugar-apple pulp per 100 g (USDA FDC)', 'usda_fdc');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001e7', 'Jamun', ARRAY['java plum', 'naval pazham']::text[], 60.0, 0.7, 15.6, 0.2, '[{"unit":"katori","grams":100},{"unit":"piece","grams":5}]'::jsonb, 'Raw java plum per 100 g (USDA FDC)', 'usda_fdc');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001e8', 'Plum (Aloo Bukhara)', ARRAY['aloo bukhara', 'plum']::text[], 46.0, 0.7, 11.4, 0.3, '[{"unit":"piece","grams":66}]'::jsonb, 'Raw plum per 100 g (USDA FDC)', 'usda_fdc');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001e9', 'Fresh Cream (Amul, 25% Fat)', ARRAY['malai cream', 'cooking cream', 'amul fresh cream']::text[], 246.0, 2.0, 3.2, 25.0, '[{"unit":"tbsp","grams":15}]'::jsonb, 'Amul fresh cream, 25% fat (label)', 'label');
insert into public.foods (id, name, aliases, kcal_per_100g, protein_g_per_100g, carbs_g_per_100g, fat_g_per_100g, portions, assumption, source) values
  ('019a9000-0000-7000-8000-0000000001ea', 'Khoya / Mawa', ARRAY['mawa', 'khoa']::text[], 421.0, 14.6, 20.5, 31.2, '[{"unit":"tbsp","grams":15},{"unit":"katori","grams":100}]'::jsonb, 'Whole milk reduced to solids', 'recipe');
