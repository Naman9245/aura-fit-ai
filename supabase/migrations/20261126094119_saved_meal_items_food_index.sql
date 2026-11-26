-- Saved meal items point at foods. Without an index on that column, the
-- foreign key check scans every saved meal item; the Supabase advisor
-- flagged it (unindexed_foreign_keys). meal_entries_food already covers
-- the same key on meal_entries.
create index saved_meal_items_food on public.saved_meal_items (food_id);
