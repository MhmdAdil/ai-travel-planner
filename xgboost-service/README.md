# AI Travel Planner — XGBoost Cost Prediction (Stage 1)

This folder is the **standalone ML stage**. It does not modify the Flutter or Spring Boot application yet.

## What is included

- `data/cost_prediction_training.csv` — 60,000 trip scenarios.
- `scripts/train_xgboost.py` — trains four XGBoost regressors.
- `scripts/predict_example.py` — predicts the sample 4-day Sri Lanka trip.
- `models/` — trained model pipelines when training succeeded in the build environment.
- `metrics.json` — MAE, RMSE and R² values from a held-out 20% test split.
- `data/feature_importance.csv` — top feature importances per model.
- `data/sample_predictions.csv` — example predicted vs. target values.
- `requirements.txt`.

## IMPORTANT academic wording

The supplied 60,000-row dataset is a **reference-derived synthetic trip-scenario dataset**.
It is **not** 60,000 historical traveller receipts.

The labels were generated from structured planning assumptions using:
- trip duration and traveller count,
- accommodation class,
- food style,
- route distance,
- transport mode,
- activity mix,
- the latest PickMe/Uber-style fare assumptions supplied for this project,
- controlled random variation.

This is appropriate for a prototype/final-year ML pipeline when real labelled trip-expense data are unavailable,
but it should be described honestly in the report. Later, real observed expenses can replace or enrich the targets.

## Latest private-ride assumptions used

- Tuk Tuk: first 1 km LKR 200; additional km midpoint LKR 80.
- Car: first 1 km LKR 450; additional km midpoint LKR 97.50.
- Minivan: first 1 km LKR 800; additional km midpoint LKR 120.
- Van: first 1 km LKR 1,500; additional km midpoint LKR 175.

## Model design

Four separate `XGBRegressor` models predict:
1. accommodation cost,
2. food cost,
3. transport cost,
4. activity cost.

The application total is the sum of these four predictions.

Why this design:
- easier to explain in a viva,
- exposes useful cost breakdowns,
- allows future retraining of one component without retraining every component.

## Run on Windows

Open Command Prompt inside this folder:

```cmd
py -m venv .venv
.venv\Scripts\activate
python -m pip install --upgrade pip
pip install -r requirements.txt
python scripts\train_xgboost.py
python scripts\predict_example.py
```

Do not integrate this into Spring Boot yet. First confirm training completes and the example prediction works.

## Dataset columns

Inputs:
- duration_days, travellers, budget_lkr, budget_level
- accommodation_type, food_preference, transport_mode, pace
- region_count, place_count, activity_count
- selected preference/activity flags
- route_distance_km, estimated_travel_hours
- nights, rooms

Targets:
- accommodation_cost_lkr
- food_cost_lkr
- transport_cost_lkr
- activities_cost_lkr
- total_cost_lkr

## Stage 2 after verification

After `train_xgboost.py` and `predict_example.py` work on the project PC:
1. create a small Python prediction API,
2. connect Spring Boot to that API,
3. add the Flutter Cost Prediction screen,
4. connect the itinerary result to the same prediction endpoint.
