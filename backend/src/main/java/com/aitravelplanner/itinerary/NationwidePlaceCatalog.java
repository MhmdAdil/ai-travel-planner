package com.aitravelplanner.itinerary;

import com.aitravelplanner.itinerary.dto.GenerateItineraryRequest;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

/** Nationwide preference-matching layer over the bundled source-linked Sri Lanka OSM snapshot. */
@Component
class NationwidePlaceCatalog {

    private static final List<RegionAnchor> REGIONS = List.of(
            new RegionAnchor("Negombo / Katunayake", 7.2083, 79.8358),
            new RegionAnchor("Colombo", 6.9271, 79.8612),
            new RegionAnchor("Bentota", 6.4210, 80.0030),
            new RegionAnchor("Galle / Unawatuna", 6.0329, 80.2168),
            new RegionAnchor("Mirissa / Weligama", 5.9483, 80.4716),
            new RegionAnchor("Yala / Tissamaharama", 6.2800, 81.2860),
            new RegionAnchor("Udawalawe", 6.4388, 80.8882),
            new RegionAnchor("Ella", 6.8667, 81.0466),
            new RegionAnchor("Nuwara Eliya", 6.9497, 80.7891),
            new RegionAnchor("Kandy", 7.2906, 80.6337),
            new RegionAnchor("Sigiriya / Dambulla", 7.9570, 80.7603),
            new RegionAnchor("Anuradhapura", 8.3114, 80.4037),
            new RegionAnchor("Polonnaruwa", 7.9403, 81.0188),
            new RegionAnchor("Trincomalee", 8.5874, 81.2152),
            new RegionAnchor("Arugam Bay", 6.8404, 81.8368),
            new RegionAnchor("Jaffna", 9.6615, 80.0255),
            new RegionAnchor("Kalpitiya", 8.2330, 79.7660),
            new RegionAnchor("Kitulgala", 6.9896, 80.4173),
            new RegionAnchor("Haputale", 6.7657, 80.9526),
            new RegionAnchor("Ratnapura", 6.6828, 80.3992));

    private final List<TravelCandidate> candidates;

    NationwidePlaceCatalog() {
        this.candidates = VerifiedOsmSnapshot.allPlaces().stream()
                .filter(place -> place.latitude() != null && place.longitude() != null)
                .map(place -> new TravelCandidate(
                        place,
                        nearestRegion(place.latitude(), place.longitude()).name(),
                        activitiesFor(place),
                        0))
                .toList();
    }

    /** Only places that actually match at least one selected place-interest or activity are returned. */
    List<TravelCandidate> rankedCandidates(GenerateItineraryRequest request) {
        return candidates.stream()
                .filter(candidate -> matchesTravelRegions(candidate, request.travelRegions()))
                .map(candidate -> candidate.withScore(preferenceScore(candidate, request)))
                .filter(candidate -> candidate.score() > 0)
                .sorted(Comparator.comparingInt(TravelCandidate::score).reversed()
                        .thenComparing(candidate -> candidate.place().name()))
                // The full dataset remains available, but itinerary generation only needs
                // a high-quality shortlist. This prevents repeated O(N^2) scans.
                .limit(1200)
                .toList();
    }


    private boolean matchesTravelRegions(TravelCandidate candidate, List<String> selectedRegions) {
        if (selectedRegions == null || selectedRegions.isEmpty()) return true;
        String anchor = normalize(candidate.region());
        for (String raw : selectedRegions) {
            String region = normalize(raw);
            if (region.equals("western province")
                    && (anchor.contains("colombo") || anchor.contains("negombo") || anchor.contains("katunayake"))) return true;
            if (region.equals("southern province")
                    && (anchor.contains("bentota") || anchor.contains("galle") || anchor.contains("unawatuna")
                    || anchor.contains("mirissa") || anchor.contains("weligama") || anchor.contains("yala")
                    || anchor.contains("tissamaharama"))) return true;
            if (region.equals("upcountry / central highlands")
                    && (anchor.contains("kandy") || anchor.contains("nuwara eliya") || anchor.contains("ella")
                    || anchor.contains("haputale"))) return true;
            if (region.equals("cultural triangle / north central")
                    && (anchor.contains("sigiriya") || anchor.contains("dambulla") || anchor.contains("anuradhapura")
                    || anchor.contains("polonnaruwa"))) return true;
            if (region.equals("eastern province")
                    && (anchor.contains("trincomalee") || anchor.contains("arugam bay"))) return true;
            if (region.equals("northern province") && anchor.contains("jaffna")) return true;
            if (region.equals("north western / wayamba") && anchor.contains("kalpitiya")) return true;
            if (region.equals("sabaragamuwa / rainforest")
                    && (anchor.contains("ratnapura") || anchor.contains("kitulgala"))) return true;
            if (region.equals("uva / south-east wildlife")
                    && (anchor.contains("ella") || anchor.contains("haputale") || anchor.contains("yala")
                    || anchor.contains("tissamaharama") || anchor.contains("udawalawe") || anchor.contains("arugam bay"))) return true;
        }
        return false;
    }

