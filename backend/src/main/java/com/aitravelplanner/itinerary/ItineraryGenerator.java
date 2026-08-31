package com.aitravelplanner.itinerary;

import com.aitravelplanner.itinerary.AccommodationCatalog.AccommodationOption;
import com.aitravelplanner.itinerary.NationwidePlaceCatalog.StartPoint;
import com.aitravelplanner.itinerary.NationwidePlaceCatalog.TravelCandidate;
import com.aitravelplanner.itinerary.dto.GenerateItineraryRequest;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import org.springframework.stereotype.Component;

@Component
class ItineraryGenerator {

    private static final double AIRPORT_LAT = 7.180756;
    private static final double AIRPORT_LNG = 79.884117;

    private final NationwidePlaceCatalog nationwideCatalog;
    private final AccommodationCatalog accommodationCatalog;
    private final PlaceSearchService placeSearchService;
    private final TransportPlanner transportPlanner;

    ItineraryGenerator(
            NationwidePlaceCatalog nationwideCatalog,
            AccommodationCatalog accommodationCatalog,
            PlaceSearchService placeSearchService,
            TransportPlanner transportPlanner) {
        this.nationwideCatalog = nationwideCatalog;
        this.accommodationCatalog = accommodationCatalog;
        this.placeSearchService = placeSearchService;
        this.transportPlanner = transportPlanner;
    }

