package com.aitravelplanner.cost.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.PositiveOrZero;

public record CostPredictionRequest(
        @Min(1) @Max(60) int durationDays,
        @Min(1) @Max(30) int travellers,
        @PositiveOrZero double budgetLkr,

        @NotBlank
        @Pattern(regexp = "LOW|MID|HIGH", message = "budgetLevel must be LOW, MID, or HIGH")
        String budgetLevel,

        @NotBlank String accommodationType,
        @NotBlank String foodPreference,
        @NotBlank String transportMode,

        @NotBlank
        @Pattern(regexp = "Relaxed|Balanced|Fast", message = "pace must be Relaxed, Balanced, or Fast")
        String pace,

        @Min(1) @Max(9) int regionCount,
        double regionCostIndex,
        double publicTransportCoverage,
        @PositiveOrZero double publicTransportKm,
        @PositiveOrZero double privateTransportKm,
        @PositiveOrZero double publicTransportCostLkr,
        @PositiveOrZero double privateTransportCostLkr,
        @PositiveOrZero double calculatedTransportCostLkr,
        @Min(1) @Max(100) int placeCount,
        @Min(0) @Max(100) int activityCount,

        boolean hasBeach,
        boolean hasCulture,
        boolean hasWildlife,
        boolean hasNature,
        boolean hasHistory,
        boolean hasAdventure,

        boolean hasHiking,
        boolean hasSurfing,
        boolean hasSafari,
        boolean hasSwimming,
        boolean hasCycling,
        boolean hasFoodTour,
        boolean hasShopping,

        @PositiveOrZero double routeDistanceKm,
        @PositiveOrZero double estimatedTravelHours,
        @Min(0) @Max(60) int nights,
        @Min(1) @Max(20) int rooms) {
}
