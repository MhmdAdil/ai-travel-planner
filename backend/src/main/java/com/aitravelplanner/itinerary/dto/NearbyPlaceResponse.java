package com.aitravelplanner.itinerary.dto;

import java.math.BigDecimal;

public record NearbyPlaceResponse(
        String id,
        String name,
        String category,
        String description,
        BigDecimal averageCostLkr,
        BigDecimal averageCostUsd,
        String feeStatus,
        String feeDetails,
        String address,
        String openingHours,
        String website,
        String phone,
        double latitude,
        double longitude,
        BigDecimal distanceKm,
        String dataSource,
        String sourceUrl) {
}
