package com.aitravelplanner.itinerary.dto;

import java.math.BigDecimal;
import java.time.LocalTime;
import java.util.List;

public record ItineraryItemResponse(
        LocalTime startTime,
        LocalTime endTime,
        String name,
        String category,
        String description,
        String location,
        int travelMinutes,
        BigDecimal distanceKm,
        BigDecimal estimatedCostLkr,
        BigDecimal estimatedCostUsd,
        List<String> alternatives) {
}
