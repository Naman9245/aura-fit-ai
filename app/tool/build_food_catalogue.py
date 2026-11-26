"""Builds the verified 406-item Indian food catalogue (PRD Food data, p. 20).

Four layers, never scraped from other apps:
  1. 120 raw staples from USDA FoodData Central (CC0 public domain).
  2. 206 cooked Indian home & mess dishes worked out by recipe maths from raw
     ingredients, cooked moisture yields and standard household measures
     (1 katori = 150 ml), each carrying its explicit assumption.
  3. 80 packaged Indian fitness staples from public nutrition labels.
  4. Weekly additions from missed-search counts (N10).

Writes app/assets/foods.json, bundled inside the app for instant offline
search. Run it from the repo root:

    python app/tool/build_food_catalogue.py

The server got the same 406 rows, with the same ids and seq numbers, from
supabase/migrations/20261125200656_seed_foods.sql. That migration is applied
and never changes, so the rows below stay exactly as seeded. A later change
to a food goes in a new migration and in LATER_FIXES, with the seq the
server gives it; foods.json then matches the server row for row, which CI
checks (supabase/tests/check_catalogue.py).
"""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
JSON_OUT = ROOT / "app" / "assets" / "foods.json"


def p(unit: str, grams: float) -> dict[str, object]:
    return {"unit": unit, "grams": grams}


KATORI = [p("katori", 150), p("small katori", 100), p("bowl", 250)]
DRY_SABZI = [p("katori", 120), p("small katori", 80), p("plate", 180)]
GRAVY = [p("katori", 150), p("bowl", 250)]
RICE_BOWL = [p("katori", 150), p("plate", 250), p("bowl", 200)]
RAW_GRAIN = [p("katori", 100), p("tbsp", 15), p("cup", 150)]
RAW_VEG = [p("medium", 100), p("katori chopped", 100), p("cup", 120)]
FRUIT_STD = [p("medium", 120), p("katori", 120)]
NUT_STD = [p("handful", 28), p("tbsp", 10), p("piece", 1.2)]
LIQUID = [p("glass", 200), p("cup", 150), p("tbsp", 15)]
OIL_PORTIONS = [p("tsp", 4.5), p("tbsp", 13.5)]


