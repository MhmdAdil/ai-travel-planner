package com.aitravelplanner.cost.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

public record PythonCostPredictionResponse(
        @JsonProperty("accommodation_cost_lkr") double accommodationCostLkr,
        @JsonProperty("food_cost_lkr") double foodCostLkr,
        @JsonProperty("transport_cost_lkr") double transportCostLkr,
        @JsonProperty("public_transport_km") double publicTransportKm,
        @JsonProperty("private_transport_km") double privateTransportKm,
        @JsonProperty("public_transport_cost_lkr") double publicTransportCostLkr,
        @JsonProperty("private_transport_cost_lkr") double privateTransportCostLkr,
        @JsonProperty("activities_cost_lkr") double activitiesCostLkr,
        @JsonProperty("total_predicted_cost_lkr") double totalPredictedCostLkr,
        @JsonProperty("user_budget_lkr") double userBudgetLkr,
        @JsonProperty("budget_difference_lkr") double budgetDifferenceLkr,
        @JsonProperty("within_budget") boolean withinBudget,
        String model) {

    public CostPredictionResponse toPublicResponse() {
        return new CostPredictionResponse(
                accommodationCostLkr,
                foodCostLkr,
                transportCostLkr,
                publicTransportKm,
                privateTransportKm,
                publicTransportCostLkr,
                privateTransportCostLkr,
                activitiesCostLkr,
                totalPredictedCostLkr,
                userBudgetLkr,
                budgetDifferenceLkr,
                withinBudget,
                model);
    }
}