    GenerationTotals generate(Trip trip, GenerateItineraryRequest request) {
        validateBudgetSufficiency(request);

        int totalDays = (int) ChronoUnit.DAYS.between(
                request.arrivalDateTime().toLocalDate(),
                request.departureDateTime().toLocalDate()) + 1;
        int targetItems = itemsPerDay(request.pace());

        List<TravelCandidate> ranked = nationwideCatalog.rankedCandidates(request);
        if (ranked.isEmpty()) {
            return generateLegacyFallback(trip, request, totalDays, targetItems);
        }

        StartPoint start = nationwideCatalog.startPoint(request);
        trip.setPlaceSource(
                "OPENSTREETMAP_PREFERENCE_ROUTE",
                "Sri Lanka OSM places matched to your selected place types and activities, then ordered from the nearest strong match to the next nearest strong match.",
                start.latitude(),
                start.longitude());

        Set<String> used = new HashSet<>();
        Set<String> coveredPreferences = new LinkedHashSet<>();
        BigDecimal activityTotal = BigDecimal.ZERO;
        BigDecimal transportTotal = BigDecimal.ZERO;
        BigDecimal accommodationTotal = BigDecimal.ZERO;

        double journeyLat = start.latitude();
        double journeyLng = start.longitude();

        for (int dayIndex = 0; dayIndex < totalDays; dayIndex++) {
            LocalDate date = request.arrivalDateTime().toLocalDate().plusDays(dayIndex);
            boolean firstDay = dayIndex == 0;
            boolean lastDay = dayIndex == totalDays - 1;

            ItineraryDay day = new ItineraryDay(
                    dayIndex + 1,
                    date,
                    "Preference route • " + nationwideCatalog.regionFor(journeyLat, journeyLng));

            LocalDateTime cursor = date.atTime(8, 0);
            if (firstDay && request.arrivalDateTime().plusMinutes(45).isAfter(cursor)) {
                cursor = request.arrivalDateTime().plusMinutes(45);
            }

            LocalDateTime dayEnd = date.atTime(19, 30);
            if (lastDay) {
                int airportReserve = request.returnToAirport() ? 180 : 120;
                LocalDateTime departureLimit = request.departureDateTime().minusMinutes(airportReserve);
                if (departureLimit.isBefore(dayEnd)) dayEnd = departureLimit;
            }

            // A late arrival should not receive unrealistic sightseeing. Go to nearby accommodation first.
            if (firstDay && cursor.toLocalTime().isAfter(LocalTime.of(18, 0))) {
                AccommodationOption stay = accommodationCatalog.nearest(
                        journeyLat, journeyLng, request.budgetLevel(), request.groupSize());
                BigDecimal distance = roadDistance(journeyLat, journeyLng, stay.latitude(), stay.longitude());
                int travel = travelMinutes(distance, request.transportMode());
                LocalDateTime checkIn = cursor.plusMinutes(travel);
                day.addItem(accommodationItem(stay, cursor, checkIn.plusMinutes(60), distance, travel, request));
                accommodationTotal = accommodationTotal.add(stay.estimatedNightCostLkr());
                transportTotal = transportTotal.add(transportPlanner.preferredCost(null, stay.address(), distance, request.groupSize(), request.budgetLevel()));
                journeyLat = stay.latitude();
                journeyLng = stay.longitude();
                trip.addDay(day);
                continue;
            }

            int planned = 0;
            int rejectedForTime = 0;
            while (planned < targetItems && rejectedForTime < 80) {
                final double fromLat = journeyLat;
                final double fromLng = journeyLng;
                TravelCandidate next = ranked.stream()
                        .filter(candidate -> !used.contains(sourceKey(candidate.place())))
                        .max(Comparator.comparingDouble(candidate -> selectionUtility(
                                candidate, request, coveredPreferences, fromLat, fromLng)))
                        .orElse(null);
                if (next == null) break;

                PlaceTemplate place = next.place();
                BigDecimal distance = roadDistance(journeyLat, journeyLng, place.latitude(), place.longitude());
                int travel = travelMinutes(distance, request.transportMode());
                LocalDateTime startTime = cursor.plusMinutes(travel);
                int visitMinutes = activityDurationMinutes(next);
                LocalDateTime endTime = startTime.plusMinutes(visitMinutes);

                if (endTime.isAfter(dayEnd)) {
                    // Mark this place unavailable for the current plan rather than repeatedly testing it.
                    used.add(sourceKey(place));
                    rejectedForTime++;
                    continue;
                }

                BigDecimal perPerson = nationwideCatalog.estimatedActivityCost(next, request.budgetLevel());
                BigDecimal itemCost = perPerson.multiply(BigDecimal.valueOf(request.groupSize()));
                List<String> alternatives = alternatives(ranked, next, used, request, place.latitude(), place.longitude());

                String region = nationwideCatalog.regionFor(place.latitude(), place.longitude());
                day.addItem(new ItineraryItem(
                        startTime.toLocalTime(),
                        endTime.toLocalTime(),
                        place.name(),
                        place.category(),
                        itineraryDescription(next, request),
                        region,
                        travel,
                        distance,
                        itemCost,
                        alternatives,
                        place.latitude(),
                        place.longitude(),
                        place.dataSource(),
                        place.sourceReference(),
                        place.sourceUrl()));

                used.add(sourceKey(place));
                coveredPreferences.addAll(nationwideCatalog.matchedPreferenceKeys(next, request));
                activityTotal = activityTotal.add(itemCost);
                transportTotal = transportTotal.add(transportPlanner.preferredCost(
                        place.sourceReference(), region, distance, request.groupSize(), request.budgetLevel()));
                journeyLat = place.latitude();
                journeyLng = place.longitude();
                cursor = endTime.plusMinutes(20);
                planned++;
            }

            // Every night except the departure night receives a nearby accommodation recommendation.
            if (!lastDay) {
                AccommodationOption stay = accommodationCatalog.nearest(
                        journeyLat, journeyLng, request.budgetLevel(), request.groupSize());
                BigDecimal distance = roadDistance(journeyLat, journeyLng, stay.latitude(), stay.longitude());
                int travel = travelMinutes(distance, request.transportMode());
                LocalDateTime transferStart = cursor.isAfter(date.atTime(20, 0)) ? cursor : date.atTime(19, 30);
                LocalDateTime checkIn = transferStart.plusMinutes(travel);
                day.addItem(accommodationItem(stay, transferStart, checkIn.plusMinutes(45), distance, travel, request));
                accommodationTotal = accommodationTotal.add(stay.estimatedNightCostLkr());
                transportTotal = transportTotal.add(transportPlanner.preferredCost(null, stay.address(), distance, request.groupSize(), request.budgetLevel()));
                journeyLat = stay.latitude();
                journeyLng = stay.longitude();
            }

            if (lastDay && request.returnToAirport()) {
                BigDecimal airportDistance = roadDistance(journeyLat, journeyLng, AIRPORT_LAT, AIRPORT_LNG);
                int airportTravel = travelMinutes(airportDistance, request.transportMode());
                LocalDateTime arriveAirport = request.departureDateTime().minusHours(2);
                LocalDateTime leaveForAirport = arriveAirport.minusMinutes(airportTravel);
                if (leaveForAirport.isBefore(date.atStartOfDay())) leaveForAirport = date.atStartOfDay();
                day.addItem(new ItineraryItem(
                        leaveForAirport.toLocalTime(),
                        arriveAirport.toLocalTime(),
                        "Travel to Bandaranaike International Airport (CMB)",
                        "Airport Transfer",
                        "Final transfer to CMB Airport, planned to arrive about two hours before departure.",
                        "Katunayake",
                        airportTravel,
                        airportDistance,
                        BigDecimal.ZERO,
                        List.of(),
                        AIRPORT_LAT,
                        AIRPORT_LNG,
                        "SYSTEM",
                        null,
                        "https://www.openstreetmap.org/?mlat=" + AIRPORT_LAT + "&mlon=" + AIRPORT_LNG));
                transportTotal = transportTotal.add(transportPlanner.preferredCost(null, "Negombo / Katunayake", airportDistance, request.groupSize(), request.budgetLevel()));
            }

            if (day.getItems().isEmpty()) {
                addTravelOrRestItem(day, request, dayIndex, nationwideCatalog.regionFor(journeyLat, journeyLng));
            }
            trip.addDay(day);
        }

        BigDecimal food = dailyFoodRate(request.budgetLevel())
                .multiply(BigDecimal.valueOf(totalDays))
                .multiply(BigDecimal.valueOf(request.groupSize()));
        BigDecimal minimumLocalTransport = dailyTransportRate(request.transportMode(), request.budgetLevel())
                .multiply(BigDecimal.valueOf(totalDays));
        BigDecimal transport = transportTotal.max(minimumLocalTransport);

        return new GenerationTotals(accommodationTotal, food, transport, activityTotal);
    }

