package com.aitravelplanner.itinerary.dto;

import java.math.BigDecimal;

public record CostSummaryResponse(
        BigDecimal accommodationLkr,
        BigDecimal foodLkr,
        BigDecimal transportLkr,
        BigDecimal activitiesLkr,
        BigDecimal totalLkr,
        BigDecimal totalUsd,
        BigDecimal budgetLkr,
        boolean withinBudget,
        BigDecimal budgetDifferenceLkr,
        BigDecimal lkrPerUsd,
        String rateNote) {
}
