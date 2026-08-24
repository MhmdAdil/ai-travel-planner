package com.aitravelplanner.itinerary;

import java.math.BigDecimal;

record PlaceTemplate(
        String name,
        String category,
        String description,
        String location,
        int visitMinutes,
        BigDecimal baseCostLkr,
        BigDecimal distanceKm,
        Double latitude,
        Double longitude,
        String dataSource,
        String sourceReference,
        String sourceUrl,
        String openingHours,
        String website,
        String phone,
        String feeStatus,
        String feeDetails) {

    PlaceTemplate(
            String name,
            String category,
            String description,
            String location,
            int visitMinutes,
            BigDecimal baseCostLkr,
            BigDecimal distanceKm,
            Double latitude,
            Double longitude,
            String dataSource,
            String sourceReference,
            String sourceUrl) {
        this(name, category, description, location, visitMinutes, baseCostLkr, distanceKm,
                latitude, longitude, dataSource, sourceReference, sourceUrl,
                "", "", "", "UNKNOWN", "Cost information is not available from OpenStreetMap.");
    }
}