    int activityDurationMinutes(TravelCandidate candidate) {
        String category = candidate.place().category().toLowerCase(Locale.ROOT);
        String activities = String.join(" ", candidate.activities()).toLowerCase(Locale.ROOT);
        if (activities.contains("hiking") || activities.contains("trekking") || category.contains("hiking")) return 240;
        if (activities.contains("safari") || category.contains("wildlife")) return 240;
        if (activities.contains("surf") || category.contains("water sports")) return 180;
        if (category.contains("beach")) return 150;
        if (category.contains("temple") || category.contains("culture") || category.contains("history")) return 150;
        if (category.contains("waterfall") || category.contains("forest") || category.contains("nature")) return 150;
        if (category.contains("mountain") || category.contains("peak") || category.contains("adventure")) return 210;
        if (category.contains("food") || category.contains("market")) return 90;
        if (category.contains("museum") || category.contains("garden")) return 120;
        return Math.max(105, candidate.place().visitMinutes());
    }

    private double selectionUtility(
            TravelCandidate candidate,
            GenerateItineraryRequest request,
            Set<String> covered,
            double fromLat,
            double fromLng) {
        double distance = NationwidePlaceCatalog.distanceKm(
                fromLat, fromLng, candidate.place().latitude(), candidate.place().longitude());
        Set<String> matched = nationwideCatalog.matchedPreferenceKeys(candidate, request);
        long uncovered = matched.stream().filter(key -> !covered.contains(key)).count();

        // First cover the user's different selected preferences; after coverage, nearest strong matches win.
        double score = candidate.score() * 25.0;
        score += uncovered * 5_000.0;
        if (uncovered == 0 && !matched.isEmpty()) score -= 2_500.0;
        score -= distance * 12.0;
        return score;
    }

    private List<String> alternatives(
            List<TravelCandidate> ranked,
            TravelCandidate current,
            Set<String> used,
            GenerateItineraryRequest request,
            double fromLat,
            double fromLng) {
        Set<String> currentMatches = nationwideCatalog.matchedPreferenceKeys(current, request);
        return ranked.stream()
                .filter(candidate -> !sourceKey(candidate.place()).equals(sourceKey(current.place())))
                .filter(candidate -> !used.contains(sourceKey(candidate.place())))
                .filter(candidate -> !java.util.Collections.disjoint(
                        nationwideCatalog.matchedPreferenceKeys(candidate, request), currentMatches))
                // Alternatives only need a small relevant pool; avoid sorting the entire dataset.
                .limit(400)
                .sorted(Comparator.comparingDouble((TravelCandidate candidate) ->
                        NationwidePlaceCatalog.distanceKm(
                                fromLat, fromLng, candidate.place().latitude(), candidate.place().longitude()))
                        .thenComparing(Comparator.comparingInt(TravelCandidate::score).reversed()))
                .limit(2)
                .map(candidate -> candidate.place().name())
                .toList();
    }

