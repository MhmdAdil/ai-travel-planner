package com.aitravelplanner.itinerary.dto;

import com.aitravelplanner.itinerary.BudgetLevel;
import com.aitravelplanner.itinerary.TripStatus;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.List;

public record ItineraryResponse(
        Long id,
        String title,
        String destinationRegion,
        String startLocation,
        LocalDateTime arrivalDateTime,
        LocalDateTime departureDateTime,
        BudgetLevel budgetLevel,
        int groupSize,
        List<String> interests,
        List<String> activities,
        String accommodationType,
        String foodPreference,
        String transportMode,
        String pace,
        TripStatus status,
        String generatorType,
        CostSummaryResponse costSummary,
        List<ItineraryDayResponse> days,
        Instant createdAt) {
}
