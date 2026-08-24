package com.aitravelplanner.itinerary;

import com.aitravelplanner.itinerary.dto.NearbyPlaceResponse;
import java.math.BigDecimal;
import java.util.List;
import java.util.Set;
import org.springframework.stereotype.Service;

@Service
class NearbyPlaceService {

    private final OsmPlaceClient osmPlaceClient;

    NearbyPlaceService(OsmPlaceClient osmPlaceClient) {
        this.osmPlaceClient = osmPlaceClient;
    }

    List<NearbyPlaceResponse> find(double latitude, double longitude, double radiusKm) {
        return find(latitude, longitude, radiusKm, Set.of());
    }

    List<NearbyPlaceResponse> find(
            double latitude, double longitude, double radiusKm, Set<String> activityFilters) {
        List<PlaceTemplate> places = osmPlaceClient.findNearby(
                latitude, longitude, radiusKm, activityFilters);
        return places.stream()
                .filter(place -> place.latitude() != null && place.longitude() != null)
                .map(place -> new NearbyPlaceResponse(
                        place.sourceReference(),
                        place.name(),
                        place.category(),
                        place.description(),
                        "FREE".equals(place.feeStatus()) ? BigDecimal.ZERO : null,
                        "FREE".equals(place.feeStatus()) ? BigDecimal.ZERO : null,
                        place.feeStatus(),
                        place.feeDetails(),
                        "your location".equalsIgnoreCase(place.location()) ? "" : place.location(),
                        place.openingHours(),
                        place.website(),
                        place.phone(),
                        place.latitude(),
                        place.longitude(),
                        place.distanceKm(),
                        place.dataSource(),
                        place.sourceUrl()))
                .toList();
    }

}