# Tuple: (name, aliases, kcal, protein, carbs, fat, portions, assumption, source)
RAW_STAPLES: list[tuple] = [
    # Flours, grains & millets (24)
    ("Whole Wheat Atta (Raw)", ["gehu ka atta", "wheat flour", "chapati atta"], 340, 12.1, 71.2, 1.7, RAW_GRAIN, "Raw whole wheat flour per 100 g (USDA FDC)", "usda_fdc"),
    ("Refined Wheat Flour (Maida)", ["maida", "all purpose flour"], 364, 10.3, 76.3, 1.0, RAW_GRAIN, "Raw refined wheat flour per 100 g (USDA FDC)", "usda_fdc"),
    ("Semolina (Suji / Rava)", ["suji", "sooji", "rava", "semolina"], 360, 12.7, 72.8, 1.1, RAW_GRAIN, "Raw semolina per 100 g (USDA FDC)", "usda_fdc"),
    ("Besan (Chickpea Flour)", ["besan", "gram flour", "chana atta"], 387, 22.4, 57.8, 6.7, RAW_GRAIN, "Raw chickpea flour per 100 g (USDA FDC)", "usda_fdc"),
    ("Ragi Flour (Finger Millet)", ["ragi atta", "nachni", "kelvaragu"], 336, 7.3, 72.0, 1.5, RAW_GRAIN, "Raw finger millet flour per 100 g (USDA FDC)", "usda_fdc"),
    ("Jowar Flour (Sorghum)", ["jowar atta", "cholam", "jolada"], 349, 10.4, 72.6, 1.9, RAW_GRAIN, "Raw sorghum flour per 100 g (USDA FDC)", "usda_fdc"),
    ("Bajra Flour (Pearl Millet)", ["bajra atta", "kambu", "sajje"], 361, 11.6, 67.5, 5.0, RAW_GRAIN, "Raw pearl millet flour per 100 g (USDA FDC)", "usda_fdc"),
    ("Makki ka Atta (Cornmeal)", ["makki atta", "maize flour", "corn flour yellow"], 362, 8.1, 76.9, 3.6, RAW_GRAIN, "Raw yellow cornmeal per 100 g (USDA FDC)", "usda_fdc"),
    ("Rice Flour (Chawal ka Atta)", ["chawal ka atta", "akki hittu", "arisi mavu"], 366, 6.0, 80.1, 1.4, RAW_GRAIN, "Raw white rice flour per 100 g (USDA FDC)", "usda_fdc"),
    ("White Basmati Rice (Raw)", ["chawal raw", "basmati raw", "kacha chawal"], 365, 7.1, 80.0, 0.7, RAW_GRAIN, "Raw white rice per 100 g (USDA FDC)", "usda_fdc"),
    ("Brown Rice (Raw)", ["brown chawal raw", "unpolished rice"], 367, 7.5, 76.2, 2.9, RAW_GRAIN, "Raw brown rice per 100 g (USDA FDC)", "usda_fdc"),
    ("Sona Masoori Rice (Raw)", ["sona masuri", "raw rice", "arisi"], 360, 6.8, 79.5, 0.6, RAW_GRAIN, "Raw medium-grain white rice per 100 g (USDA FDC)", "usda_fdc"),
    ("Parboiled Rice (Ukda / Idli Rice)", ["ukda chawal", "matta rice raw", "idli arisi"], 368, 7.5, 80.4, 0.8, RAW_GRAIN, "Raw parboiled rice per 100 g (USDA FDC)", "usda_fdc"),
    ("Rolled Oats (Raw)", ["oats", "jai", "oatmeal dry"], 379, 13.2, 67.7, 6.5, [p("cup", 80), p("katori", 50), p("tbsp", 10)], "Dry rolled oats per 100 g (USDA FDC)", "usda_fdc"),
    ("Poha / Flattened Rice (Dry)", ["kacha poha", "aval", "chira", "atukulu"], 358, 6.6, 77.3, 1.2, [p("katori", 50), p("cup", 70)], "Dry rice flakes per 100 g (USDA FDC)", "usda_fdc"),
    ("Murmura / Puffed Rice", ["murmura", "kurmura", "muri", "pori"], 382, 7.5, 85.0, 0.5, [p("katori", 25), p("bowl", 40)], "Dry puffed rice per 100 g (USDA FDC)", "usda_fdc"),
    ("Sabudana / Tapioca Pearls (Dry)", ["sabudana", "sago", "javvarisi"], 358, 0.2, 88.7, 0.0, [p("katori", 80), p("tbsp", 15)], "Dry tapioca pearls per 100 g (USDA FDC)", "usda_fdc"),
    ("Daliya / Broken Wheat (Raw)", ["dalia", "lapsi", "cracked wheat"], 342, 12.3, 72.0, 1.8, RAW_GRAIN, "Dry cracked wheat per 100 g (USDA FDC)", "usda_fdc"),
    ("Quinoa (Raw)", ["quinoa dry"], 368, 14.1, 64.2, 6.1, RAW_GRAIN, "Uncooked quinoa per 100 g (USDA FDC)", "usda_fdc"),
    ("Sattu (Roasted Gram Flour)", ["sattu", "chana sattu", "roasted bengal gram flour"], 378, 20.6, 61.5, 5.2, [p("tbsp", 15), p("scoop", 30), p("katori", 80)], "Dry roasted Bengal gram flour per 100 g (USDA FDC)", "usda_fdc"),
    ("Vermicelli / Semiya (Dry)", ["sewai", "seviyan", "semiya raw"], 358, 11.5, 74.7, 1.2, RAW_GRAIN, "Dry wheat vermicelli per 100 g (USDA FDC)", "usda_fdc"),
    ("Foxtail Millet / Kangni (Raw)", ["kangni", "thinai", "korralu"], 351, 11.2, 63.2, 4.0, RAW_GRAIN, "Raw foxtail millet per 100 g (USDA FDC)", "usda_fdc"),
    ("Barnyard Millet / Samak (Raw)", ["samak chawal", "sama", "vrat ke chawal"], 342, 6.2, 65.5, 2.2, RAW_GRAIN, "Raw barnyard millet per 100 g (USDA FDC)", "usda_fdc"),
    ("Buckwheat Flour / Kuttu ka Atta", ["kuttu atta", "buckwheat"], 335, 12.6, 70.6, 3.1, RAW_GRAIN, "Whole-groat buckwheat flour per 100 g (USDA FDC)", "usda_fdc"),

    # Pulses, lentils & legumes raw (16)
    ("Toor / Arhar Dal (Raw)", ["toor dal raw", "arhar", "tuvar", "pigeon pea"], 343, 21.7, 62.8, 1.5, RAW_GRAIN, "Dry split pigeon peas per 100 g (USDA FDC)", "usda_fdc"),
    ("Yellow Moong Dal (Raw)", ["dhuli moong", "split mung bean", "pesara pappu"], 348, 24.5, 59.9, 1.2, RAW_GRAIN, "Dry split mung beans per 100 g (USDA FDC)", "usda_fdc"),
    ("Whole Green Moong (Raw)", ["sabut moong", "green gram", "hare moong"], 347, 23.9, 62.6, 1.2, RAW_GRAIN, "Dry mung beans per 100 g (USDA FDC)", "usda_fdc"),
    ("Moong Sprouts (Raw)", ["ankurit moong", "mung sprouts", "sprouted moong"], 30, 3.0, 5.9, 0.2, [p("katori", 80), p("bowl", 120)], "Raw sprouted mung beans per 100 g (USDA FDC)", "usda_fdc"),
    ("Masoor Dal (Red Lentils, Raw)", ["lal masoor", "red lentil"], 352, 24.6, 63.4, 1.1, RAW_GRAIN, "Dry red lentils per 100 g (USDA FDC)", "usda_fdc"),
    ("Whole Masoor (Brown Lentils, Raw)", ["sabut masoor", "kali masoor"], 353, 25.8, 60.1, 1.1, RAW_GRAIN, "Dry whole lentils per 100 g (USDA FDC)", "usda_fdc"),
    ("Urad Dal Split (Raw)", ["dhuli urad", "ulundu", "black gram split"], 341, 25.2, 59.0, 1.6, RAW_GRAIN, "Dry split black gram per 100 g (USDA FDC)", "usda_fdc"),
    ("Whole Black Urad (Sabut Urad, Raw)", ["sabut urad", "kali dal raw"], 341, 25.0, 58.9, 1.6, RAW_GRAIN, "Dry whole black gram per 100 g (USDA FDC)", "usda_fdc"),
    ("Chana Dal (Split Bengal Gram, Raw)", ["chana dal raw", "kadala parippu"], 364, 21.5, 61.0, 5.3, RAW_GRAIN, "Dry split chickpeas per 100 g (USDA FDC)", "usda_fdc"),
    ("Kabuli Chana / Chickpeas (Raw)", ["safed chana", "garbanzo", "chole raw"], 378, 20.5, 63.0, 6.0, RAW_GRAIN, "Dry chickpeas per 100 g (USDA FDC)", "usda_fdc"),
    ("Kala Chana / Black Chickpeas (Raw)", ["desi chana", "brown chana", "kadala"], 360, 20.0, 60.7, 5.1, RAW_GRAIN, "Dry brown chickpeas per 100 g (USDA FDC)", "usda_fdc"),
    ("Rajma / Red Kidney Beans (Raw)", ["rajma raw", "kidney beans"], 333, 23.6, 60.0, 0.8, RAW_GRAIN, "Dry red kidney beans per 100 g (USDA FDC)", "usda_fdc"),
    ("Lobia / Black-Eyed Peas (Raw)", ["chawli", "rongi", "karamani"], 336, 23.5, 60.0, 1.3, RAW_GRAIN, "Dry cowpeas per 100 g (USDA FDC)", "usda_fdc"),
    ("Moth Beans / Matki (Raw)", ["matki", "moth dal"], 343, 22.9, 61.5, 1.6, RAW_GRAIN, "Dry moth beans per 100 g (USDA FDC)", "usda_fdc"),
    ("Soybean Whole (Raw)", ["soya bean dry", "bhatmas"], 446, 36.5, 30.2, 19.9, RAW_GRAIN, "Dry mature soybeans per 100 g (USDA FDC)", "usda_fdc"),
    ("Green Peas / Matar (Raw)", ["hara matar", "fresh peas"], 81, 5.4, 14.5, 0.4, [p("katori", 100), p("tbsp", 15)], "Raw green peas per 100 g (USDA FDC)", "usda_fdc"),

    # Dairy, eggs, meat & fish raw (22)
    ("Paneer (Fresh Cow Milk)", ["cottage cheese indian", "chhena paneer"], 265, 18.3, 3.4, 20.8, [p("cube", 15), p("katori cubes", 100), p("slice", 50)], "Fresh Indian paneer per 100 g (USDA FDC)", "usda_fdc"),
    ("Low-Fat Paneer (Toned Milk)", ["lite paneer", "skim paneer"], 178, 22.0, 4.5, 8.0, [p("katori cubes", 100), p("slice", 50)], "Low-fat paneer per 100 g (USDA FDC)", "usda_fdc"),
    ("Firm Tofu (Raw)", ["soya paneer", "bean curd", "tofu"], 144, 15.8, 2.8, 8.7, [p("katori cubes", 100), p("slice", 50)], "Firm calcium-set tofu per 100 g (USDA FDC)", "usda_fdc"),
    ("Whole Cow Milk", ["gai ka doodh", "cow milk"], 61, 3.2, 4.8, 3.3, LIQUID, "Fluid whole cow milk, 3.25% fat per 100 g (USDA FDC)", "usda_fdc"),
    ("Buffalo Milk", ["bhains ka doodh", "full fat doodh"], 97, 3.8, 5.2, 6.9, LIQUID, "Fluid buffalo milk per 100 g (USDA FDC)", "usda_fdc"),
    ("Skimmed Milk", ["double toned milk", "fat free doodh"], 34, 3.4, 5.0, 0.1, LIQUID, "Nonfat fluid milk per 100 g (USDA FDC)", "usda_fdc"),
    ("Plain Curd / Dahi (Home Set)", ["dahi", "curd", "thayir", "mosaru", "doi"], 61, 3.5, 4.7, 3.3, [p("katori", 150), p("small katori", 100), p("tbsp", 15)], "Plain whole-milk yogurt per 100 g (USDA FDC)", "usda_fdc"),
    ("Low-Fat Curd / Dahi", ["toned dahi", "low fat yogurt"], 46, 4.3, 5.2, 1.0, [p("katori", 150), p("small katori", 100)], "Low-fat plain yogurt per 100 g (USDA FDC)", "usda_fdc"),
    ("Hung Curd / Chakka", ["chakka dahi", "strained curd"], 97, 9.0, 4.0, 5.0, [p("katori", 100), p("tbsp", 20)], "Strained plain yogurt per 100 g (USDA FDC)", "usda_fdc"),
    ("Plain Buttermilk / Chaas", ["chaas", "mattha", "moru", "majjige"], 22, 1.5, 2.2, 0.8, [p("glass", 200), p("cup", 150)], "Diluted plain cultured buttermilk per 100 g (USDA FDC)", "usda_fdc"),
    ("Whole Egg (Raw)", ["kacha anda", "muttai", "dim"], 143, 12.6, 0.7, 9.5, [p("egg", 50)], "Raw whole chicken egg per 100 g (USDA FDC)", "usda_fdc"),
    ("Egg White (Raw)", ["anda safedi", "egg albumin"], 52, 10.9, 0.7, 0.2, [p("egg white", 33)], "Raw chicken egg white per 100 g (USDA FDC)", "usda_fdc"),
    ("Egg Yolk (Raw)", ["anda zardi", "yellow of egg"], 322, 15.9, 3.6, 26.5, [p("egg yolk", 17)], "Raw chicken egg yolk per 100 g (USDA FDC)", "usda_fdc"),
    ("Chicken Breast Boneless (Raw)", ["murga breast", "lean chicken raw"], 120, 22.5, 0.0, 2.6, [p("breast", 150), p("katori cubes", 120)], "Raw skinless chicken breast per 100 g (USDA FDC)", "usda_fdc"),
    ("Chicken Thigh Skinless (Raw)", ["chicken leg boneless", "murga thigh"], 121, 19.7, 0.0, 4.1, [p("piece", 100)], "Raw skinless chicken thigh per 100 g (USDA FDC)", "usda_fdc"),
    ("Goat Meat / Mutton Lean (Raw)", ["mutton raw", "bakra meat", "gosht"], 109, 20.6, 0.0, 2.3, [p("katori", 120), p("piece", 50)], "Raw lean goat meat per 100 g (USDA FDC)", "usda_fdc"),
    ("Rohu / Carp Fish (Raw)", ["rohu machli", "katla", "rui maach"], 97, 17.0, 0.0, 2.7, [p("piece", 80), p("fillet", 120)], "Raw freshwater carp per 100 g (USDA FDC)", "usda_fdc"),
    ("Surmai / King Mackerel (Raw)", ["seer fish", "vanjaram", "neymeen"], 105, 19.0, 0.0, 2.6, [p("steak", 100)], "Raw king mackerel per 100 g (USDA FDC)", "usda_fdc"),
    ("Pomfret Fish (Raw)", ["paplet", "avoli", "vaval"], 96, 18.5, 0.0, 2.0, [p("medium", 120)], "Raw white pomfret per 100 g (USDA FDC)", "usda_fdc"),
    ("Prawns / Shrimp (Raw)", ["jhinga", "chingri", "eral"], 85, 20.1, 0.0, 0.5, [p("katori", 100)], "Raw peeled shrimp per 100 g (USDA FDC)", "usda_fdc"),
    ("Pure Ghee (Clarified Butter)", ["desi ghee", "cow ghee", "tup", "nei"], 900, 0.0, 0.0, 99.8, OIL_PORTIONS, "Clarified butter per 100 g (USDA FDC)", "usda_fdc"),
    ("Cooking Oil (Mustard / Groundnut / Sunflower)", ["sarson tel", "singdana tel", "refined oil", "coconut oil", "olive oil"], 884, 0.0, 0.0, 100.0, OIL_PORTIONS, "Pure vegetable oil per 100 g (USDA FDC)", "usda_fdc"),

    # Vegetables raw (26)
    ("Potato (Aloo, Raw)", ["aloo", "batata", "urulaikizhangu"], 77, 2.0, 17.5, 0.1, [p("medium", 120), p("small", 80)], "Raw potato flesh per 100 g (USDA FDC)", "usda_fdc"),
    ("Sweet Potato (Shakarkandi, Boiled/Raw)", ["shakarkand", "ratalu"], 86, 1.6, 20.1, 0.1, [p("medium", 130), p("katori", 120)], "Sweet potato per 100 g (USDA FDC)", "usda_fdc"),
    ("Onion (Pyaz, Raw)", ["pyaaz", "kanda", "vengayam"], 40, 1.1, 9.3, 0.1, [p("medium", 80), p("ring serving", 40)], "Raw onion per 100 g (USDA FDC)", "usda_fdc"),
    ("Tomato (Tamatar, Raw)", ["tamatar", "thakkali"], 18, 0.9, 3.9, 0.2, [p("medium", 90), p("katori", 100)], "Raw red tomato per 100 g (USDA FDC)", "usda_fdc"),
    ("Cucumber (Kheera, Raw)", ["kheera", "kakdi", "vellari"], 15, 0.7, 3.6, 0.1, [p("medium", 150), p("plate slices", 120)], "Raw cucumber per 100 g (USDA FDC)", "usda_fdc"),
    ("Carrot (Gajar, Raw)", ["gajar", "carrot"], 41, 0.9, 9.6, 0.2, [p("medium", 70), p("katori", 100)], "Raw carrot per 100 g (USDA FDC)", "usda_fdc"),
    ("Beetroot (Chukandar, Raw)", ["chukandar", "beet"], 43, 1.6, 9.6, 0.2, [p("medium", 80), p("katori", 100)], "Raw beetroot per 100 g (USDA FDC)", "usda_fdc"),
    ("Radish (Mooli, Raw)", ["mooli", "mullangi"], 16, 0.7, 3.4, 0.1, [p("medium", 100)], "Raw white radish per 100 g (USDA FDC)", "usda_fdc"),
    ("Spinach (Palak, Raw)", ["palak", "keerai"], 23, 2.9, 3.6, 0.4, [p("bunch", 200), p("cup", 30)], "Raw spinach leaves per 100 g (USDA FDC)", "usda_fdc"),
    ("Fenugreek Leaves (Methi, Raw)", ["methi bhaji", "vendhaya keerai"], 49, 4.4, 6.0, 0.9, [p("cup", 40), p("bunch", 150)], "Raw fenugreek leaves per 100 g (USDA FDC)", "usda_fdc"),
    ("Cauliflower (Phool Gobhi, Raw)", ["gobhi", "gobi"], 25, 1.9, 5.0, 0.3, RAW_VEG, "Raw cauliflower florets per 100 g (USDA FDC)", "usda_fdc"),
    ("Cabbage (Patta Gobhi, Raw)", ["band gobhi", "kobi", "muttaikose"], 25, 1.3, 5.8, 0.1, RAW_VEG, "Raw green cabbage per 100 g (USDA FDC)", "usda_fdc"),
    ("Broccoli (Raw)", ["hari gobhi", "broccoli"], 34, 2.8, 6.6, 0.4, RAW_VEG, "Raw broccoli florets per 100 g (USDA FDC)", "usda_fdc"),
    ("Okra / Ladyfinger (Bhindi, Raw)", ["bhindi", "vendakkai", "bhendi"], 33, 1.9, 7.5, 0.2, RAW_VEG, "Raw okra per 100 g (USDA FDC)", "usda_fdc"),
    ("Eggplant / Brinjal (Baingan, Raw)", ["baingan", "kathirikai", "ringan"], 25, 1.0, 5.9, 0.2, RAW_VEG, "Raw eggplant per 100 g (USDA FDC)", "usda_fdc"),
    ("Bottle Gourd (Lauki / Dudhi, Raw)", ["lauki", "ghiya", "dudhi", "sorakkai"], 14, 0.6, 3.4, 0.0, RAW_VEG, "Raw bottle gourd per 100 g (USDA FDC)", "usda_fdc"),
    ("Ridge Gourd (Turai / Tori, Raw)", ["tori", "turai", "dodka", "peerkangai"], 20, 1.2, 4.4, 0.2, RAW_VEG, "Raw ridge gourd per 100 g (USDA FDC)", "usda_fdc"),
    ("Bitter Gourd (Karela, Raw)", ["karela", "pavakkai", "karle"], 17, 1.0, 3.7, 0.2, RAW_VEG, "Raw bitter gourd per 100 g (USDA FDC)", "usda_fdc"),
    ("Capsicum / Bell Pepper (Shimla Mirch)", ["shimla mirch", "capsicum"], 26, 1.0, 6.0, 0.3, RAW_VEG, "Raw bell pepper per 100 g (USDA FDC)", "usda_fdc"),
    ("French Beans (Farasbi, Raw)", ["beans", "haricot beans", "farasbi"], 31, 1.8, 7.0, 0.2, RAW_VEG, "Raw snap green beans per 100 g (USDA FDC)", "usda_fdc"),
    ("Button Mushroom (Raw)", ["khumb", "mushroom"], 22, 3.1, 3.3, 0.3, [p("pack", 200), p("katori", 80)], "Raw white mushrooms per 100 g (USDA FDC)", "usda_fdc"),
    ("Sweet Corn Kernels (Boiled)", ["makai", "bhutta", "corn"], 96, 3.4, 21.0, 1.5, [p("katori", 120), p("cob", 100)], "Boiled yellow sweet corn per 100 g (USDA FDC)", "usda_fdc"),
    ("Pumpkin / Kaddu (Raw)", ["kaddu", "sitaphal sabzi", "mathan"], 26, 1.0, 6.5, 0.1, RAW_VEG, "Raw pumpkin per 100 g (USDA FDC)", "usda_fdc"),
    ("Drumstick (Sahjan / Murungakkai)", ["sahjan", "shevga", "drumstick"], 37, 2.1, 8.5, 0.2, [p("piece", 50)], "Raw drumstick pods per 100 g (USDA FDC)", "usda_fdc"),
    ("Raw Banana / Plantain (Kacha Kela)", ["kacha kela", "vazhakkai"], 122, 1.3, 31.9, 0.4, [p("medium", 120)], "Raw green plantain per 100 g (USDA FDC)", "usda_fdc"),
    ("Lemon (Nimbu)", ["nimbu", "lime"], 29, 1.1, 9.3, 0.3, [p("medium", 40), p("tbsp juice", 15)], "Raw lemon per 100 g (USDA FDC)", "usda_fdc"),

    # Fruits, nuts, seeds & sweeteners (32)
    ("Banana (Kela, Ripe)", ["kela", "vazhaipazham", "banana"], 89, 1.1, 22.8, 0.3, [p("medium", 118), p("small elaichi", 60)], "Raw ripe banana per 100 g (USDA FDC)", "usda_fdc"),
    ("Apple (Seb)", ["seb", "apple"], 52, 0.3, 13.8, 0.2, [p("medium", 160), p("katori diced", 110)], "Raw apple with skin per 100 g (USDA FDC)", "usda_fdc"),
    ("Papaya (Papita, Ripe)", ["papita", "pappali"], 43, 0.5, 10.8, 0.3, [p("katori cubes", 140), p("plate", 220)], "Raw papaya per 100 g (USDA FDC)", "usda_fdc"),
    ("Mango (Aam, Ripe)", ["aam", "alphonso", "banganapalli"], 60, 0.8, 15.0, 0.4, [p("medium", 180), p("katori cubes", 140)], "Raw mango flesh per 100 g (USDA FDC)", "usda_fdc"),
    ("Guava (Amrood)", ["amrood", "peru", "koyya"], 68, 2.6, 14.3, 1.0, [p("medium", 120)], "Raw common guava per 100 g (USDA FDC)", "usda_fdc"),
    ("Pomegranate (Anar)", ["anar", "dalimb", "madulai"], 83, 1.7, 18.7, 1.2, [p("katori seeds", 120)], "Raw pomegranate arils per 100 g (USDA FDC)", "usda_fdc"),
    ("Orange / Mosambi (Santra)", ["santra", "mosambi", "sweet lime", "kinnow"], 47, 0.9, 11.8, 0.1, [p("medium", 130)], "Raw orange per 100 g (USDA FDC)", "usda_fdc"),
    ("Watermelon (Tarbooz)", ["tarbooz", "kalingad", "watermelon"], 30, 0.6, 7.6, 0.2, [p("katori cubes", 150), p("bowl", 250)], "Raw watermelon per 100 g (USDA FDC)", "usda_fdc"),
    ("Muskmelon (Kharbooja)", ["kharbooja", "cantaloupe"], 34, 0.8, 8.2, 0.2, [p("katori cubes", 150)], "Raw cantaloupe per 100 g (USDA FDC)", "usda_fdc"),
    ("Grapes (Angoor)", ["angoor", "draksha"], 69, 0.7, 18.1, 0.2, [p("katori", 120)], "Raw grapes per 100 g (USDA FDC)", "usda_fdc"),
    ("Sapodilla (Chikoo)", ["chikoo", "sapota"], 83, 0.4, 20.0, 1.1, [p("medium", 85)], "Raw sapodilla per 100 g (USDA FDC)", "usda_fdc"),
    ("Pineapple (Ananas)", ["ananas", "pineapple"], 50, 0.5, 13.1, 0.1, [p("katori cubes", 140)], "Raw pineapple per 100 g (USDA FDC)", "usda_fdc"),
    ("Pear (Nashpati)", ["nashpati", "pear"], 57, 0.4, 15.2, 0.1, [p("medium", 160)], "Raw pear per 100 g (USDA FDC)", "usda_fdc"),
    ("Dates (Khajoor)", ["khajoor", "kimia dates", "medjool"], 282, 2.5, 75.0, 0.4, [p("piece", 8)], "Deglet/pitted dates per 100 g (USDA FDC)", "usda_fdc"),
    ("Raisins (Kishmish)", ["kishmish", "manuka"], 299, 3.1, 79.2, 0.5, [p("tbsp", 10), p("handful", 25)], "Seedless raisins per 100 g (USDA FDC)", "usda_fdc"),
    ("Almonds (Badam)", ["badam", "almonds"], 579, 21.2, 21.6, 49.9, [p("almond", 1.2), p("handful", 28)], "Whole raw almonds per 100 g (USDA FDC)", "usda_fdc"),
    ("Walnuts (Akhrot)", ["akhrot", "walnut"], 654, 15.2, 13.7, 65.2, [p("half", 2.5), p("handful", 28)], "English walnuts per 100 g (USDA FDC)", "usda_fdc"),
    ("Cashews (Kaju)", ["kaju", "cashew nut"], 553, 18.2, 30.2, 43.9, [p("cashew", 1.5), p("handful", 28)], "Raw cashews per 100 g (USDA FDC)", "usda_fdc"),
    ("Pistachios (Pista)", ["pista", "pistachio"], 560, 20.2, 27.2, 45.3, [p("handful", 28), p("tbsp", 10)], "Raw pistachios per 100 g (USDA FDC)", "usda_fdc"),
    ("Peanuts (Moongphali, Raw / Roasted)", ["moongphali", "singdana", "verkadalai", "groundnut"], 567, 25.8, 16.1, 49.2, [p("handful", 28), p("katori", 60), p("tbsp", 10)], "Dry roasted peanuts without oil per 100 g (USDA FDC)", "usda_fdc"),
    ("Roasted Chana (Bhuna Chana)", ["bhuna chana", "futana", "pottukadalai"], 369, 20.8, 60.0, 5.4, [p("handful", 30), p("katori", 60)], "Dry roasted chickpeas per 100 g (USDA FDC)", "usda_fdc"),
    ("Makhana / Fox Nuts (Plain Popped)", ["phool makhana", "lotus seeds"], 347, 9.7, 76.9, 0.1, [p("katori", 20), p("bowl", 35)], "Dried popped lotus seeds per 100 g (USDA FDC)", "usda_fdc"),
    ("Flax Seeds (Alsi)", ["alsi", "jawas", "flaxseed"], 534, 18.3, 28.9, 42.2, [p("tbsp", 10), p("tsp", 3.5)], "Whole flaxseed per 100 g (USDA FDC)", "usda_fdc"),
    ("Chia Seeds", ["chia", "sabja"], 486, 16.5, 42.1, 30.7, [p("tbsp", 12), p("tsp", 4)], "Dried chia seeds per 100 g (USDA FDC)", "usda_fdc"),
    ("Pumpkin Seeds (Pepitas)", ["kaddu ke beej", "pumpkin seeds"], 559, 30.2, 10.7, 49.1, [p("tbsp", 10), p("handful", 28)], "Dried pumpkin seed kernels per 100 g (USDA FDC)", "usda_fdc"),
    ("Sunflower Seeds", ["surajmukhi ke beej", "sunflower seeds"], 584, 20.8, 20.0, 51.5, [p("tbsp", 10), p("handful", 28)], "Dried sunflower seed kernels per 100 g (USDA FDC)", "usda_fdc"),
    ("Sesame Seeds (Til)", ["safed til", "kala til", "ellu"], 573, 17.7, 23.5, 49.7, [p("tbsp", 9), p("tsp", 3)], "Whole dried sesame seeds per 100 g (USDA FDC)", "usda_fdc"),
    ("Fresh Coconut Meat (Nariyal)", ["geela nariyal", "thengai", "khobra"], 354, 3.3, 15.2, 33.5, [p("piece", 25), p("tbsp grated", 10)], "Raw coconut meat per 100 g (USDA FDC)", "usda_fdc"),
    ("White Sugar (Cheeni)", ["cheeni", "shakkar", "sakkarai"], 387, 0.0, 100.0, 0.0, [p("tsp", 4), p("tbsp", 12)], "Granulated sugar per 100 g (USDA FDC)", "usda_fdc"),
    ("Jaggery (Gur / Gud)", ["gud", "gur", "vellam", "bellam"], 383, 0.4, 98.0, 0.1, [p("piece", 10), p("tbsp", 12)], "Cane jaggery per 100 g (USDA FDC)", "usda_fdc"),
    ("Honey (Shahad)", ["shahad", "madhu"], 304, 0.3, 82.4, 0.0, [p("tsp", 7), p("tbsp", 21)], "Pure honey per 100 g (USDA FDC)", "usda_fdc"),
    ("Unsweetened Cocoa Powder", ["cocoa powder", "koko"], 228, 19.6, 57.9, 13.7, [p("tbsp", 5), p("tsp", 2)], "Dry unsweetened cocoa per 100 g (USDA FDC)", "usda_fdc"),
]


