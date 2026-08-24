package com.aitravelplanner.itinerary;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Comparator;
import java.util.List;
import org.springframework.stereotype.Component;

@Component
class NearbyFallbackCatalog {

    private static final List<FallbackPlace> PLACES = List.of(
            place("Colombo Lotus Tower", "Attraction", 6.9272, 79.8583, 6000),
            place("Beira Lake", "Nature", 6.9274, 79.8547, 0),
            place("Pettah Floating Market", "Food", 6.9334, 79.8555, 1500),
            place("Gangaramaya Temple", "Temples", 6.9167, 79.8562, 600),
            place("Colombo National Museum", "History", 6.9107, 79.8612, 2500),
            place("Galle Face Green", "Relaxation", 6.9270, 79.8447, 0),
            place("Temple of the Sacred Tooth Relic", "Temples", 7.2936, 80.6413, 3000),
            place("Kandy Lake", "Relaxation", 7.2906, 80.6410, 0),
            place("Galle Fort", "History", 6.0260, 80.2170, 800),
            place("Galle Lighthouse", "History", 6.0258, 80.2186, 0),
            place("Nine Arch Bridge", "History", 6.8768, 81.0610, 600),
            place("Little Adam's Peak", "Hiking", 6.8667, 81.0656, 800),
            place("Sigiriya Rock Fortress", "History", 7.9570, 80.7603, 11000),
            place("Gregory Lake", "Nature", 6.9567, 80.7781, 2000));

    List<PlaceTemplate> find(double latitude, double longitude, double radiusKm) {
        return PLACES.stream()
                .map(place -> place.toTemplate(distanceKm(latitude, longitude, place.latitude(), place.longitude())))
                .filter(place -> place.distanceKm().doubleValue() <= radiusKm)
                .sorted(Comparator.comparing(PlaceTemplate::distanceKm))
                .limit(20)
                .toList();
    }

    private static FallbackPlace place(
            String name, String category, double latitude, double longitude, int estimatedCostLkr) {
        return new FallbackPlace(name, category, latitude, longitude, estimatedCostLkr);
    }

    private static double distanceKm(double lat1, double lon1, double lat2, double lon2) {
        double earthRadiusKm = 6371.0088;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return earthRadiusKm * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }

    private record FallbackPlace(
            String name,
            String category,
            double latitude,
            double longitude,
            int estimatedCostLkr) {

        PlaceTemplate toTemplate(double distanceKm) {
            String sourceUrl = "https://www.openstreetmap.org/?mlat=" + latitude
                    + "&mlon=" + longitude + "#map=17/" + latitude + "/" + longitude;
            return new PlaceTemplate(
                    name,
                    category,
                    "Local demonstration fallback used while live OpenStreetMap search is unavailable.",
                    "Sri Lanka",
                    90,
                    BigDecimal.valueOf(estimatedCostLkr),
                    BigDecimal.valueOf(distanceKm).setScale(2, RoundingMode.HALF_UP),
                    latitude,
                    longitude,
                    "FALLBACK_CATALOG",
                    "fallback:" + name.toLowerCase().replace(' ', '-'),
                    sourceUrl);
        }
    }
}