    StartPoint startPoint(GenerateItineraryRequest request) {
        if (request.latitude() != null && request.longitude() != null) {
            return new StartPoint(request.latitude(), request.longitude(), request.startLocation());
        }
        String requested = normalize(request.destinationRegion() + " " + request.startLocation());
        Optional<RegionAnchor> direct = REGIONS.stream()
                .filter(region -> requested.contains(normalize(region.name()).split(" ")[0])
                        || aliases(region.name()).stream().anyMatch(requested::contains))
                .min(Comparator.comparingInt(region -> requested.indexOf(
                        aliases(region.name()).stream().filter(requested::contains).findFirst()
                                .orElse(normalize(region.name()).split(" ")[0]))));
        if (direct.isPresent()) {
            RegionAnchor region = direct.get();
            return new StartPoint(region.latitude(), region.longitude(), region.name());
        }
        // For smaller named towns, use a mapped place with the same name when one exists.
        Optional<TravelCandidate> mapped = candidates.stream()
                .filter(candidate -> normalize(candidate.place().name()).equals(normalize(request.destinationRegion()))
                        || normalize(candidate.place().name()).equals(normalize(request.startLocation())))
                .findFirst();
        if (mapped.isPresent()) {
            PlaceTemplate place = mapped.get().place();
            return new StartPoint(place.latitude(), place.longitude(), place.name());
        }
        return new StartPoint(7.180756, 79.884117, "Bandaranaike International Airport");
    }

    Optional<TravelCandidate> findByName(String name) {
        if (name == null || name.isBlank()) return Optional.empty();
        String wanted = normalize(name);
        return candidates.stream()
                .filter(candidate -> normalize(candidate.place().name()).equals(wanted))
                .findFirst();
    }

    String regionFor(double latitude, double longitude) {
        return nearestRegion(latitude, longitude).name();
    }

    int preferenceScore(TravelCandidate candidate, GenerateItineraryRequest request) {
        int score = 0;
        String category = normalize(candidate.place().category());
        String searchable = normalize(candidate.place().name() + " " + candidate.place().description());
        Set<String> candidateActivities = candidate.activities().stream()
                .map(NationwidePlaceCatalog::normalize)
                .collect(Collectors.toSet());

        for (String interest : safe(request.interests())) {
            if (matchesInterest(category, searchable, interest)) score += 40;
        }
        for (String activity : safe(request.activities())) {
            if (matchesActivity(category, searchable, candidateActivities, activity)) score += 55;
        }
        // Named POIs are preferable to generic infrastructure after relevance is established.
        if (score > 0 && candidate.place().name() != null && !candidate.place().name().isBlank()) score += 3;
        return score;
    }

    Set<String> matchedPreferenceKeys(TravelCandidate candidate, GenerateItineraryRequest request) {
        Set<String> result = new java.util.LinkedHashSet<>();
        String category = normalize(candidate.place().category());
        String searchable = normalize(candidate.place().name() + " " + candidate.place().description());
        Set<String> candidateActivities = candidate.activities().stream()
                .map(NationwidePlaceCatalog::normalize)
                .collect(Collectors.toSet());
        for (String interest : safe(request.interests())) {
            if (matchesInterest(category, searchable, interest)) result.add("interest:" + normalize(interest));
        }
        for (String activity : safe(request.activities())) {
            if (matchesActivity(category, searchable, candidateActivities, activity)) result.add("activity:" + normalize(activity));
        }
        return result;
    }

