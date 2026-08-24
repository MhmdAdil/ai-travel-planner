package com.aitravelplanner.itinerary;

import java.util.List;

record PlaceSearchResult(
        List<PlaceTemplate> places,
        String generatorType,
        String providerNote,
        Double destinationLatitude,
        Double destinationLongitude) {
}
