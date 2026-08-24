package com.aitravelplanner.itinerary.dto;

import java.math.BigDecimal;
import java.util.List;

public record RouteResponse(
        List<RoutePointResponse> points,
        BigDecimal distanceKm,
        long durationMinutes) {}
