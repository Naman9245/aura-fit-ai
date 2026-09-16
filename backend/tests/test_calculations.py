import pytest

from app.utils.calculations import calculate_bmi, calculate_bmr, calculate_metrics


def test_bmi_is_weight_over_height_squared():
    assert calculate_bmi(70, 175) == 22.86


@pytest.mark.parametrize(
    "gender,expected",
    [("male", 1673.75), ("female", 1507.75), ("other", 1590.75)],
)
def test_bmr_uses_the_mifflin_st_jeor_equation(gender, expected):
    assert calculate_bmr(70, 175, 25, gender) == expected


@pytest.mark.parametrize(
    "goal", ["Gain Muscle", "Lose Fat", "Maintain Weight", "Body Recomposition", "Athletic Performance"]
)
def test_macros_add_up_to_the_calorie_goal(goal):
    m = calculate_metrics(70, 175, 25, "male", goal, "active")

    calories_from_macros = m.protein_grams * 4 + m.carbs_grams * 4 + m.fats_grams * 9

    assert calories_from_macros == pytest.approx(m.calorie_goal, abs=2)


def test_a_fat_loss_goal_is_a_500_calorie_deficit():
    m = calculate_metrics(70, 175, 25, "male", "Lose Fat", "sedentary")

    assert m.maintenance_calories == pytest.approx(1673.75 * 1.2, abs=0.01)
    assert m.calorie_goal == pytest.approx(m.maintenance_calories - 500, abs=0.01)


def test_active_people_get_more_water_and_a_higher_step_target():
    sedentary = calculate_metrics(70, 175, 25, "male", "Maintain Weight", "sedentary")
    athlete = calculate_metrics(70, 175, 25, "male", "Maintain Weight", "athlete")

    assert athlete.water_liters == pytest.approx(sedentary.water_liters + 0.5)
    assert (sedentary.daily_step_target, athlete.daily_step_target) == (8000, 13000)


@pytest.mark.parametrize(
    "kwargs",
    [{"activity_level": "couch"}, {"goal": "Get Rich"}],
)
def test_unknown_options_raise_instead_of_guessing(kwargs):
    args = {"goal": "Lose Fat", "activity_level": "active", **kwargs}

    with pytest.raises(ValueError):
        calculate_metrics(70, 175, 25, "male", args["goal"], args["activity_level"])