COOKED_DISHES: list[tuple] = [
    # Indian Breads (26)
    ("Phulka / Plain Roti", ["roti", "chapati", "fulka", "gehu ki roti", "poli"], 242, 8.6, 50.6, 1.2, [p("piece", 40), p("small phulka", 30), p("large roti", 50)], "28 g whole wheat atta cooked into 40 g dry phulka, no ghee", "recipe"),
    ("Chapati with Ghee", ["ghee roti", "buttered chapati", "chupdi roti"], 298, 7.9, 46.8, 8.8, [p("piece", 44), p("small", 34)], "28 g wheat atta + 3.5 g ghee per 44 g chapati", "recipe"),
    ("Tandoori Roti (Plain)", ["tandoori roti", "clay oven roti"], 265, 8.8, 54.0, 1.6, [p("piece", 65)], "48 g whole wheat dough baked in tandoor, no butter", "recipe"),
    ("Butter Tandoori Roti", ["butter roti"], 305, 8.2, 50.5, 7.5, [p("piece", 70)], "Tandoori roti brushed with 4 g butter", "recipe"),
    ("Rumali Roti", ["roomali roti", "thin handkerchief roti"], 278, 8.4, 57.5, 1.8, [p("piece", 65)], "50 g atta-maida blend cooked thin, no butter", "recipe"),
    ("Bajra Roti / Bhakri", ["bajre ki roti", "pearl millet roti", "kambu roti"], 248, 8.0, 46.5, 3.5, [p("piece", 60)], "42 g bajra flour cooked dry into 60 g bhakri, no ghee", "recipe"),
    ("Jowar Bhakri / Roti", ["jowar ki roti", "jolada rotti", "bhakri"], 238, 7.1, 49.5, 1.3, [p("piece", 65)], "45 g jowar flour cooked dry into 65 g bhakri, no ghee", "recipe"),
    ("Ragi Roti", ["nachni bhakri", "ragi rotti"], 232, 5.2, 49.0, 1.6, [p("piece", 60)], "42 g ragi flour cooked dry, no ghee", "recipe"),
    ("Makki ki Roti", ["makke ki roti", "corn roti"], 255, 5.6, 53.0, 2.8, [p("piece", 65)], "45 g makki atta cooked on tawa, no ghee", "recipe"),
    ("Missi Roti", ["besan roti", "punjabi missi roti"], 268, 11.8, 46.0, 4.2, [p("piece", 55)], "50:50 wheat atta and besan with spices, 2 g oil", "recipe"),
    ("Multigrain Roti", ["7 grain roti", "mixed millet chapati"], 246, 9.8, 47.5, 2.2, [p("piece", 42)], "30 g wheat, jowar, ragi and besan blend, no ghee", "recipe"),
    ("Plain Triangle Paratha", ["sada paratha", "tawa paratha", "parotta home"], 312, 7.8, 48.5, 9.6, [p("piece", 60)], "40 g wheat atta roasted with 5 g oil/ghee", "recipe"),
    ("Aloo Paratha", ["potato stuffed paratha", "alu paratha"], 258, 5.6, 41.5, 7.8, [p("piece", 100), p("large dhaba", 140)], "45 g atta + 45 g spiced potato + 6 g oil/ghee", "recipe"),
    ("Paneer Paratha", ["cottage cheese paratha"], 286, 11.2, 34.5, 11.4, [p("piece", 110)], "45 g atta + 50 g grated paneer + 5 g oil/ghee", "recipe"),
    ("Gobhi Paratha", ["cauliflower paratha", "gobi paratha"], 238, 6.2, 37.0, 7.2, [p("piece", 100)], "45 g atta + 45 g grated gobhi + 5.5 g oil", "recipe"),
    ("Methi Paratha / Thepla", ["thepla", "gujarati methi thepla", "methi paratha"], 285, 7.6, 43.0, 9.2, [p("piece", 45), p("paratha", 70)], "Wheat atta, fresh methi leaves, curd and 4 g oil", "recipe"),
    ("Mooli Paratha", ["radish paratha"], 232, 5.8, 36.5, 7.0, [p("piece", 100)], "45 g atta + grated radish + 5.5 g oil", "recipe"),
    ("Onion Paratha (Pyaz Paratha)", ["pyaaz ka paratha", "kanda paratha"], 254, 6.0, 39.5, 7.8, [p("piece", 95)], "45 g atta + chopped onion + 6 g oil", "recipe"),
    ("Sattu Paratha", ["bihari sattu paratha", "makuni"], 276, 10.4, 42.5, 7.2, [p("piece", 95)], "45 g atta + 30 g spiced sattu + 5 g mustard oil", "recipe"),
    ("Egg Paratha (Anda Paratha)", ["anda paratha", "baida paratha"], 268, 9.8, 32.0, 11.0, [p("piece", 115)], "1 tawa paratha cooked with 1 whole egg and 5 g oil", "recipe"),
    ("Lachha Paratha", ["layered paratha", "kerala parotta", "malabar parotta"], 338, 7.2, 49.0, 12.5, [p("piece", 80)], "Layered flour dough pan-roasted with 9 g fat", "recipe"),
    ("Poori (Whole Wheat, Fried)", ["puri", "atta poori", "luchi"], 356, 7.5, 46.5, 15.6, [p("piece", 30)], "22 g wheat dough deep-fried absorbing 4.5 g oil", "recipe"),
    ("Bhatura", ["bhature", "chole bhature bread"], 342, 7.4, 50.2, 12.4, [p("piece", 80)], "Maida-curd dough deep-fried absorbing 9.5 g oil", "recipe"),
    ("Plain Naan", ["tandoori naan"], 290, 8.7, 54.5, 4.0, [p("piece", 90)], "Leavened maida dough baked in tandoor, no butter", "recipe"),
    ("Butter / Garlic Naan", ["butter naan", "garlic naan"], 326, 8.3, 51.0, 9.8, [p("piece", 100)], "Tandoori naan brushed with 6 g butter and garlic", "recipe"),
    ("Amritsari Kulcha", ["aloo kulcha", "stuffed kulcha"], 284, 7.2, 46.0, 7.8, [p("piece", 110)], "Stuffed potato kulcha baked with 5 g butter", "recipe"),

    # Cooked Rice, Khichdi, Pulao & Biryani (22)
    ("Steamed White Rice (Cooked)", ["ubla chawal", "boiled rice", "plain rice", "bhat", "annam"], 130, 2.7, 28.2, 0.3, RICE_BOWL, "36 g raw white rice boiled in water to 100 g, no oil", "recipe"),
    ("Cooked Brown Rice", ["brown chawal", "red matta rice cooked"], 123, 2.7, 25.6, 1.0, RICE_BOWL, "34 g raw brown rice boiled in water, no oil", "recipe"),
    ("Jeera Rice", ["cumin rice", "zeera chawal"], 158, 2.8, 28.5, 3.6, RICE_BOWL, "Steamed basmati rice tempered with 1 tsp ghee/oil per katori", "recipe"),
    ("Veg Pulao", ["vegetable pulav", "tehri", "masala bhat"], 152, 3.3, 25.8, 4.0, RICE_BOWL, "Basmati rice cooked with mixed vegetables and 1 tsp oil per katori", "recipe"),
    ("Matar Pulao (Peas Pulao)", ["green peas rice"], 154, 3.6, 26.2, 3.8, RICE_BOWL, "Basmati rice cooked with green peas and 1 tsp ghee per katori", "recipe"),
    ("Paneer Pulao", ["paneer tawa pulao"], 178, 6.2, 23.5, 6.6, RICE_BOWL, "Rice tossed with 25 g paneer cubes, veggies and 1 tsp oil per katori", "recipe"),
    ("Soya Chunks Pulao", ["nutrela pulao", "soya tehri", "meal maker rice"], 156, 7.8, 24.0, 3.2, RICE_BOWL, "Rice cooked with hydrated soya chunks and 1 tsp oil per katori", "recipe"),
    ("Moong Dal Khichdi", ["dal khichdi", "kichdi", "pongal"], 128, 4.8, 21.5, 2.6, RICE_BOWL, "50:50 rice and yellow moong dal pressure-cooked with 0.7 tsp ghee per katori", "recipe"),
    ("Masala Vegetable Khichdi", ["mix dal khichdi", "dalia khichdi"], 132, 4.9, 20.8, 3.2, RICE_BOWL, "Rice, moong dal and vegetables with 1 tsp ghee tadka per katori", "recipe"),
    ("Ven Pongal (Ghee Khara Pongal)", ["khara pongal", "venpongal"], 168, 4.6, 23.5, 6.2, RICE_BOWL, "Rice and moong dal tempered with cashew, pepper and ghee", "recipe"),
    ("Bisi Bele Bath", ["bisibelebath", "sambar sadam"], 144, 4.5, 22.8, 3.9, RICE_BOWL, "Rice, toor dal, vegetables, tamarind and spice paste with 1 tsp ghee", "recipe"),
    ("Curd Rice (Thayir Sadam)", ["dahi chawal", "bagala bath", "mosaranna"], 118, 3.4, 19.2, 3.1, RICE_BOWL, "Soft rice mixed with home curd and light mustard tadka", "recipe"),
    ("Lemon Rice (Chitranna)", ["nimbu chawal", "elumichai sadam"], 164, 3.4, 26.8, 4.8, RICE_BOWL, "Cooked rice tempered with peanuts, curry leaves, lemon and 1 tsp oil", "recipe"),
    ("Tamarind Rice (Puliyogare)", ["pulihora", "puliyodharai"], 172, 3.6, 27.5, 5.2, RICE_BOWL, "Rice tossed with tamarind-sesame paste, peanuts and oil", "recipe"),
    ("Tomato Rice", ["tamatar chawal", "thakkali sadam"], 148, 2.9, 25.4, 3.8, RICE_BOWL, "Rice cooked with onion-tomato masala and 1 tsp oil per katori", "recipe"),
    ("Sabudana Khichdi", ["vrat khichdi", "sago khichdi"], 196, 3.8, 33.5, 5.4, [p("katori", 140), p("plate", 200)], "Soaked sabudana, crushed peanuts, potato and 1 tsp oil per katori", "recipe"),
    ("Veg Biryani", ["vegetable dum biryani"], 168, 4.0, 26.5, 5.2, [p("katori", 150), p("plate", 280)], "Layered basmati rice, mixed vegetables, curd and 1.2 tsp oil/ghee per katori", "recipe"),
    ("Egg Biryani (Anda Biryani)", ["muttai biryani"], 176, 6.8, 23.5, 6.0, [p("plate", 280), p("katori", 150)], "Spiced basmati rice with boiled eggs and 1.2 tsp oil per katori", "recipe"),
    ("Chicken Biryani", ["hyderabadi chicken biryani", "murgh biryani"], 188, 10.5, 21.8, 6.5, [p("plate", 300), p("katori", 160)], "Basmati rice layered with marinated chicken (~35% meat by weight)", "recipe"),
    ("Mutton Biryani", ["gosht biryani"], 204, 10.2, 21.5, 8.6, [p("plate", 300), p("katori", 160)], "Basmati rice layered with spiced mutton pieces", "recipe"),
    ("Veg Fried Rice", ["indo chinese fried rice", "schezwan veg rice"], 166, 3.4, 27.2, 4.8, RICE_BOWL, "Wok-tossed rice with chopped veggies and 1 tsp oil per katori", "recipe"),
    ("Chicken / Egg Fried Rice", ["egg fried rice", "chicken schezwan rice"], 182, 8.2, 24.5, 5.6, RICE_BOWL, "Wok-tossed rice with egg/chicken strips and 1 tsp oil per katori", "recipe"),

    # Cooked Dals, Rajma, Chole & Kadhi (22)
    ("Toor Dal Tadka (Home Style)", ["arhar dal", "yellow dal tadka", "varan", "mess dal"], 114, 5.6, 15.2, 3.4, KATORI, "38 g raw toor dal cooked to 150 g katori with 4.5 g (1 tsp) oil tadka", "recipe"),
    ("Plain Boiled Toor Dal (Varan, No Tadka)", ["sadi dal", "plain varan", "diet dal"], 88, 5.6, 15.5, 0.4, KATORI, "38 g raw toor dal boiled with turmeric and salt, no oil", "recipe"),
    ("Dal Fry (Dhaba / Rich Tadka)", ["punjabi dal fry"], 136, 5.8, 15.6, 5.6, KATORI, "Thick toor-chana dal tempered with onion, tomato and 1.5 tsp ghee/oil", "recipe"),
    ("Yellow Moong Dal (Home Style)", ["moong dal tadka", "mugachi dal", "pesara pappu cooked"], 108, 6.2, 14.5, 2.8, KATORI, "38 g yellow moong dal cooked to 150 g katori with 3.5 g oil tadka", "recipe"),
    ("Whole Green Moong Dal Curry", ["sabut moong dal", "green gram curry"], 118, 6.8, 16.0, 3.0, KATORI, "Soaked green moong pressure-cooked with onion-tomato and 1 tsp oil", "recipe"),
    ("Masoor Dal Tadka", ["red lentil dal", "lal masoor cooked"], 112, 6.4, 15.4, 2.8, KATORI, "Red lentils cooked with garlic-cumin 1 tsp oil tadka per katori", "recipe"),
    ("Kali Masoor / Sabut Masoor Dal", ["black masoor dal", "akkha masoor"], 120, 6.8, 16.2, 3.1, KATORI, "Whole brown lentils cooked with onion-tomato and 1 tsp oil", "recipe"),
    ("Chana Dal Tadka", ["bengal gram dal cooked"], 132, 6.2, 17.8, 4.0, KATORI, "Split chana dal pressure-cooked with 1 tsp oil/ghee tadka", "recipe"),
    ("Dal Makhani (Home Style)", ["maa ki dal", "black urad rajma dal"], 158, 6.4, 16.5, 7.4, KATORI, "Whole black urad and rajma simmered with light butter/cream", "recipe"),
    ("Panchmel / Mix Dal", ["panchratna dal", "mixed lentil dal"], 122, 6.4, 16.2, 3.5, KATORI, "Five-lentil Rajasthani dal with 1 tsp ghee tadka per katori", "recipe"),
    ("Palak Dal (Dal Palak)", ["spinach dal", "keerai kootu"], 104, 5.8, 13.8, 2.9, KATORI, "Toor/moong dal cooked with chopped spinach and 1 tsp oil tadka", "recipe"),
    ("Sambar (South Indian)", ["tiffin sambar", "udupi sambar", "vegetable sambar"], 78, 3.4, 11.8, 2.0, KATORI, "Thin toor dal broth with drumstick, gourds, tamarind and 0.5 tsp oil", "recipe"),
    ("Tomato Pepper Rasam", ["rasam", "charu", "saaru"], 34, 1.1, 5.5, 0.9, KATORI, "Thin tamarind-tomato-pepper broth with light mustard tadka", "recipe"),
    ("Gujarati Kadhi", ["meethi kadhi", "dahi kadhi"], 76, 2.8, 9.2, 3.1, KATORI, "Buttermilk and besan simmered with curry leaves and 0.7 tsp ghee", "recipe"),
    ("Punjabi Kadhi Pakora", ["besan kadhi with pakoda"], 134, 4.8, 12.6, 7.2, KATORI, "Sour curd-besan gravy with 2 small besan pakoras per katori", "recipe"),
    ("Rajma Masala (Home Style)", ["rajma curry", "kidney bean curry"], 134, 6.8, 18.5, 3.7, KATORI, "Boiled rajma in onion-tomato masala with 1 tsp oil per katori", "recipe"),
    ("Rajma Chawal (Home Plate)", ["rajma chawal", "rajma rice"], 132, 4.8, 23.4, 2.0, [p("plate", 300), p("small bowl", 220)], "150 g steamed white rice + 150 g home-style rajma masala", "recipe"),
    ("Dal Chawal (Home Plate)", ["dal chawal", "dal bhat", "varan bhat"], 122, 4.2, 21.7, 1.9, [p("plate", 300), p("small bowl", 220)], "150 g steamed white rice + 150 g home toor dal tadka", "recipe"),
    ("Kadhi Chawal (Home Plate)", ["kadhi chawal", "kadhi rice"], 103, 2.8, 18.7, 1.7, [p("plate", 300), p("small bowl", 220)], "150 g steamed white rice + 150 g home kadhi", "recipe"),
    ("Chole Chawal (Home Plate)", ["chole chawal", "chana chawal"], 139, 4.7, 24.0, 2.6, [p("plate", 300), p("small bowl", 220)], "150 g steamed white rice + 150 g Punjabi chole", "recipe"),
    ("Punjabi Chole / Chana Masala", ["chole", "amritsari chole", "chickpea curry"], 148, 6.6, 19.8, 4.8, KATORI, "Boiled kabuli chana in onion-tomato spice gravy with 1 tsp oil", "recipe"),
    ("Kala Chana Curry / Ghugni", ["black chana sabzi", "kadala curry", "ghugni"], 138, 6.8, 19.2, 3.8, KATORI, "Boiled kala chana in home onion-tomato gravy with 1 tsp oil", "recipe"),
    ("Lobia / Rongia Masala", ["black eyed peas curry", "chawli bhaji"], 128, 6.9, 18.2, 3.1, KATORI, "Boiled lobia in tomato-ginger gravy with 1 tsp oil per katori", "recipe"),
    ("Matki Usal (Sprouted Moth Curry)", ["usal", "matki chi usal"], 124, 6.4, 17.5, 3.2, KATORI, "Sprouted moth beans cooked Maharashtrian style with 1 tsp oil", "recipe"),
    ("Boiled Chickpeas / Chana (Plain)", ["uble chole", "boiled kala chana"], 164, 8.9, 27.4, 2.6, KATORI, "Boiled chickpeas with salt and lemon, no oil", "recipe"),
    ("Boiled Rajma (Plain)", ["uble rajma", "boiled kidney beans"], 127, 8.7, 22.8, 0.5, KATORI, "Boiled red kidney beans, no oil", "recipe"),

    # Paneer, Tofu, Soya & Vegetable Sabzis (40)
    ("Paneer Bhurji", ["scrambled paneer", "paneer bhurjee"], 218, 13.8, 5.6, 15.6, DRY_SABZI, "70 g fresh paneer scrambled with onion, tomato and 3 g oil per 100 g", "recipe"),
    ("Low-Fat Paneer Bhurji", ["diet paneer bhurji"], 156, 16.5, 5.8, 7.4, DRY_SABZI, "Low-fat toned paneer scrambled with onion, tomato and 2 g oil", "recipe"),
    ("Palak Paneer", ["saag paneer", "spinach cottage cheese"], 168, 9.6, 6.8, 11.6, GRAVY, "Paneer cubes in blanched spinach puree with 1 tsp oil per katori", "recipe"),
    ("Matar Paneer", ["peas paneer curry", "mutter paneer"], 164, 8.8, 9.8, 10.2, GRAVY, "Paneer and green peas in home onion-tomato gravy", "recipe"),
    ("Kadai Paneer", ["capsicum paneer sabzi"], 188, 10.2, 7.6, 13.0, GRAVY, "Paneer, bell peppers and onion tossed in kadai masala", "recipe"),
    ("Paneer Butter Masala / Shahi Paneer", ["paneer makhani"], 224, 9.2, 9.5, 16.8, GRAVY, "Paneer in rich tomato-cashew-butter gravy", "recipe"),
    ("Paneer Tikka (Grilled / Tandoori)", ["tandoori paneer tikka", "achari paneer tikka"], 212, 14.6, 5.4, 14.8, [p("piece", 30), p("plate", 180)], "Paneer cubes marinated in hung curd and spices, grilled", "recipe"),
    ("Chilli Paneer (Dry / Semi-Gravy)", ["paneer chilly"], 208, 11.0, 12.5, 12.8, [p("katori", 140), p("plate", 200)], "Pan-seared paneer tossed with capsicum, onion and soy-chilli sauce", "recipe"),
    ("Tofu Bhurji / Stir-Fry", ["scrambled soya paneer"], 136, 11.8, 5.2, 7.6, DRY_SABZI, "Firm tofu crumbled with onion, tomato, turmeric and 1 tsp oil", "recipe"),
    ("Soya Chunks Sabzi / Curry", ["nutrela sabzi", "meal maker curry", "soya wadi"], 128, 13.5, 10.2, 3.6, KATORI, "30 g dry soya chunks boiled and cooked in onion-tomato masala + 1 tsp oil", "recipe"),
    ("Soya Keema Matar", ["veg keema", "soya granules sabzi"], 134, 14.2, 11.0, 3.8, DRY_SABZI, "Hydrated soya granules cooked with green peas and 1 tsp oil", "recipe"),
    ("Dry Soya Chunks Stir-Fry", ["high protein soya roast", "chilli soya"], 146, 16.8, 10.8, 4.0, DRY_SABZI, "Boiled squeezed soya chunks pan-tossed with spices, capsicum and 1 tsp oil", "recipe"),
    ("Aloo Gobhi (Dry)", ["potato cauliflower sabzi", "alu gobi"], 108, 2.4, 13.5, 5.0, DRY_SABZI, "Potato and cauliflower cooked dry with 1 tsp oil per katori", "recipe"),
    ("Aloo Matar (Gravy)", ["potato peas curry"], 104, 2.9, 13.8, 4.1, GRAVY, "Potato and green peas in light tomato gravy with 1 tsp oil", "recipe"),
    ("Jeera Aloo", ["cumin potatoes", "sukhe aloo"], 132, 2.2, 18.5, 5.6, DRY_SABZI, "Boiled diced potatoes tempered with cumin and 1 tsp oil per katori", "recipe"),
    ("Aloo Methi", ["potato fenugreek sabzi"], 118, 2.9, 15.2, 5.1, DRY_SABZI, "Potatoes sauteed with fresh methi leaves and 1 tsp oil", "recipe"),
    ("Aloo Palak", ["potato spinach sabzi"], 98, 2.8, 12.0, 4.4, DRY_SABZI, "Potatoes cooked with chopped spinach and 1 tsp oil", "recipe"),
    ("Aloo Shimla Mirch", ["potato capsicum sabzi"], 106, 2.0, 13.6, 4.8, DRY_SABZI, "Potatoes and bell peppers sauteed with 1 tsp oil", "recipe"),
    ("Dum Aloo", ["kashmiri dum aloo"], 154, 2.6, 17.8, 8.2, GRAVY, "Baby potatoes simmered in spiced curd-tomato gravy", "recipe"),
    ("Bhindi Masala / Bhindi Fry (Home)", ["ladyfinger sabzi", "vendakkai poriyal", "bhendi bhaji"], 104, 2.4, 9.8, 6.2, DRY_SABZI, "Cut bhindi sauteed with onion and 1.2 tsp oil per katori to stop stickiness", "recipe"),
    ("Baingan Bharta", ["roasted brinjal mash", "vangyache bharit"], 92, 1.8, 8.8, 5.6, DRY_SABZI, "Fire-roasted mashed baingan cooked with onion, tomato and 1 tsp oil", "recipe"),
    ("Aloo Baingan", ["potato brinjal sabzi"], 98, 1.9, 12.4, 4.6, DRY_SABZI, "Eggplant and potato cooked home style with 1 tsp oil", "recipe"),
    ("Lauki ki Sabzi (Bottle Gourd)", ["ghiya sabzi", "dudhi bhaji"], 64, 1.2, 5.8, 4.0, KATORI, "Steamed bottle gourd with light 1 tsp oil cumin tadka per katori", "recipe"),
    ("Lauki Chana Dal", ["ghiya chana dal", "dudhi chana"], 98, 4.2, 12.6, 3.6, KATORI, "Bottle gourd pressure-cooked with chana dal and 1 tsp oil", "recipe"),
    ("Tori / Turai ki Sabzi", ["ridge gourd sabzi", "dodka bhaji"], 68, 1.5, 6.4, 4.1, KATORI, "Ridge gourd cooked in its own moisture with 1 tsp oil per katori", "recipe"),
    ("Tinda / Parwal ki Sabzi", ["parwal aloo", "apple gourd sabzi", "kundru sabzi"], 78, 1.6, 8.2, 4.4, DRY_SABZI, "Gourd vegetable sauteed home style with 1 tsp oil", "recipe"),
    ("Karela Pyaz (Bitter Gourd Stir-Fry)", ["karela sabzi", "pavakkai fry"], 114, 2.1, 10.2, 7.2, DRY_SABZI, "Sliced bitter gourd and onions slow-cooked with 1.5 tsp oil", "recipe"),
    ("Patta Gobhi Matar (Cabbage Peas)", ["band gobhi sabzi", "cabbage thoran", "kobi chi bhaji"], 82, 2.4, 8.6, 4.2, DRY_SABZI, "Shredded cabbage and peas stir-fried with mustard and 1 tsp oil", "recipe"),
    ("Mix Veg Sabzi (Home Style)", ["mixed vegetable dry", "subz miloni"], 106, 2.8, 11.4, 5.4, DRY_SABZI, "Carrot, beans, peas, gobhi and potato cooked with 1 tsp oil per katori", "recipe"),
    ("Farasbi / Beans Poriyal", ["french beans sabzi", "beans thoran", "gawar phali"], 84, 2.5, 8.8, 4.4, DRY_SABZI, "Chopped green beans cooked with grated coconut and 1 tsp oil", "recipe"),
    ("Mushroom Masala / Matar Mushroom", ["khumb matar", "mushroom do pyaza"], 108, 4.2, 8.4, 6.4, GRAVY, "Button mushrooms and peas in onion-tomato masala with 1 tsp oil", "recipe"),
    ("Palak Corn (Spinach Corn)", ["methi corn", "corn palak"], 116, 4.2, 13.0, 5.2, GRAVY, "Sweet corn kernels simmered in spinach puree with 1 tsp oil/butter", "recipe"),
    ("Besan Gatte ki Sabzi", ["rajasthani gatta curry"], 156, 6.8, 16.5, 7.0, GRAVY, "Steamed besan dumplings in spiced curd gravy", "recipe"),
    ("Pithla / Zunka", ["besan pithla", "jhunka"], 124, 6.2, 14.2, 4.8, KATORI, "Gram flour cooked with onion, chillies and 1 tsp oil", "recipe"),
    (" Bharwa Baingan / Mirchi ka Salan", ["gutti vankaya", "stuffed brinjal"], 142, 3.2, 10.5, 9.8, GRAVY, "Baby brinjals in peanut-sesame-coconut masala", "recipe"),
    ("Avial (Kerala Mixed Veg)", ["aviyal"], 118, 2.4, 11.2, 7.2, KATORI, "Mixed gourds and tubers cooked with coconut-curd paste and coconut oil", "recipe"),
    ("Sarson ka Saag", ["mustard greens saag"], 112, 3.8, 8.6, 7.0, KATORI, "Mustard and spinach greens slow-cooked with makki atta and 1 tsp ghee", "recipe"),
    ("Chana Batata / Sukha Kala Chana", ["ashtami kala chana", "sukhe chane"], 154, 7.8, 21.5, 4.2, DRY_SABZI, "Boiled kala chana tossed dry with spices and 1 tsp oil", "recipe"),
    ("Raw Banana / Vazhakkai Stir-Fry", ["kache kele ki sabzi", "vazhakkai podimas"], 138, 1.8, 22.5, 4.6, DRY_SABZI, "Steamed raw plantain cubes tossed with spices and 1 tsp oil", "recipe"),
    ("Bharta / Chokha (Aloo Chokha)", ["aloo bharta", "bihari chokha"], 102, 2.0, 16.8, 3.0, DRY_SABZI, "Boiled mashed potato with onion, green chilli and 0.5 tsp mustard oil", "recipe"),

    # Egg, Chicken, Fish & Mutton Dishes (22)
    ("Boiled Whole Egg", ["ubla anda", "hard boiled egg", "siddha dim"], 155, 12.6, 1.1, 10.6, [p("egg", 50)], "Hard-boiled whole chicken egg, peeled, no oil", "recipe"),
    ("Boiled Egg White", ["uble ande ki safedi", "boiled egg albumin"], 52, 10.9, 0.7, 0.2, [p("egg white", 33)], "Hard-boiled egg white only, yolk removed, no oil", "recipe"),
    ("Masala Omelette (2 Eggs)", ["anda omelette", "indian masala omelet"], 184, 11.4, 2.8, 14.2, [p("omelette (2 eggs)", 120), p("single-egg omelette", 60)], "2 whole eggs whisked with onion, chilli, tomato and 4.5 g (1 tsp) oil", "recipe"),
    ("Egg White Omelette (3 Whites)", ["diet white omelette"], 92, 9.8, 2.4, 4.6, [p("omelette (3 whites)", 120)], "3 egg whites with veggies cooked in 4.5 g (1 tsp) oil", "recipe"),
    ("Egg Bhurji (Anda Bhurji)", ["scrambled indian eggs", "akuri"], 178, 10.8, 4.2, 13.2, [p("katori", 140), p("plate", 200)], "2 eggs scrambled with onion, tomato and 5 g oil", "recipe"),
    ("Half Fry / Sunny Side Up Egg", ["fried egg", "bullseye egg"], 196, 12.2, 0.8, 15.8, [p("egg", 56)], "1 egg fried on tawa with 3 g oil", "recipe"),
    ("Egg Curry (AndaTari)", ["muttai kulambu", "dimer dalna", "egg masala"], 146, 8.2, 6.4, 9.8, [p("katori", 150), p("bowl", 220)], "Boiled eggs in home onion-tomato masala gravy", "recipe"),
    ("Boiled / Poached Chicken Breast", ["ubla chicken", "steamed gym chicken"], 165, 31.0, 0.0, 3.6, [p("breast", 150), p("katori cubes", 120)], "Skinless chicken breast boiled/poached, cooked weight, no oil", "recipe"),
    ("Grilled / Tandoori Chicken Breast", ["chicken tikka breast", "airfryer chicken"], 178, 29.5, 2.2, 5.4, [p("breast", 150), p("katori cubes", 120)], "Skinless chicken breast marinated in curd-spices with 2 g oil", "recipe"),
    ("Tandoori Chicken (Bone-in Weight, Edible)", ["roasted murgh tandoori"], 195, 25.8, 2.5, 9.0, [p("quarter", 150), p("half bird", 300)], "Edible roasted tandoori chicken meat marinated in curd and spices", "recipe"),
    ("Chicken Tikka (Boneless)", ["murgh tikka", "hariyali chicken tikka"], 186, 26.5, 3.0, 7.4, [p("piece", 30), p("plate", 180)], "Boneless chicken chunks marinated in hung curd, skewered and roasted", "recipe"),
    ("Home-Style Chicken Curry", ["tari wala chicken", "kozhi kulambu", "murgir jhol"], 162, 17.5, 5.2, 7.8, [p("katori", 150), p("bowl", 200)], "Skinless chicken cooked in onion-tomato-ginger gravy with 1 tsp oil/katori", "recipe"),
    ("Kadai / Bhuna Chicken", ["chicken sukha", "pepper chicken dry"], 188, 19.8, 5.8, 9.4, [p("katori", 150), p("bowl", 200)], "Semi-dry chicken tossed with capsicum, onion and roasted spices", "recipe"),
    ("Butter Chicken (Murgh Makhani)", ["chicken makhani"], 228, 15.8, 7.5, 15.0, [p("katori", 150), p("bowl", 200)], "Tandoori chicken in tomato-cashew-butter-cream gravy", "recipe"),
    ("Palak Chicken (Saagwala)", ["spinach chicken"], 158, 18.2, 4.8, 7.2, [p("katori", 150), p("bowl", 200)], "Boneless chicken cooked in spinach puree with 1 tsp oil", "recipe"),
    ("Chicken Keema Matar", ["minced chicken curry"], 176, 19.2, 5.6, 8.4, [p("katori", 150), p("bowl", 220)], "Lean minced chicken cooked with green peas and spices", "recipe"),
    ("Chicken Clear Soup", ["murgh shorba", "chicken broth"], 48, 6.5, 2.2, 1.4, [p("bowl", 220), p("cup", 150)], "Shredded chicken breast in clear ginger-garlic stock, no cream", "recipe"),
    ("Home Fish Curry (Rohu / Surmai)", ["macher jhol", "meen kulambu", "fish curry"], 138, 14.8, 4.2, 6.8, [p("katori", 150), p("bowl", 200)], "Fresh fish simmered in mustard/tamarind-tomato gravy with 1 tsp oil", "recipe"),
    ("Tawa Fish Fry", ["seer fish tawa fry", "paplet fry", "meen varuval"], 198, 21.5, 4.5, 10.4, [p("piece", 80), p("fillet", 110)], "Spice-marinated fish shallow-seared on tawa with 1 tsp oil", "recipe"),
    ("Prawn Masala / Sukka", ["jhinga masala", "chemmeen roast"], 144, 17.6, 5.4, 5.6, [p("katori", 150)], "Prawns cooked with onion, tomato, kokum/tamarind and 1 tsp oil", "recipe"),
    ("Mutton Curry / Rogan Josh", ["gosht ka salan", "kosha mangsho"], 196, 17.8, 4.8, 11.6, [p("katori", 150), p("bowl", 200)], "Bone-out mutton slow-cooked in spiced onion-curd gravy", "recipe"),
    ("Seekh Kebab (Chicken)", ["murgh seekh kabab"], 182, 23.5, 3.8, 8.0, [p("piece", 50), p("plate", 200)], "Minced chicken kebab grilled on skewer", "recipe"),

    # Breakfasts, Tiffins, Snacks, Salads & Drinks (70)
    ("Kanda / Batata Poha", ["poha cooked", "indori poha", "aval upma"], 142, 3.2, 24.5, 3.6, [p("katori", 130), p("plate", 200)], "Flattened rice cooked with onion, peanuts and 1 tsp oil per plate", "recipe"),
    ("Rava Upma", ["suji upma", "uppittu", "khara bath"], 148, 3.8, 22.8, 4.6, [p("katori", 150), p("plate", 200)], "Roasted suji cooked with veggies, mustard and 1 tsp oil/ghee per katori", "recipe"),
    ("Semiya / Vermicelli Upma", ["namkeen seviyan", "semiya pulao"], 152, 4.4, 24.8, 4.0, [p("katori", 150), p("plate", 200)], "Wheat vermicelli cooked with vegetables and 1 tsp oil", "recipe"),
    ("Cooked Porridge Oats (with Milk)", ["milk oatmeal", "doodh wale oats"], 98, 4.4, 14.8, 2.4, [p("bowl", 250), p("katori", 150)], "40 g rolled oats cooked in 150 ml toned milk + water, no sugar", "recipe"),
    ("Masala Vegetable Oats (Cooked)", ["savoury oats", "namkeen oats"], 76, 2.8, 11.8, 2.0, [p("bowl", 250), p("katori", 150)], "40 g oats cooked in water with vegetables and 0.5 tsp oil", "recipe"),
    ("Namkeen Vegetable Daliya", ["broken wheat upma", "lapsi khichdi"], 114, 3.8, 18.8, 2.6, [p("bowl", 220), p("katori", 150)], "Cracked wheat pressure-cooked with veggies and 0.7 tsp ghee", "recipe"),
    ("Meetha Daliya (Milk Broken Wheat)", ["sweet dalia porridge"], 118, 4.2, 19.5, 2.6, [p("bowl", 220), p("katori", 150)], "Broken wheat cooked in toned milk with 1 tsp jaggery", "recipe"),
    ("Steamed Rice Idli", ["idli", "idly"], 146, 4.4, 30.2, 0.6, [p("idli", 45), p("plate", 135)], "Fermented rice-urad batter steamed in moulds, no oil", "recipe"),
    ("Rava Idli", ["semolina idli", "mtr rava idli"], 178, 4.8, 28.5, 5.0, [p("idli", 55)], "Suji-curd batter tempered with mustard, cashew and ghee, steamed", "recipe"),
    ("Ragi Idli", ["finger millet idli"], 142, 4.6, 28.8, 0.8, [p("idli", 45)], "Fermented ragi-urad batter steamed, no oil", "recipe"),
    ("Plain Roast Dosa", ["sada dosa", "dosai"], 198, 4.8, 34.5, 4.6, [p("dosa", 80)], "Fermented rice-urad crepe cooked on tawa with 3.5 g (0.8 tsp) oil", "recipe"),
    ("Masala Dosa", ["potato dosa", "mysore masala dosa"], 214, 4.6, 33.8, 6.8, [p("dosa", 150)], "Crisp dosa filled with 65 g potato bhaji, cooked with 1.5 tsp oil", "recipe"),
    ("Rava Dosa", ["crispy suji dosa"], 226, 4.5, 34.0, 8.0, [p("dosa", 100)], "Lacy suji-rice crepe cooked with 1.5 tsp oil", "recipe"),
    ("Ragi Dosa", ["nachni dosa", "finger millet crepe"], 182, 4.8, 32.0, 3.8, [p("dosa", 80)], "Ragi flour crepe cooked on tawa with 3 g oil", "recipe"),
    ("Pesarattu (Green Moong Dosa)", ["moong dal dosa", "pesarattu"], 188, 9.2, 27.5, 4.6, [p("dosa", 90)], "Ground whole green moong crepe cooked with 4 g oil", "recipe"),
    ("Adai (Mixed Lentil Dosa)", ["paruppu adai"], 204, 8.8, 30.2, 5.2, [p("dosa", 95)], "Rice and four-lentil protein crepe cooked with 1 tsp oil", "recipe"),
    ("Onion Tomato Uttapam", ["uthappam", "ooththappam"], 176, 4.6, 30.0, 4.2, [p("piece", 110)], "Thick dosa batter topped with onion, tomato and 4 g oil", "recipe"),
    ("Appam / Paniyaram", ["palappam", "kuzhi paniyaram", "paddu", "appe"], 172, 4.2, 31.0, 3.6, [p("piece", 35), p("plate", 140)], "Fermented rice batter cooked with minimal oil", "recipe"),
    ("Medu Vada", ["ulundu vadai", "urad dal vada"], 288, 9.8, 31.5, 13.6, [p("vada", 50)], "Ground urad batter deep-fried", "recipe"),
    ("Besan Chilla", ["besan cheela", "gram flour pancake", "pudla"], 196, 10.2, 24.5, 6.4, [p("chilla", 75)], "38 g besan + onion/tomato cooked on tawa with 3.5 g oil", "recipe"),
    ("Moong Dal Chilla", ["moonglet", "yellow moong pancake"], 184, 10.6, 24.2, 5.0, [p("chilla", 80)], "Ground soaked moong dal batter cooked with 3.5 g oil", "recipe"),
    ("Paneer Stuffed Moong Chilla", ["high protein chilla"], 204, 12.8, 19.5, 8.2, [p("chilla", 120)], "Moong dal chilla stuffed with 35 g grated paneer", "recipe"),
    ("Oats Besan Chilla", ["oats cheela"], 188, 8.6, 25.8, 5.6, [p("chilla", 80)], "Ground oats and besan pancake cooked with 3.5 g oil", "recipe"),
    ("Coconut Chutney", ["nariyal chutney", "thengai chutney"], 218, 2.8, 8.5, 19.4, [p("tbsp", 20), p("small katori", 50)], "Fresh coconut ground with roasted chana and mustard tadka", "recipe"),
    ("Green Mint Coriander Chutney", ["hari chutney", "pudina dhaniya chutney"], 42, 2.2, 6.8, 0.6, [p("tbsp", 15), p("small katori", 40)], "Fresh coriander, mint, green chilli and lemon, no oil", "recipe"),
    ("Peanut Chutney", ["groundnut chutney", "palli chutney"], 248, 9.8, 10.4, 18.8, [p("tbsp", 20), p("small katori", 50)], "Roasted peanuts ground with garlic, tamarind and light tadka", "recipe"),
    ("Tomato Onion Kara Chutney", ["red dosa chutney"], 96, 1.8, 10.6, 5.2, [p("tbsp", 20), p("small katori", 50)], "Sauteed onion, tomato and red chillies ground with 0.5 tsp oil", "recipe"),
    ("Khaman Dhokla", ["besan dhokla", "steamed khaman"], 162, 6.8, 24.8, 4.0, [p("piece", 35), p("plate", 140)], "Steamed fermented besan sponge with light mustard-sesame tadka", "recipe"),
    ("Khandvi", ["patuli", "gujarati khandvi"], 144, 6.2, 16.8, 5.8, [p("plate", 120)], "Rolled besan-buttermilk sheets tempered with sesame and coconut", "recipe"),
    ("Sprouts Chaat / Bhel", ["moong sprouts salad", "ankurit chaat"], 74, 5.2, 12.2, 0.6, [p("bowl", 150), p("katori", 100)], "Steamed moong sprouts tossed with onion, tomato, cucumber and lemon, no oil", "recipe"),
    ("Kala Chana Chaat", ["boiled chana salad", "protein chana chaat"], 136, 7.2, 22.4, 2.0, [p("bowl", 160), p("katori", 110)], "Boiled kala chana with chopped onion, tomato, cucumber and lemon, no oil", "recipe"),
    ("Peanut Masala / Boiled Peanut Chaat", ["singdana chaat", "masala kadalai"], 234, 10.8, 14.5, 14.8, [p("katori", 100)], "Boiled peanuts tossed with onion, tomato, coriander and lemon", "recipe"),
    ("Paneer Salad Bowl", ["grilled paneer salad"], 138, 9.4, 6.2, 8.4, [p("bowl", 200)], "80 g paneer cubes tossed with 120 g cucumber, tomato, bell pepper and lemon", "recipe"),
    ("Chicken Salad Bowl", ["boiled chicken salad", "gym chicken bowl"], 108, 15.8, 4.6, 2.8, [p("bowl", 220)], "110 g boiled/grilled chicken breast with 110 g fresh salad veggies", "recipe"),
    ("Kachumber / Green Salad", ["kheera tamatar pyaz salad", "indian green salad"], 24, 0.9, 5.0, 0.2, [p("plate", 150), p("katori", 100)], "Sliced cucumber, tomato, onion, carrot and lemon, no dressing", "recipe"),
    ("Cucumber Tomato Raita", ["veg raita", "curd pachadi", "koshimbir"], 58, 3.1, 5.2, 2.7, [p("katori", 150), p("small katori", 100)], "Home curd whisked with grated cucumber, tomato and roasted jeera, no oil", "recipe"),
    ("Boondi Raita", ["bundi raita"], 98, 3.6, 9.4, 5.2, [p("katori", 150), p("small katori", 100)], "Curd mixed with soaked besan boondi and roasted cumin", "recipe"),
    ("Roasted Makhana (Light Ghee)", ["ghee roasted foxnuts"], 396, 8.8, 69.5, 9.5, [p("katori", 25), p("bowl", 40)], "Popped makhana roasted in 0.5 tsp ghee per katori", "recipe"),
    ("Bhel Puri", ["sukha bhel", "jhalmuri"], 218, 5.4, 36.8, 5.6, [p("plate", 120), p("katori", 70)], "Puffed rice, sev, onion, potato, tomato and chutneys", "recipe"),
    ("Pani Puri / Golgappa", ["puchka", "gol gappe", "pakodi"], 186, 4.2, 31.5, 4.8, [p("piece", 20), p("plate", 120)], "Crisp puris filled with potato-chana mash and spiced water", "recipe"),
    ("Samosa (Aloo)", ["punjabi samosa", "singara"], 298, 5.2, 35.8, 14.8, [p("piece", 80), p("small", 50)], "Deep-fried maida pastry stuffed with spiced potato and peas", "recipe"),
    ("Onion / Palak Pakora (Bhajiya)", ["kanda bhaji", "pyaz pakoda", "bajji"], 312, 7.6, 33.5, 16.4, [p("piece", 20), p("plate", 100)], "Onion/spinach coated in besan batter and deep-fried", "recipe"),
    ("Bread Pakora", ["stuffed bread pakoda"], 286, 6.8, 34.2, 13.6, [p("piece", 95)], "Bread triangle dipped in besan batter and deep-fried", "recipe"),
    ("Sabudana Vada", ["sago vada"], 292, 4.4, 39.5, 13.0, [p("vada", 55)], "Sabudana, potato and peanut patty fried crisp", "recipe"),
    ("Vada Pav", ["mumbai wada pav"], 264, 6.2, 38.5, 9.4, [p("piece", 115)], "1 ladi pav + 1 batata vada + dry garlic chutney", "recipe"),
    ("Pav Bhaji", ["butter pav bhaji"], 194, 5.2, 27.6, 7.0, [p("plate", 280), p("katori", 150)], "Mashed vegetable bhaji with 2 buttered ladi pavs", "recipe"),
    ("Misal Pav", ["puneri misal", "kolhapuri misal"], 188, 6.4, 26.8, 6.2, [p("plate", 300)], "Sprouted matki usal with farsan and 2 ladi pavs", "recipe"),
    ("Aloo Tikki", ["potato cutlet", "ragda pattice patty"], 234, 4.0, 32.8, 9.6, [p("piece", 60)], "Shallow-fried spiced mashed potato patty", "recipe"),
    ("Veg Grilled Sandwich", ["cucumber tomato sandwich", "bombay sandwich"], 212, 6.4, 32.5, 6.2, [p("sandwich", 150)], "2 whole wheat bread slices, veggies, green chutney and 4 g butter", "recipe"),
    ("Paneer Tikka / Bhurji Sandwich", ["high protein veg sandwich"], 244, 11.4, 28.0, 9.6, [p("sandwich", 160)], "2 brown bread slices stuffed with 60 g spiced paneer", "recipe"),
    ("Boiled Egg / Omelette Bread Toast", ["bread omelette", "anda bread"], 232, 11.2, 24.5, 9.8, [p("serving", 170)], "2 bread slices toasted with 2-egg omelette and 1 tsp oil", "recipe"),
    ("Peanut Butter Banana Toast", ["pb toast"], 268, 8.6, 36.4, 10.2, [p("slice", 95)], "Whole wheat toast + 1 tbsp peanut butter + half sliced banana", "recipe"),
    ("Cooked Masala Maggi (with Veggies)", ["prepared maggi", "hostel maggi"], 148, 3.6, 21.8, 5.2, [p("bowl", 250)], "1 pack (70 g) instant noodles boiled in water with onion, peas and tastemaker", "recipe"),
    ("Egg Maggi (Cooked)", ["anda maggi"], 158, 6.4, 18.2, 6.6, [p("bowl", 300)], "1 pack Maggi cooked with 1 whole egg", "recipe"),
    ("Masala Chai (Home Milk Tea, 1 tsp Sugar)", ["adrak chai", "elaichi chai", "indian tea"], 54, 1.8, 7.2, 2.0, [p("cup", 150), p("cutting glass", 100), p("mug", 220)], "75 ml toned milk + 75 ml water + tea leaves + 1 tsp (4 g) sugar per 150 ml cup", "recipe"),
    ("Masala Chai (Unsweetened / No Sugar)", ["pheeki chai", "sugarfree chai"], 34, 1.8, 2.6, 1.9, [p("cup", 150), p("mug", 220)], "50:50 toned milk and water brewed with ginger/cardamom, no sugar", "recipe"),
    ("South Indian Filter Coffee (with Sugar)", ["kaapi", "milk coffee"], 62, 2.1, 8.0, 2.4, [p("cup", 150), p("tumbler", 120)], "100 ml toned milk + decoction + 1 tsp sugar", "recipe"),
    ("Black Coffee / Green Tea (Unsweetened)", ["americano", "kali coffee", "green tea"], 2, 0.2, 0.3, 0.0, [p("cup", 150), p("mug", 240)], "Brewed coffee or green tea in water, no milk or sugar", "recipe"),
    ("Cold Coffee (Home Blended)", ["iced milk coffee"], 78, 2.8, 11.4, 2.4, [p("glass", 250)], "Toned milk blended with coffee and 1.5 tsp sugar, no ice cream", "recipe"),
    ("Nimbu Pani (Salted / No Sugar)", ["shikanji namkeen", "fresh lime water"], 8, 0.2, 2.0, 0.0, [p("glass", 250)], "1 lemon squeezed in water with black salt and roasted jeera, no sugar", "recipe"),
    ("Sweet Nimbu Pani (1.5 tsp Sugar)", ["meethi shikanji", "lemonade"], 34, 0.2, 8.6, 0.0, [p("glass", 250)], "Fresh lemon water with 6 g sugar", "recipe"),
    ("Sweet Lassi", ["punjabi lassi"], 92, 3.2, 13.8, 2.7, [p("glass", 250)], "Home curd blended with water and 2 tsp sugar", "recipe"),
    ("Sattu Drink (Namkeen Sattu Sharbat)", ["bihari sattu cooler", "protein sattu drink"], 68, 3.8, 11.2, 0.9, [p("glass", 250)], "30 g roasted chana sattu mixed in water with lemon, jeera and salt", "recipe"),
    ("Banana Milkshake (No Added Sugar)", ["kela shake"], 82, 3.0, 14.2, 1.6, [p("glass", 250)], "1 medium banana blended with 150 ml toned milk, no sugar", "recipe"),
    ("Whey Banana Oats Smoothie", ["gym bulking shake", "post workout smoothie"], 124, 9.8, 15.6, 2.4, [p("shaker", 350)], "1 scoop whey + 1 banana + 30 g oats + 200 ml toned milk", "recipe"),
    ("Rice Kheer / Payasam", ["chawal ki kheer", "pal payasam"], 142, 4.0, 21.8, 4.4, [p("katori", 150), p("small katori", 100)], "Milk simmered with rice, cardamom, nuts and sugar", "recipe"),
    ("Suji ka Halwa", ["sheera", "rava kesari"], 268, 4.2, 38.5, 10.8, [p("small katori", 80), p("katori", 130)], "Roasted suji cooked with water/milk, sugar and ghee", "recipe"),
    ("Gajar ka Halwa", ["carrot halwa"], 216, 4.4, 29.8, 8.8, [p("small katori", 90), p("katori", 140)], "Grated carrots slow-cooked in milk, khoya, sugar and ghee", "recipe"),
    ("Gulab Jamun", ["kala jamun"], 318, 4.8, 52.0, 10.2, [p("piece", 45)], "Khoya dumpling fried and soaked in sugar syrup", "recipe"),
    ("Besan Ladoo", ["besan ke laddu", "boondi ladoo", "motichoor ladoo"], 462, 9.2, 54.0, 23.4, [p("ladoo", 35)], "Roasted besan, ghee and sugar shaped into ladoo", "recipe"),
]