    private ItineraryItem accommodationItem(
            AccommodationOption stay,
            LocalDateTime start,
            LocalDateTime end,
            BigDecimal distance,
            int travelMinutes,
            GenerateItineraryRequest request) {
        return new ItineraryItem(
                start.toLocalTime(),
                end.toLocalTime(),
                stay.name(),
                "Accommodation",
                "Nearby overnight stay recommendation: " + stay.type()
                        + ". " + stay.address()
                        + ". The displayed night cost is a planning estimate; confirm the live room price before booking.",
                stay.address(),
                travelMinutes,
                distance,
                stay.estimatedNightCostLkr(),
                accommodationCatalog.alternatives(
                                stay.latitude(),
                                stay.longitude(),
                                request.budgetLevel(),
                                request.groupSize(),
                                stay.name(),
                                2)
                        .stream()
                        .map(AccommodationOption::name)
                        .toList(),
                stay.latitude(),
                stay.longitude(),
                "SRI_LANKA_OPEN_DATA",
                null,
                null);
    }

    private String itineraryDescription(TravelCandidate candidate, GenerateItineraryRequest request) {
        List<String> selectedMatches = new ArrayList<>();
        Set<String> keys = nationwideCatalog.matchedPreferenceKeys(candidate, request);
        for (String key : keys) selectedMatches.add(key.substring(key.indexOf(':') + 1));
        String activities = String.join(", ", candidate.activities().stream().limit(3).toList());
        String reason = selectedMatches.isEmpty() ? "your preferences" : String.join(", ", selectedMatches);
        String base = candidate.place().description();
        if (base == null || base.isBlank()) base = candidate.place().name() + " is a mapped Sri Lankan place.";
        return ShortDescription.limit(base + " Matched: " + reason + ". Suggested activities: " + activities + ".", 46);
    }

    private BigDecimal roadDistance(double fromLat, double fromLng, double toLat, double toLng) {
        double roadApproximation = NationwidePlaceCatalog.distanceKm(fromLat, fromLng, toLat, toLng) * 1.22;
        return BigDecimal.valueOf(roadApproximation).setScale(2, RoundingMode.HALF_UP);
    }

    private String sourceKey(PlaceTemplate place) {
        if (place.sourceReference() != null && !place.sourceReference().isBlank()) return place.sourceReference();
        return place.name() + "@" + place.latitude() + "," + place.longitude();
    }

    private int travelMinutes(BigDecimal distanceKm, String transportMode) {
        if (distanceKm.signum() <= 0) return 0;
        String mode = transportMode.toLowerCase(Locale.ROOT);
        double speed = mode.contains("walk") ? 5.0
                : mode.contains("public") || mode.contains("bus") || mode.contains("train") ? 32.0
                : mode.contains("tuk") ? 28.0
                : 42.0;
        return Math.max(10, (int) Math.ceil(distanceKm.doubleValue() / speed * 60));
    }

    private BigDecimal estimatedLegTransportCost(BigDecimal distanceKm, String mode) {
        String value = mode.toLowerCase(Locale.ROOT);
        double rate = value.contains("public") || value.contains("bus") || value.contains("train") ? 18.0
                : value.contains("tuk") ? 85.0
                : value.contains("private") || value.contains("rental") ? 120.0
                : 35.0;
        return BigDecimal.valueOf(distanceKm.doubleValue() * rate).setScale(2, RoundingMode.HALF_UP);
    }

    private void addTravelOrRestItem(
            ItineraryDay day, GenerateItineraryRequest request, int dayIndex, String region) {
        LocalDateTime anchor = dayIndex == 0 ? request.arrivalDateTime() : day.getDate().atTime(9, 0);
        day.addItem(new ItineraryItem(
                anchor.toLocalTime(), anchor.plusMinutes(90).toLocalTime(),
                dayIndex == 0 ? "Arrival, transfer and check-in" : "Regional transfer and flexible time",
                "Travel",
                "Use this time for transfer, check-in, meals and rest before the next recommended activities.",
                region, 90, BigDecimal.ZERO, BigDecimal.ZERO, List.of(),
                null, null, "SYSTEM", null, null));
    }