    private boolean matchesInterest(String category, String text, String rawInterest) {
        String interest = normalize(rawInterest);
        return switch (interest) {
            case "beaches" -> category.equals("beaches") || category.equals("water sports");
            case "culture" -> Set.of("culture", "temples", "history").contains(category);
            case "wildlife" -> category.equals("wildlife");
            case "adventure" -> Set.of("adventure", "hiking", "cycling", "water sports",
                    "camping & picnics", "rocks & caves", "mountains & peaks", "boating & marinas").contains(category);
            case "food" -> Set.of("food", "markets").contains(category);
            case "nature" -> Set.of("nature", "forests", "waterfalls", "rivers", "ponds & lakes",
                    "mountains & peaks", "gardens", "hot springs", "wildlife").contains(category);
            case "history" -> Set.of("history", "culture", "temples").contains(category);
            case "relaxation" -> Set.of("beaches", "gardens", "nature", "hot springs").contains(category);
            case "waterfalls" -> category.equals("waterfalls");
            case "mountains & hills" -> Set.of("mountains & peaks", "hiking", "adventure").contains(category);
            case "agro tourism" -> category.equals("farms") || text.contains("tea") || text.contains("estate") || text.contains("farm");
            case "forests & rainforests" -> Set.of("forests", "nature").contains(category) || text.contains("rainforest");
            case "lakes & rivers" -> Set.of("rivers", "ponds & lakes", "boating & marinas").contains(category);
            case "temples & heritage" -> Set.of("temples", "culture", "history").contains(category);
            case "viewpoints" -> Set.of("mountains & peaks", "adventure", "hiking").contains(category) || text.contains("viewpoint");
            case "gardens" -> category.equals("gardens");
            case "caves & rocks" -> category.equals("rocks & caves");
            default -> category.contains(interest) || text.contains(interest);
        };
    }

    private boolean matchesActivity(
            String category,
            String text,
            Set<String> candidateActivities,
            String rawActivity) {
        String activity = normalize(rawActivity);
        if (candidateActivities.stream().anyMatch(value -> value.contains(activity) || activity.contains(value))) {
            return true;
        }
        return switch (activity) {
            case "hiking" -> Set.of("hiking", "mountains & peaks", "adventure").contains(category);
            case "surfing" -> category.equals("water sports") && text.contains("surf");
            case "wildlife safari" -> category.equals("wildlife");
            case "swimming" -> category.equals("water sports") && (text.contains("swim") || text.contains("pool"));
            case "cycling" -> category.equals("cycling");
            case "photography" -> !Set.of("food", "markets", "shopping malls", "sports", "playgrounds").contains(category);
            case "food tours" -> Set.of("food", "markets").contains(category);
            case "shopping" -> Set.of("markets", "shopping malls").contains(category);
            case "snorkelling & diving", "diving or snorkelling" -> category.equals("water sports")
                    && (text.contains("div") || text.contains("snork"));
            case "whale watching" -> text.contains("whale") || (category.equals("boating & marinas") && text.contains("sea"));
            case "bird watching" -> category.equals("wildlife") || category.equals("forests") || text.contains("bird");
            case "boating" -> Set.of("boating & marinas", "rivers", "ponds & lakes").contains(category);
            case "camping" -> category.equals("camping & picnics");
            case "temple visits" -> category.equals("temples");
            case "heritage sightseeing" -> Set.of("culture", "history", "temples").contains(category);
            case "tea estate visit" -> category.equals("farms") || text.contains("tea") || text.contains("estate");
            case "waterfall visit" -> category.equals("waterfalls");
            case "scenic viewpoints" -> Set.of("mountains & peaks", "hiking", "adventure").contains(category) || text.contains("viewpoint");
            default -> text.contains(activity);
        };
    }