PACKAGED_STAPLES: list[tuple] = [
    # Dairy & High-Protein Packaged (24)
    ("Amul Taaza Toned Milk", ["amul toned doodh", "tetrapak milk"], 58, 3.0, 4.7, 3.0, LIQUID, "Amul Taaza nutrition label per 100 ml", "label"),
    ("Amul Gold Full Cream Milk", ["amul gold doodh"], 87, 3.1, 4.7, 6.0, LIQUID, "Amul Gold nutrition label per 100 ml", "label"),
    ("Amul Slim 'n' Trim Skimmed Milk", ["amul slim milk", "zero fat milk"], 35, 3.5, 5.0, 0.1, LIQUID, "Amul Slim n Trim nutrition label per 100 ml", "label"),
    ("Amul Cow Milk", ["amul gai doodh"], 63, 3.2, 4.7, 3.5, LIQUID, "Amul Cow Milk nutrition label per 100 ml", "label"),
    ("Amul Masti Dahi (Cup / Pouch)", ["amul curd", "packaged dahi"], 63, 3.7, 4.4, 3.1, [p("katori", 150), p("cup", 200), p("small cup", 85)], "Amul Masti Dahi nutrition label per 100 g", "label"),
    ("Amul Fresh Malai Paneer", ["amul paneer cube"], 296, 20.0, 4.5, 22.0, [p("katori cubes", 100), p("pack", 200), p("slice", 50), p("cube", 15)], "Amul Malai Paneer nutrition label per 100 g", "label"),
    ("Amul High Protein Paneer", ["amul protein paneer"], 185, 25.0, 4.5, 7.5, [p("katori cubes", 100), p("pack", 200), p("slice", 50)], "Amul High Protein Paneer nutrition label per 100 g", "label"),
    ("Amul High Protein Buttermilk", ["amul protein chaas", "15g protein buttermilk"], 54, 7.5, 3.8, 0.9, [p("tetrapak", 200)], "Amul High Protein Buttermilk label (15 g protein per 200 ml pack)", "label"),
    ("Amul High Protein Rose Lassi", ["amul protein lassi", "15g protein lassi"], 74, 7.5, 9.2, 0.8, [p("tetrapak", 200)], "Amul High Protein Lassi label (15 g protein per 200 ml pack)", "label"),
    ("Amul High Protein Milkshake / Blueberry Shake", ["amul 20g protein shake"], 82, 10.0, 8.5, 0.9, [p("pack", 200)], "Amul High Protein Shake label per 100 ml", "label"),
    ("Amul Cheese Slice", ["processed cheese slice"], 312, 20.0, 1.5, 25.0, [p("slice", 20)], "Amul Cheese Slice nutrition label per 100 g", "label"),
    ("Amul Cheese Cube", ["cheese chota cube"], 316, 20.0, 1.5, 25.5, [p("cube", 25)], "Amul Processed Cheese Cube label per 100 g", "label"),
    ("Amul Salted Butter", ["makhan", "table butter"], 722, 0.6, 0.0, 80.0, [p("chiplet", 10), p("tsp", 5), p("tbsp", 14)], "Amul Pasteurised Butter nutrition label per 100 g", "label"),
    ("Mother Dairy Toned Milk", ["mother dairy doodh"], 58, 3.0, 4.7, 3.0, LIQUID, "Mother Dairy Toned Milk nutrition label per 100 ml", "label"),
    ("Mother Dairy Classic Dahi", ["mother dairy curd"], 62, 3.6, 4.6, 3.1, [p("katori", 150), p("cup", 200)], "Mother Dairy Classic Curd nutrition label per 100 g", "label"),
    ("Epigamia Natural Greek Yogurt", ["epigamia greek curd", "unsweetened greek yogurt"], 78, 8.3, 4.8, 2.8, [p("cup", 90)], "Epigamia Natural Greek Yogurt nutrition label per 100 g", "label"),
    ("Epigamia Turbo High Protein Yogurt", ["epigamia turbo"], 72, 11.0, 5.0, 0.8, [p("cup", 140)], "Epigamia Turbo Protein Yogurt nutrition label per 100 g", "label"),
    ("Epigamia Everyday Milkshake (25g Protein)", ["epigamia protein shake"], 76, 10.0, 6.8, 1.0, [p("bottle", 250)], "Epigamia Protein Milkshake nutrition label per 100 ml", "label"),
    ("Milky Mist Skyr (High Protein)", ["skyr yogurt", "milky mist protein"], 68, 11.2, 4.5, 0.5, [p("cup", 100), p("tub", 225)], "Milky Mist Skyr nutrition label per 100 g", "label"),
    ("Milky Mist Natural Greek Yogurt", ["milky mist greek curd"], 84, 7.5, 5.2, 3.6, [p("cup", 100)], "Milky Mist Greek Yogurt nutrition label per 100 g", "label"),
    ("Milky Mist Fresh Paneer", ["milky mist malai paneer"], 289, 19.5, 4.0, 21.5, [p("katori cubes", 100), p("pack", 200)], "Milky Mist Paneer nutrition label per 100 g", "label"),
    ("Nestlé a+ Nourish Toned Milk", ["nestle slim milk"], 59, 3.1, 4.8, 3.0, LIQUID, "Nestlé a+ Toned Milk nutrition label per 100 ml", "label"),
    ("Britannia Winkin' Cow Cheese Spread", ["cheese spread"], 248, 12.5, 3.5, 20.0, [p("tbsp", 15), p("tsp", 5)], "Cheese spread nutrition label per 100 g", "label"),
    ("Briyas / Morinaga Firm Soya Tofu", ["packaged soya tofu"], 132, 14.5, 3.2, 6.8, [p("katori cubes", 100), p("pack", 200)], "Packaged soya tofu nutrition label per 100 g", "label"),

    # Whey, Plant Protein & Soya Chunks (12)
    ("Whey Protein Concentrate (80%, Standard)", ["whey scoop", "protein powder", "wpc"], 392, 76.0, 9.5, 5.5, [p("scoop", 33)], "Standard whey concentrate label (~25 g protein per 33 g scoop)", "label"),
    ("Whey Protein Isolate (90%)", ["iso whey", "wpi", "zero carb whey"], 372, 86.0, 2.5, 1.5, [p("scoop", 30)], "Standard whey isolate label (~26 g protein per 30 g scoop)", "label"),
    ("Unflavoured Raw Whey Concentrate", ["raw whey", "asitis whey"], 400, 80.0, 6.5, 6.0, [p("scoop", 30)], "Unflavoured 80% WPC nutrition label per 100 g", "label"),
    ("MuscleBlaze Biozyme Performance Whey", ["mb whey", "muscleblaze scoop"], 386, 69.5, 13.0, 6.2, [p("scoop", 36)], "MuscleBlaze Biozyme Whey label (25 g protein per 36 g scoop)", "label"),
    ("Optimum Nutrition (ON) Gold Standard Whey", ["on whey", "gold standard scoop"], 387, 77.4, 9.7, 4.8, [p("scoop", 31)], "ON Gold Standard 100% Whey label (24 g protein per 31 g scoop)", "label"),
    ("Avvatar Whey Protein", ["avvatar scoop"], 388, 76.5, 9.0, 5.2, [p("scoop", 35)], "Avvatar Whey Protein nutrition label per 100 g", "label"),
    ("Nakpro Perform Whey Concentrate", ["nakpro whey"], 390, 72.7, 11.0, 6.0, [p("scoop", 33)], "Nakpro Perform Whey label (24 g protein per 33 g scoop)", "label"),
    ("Plant Protein Powder (Pea + Brown Rice)", ["vegan protein scoop", "oziva plant protein", "cosmix"], 382, 74.0, 10.5, 4.8, [p("scoop", 34)], "Pea-rice plant protein blend label (~25 g protein per 34 g scoop)", "label"),
    ("Nutrela Soya Chunks (Dry Weight)", ["soya badi dry", "fortune soya chunks", "saffola soya"], 345, 52.0, 33.0, 0.5, [p("katori dry", 50), p("small katori dry", 30)], "Nutrela Soya Chunks label per 100 g dry weight (26 g protein in 50 g)", "label"),
    ("Nutrela Soya Granules / Mini Chunks (Dry)", ["soya keema dry", "mini soya wadi"], 345, 52.0, 33.0, 0.5, [p("katori dry", 50), p("small katori dry", 30)], "Defatted soya granules nutrition label per 100 g dry", "label"),
    ("Creatine Monohydrate", ["creatine scoop"], 0, 0.0, 0.0, 0.0, [p("scoop", 3), p("tsp", 5)], "Pure micronised creatine monohydrate, 0 kcal", "label"),
    ("Skimmed Milk Powder (Everyday / Amul Sagar)", ["milk powder", "dairy whitener"], 358, 35.0, 52.0, 1.0, [p("tbsp", 10)], "Skimmed milk powder nutrition label per 100 g", "label"),

    # Nut Butters, Oats, Muesli, Breads, Bars & Everyday Packaged (44)
    ("Pintola All Natural Unsweetened Peanut Butter", ["natural peanut butter", "unsweetened pb"], 612, 30.0, 18.0, 49.0, [p("tbsp", 16), p("tsp", 5)], "100% roasted peanuts label (9.6 g protein per 32 g serving)", "label"),
    ("Pintola High Protein Peanut Butter (Dark Choc)", ["whey peanut butter", "protein pb"], 568, 37.0, 24.0, 38.0, [p("tbsp", 16), p("tsp", 5)], "Pintola High Protein PB nutrition label per 100 g", "label"),
    ("Classic Sweetened Peanut Butter (Sundrop / MyFitness)", ["creamy peanut butter", "crunchy pb"], 604, 25.0, 22.0, 48.0, [p("tbsp", 16), p("tsp", 5)], "Classic peanut butter nutrition label per 100 g", "label"),
    ("Almond Butter (Unsweetened)", ["badam butter"], 614, 21.0, 19.0, 55.0, [p("tbsp", 16)], "100% roasted almond butter label per 100 g", "label"),
    ("Quaker Oats (Dry)", ["quaker white oats"], 404, 11.8, 68.5, 9.2, [p("katori", 40), p("cup", 80), p("tbsp", 10)], "Quaker Oats India nutrition label per 100 g", "label"),
    ("Saffola Oats (Plain, Dry)", ["saffola plain oats"], 398, 12.2, 69.0, 8.6, [p("katori", 40), p("cup", 80)], "Saffola Plain Oats nutrition label per 100 g", "label"),
    ("Saffola Masala Oats Classic (Dry Mix)", ["masala oats packet"], 378, 10.2, 66.5, 8.0, [p("single pack", 38)], "Saffola Classic Masala Oats dry mix label per 100 g", "label"),
    ("Yoga Bar No Added Sugar Muesli", ["high protein muesli", "yogabar muesli"], 418, 14.5, 62.0, 12.2, [p("bowl serving", 50), p("katori", 40)], "No-added-sugar nuts & seeds muesli label per 100 g", "label"),
    ("Bagrry's Crunchy Muesli", ["fruit and nut muesli"], 412, 9.2, 72.5, 9.5, [p("serving", 40)], "Crunchy muesli nutrition label per 100 g", "label"),
    ("Kellogg's Corn Flakes (Original)", ["makai flakes", "cornflakes"], 376, 7.6, 84.0, 0.8, [p("bowl dry", 30)], "Kellogg's Corn Flakes India label per 100 g", "label"),
    ("Kellogg's Chocos", ["chocos"], 388, 8.5, 79.0, 3.8, [p("bowl dry", 30)], "Kellogg's Chocos nutrition label per 100 g", "label"),
    ("The Whole Truth 20g Protein Bar", ["twt protein bar"], 392, 30.0, 38.0, 14.0, [p("bar", 67)], "20 g protein bar nutrition label (~263 kcal per 67 g bar)", "label"),
    ("Yoga Bar 20g Protein Bar", ["yogabar 20g"], 384, 28.6, 40.0, 13.5, [p("bar", 70)], "Yoga Bar 20 g Protein Bar nutrition label per 100 g", "label"),
    ("Yoga Bar 10g Breakfast Protein Bar", ["yogabar 10g"], 408, 20.0, 48.0, 15.0, [p("bar", 50)], "Yoga Bar 10 g Protein Bar nutrition label per 100 g", "label"),
    ("RiteBite Max Protein Daily 10g Bar", ["max protein bar 10g"], 396, 20.0, 49.0, 13.5, [p("bar", 50)], "Max Protein Daily 10 g Bar label per 100 g", "label"),
    ("RiteBite Max Protein Ultimate 20g Bar", ["max protein 20g"], 388, 28.5, 41.0, 13.0, [p("bar", 70)], "Max Protein 20 g Bar label per 100 g", "label"),
    ("RiteBite Max Protein Chips", ["protein nachos", "protein chips"], 426, 18.0, 56.0, 14.5, [p("pack", 55)], "Max Protein Multigrain Chips label per 100 g", "label"),
    ("Britannia 100% Whole Wheat Bread", ["atta bread", "whole wheat slice"], 252, 8.8, 48.5, 2.4, [p("slice", 28)], "100% whole wheat bread label per 100 g", "label"),
    ("Brown Bread (Britannia / Harvest Gold)", ["brown bread slice"], 258, 8.2, 50.6, 2.2, [p("slice", 28)], "Indian brown bread nutrition label per 100 g", "label"),
    ("Multigrain Bread (English Oven / The Health Factory)", ["seed bread", "high protein bread"], 266, 10.5, 46.0, 4.2, [p("slice", 30)], "Multigrain seeded bread nutrition label per 100 g", "label"),
    ("White Sandwich Bread (Modern / Britannia)", ["maida bread", "white bread slice"], 268, 7.6, 54.0, 2.2, [p("slice", 25)], "White sandwich bread nutrition label per 100 g", "label"),
    ("Ladi Pav / Burger Bun", ["pav bread", "bun"], 276, 8.0, 54.5, 2.8, [p("pav", 38)], "Bakery ladi pav nutrition label per 100 g", "label"),
    ("Dry Roasted Papad (Lijjat Urad Papad)", ["roasted papad", "appalam"], 328, 21.0, 56.0, 1.8, [p("papad", 12)], "Dry flame-roasted urad papad label, no oil", "label"),
    ("Fried Papad", ["tala papad"], 468, 16.5, 44.0, 25.0, [p("papad", 16)], "Deep-fried urad papad", "label"),
    ("Maggi 2-Minute Masala Noodles (Dry Pack)", ["maggi dry cake"], 427, 8.2, 63.5, 15.7, [p("pack", 70)], "Maggi 2-Minute Noodles dry nutrition label per 100 g", "label"),
    ("Sunfeast Yippee Noodles (Dry Pack)", ["yippee noodles"], 442, 8.5, 64.0, 16.8, [p("pack", 65)], "Yippee Noodles dry nutrition label per 100 g", "label"),
    ("Parle-G Glucose Biscuit", ["parle g", "chai biscuit"], 452, 6.7, 78.2, 12.6, [p("biscuit", 5.5), p("small pack", 55)], "Parle-G nutrition label per 100 g", "label"),
    ("Britannia Marie Gold Biscuit", ["marie biscuit", "tea biscuit"], 438, 7.8, 77.5, 10.8, [p("biscuit", 5)], "Britannia Marie Gold nutrition label per 100 g", "label"),
    ("Britannia NutriChoice Digestive Biscuit", ["digestive biscuit", "oats biscuit"], 482, 7.6, 66.0, 20.5, [p("biscuit", 10)], "NutriChoice Digestive nutrition label per 100 g", "label"),
    ("Britannia Good Day Cashew Cookie", ["good day biscuit", "butter cookie"], 502, 6.8, 66.5, 23.0, [p("cookie", 9)], "Good Day Cashew Cookie label per 100 g", "label"),
    ("Monaco / Krackjack Salted Biscuit", ["namkeen biscuit"], 486, 7.5, 67.0, 20.8, [p("biscuit", 4)], "Salted cracker biscuit label per 100 g", "label"),
    ("Rusk / Toast Biscuit (Suji Rusk)", ["chai rusk", "milk rusk"], 428, 9.2, 73.5, 10.8, [p("rusk", 12)], "Bakery suji rusk nutrition label per 100 g", "label"),
    ("Haldiram's Aloo Bhujia / Bhujia Sev", ["bhujia", "bikaneri bhujia", "namkeen"], 568, 12.8, 42.0, 39.0, [p("handful", 25), p("small katori", 35), p("katori", 65), p("tbsp", 10)], "Haldiram's Bhujia nutrition label per 100 g", "label"),
    ("Haldiram's Moong Dal Namkeen", ["fried salted moong dal"], 472, 21.5, 49.0, 21.0, [p("handful", 25), p("small katori", 35), p("katori", 65)], "Haldiram's Salted Moong Dal label per 100 g", "label"),
    ("Lay's Classic Potato Chips", ["potato wafers", "lays packet"], 536, 6.5, 52.8, 33.5, [p("small pack", 25), p("medium pack", 50), p("handful", 15)], "Potato chips nutrition label per 100 g", "label"),
    ("Kurkure Masala Munch", ["kurkure"], 548, 6.0, 55.0, 34.0, [p("small pack", 30), p("medium pack", 55), p("handful", 20)], "Corn puff snack nutrition label per 100 g", "label"),
    ("Dark Chocolate (70% Cocoa, Amul Dark)", ["amul dark chocolate", "bitter chocolate"], 546, 7.8, 46.0, 37.0, [p("square", 8), p("bar", 40)], "70% dark chocolate label per 100 g", "label"),
    ("Dairy Milk Chocolate (Cadbury)", ["milk chocolate"], 532, 7.5, 57.5, 29.5, [p("small bar", 13), p("bar", 40), p("square", 5)], "Cadbury Dairy Milk nutrition label per 100 g", "label"),
    ("Tomato Ketchup (Kissan / Maggi)", ["tomato sauce"], 118, 1.2, 28.0, 0.2, [p("sachet", 8), p("tbsp", 15)], "Tomato ketchup nutrition label per 100 g", "label"),
    ("Mixed Fruit Jam (Kissan)", ["bread jam"], 276, 0.3, 68.5, 0.1, [p("tsp", 7), p("tbsp", 20)], "Mixed fruit jam nutrition label per 100 g", "label"),
    ("Indian Pickle (Mango / Mixed Achar)", ["aam ka achar", "mango pickle", "oorugai"], 238, 2.2, 14.5, 19.2, [p("tsp", 6), p("tbsp", 15)], "Oil-cured Indian mango pickle label per 100 g", "label"),
    ("Tender Coconut Water (Natural / Packaged)", ["nariyal pani", "elaneer"], 19, 0.7, 3.7, 0.2, [p("coconut", 200), p("glass", 200)], "Pure tender coconut water per 100 ml", "label"),
    ("Bournvita / Horlicks Powder", ["health drink mix"], 384, 7.5, 84.0, 2.0, [p("tbsp", 10), p("tsp", 5)], "Malted drink mix dry powder label per 100 g", "label"),
    ("Mayonnaise (Eggless Veg Mayo)", ["veg mayo"], 388, 0.8, 12.5, 37.5, [p("tsp", 5), p("tbsp", 15)], "Eggless mayonnaise nutrition label per 100 g", "label"),
]


