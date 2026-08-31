from fastapi.testclient import TestClient
from api.main import app

EXAMPLE = {
    "duration_days": 4,
    "travellers": 2,
    "budget_lkr": 120000,
    "budget_level": "LOW",
    "accommodation_type": "Budget guesthouse",
    "food_preference": "Sri Lankan",
    "transport_mode": "Public transport + Tuk/Taxi",
    "pace": "Balanced",
    "region_count": 2,
    "region_cost_index": 1.12,
    "public_transport_coverage": 0.40,
    "public_transport_km": 400.0,
    "private_transport_km": 600.0,
    "public_transport_cost_lkr": 6200.0,
    "private_transport_cost_lkr": 59025.0,
    "calculated_transport_cost_lkr": 65225.0,
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
    "route_distance_km": 1000.0,
    "estimated_travel_hours": 25.0,
    "nights": 3,
    "rooms": 1,
}


def main() -> None:
    with TestClient(app) as client:
        health = client.get("/health")
        print("HEALTH:", health.status_code, health.json())

        prediction = client.post("/predict", json=EXAMPLE)
        print("PREDICT:", prediction.status_code)

        body = prediction.json()
        print(body)

        assert health.status_code == 200, health.text
        assert prediction.status_code == 200, prediction.text

        assert body["model"] == "XGBoost + route-based transport"
        assert body["total_predicted_cost_lkr"] > 0

        assert round(body["transport_cost_lkr"], 2) == 65225.0
        assert round(body["public_transport_km"], 2) == 400.0
        assert round(body["private_transport_km"], 2) == 600.0
        assert round(body["public_transport_cost_lkr"], 2) == 6200.0
        assert round(body["private_transport_cost_lkr"], 2) == 59025.0

        assert round(
            body["public_transport_cost_lkr"]
            + body["private_transport_cost_lkr"],
            2,
        ) == round(body["transport_cost_lkr"], 2)

        assert round(
            body["public_transport_km"] + body["private_transport_km"],
            2,
        ) == round(EXAMPLE["route_distance_km"], 2)

    print("API TEST PASSED")


if __name__ == "__main__":
    main()
