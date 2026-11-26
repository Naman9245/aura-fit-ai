-- Food 229's name started with a space in the seed
-- (20261125200656_seed_foods.sql, which is applied and never changes).
-- The update gives the row the next number from foods_seq (foods_stamp), so
-- phones fetch the fix with their next catalogue sync. app/assets/foods.json
-- carries the same name and number, from LATER_FIXES in
-- app/tool/build_food_catalogue.py.
update public.foods
set name = 'Bharwa Baingan / Mirchi ka Salan'
where id = '019a9000-0000-7000-8000-0000000000e5'
  and name = ' Bharwa Baingan / Mirchi ka Salan';