# Changes to seeded foods since the seed, oldest first: the seq of the food
# in the seed, the fields that changed, and the seq the server gave the row.
LATER_FIXES: list[dict[str, object]] = [
    # 20261126094131_fix_food_229_name.sql: the name started with a space.
    {"seed_seq": 229, "name": "Bharwa Baingan / Mirchi ka Salan", "seq": 407},
]


def main() -> None:
    all_rows = RAW_STAPLES + COOKED_DISHES + PACKAGED_STAPLES
    print(
        f"Counts -> raw: {len(RAW_STAPLES)}, cooked: {len(COOKED_DISHES)}, "
        f"packaged: {len(PACKAGED_STAPLES)}, total: {len(all_rows)}"
    )
    assert len(RAW_STAPLES) >= 100, f"Expected >=100 raw, got {len(RAW_STAPLES)}"
    assert len(COOKED_DISHES) >= 150, f"Expected >=150 cooked, got {len(COOKED_DISHES)}"
    assert len(PACKAGED_STAPLES) >= 50, f"Expected >=50 packaged, got {len(PACKAGED_STAPLES)}"
    assert len(all_rows) >= 300, f"Expected >=300 total, got {len(all_rows)}"

    seen_names: set[str] = set()
    catalogue: list[dict[str, object]] = []
    for idx, row in enumerate(all_rows, start=1):
        name, aliases, kcal, pro, carb, fat, portions, assumption, source = row
        assert name not in seen_names, f"Duplicate food name: {name}"
        seen_names.add(name)
        assert 1 <= len(name) <= 200
        assert len(aliases) <= 20
        assert 0 <= kcal <= 900, f"kcal out of range for {name}: {kcal}"
        assert 0 <= pro <= 100 and 0 <= carb <= 100 and 0 <= fat <= 100
        assert round(pro + carb + fat, 1) <= 100.0, (
            f"Macros > 100g for {name}: {pro + carb + fat}"
        )
        assert 0 <= len(assumption) <= 300
        assert source in ("usda_fdc", "recipe", "label")

        food_id = f"019a9000-0000-7000-8000-{idx:012x}"
        catalogue.append(
            {
                "id": food_id,
                "name": name,
                "aliases": aliases,
                "kcal_per_100g": round(float(kcal), 1),
                "protein_g_per_100g": round(float(pro), 1),
                "carbs_g_per_100g": round(float(carb), 1),
                "fat_g_per_100g": round(float(fat), 1),
                "portions": portions,
                "assumption": assumption,
                "source": source,
                "seq": idx,
            }
        )

    for fix in LATER_FIXES:
        row = catalogue[int(fix["seed_seq"]) - 1]
        assert row["seq"] == fix["seed_seq"]
        row.update({k: v for k, v in fix.items() if k != "seed_seq"})

    JSON_OUT.parent.mkdir(parents=True, exist_ok=True)
    JSON_OUT.write_text(
        json.dumps(catalogue, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    print(f"Wrote {JSON_OUT.stat().st_size} bytes to {JSON_OUT}")


if __name__ == "__main__":
    main()
