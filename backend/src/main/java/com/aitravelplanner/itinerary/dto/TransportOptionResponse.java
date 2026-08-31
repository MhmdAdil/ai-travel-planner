package com.aitravelplanner.itinerary.dto;

import java.math.BigDecimal;

public record TransportOptionResponse(
        String type,
        String vehicleModel,
        String serviceName,
        int capacity,
        int estimatedMinutes,
        BigDecimal estimatedFareLkr,
        String fareNote,
        String source) {
}
