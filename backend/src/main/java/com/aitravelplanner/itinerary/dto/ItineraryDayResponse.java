package com.aitravelplanner.itinerary.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public record ItineraryDayResponse(
        int dayNumber,
        LocalDate date,
        String theme,
        BigDecimal estimatedCostLkr,
        BigDecimal estimatedCostUsd,
        List<ItineraryItemResponse> items) {
}