    static List<String> activitiesFor(PlaceTemplate place) {
        String category = place.category();
        String text = normalize(place.name() + " " + place.description());
        if (category.equals("Water Sports")) {
            if (text.contains("surf")) return List.of("Surfing", "Water sports", "Photography");
            if (text.contains("div") || text.contains("snork")) return List.of("Diving or snorkelling", "Water sports", "Photography");
            if (text.contains("swim") || text.contains("pool")) return List.of("Swimming", "Water sports", "Recreation");
            return List.of("Water sports", "Coastal recreation", "Photography");
        }
        return switch (category) {
            case "Beaches" -> List.of("Beach visit", "Sunset watching", "Photography");
            case "Wildlife" -> List.of("Wildlife Safari", "Wildlife watching", "Bird watching", "Photography");
            case "Hiking" -> List.of("Hiking", "Trekking", "Scenic viewpoint", "Photography");
            case "Mountains & Peaks" -> List.of("Hiking", "Scenic viewpoint", "Photography");
            case "Adventure" -> List.of("Scenic viewpoint", "Adventure", "Photography");
            case "Temples" -> List.of("Temple visit", "Culture", "Heritage", "Photography");
            case "Culture" -> List.of("Culture", "Heritage", "Sightseeing", "Photography");
            case "History" -> List.of("History", "Heritage", "Sightseeing", "Photography");
            case "Waterfalls" -> List.of("Waterfall visit", "Nature", "Photography");
            case "Forests", "Nature" -> List.of("Nature walk", "Wildlife watching", "Photography");
            case "Rivers" -> List.of("River visit", "Nature", "Photography");
            case "Ponds & Lakes" -> List.of("Lake visit", "Nature", "Photography");
            case "Rocks & Caves" -> List.of("Cave or rock visit", "Adventure", "Photography");
            case "Camping & Picnics" -> List.of("Camping", "Picnic", "Nature");
            case "Cycling" -> List.of("Cycling", "Adventure", "Sightseeing");
            case "Boating & Marinas" -> List.of("Boating", "Marina visit", "Photography");
            case "Gardens" -> List.of("Garden visit", "Nature walk", "Photography");
            case "Food" -> List.of("Local food", "Food tours", "Cafe or restaurant");
            case "Markets" -> List.of("Market visit", "Shopping", "Food tours");
            case "Shopping Malls" -> List.of("Shopping", "Local shopping");
            case "Farms" -> List.of("Farm visit", "Rural experience", "Photography");
            case "Sports" -> List.of("Sports", "Recreation", "Local experience");
            default -> List.of("Sightseeing", "Photography", "Local experience");
        };
    }

    BigDecimal estimatedActivityCost(TravelCandidate candidate, BudgetLevel level) {
        int base = switch (candidate.place().category()) {
            case "Wildlife" -> 12000;
            case "Water Sports" -> 7000;
            case "Hiking", "Adventure", "Boating & Marinas" -> 2500;
            case "Culture", "History", "Temples" -> 1500;
            case "Food", "Markets" -> 2000;
            default -> 750;
        };
        double factor = switch (level) {
            case LOW -> 0.8;
            case MID -> 1.0;
            case HIGH -> 1.25;
        };
        return BigDecimal.valueOf(base * factor).setScale(2, RoundingMode.HALF_UP);
    }

    static double distanceKm(double lat1, double lon1, double lat2, double lon2) {
        double earthRadius = 6371.0088;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return earthRadius * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }

    private static RegionAnchor nearestRegion(double latitude, double longitude) {
        return REGIONS.stream()
                .min(Comparator.comparingDouble(region -> distanceKm(
                        latitude, longitude, region.latitude(), region.longitude())))
                .orElse(REGIONS.get(0));
    }

    private static List<String> aliases(String region) {
        String n = normalize(region);
        List<String> parts = new ArrayList<>();
        for (String part : n.split("/")) parts.add(part.trim());
        if (n.contains("negombo")) parts.addAll(List.of("katunayake", "airport"));
        if (n.contains("galle")) parts.add("unawatuna");
        if (n.contains("mirissa")) parts.add("weligama");
        if (n.contains("sigiriya")) parts.add("dambulla");
        if (n.contains("yala")) parts.add("tissamaharama");
        return parts;
    }

    private static List<String> safe(List<String> values) {
        return values == null ? List.of() : values;
    }

    private static String normalize(String value) {
        return value == null ? "" : value.toLowerCase(Locale.ROOT).trim();
    }

    record TravelCandidate(PlaceTemplate place, String region, List<String> activities, int score) {
        TravelCandidate withScore(int newScore) {
            return new TravelCandidate(place, region, activities, newScore);
        }
    }

    record StartPoint(double latitude, double longitude, String label) {}
    private record RegionAnchor(String name, double latitude, double longitude) {}
}
