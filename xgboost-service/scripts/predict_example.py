from pathlib import Path
import joblib
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
MODELS = ROOT / "models"

trip = {
    "duration_days": 4,
    "travellers": 2,
    "budget_lkr": 120000,
    "budget_level": "LOW",
    "accommodation_type": "Budget hotel",
    "food_preference": "Sri Lankan",
    "transport_mode": "Public transport",
    "pace": "Balanced",
    "region_count": 2,
    "place_count": 7,
    "activity_count": 5,
    "has_beach": 1,
    "has_culture": 1,
    "has_wildlife": 1,
    "has_nature": 0,
    "has_history": 0,
    "has_adventure": 0,
    "has_hiking": 0,
    "has_surfing": 1,
    "has_safari": 1,
    "has_swimming": 0,
    "has_cycling": 0,
    "has_food_tour": 0,
    "has_shopping": 0,
    "route_distance_km": 420.0,
    "estimated_travel_hours": 11.5,
    "nights": 3,
    "rooms": 1,
}
X = pd.DataFrame([trip])

names = ["accommodation", "food", "transport", "activities"]
result = {}
for name in names:
    model = joblib.load(MODELS / f"{name}_xgboost.joblib")
    result[name] = max(float(model.predict(X)[0]), 0.0)

result["total"] = sum(result.values())

print("Predicted trip cost (LKR)")
for key, value in result.items():
    print(f"{key:>14}: {value:,.0f}")
