from __future__ import annotations

from pathlib import Path
from typing import Literal

import joblib
import pandas as pd
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

ROOT = Path(__file__).resolve().parents[1]
MODELS_DIR = ROOT / "models"

MODEL_NAMES = ("accommodation", "food", "transport", "activities")

app = FastAPI(
    title="AI Travel Planner Cost Prediction API",
    version="1.0.0",
    description="XGBoost cost prediction service for the AI Travel Planner.",
)

_models: dict[str, object] = {}


class CostPredictionRequest(BaseModel):
    duration_days: int = Field(ge=1, le=60)
    travellers: int = Field(ge=1, le=30)
    budget_lkr: float = Field(ge=0)

    budget_level: Literal["LOW", "MID", "HIGH"]
    accommodation_type: str
    food_preference: str
    transport_mode: str
    pace: Literal["Relaxed", "Balanced", "Fast"]

    region_count: int = Field(ge=1, le=9)
    region_cost_index: float = Field(ge=0.5, le=2.0)
    public_transport_coverage: float = Field(ge=0, le=1)
    public_transport_km: float = Field(ge=0, le=10000)
    private_transport_km: float = Field(ge=0, le=10000)
    public_transport_cost_lkr: float = Field(ge=0)
    private_transport_cost_lkr: float = Field(ge=0)
    calculated_transport_cost_lkr: float = Field(ge=0)
    place_count: int = Field(ge=1, le=100)
    activity_count: int = Field(ge=0, le=100)

    has_beach: int = Field(ge=0, le=1)
    has_culture: int = Field(ge=0, le=1)
    has_wildlife: int = Field(ge=0, le=1)
    has_nature: int = Field(ge=0, le=1)
    has_history: int = Field(ge=0, le=1)
    has_adventure: int = Field(ge=0, le=1)

    has_hiking: int = Field(ge=0, le=1)
    has_surfing: int = Field(ge=0, le=1)
    has_safari: int = Field(ge=0, le=1)
    has_swimming: int = Field(ge=0, le=1)
    has_cycling: int = Field(ge=0, le=1)
    has_food_tour: int = Field(ge=0, le=1)
    has_shopping: int = Field(ge=0, le=1)

    route_distance_km: float = Field(ge=0, le=10000)
    estimated_travel_hours: float = Field(ge=0, le=300)
    nights: int = Field(ge=0, le=60)
    rooms: int = Field(ge=1, le=20)


class CostPredictionResponse(BaseModel):
    accommodation_cost_lkr: float
    food_cost_lkr: float
    transport_cost_lkr: float
    public_transport_km: float
    private_transport_km: float
    public_transport_cost_lkr: float
    private_transport_cost_lkr: float
    activities_cost_lkr: float
    total_predicted_cost_lkr: float
    user_budget_lkr: float
    budget_difference_lkr: float
    within_budget: bool
    model: str = "XGBoost"


def _load_models() -> None:
    missing = []
    for name in MODEL_NAMES:
        path = MODELS_DIR / f"{name}_xgboost.joblib"
        if not path.exists():
            missing.append(str(path))
            continue
        _models[name] = joblib.load(path)

    if missing:
        raise RuntimeError(
            "Missing trained XGBoost model files. Run scripts\\train_xgboost.py first. "
            + " Missing: "
            + ", ".join(missing)
        )


@app.on_event("startup")
def startup() -> None:
    _load_models()


@app.get("/health")
def health() -> dict:
    return {
        "status": "ok",
        "service": "cost-prediction",
        "model": "XGBoost",
        "models_loaded": sorted(_models.keys()),
    }


@app.post("/predict", response_model=CostPredictionResponse)
def predict(request: CostPredictionRequest) -> CostPredictionResponse:
    if len(_models) != len(MODEL_NAMES):
        raise HTTPException(
            status_code=503,
            detail="XGBoost models are not loaded. Train models and restart the API.",
        )

    row = pd.DataFrame([request.model_dump()])

    predicted: dict[str, float] = {}
    for name in ("accommodation", "food", "activities"):
        value = float(_models[name].predict(row)[0])
        predicted[name] = max(value, 0.0)

    # Transport is deterministic once the completed itinerary supplies every route leg.
    # Using the XGBoost transport value here could under-estimate long journeys because the
    # user expects every travelled kilometre to be charged. The ML service therefore keeps
    # XGBoost for the uncertain components and uses the exact route/fare calculation for
    # transport. This also makes the cost explainable in the Flutter UI.
    predicted["transport"] = max(request.calculated_transport_cost_lkr, 0.0)

    total = sum(predicted.values())
    difference = request.budget_lkr - total

    return CostPredictionResponse(
        accommodation_cost_lkr=round(predicted["accommodation"], 2),
        food_cost_lkr=round(predicted["food"], 2),
        transport_cost_lkr=round(predicted["transport"], 2),
        public_transport_km=round(request.public_transport_km, 2),
        private_transport_km=round(request.private_transport_km, 2),
        public_transport_cost_lkr=round(request.public_transport_cost_lkr, 2),
        private_transport_cost_lkr=round(request.private_transport_cost_lkr, 2),
        activities_cost_lkr=round(predicted["activities"], 2),
        total_predicted_cost_lkr=round(total, 2),
        user_budget_lkr=round(request.budget_lkr, 2),
        budget_difference_lkr=round(difference, 2),
        within_budget=difference >= 0,
        model="XGBoost + route-based transport",
    )
