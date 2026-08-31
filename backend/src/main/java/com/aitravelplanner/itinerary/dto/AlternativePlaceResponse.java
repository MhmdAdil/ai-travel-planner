package com.aitravelplanner.itinerary.dto;

import java.math.BigDecimal;

public record AlternativePlaceResponse(
        String name,
        String category,
        String description,
        String location,
        int travelMinutes,
        int visitMinutes,
        BigDecimal distanceKm,
        BigDecimal estimatedCostLkr,
        BigDecimal estimatedCostUsd,
        java.util.List<TransportOptionResponse> transportOptions,
        Double latitude,
        Double longitude,
        String dataSource,
        String sourceReference,
        String sourceUrl) {
}
