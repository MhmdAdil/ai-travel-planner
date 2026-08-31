package com.aitravelplanner.itinerary;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.io.InputStream;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/**
 * Source-linked nationwide OpenStreetMap index for Sri Lanka.
 *
 * <p>Live OpenStreetMap remains the primary source. This bundled index supplies source-linked
 * named OSM places across Sri Lanka when public Overpass endpoints are unavailable. It contains
 * no Google Maps content, ratings, reviews, photos, prices or copied descriptions.</p>
 */
final class VerifiedOsmSnapshot {

    private static final String DATASET = "/open-data/sri-lanka-places.json";
    private static final List<VerifiedPlace> PLACES = loadDataset();

    private VerifiedOsmSnapshot() {}

    static List<PlaceTemplate> findNearby(
            double latitude,
            double longitude,
            int radiusMetres,
            Set<String> activityFilters) {
        Set<String> normalizedFilters = activityFilters.stream()
                .map(value -> value.trim().toLowerCase(Locale.ROOT))
                .collect(java.util.stream.Collectors.toSet());
        List<PlaceTemplate> matches = new ArrayList<>();
        for (VerifiedPlace place : PLACES) {
            if (!matchesFilter(place.category(), normalizedFilters)) continue;
            double rawDistance = distanceKilometres(
                    latitude, longitude, place.latitude(), place.longitude());
            if (rawDistance > radiusMetres / 1_000.0) continue;
            BigDecimal distance = BigDecimal.valueOf(rawDistance)
                    .setScale(2, RoundingMode.HALF_UP);
            matches.add(new PlaceTemplate(
                    place.name(), place.category(), ShortDescription.limit(place.description(), 40), place.address(),
                    visitMinutes(place.category()), BigDecimal.ZERO, distance,
                    place.latitude(), place.longitude(), place.dataSource(),
                    place.sourceReference(), place.sourceUrl(), safe(place.openingHours()),
                    safe(place.website()), safe(place.phone()), safeOr(place.feeStatus(), "UNKNOWN"),
                    safeOr(place.feeDetails(), "Price: not published by the source.")));
        }
        matches.sort(Comparator.comparing(PlaceTemplate::distanceKm));
        return List.copyOf(matches);
    }

    static int size() {
        return PLACES.size();
    }

    static List<PlaceTemplate> allPlaces() {
        List<PlaceTemplate> result = new ArrayList<>(PLACES.size());
        for (VerifiedPlace place : PLACES) {
            result.add(new PlaceTemplate(
                    place.name(), place.category(), ShortDescription.limit(place.description(), 40), place.address(),
                    visitMinutes(place.category()), BigDecimal.ZERO, BigDecimal.ZERO,
                    place.latitude(), place.longitude(), place.dataSource(),
                    place.sourceReference(), place.sourceUrl(), safe(place.openingHours()),
                    safe(place.website()), safe(place.phone()), safeOr(place.feeStatus(), "UNKNOWN"),
                    safeOr(place.feeDetails(), "Price: not published by the source.")));
        }
        return List.copyOf(result);
    }

    private static boolean matchesFilter(String category, Set<String> normalizedFilters) {
        if (normalizedFilters.isEmpty()) return true;
        String normalizedCategory = category.toLowerCase(Locale.ROOT);
        if (normalizedFilters.contains(normalizedCategory)) return true;
        if (normalizedFilters.contains("nature & parks")
                && Set.of("nature", "wildlife", "waterfalls", "rivers", "ponds & lakes",
                        "rocks & caves", "mountains & peaks", "forests", "gardens", "hot springs")
                        .contains(normalizedCategory)) return true;
        if (normalizedFilters.contains("museums & history")
                && (normalizedCategory.equals("culture") || normalizedCategory.equals("history"))) return true;
        if (normalizedFilters.contains("food & cafes") && normalizedCategory.equals("food")) return true;
        if (normalizedFilters.contains("attractions")
                && Set.of("attraction", "water parks", "wildlife", "cinemas & theatres",
                        "markets", "shopping malls", "playgrounds").contains(normalizedCategory)) return true;
        if (normalizedFilters.contains("adventure & viewpoints")
                && Set.of("adventure", "hiking", "cycling", "water sports", "camping & picnics",
                        "rocks & caves", "mountains & peaks", "waterfalls", "boating & marinas")
                        .contains(normalizedCategory)) return true;
        if (normalizedFilters.contains("wildlife & zoos") && normalizedCategory.equals("wildlife")) return true;
        if (normalizedFilters.contains("hiking & trails") && normalizedCategory.equals("hiking")) return true;
        if (normalizedFilters.contains("surfing & water sports") && normalizedCategory.equals("water sports")) return true;
        if (normalizedFilters.contains("sports & recreation") && normalizedCategory.equals("sports")) return true;
        return false;
    }

    private static int visitMinutes(String category) {
        return switch (category) {
            case "Beaches", "Adventure", "Hiking", "Cycling", "Water Sports",
                    "Camping & Picnics", "Mountains & Peaks" -> 180;
            case "Nature", "History", "Culture", "Temples", "Waterfalls", "Rivers",
                    "Ponds & Lakes", "Rocks & Caves", "Forests", "Gardens", "Hot Springs" -> 120;
            default -> 105;
        };
    }

    private static List<VerifiedPlace> loadDataset() {
        try (InputStream input = VerifiedOsmSnapshot.class.getResourceAsStream(DATASET)) {
            if (input == null) throw new IllegalStateException("Missing open-data dataset: " + DATASET);
            return List.copyOf(new ObjectMapper().readValue(
                    input, new TypeReference<List<VerifiedPlace>>() {}));
        } catch (IOException exception) {
            throw new IllegalStateException("Could not read open-data dataset: " + DATASET, exception);
        }
    }

    private static double distanceKilometres(double lat1, double lon1, double lat2, double lon2) {
        double earthRadiusKm = 6_371.0088;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return earthRadiusKm * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }

    private static String safe(String value) {
        return value == null ? "" : value;
    }

    private static String safeOr(String value, String fallback) {
        return value == null || value.isBlank() ? fallback : value;
    }

    private record VerifiedPlace(
            String name, String category, String description, String address,
            double latitude, double longitude, String sourceReference,
            String sourceUrl, String dataSource, String openingHours,
            String website, String phone, String feeStatus, String feeDetails) {}
}
