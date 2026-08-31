package com.aitravelplanner.cost.dto;

public record CostPredictionResponse(
        double accommodationCostLkr,
        double foodCostLkr,
        double transportCostLkr,
        double publicTransportKm,
        double privateTransportKm,
        double publicTransportCostLkr,
        double privateTransportCostLkr,
        double activitiesCostLkr,
        double totalPredictedCostLkr,
        double userBudgetLkr,
        double budgetDifferenceLkr,
        boolean withinBudget,
        String model) {
}
