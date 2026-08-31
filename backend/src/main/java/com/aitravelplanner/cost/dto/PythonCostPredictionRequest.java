package com.aitravelplanner.cost.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

public record PythonCostPredictionRequest(
        @JsonProperty("duration_days") int durationDays,
        int travellers,
        @JsonProperty("budget_lkr") double budgetLkr,
        @JsonProperty("budget_level") String budgetLevel,
        @JsonProperty("accommodation_type") String accommodationType,
        @JsonProperty("food_preference") String foodPreference,
        @JsonProperty("transport_mode") String transportMode,
        String pace,
        @JsonProperty("region_count") int regionCount,
        @JsonProperty("region_cost_index") double regionCostIndex,
        @JsonProperty("public_transport_coverage") double publicTransportCoverage,
        @JsonProperty("public_transport_km") double publicTransportKm,
        @JsonProperty("private_transport_km") double privateTransportKm,
        @JsonProperty("public_transport_cost_lkr") double publicTransportCostLkr,
        @JsonProperty("private_transport_cost_lkr") double privateTransportCostLkr,
        @JsonProperty("calculated_transport_cost_lkr") double calculatedTransportCostLkr,
        @JsonProperty("place_count") int placeCount,
        @JsonProperty("activity_count") int activityCount,
        @JsonProperty("has_beach") int hasBeach,
        @JsonProperty("has_culture") int hasCulture,
        @JsonProperty("has_wildlife") int hasWildlife,
        @JsonProperty("has_nature") int hasNature,
        @JsonProperty("has_history") int hasHistory,
        @JsonProperty("has_adventure") int hasAdventure,
        @JsonProperty("has_hiking") int hasHiking,
        @JsonProperty("has_surfing") int hasSurfing,
        @JsonProperty("has_safari") int hasSafari,
        @JsonProperty("has_swimming") int hasSwimming,
        @JsonProperty("has_cycling") int hasCycling,
        @JsonProperty("has_food_tour") int hasFoodTour,
        @JsonProperty("has_shopping") int hasShopping,
        @JsonProperty("route_distance_km") double routeDistanceKm,
        @JsonProperty("estimated_travel_hours") double estimatedTravelHours,
        int nights,
        int rooms) {

    public static PythonCostPredictionRequest from(CostPredictionRequest request) {
        return new PythonCostPredictionRequest(
                request.durationDays(),
                request.travellers(),
                request.budgetLkr(),
                request.budgetLevel(),
                request.accommodationType(),
                request.foodPreference(),
                request.transportMode(),
                request.pace(),
                request.regionCount(),
                request.regionCostIndex(),
                request.publicTransportCoverage(),
                request.publicTransportKm(),
                request.privateTransportKm(),
                request.publicTransportCostLkr(),
                request.privateTransportCostLkr(),
                request.calculatedTransportCostLkr(),
                request.placeCount(),
                request.activityCount(),
                bit(request.hasBeach()),
                bit(request.hasCulture()),
                bit(request.hasWildlife()),
                bit(request.hasNature()),
                bit(request.hasHistory()),
                bit(request.hasAdventure()),
                bit(request.hasHiking()),
                bit(request.hasSurfing()),
                bit(request.hasSafari()),
                bit(request.hasSwimming()),
                bit(request.hasCycling()),
                bit(request.hasFoodTour()),
                bit(request.hasShopping()),
                request.routeDistanceKm(),
                request.estimatedTravelHours(),
                request.nights(),
                request.rooms());
    }

    private static int bit(boolean value) {
        return value ? 1 : 0;
    }
}
