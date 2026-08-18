package com.aitravelplanner.itinerary;

import java.math.BigDecimal;

record PlaceTemplate(
        String name,
        String category,
        String description,
        int visitMinutes,
        BigDecimal baseCostLkr,
        BigDecimal distanceKm) {
}