    private GenerationTotals generateLegacyFallback(
            Trip trip, GenerateItineraryRequest request, int totalDays, int targetItems) {
        PlaceSearchResult search = placeSearchService.findPlaces(
                request.destinationRegion(), request.latitude(), request.longitude());
        trip.setPlaceSource(search.generatorType(), search.providerNote(),
                search.destinationLatitude(), search.destinationLongitude());
        BigDecimal activities = BigDecimal.ZERO;
        int index = 0;
        for (int dayIndex = 0; dayIndex < totalDays; dayIndex++) {
            LocalDate date = request.arrivalDateTime().toLocalDate().plusDays(dayIndex);
            ItineraryDay day = new ItineraryDay(dayIndex + 1, date,
                    request.interests().get(dayIndex % request.interests().size()) + " • " + request.destinationRegion());
            LocalDateTime cursor = date.atTime(9, 0);
            for (int i = 0; i < targetItems && index < search.places().size(); i++, index++) {
                PlaceTemplate place = search.places().get(index);
                LocalDateTime end = cursor.plusMinutes(place.visitMinutes());
                BigDecimal cost = place.baseCostLkr().multiply(BigDecimal.valueOf(request.groupSize()));
                day.addItem(new ItineraryItem(cursor.toLocalTime(), end.toLocalTime(), place.name(), place.category(),
                        place.description(), place.location(), 0, place.distanceKm(), cost, List.of(),
                        place.latitude(), place.longitude(), place.dataSource(), place.sourceReference(), place.sourceUrl()));
                activities = activities.add(cost);
                cursor = end.plusMinutes(30);
            }
            if (day.getItems().isEmpty()) addTravelOrRestItem(day, request, dayIndex, request.destinationRegion());
            trip.addDay(day);
        }
        int nights = Math.max(0, totalDays - 1);
        int rooms = Math.max(1, (request.groupSize() + 1) / 2);
        return new GenerationTotals(
                accommodationRate(request.accommodationType(), request.budgetLevel())
                        .multiply(BigDecimal.valueOf(nights)).multiply(BigDecimal.valueOf(rooms)),
                dailyFoodRate(request.budgetLevel()).multiply(BigDecimal.valueOf(totalDays))
                        .multiply(BigDecimal.valueOf(request.groupSize())),
                dailyTransportRate(request.transportMode(), request.budgetLevel()).multiply(BigDecimal.valueOf(totalDays)),
                activities);
    }

    private int itemsPerDay(String pace) {
        return switch (pace.toLowerCase(Locale.ROOT)) {
            case "relaxed" -> 2;
            case "fast" -> 4;
            default -> 3;
        };
    }

    private BigDecimal accommodationRate(String type, BudgetLevel level) {
        String value = type.toLowerCase(Locale.ROOT);
        if (value.contains("luxury") || value.contains("4") || value.contains("5")) return BigDecimal.valueOf(55000);
        if (value.contains("mid") || value.contains("3")) return BigDecimal.valueOf(18000);
        return switch (level) {
            case LOW -> BigDecimal.valueOf(6500);
            case MID -> BigDecimal.valueOf(15000);
            case HIGH -> BigDecimal.valueOf(40000);
        };
    }

    private BigDecimal dailyFoodRate(BudgetLevel level) {
        return switch (level) {
            case LOW -> BigDecimal.valueOf(2500);
            case MID -> BigDecimal.valueOf(5000);
            case HIGH -> BigDecimal.valueOf(10000);
        };
    }

    private BigDecimal dailyTransportRate(String mode, BudgetLevel level) {
        String value = mode.toLowerCase(Locale.ROOT);
        if (value.contains("public") || value.contains("bus") || value.contains("train")) return BigDecimal.valueOf(2000);
        if (value.contains("tuk")) return BigDecimal.valueOf(4500);
        if (value.contains("rental") || value.contains("private")) return BigDecimal.valueOf(12000);
        return switch (level) {
            case LOW -> BigDecimal.valueOf(2500);
            case MID -> BigDecimal.valueOf(6000);
            case HIGH -> BigDecimal.valueOf(15000);
        };
    }

    private void validateBudgetSufficiency(GenerateItineraryRequest request) {
        long days = ChronoUnit.DAYS.between(
                request.arrivalDateTime().toLocalDate(), request.departureDateTime().toLocalDate()) + 1;
        BigDecimal baselinePerDayPerPerson = switch (request.budgetLevel()) {
            case LOW -> BigDecimal.valueOf(5500);
            case MID -> BigDecimal.valueOf(11000);
            case HIGH -> BigDecimal.valueOf(24000);
        };
        BigDecimal minimum = baselinePerDayPerPerson.multiply(BigDecimal.valueOf(days))
                .multiply(BigDecimal.valueOf(request.groupSize()));
        if (request.budgetLkr().compareTo(minimum) < 0) {
            throw new InvalidTripRequestException(
                    "Budget is too low for the selected duration, traveller count and budget level. "
                            + "A practical minimum estimate is LKR " + minimum.toBigInteger() + ".");
        }
    }

    record GenerationTotals(BigDecimal accommodation, BigDecimal food, BigDecimal transport, BigDecimal activities) {}
}
