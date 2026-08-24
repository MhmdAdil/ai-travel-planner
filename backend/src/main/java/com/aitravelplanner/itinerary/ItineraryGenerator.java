package com.aitravelplanner.itinerary;

import com.aitravelplanner.itinerary.dto.GenerateItineraryRequest;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import org.springframework.stereotype.Component;

@Component
class ItineraryGenerator {

    private final PlaceSearchService placeSearchService;

    ItineraryGenerator(PlaceSearchService placeSearchService) {
        this.placeSearchService = placeSearchService;
    }

    GenerationTotals generate(Trip trip, GenerateItineraryRequest request) {
        PlaceSearchResult searchResult = placeSearchService.findPlaces(request.destinationRegion());
        List<PlaceTemplate> catalog = rankedPlaces(request, searchResult.places());
        trip.setPlaceSource(
                searchResult.generatorType(),
                searchResult.providerNote(),
                searchResult.destinationLatitude(),
                searchResult.destinationLongitude());
        int totalDays = (int) ChronoUnit.DAYS.between(
                request.arrivalDateTime().toLocalDate(),
                request.departureDateTime().toLocalDate()) + 1;
        int targetItems = itemsPerDay(request.pace());
        BigDecimal activityTotal = BigDecimal.ZERO;
        int nextPlaceIndex = 0;

        for (int dayIndex = 0; dayIndex < totalDays; dayIndex++) {
            LocalDate date = request.arrivalDateTime().toLocalDate().plusDays(dayIndex);
            String theme = request.interests().get(dayIndex % request.interests().size());
            ItineraryDay day = new ItineraryDay(dayIndex + 1, date, theme + " in " + request.destinationRegion());

            LocalDateTime cursor = date.atTime(8, 30);
            if (dayIndex == 0 && request.arrivalDateTime().plusHours(1).isAfter(cursor)) {
                cursor = request.arrivalDateTime().plusHours(1);
            }
            LocalDateTime dayEnd = date.atTime(19, 0);
            if (dayIndex == totalDays - 1) {
                LocalDateTime departureLimit = request.departureDateTime().minusHours(2);
                if (departureLimit.isBefore(dayEnd)) {
                    dayEnd = departureLimit;
                }
            }

            PlaceTemplate previousPlace = null;
            for (int itemIndex = 0; itemIndex < targetItems && nextPlaceIndex < catalog.size(); itemIndex++) {
                PlaceTemplate template = catalog.get(nextPlaceIndex);
                BigDecimal legDistance = legDistance(previousPlace, template, searchResult);
                int travelMinutes = travelMinutes(legDistance, request.transportMode());
                LocalDateTime start = cursor.plusMinutes(travelMinutes);
                LocalDateTime end = start.plusMinutes(template.visitMinutes());
                if (end.isAfter(dayEnd)) {
                    break;
                }

                BigDecimal itemCost = adjustedActivityCost(template.baseCostLkr(), request.budgetLevel())
                        .multiply(BigDecimal.valueOf(request.groupSize()));
                List<String> alternatives = alternativeNames(catalog, template);
                day.addItem(new ItineraryItem(
                        start.toLocalTime(),
                        end.toLocalTime(),
                        template.name(),
                        template.category(),
                        template.description(),
                        template.location(),
                        travelMinutes,
                        legDistance,
                        itemCost,
                        alternatives,
                        template.latitude(),
                        template.longitude(),
                        template.dataSource(),
                        template.sourceReference(),
                        template.sourceUrl()));
                activityTotal = activityTotal.add(itemCost);
                cursor = end;
                previousPlace = template;
                nextPlaceIndex++;
            }

            if (day.getItems().isEmpty()) {
                boolean arrivalDay = dayIndex == 0;
                LocalDateTime anchor = arrivalDay
                        ? request.arrivalDateTime()
                        : request.departureDateTime().minusHours(2);
                String name = arrivalDay ? "Arrival and accommodation check-in" : "Departure preparation and transfer";
                day.addItem(new ItineraryItem(
                        anchor.toLocalTime(),
                        anchor.plusMinutes(60).toLocalTime(),
                        name,
                        "Travel",
                        arrivalDay
                                ? "Arrive, transfer from the starting point and settle into your accommodation."
                                : "Check out and allow sufficient time to reach the departure point.",
                        request.startLocation(),
                        60,
                        BigDecimal.ZERO,
                        BigDecimal.ZERO,
                        List.of(),
                        null,
                        null,
                        "SYSTEM",
                        null,
                        null));
            }
            trip.addDay(day);
        }

        int nights = Math.max(0, totalDays - 1);
        int rooms = Math.max(1, (request.groupSize() + 1) / 2);
        BigDecimal accommodation = accommodationRate(request.accommodationType(), request.budgetLevel())
                .multiply(BigDecimal.valueOf(nights))
                .multiply(BigDecimal.valueOf(rooms));
        BigDecimal food = dailyFoodRate(request.budgetLevel())
                .multiply(BigDecimal.valueOf(totalDays))
                .multiply(BigDecimal.valueOf(request.groupSize()));
        BigDecimal transport = dailyTransportRate(request.transportMode(), request.budgetLevel())
                .multiply(BigDecimal.valueOf(totalDays));
        return new GenerationTotals(accommodation, food, transport, activityTotal);
    }

    private List<PlaceTemplate> rankedPlaces(
            GenerateItineraryRequest request,
            List<PlaceTemplate> availablePlaces) {
        List<String> wanted = new ArrayList<>();
        wanted.addAll(request.interests());
        if (request.activities() != null) {
            wanted.addAll(request.activities());
        }
        return availablePlaces.stream()
                .sorted(Comparator
                        .comparingInt((PlaceTemplate place) -> matchScore(place, wanted)).reversed()
                        .thenComparing(PlaceTemplate::distanceKm))
                .toList();
    }

    private int matchScore(PlaceTemplate place, List<String> wanted) {
        String searchable = (place.name() + " " + place.category() + " " + place.description())
                .toLowerCase(Locale.ROOT);
        return (int) wanted.stream()
                .flatMap(value -> preferenceTokens(value).stream())
                .filter(searchable::contains)
                .count();
    }

    private List<String> preferenceTokens(String preference) {
        String value = preference.toLowerCase(Locale.ROOT);
        if (value.contains("hik") || value.contains("adventure")) {
            return List.of(value, "adventure", "nature", "peak", "viewpoint");
        }
        if (value.contains("beach") || value.contains("surf")) {
            return List.of(value, "beach", "coast");
        }
        if (value.contains("culture")) {
            return List.of(value, "culture", "temple", "museum", "worship");
        }
        if (value.contains("history")) {
            return List.of(value, "history", "historic", "heritage", "museum");
        }
        if (value.contains("wildlife")) {
            return List.of(value, "wildlife", "nature", "reserve", "zoo");
        }
        if (value.contains("food")) {
            return List.of(value, "food", "restaurant", "cafe");
        }
        return List.of(value);
    }

    private List<String> alternativeNames(List<PlaceTemplate> catalog, PlaceTemplate current) {
        List<String> sameCategory = catalog.stream()
                .filter(place -> !place.name().equals(current.name()))
                .filter(place -> place.category().equals(current.category()))
                .limit(2)
                .map(PlaceTemplate::name)
                .toList();
        if (sameCategory.size() == 2) return sameCategory;
        List<String> alternatives = new ArrayList<>(sameCategory);
        catalog.stream()
                .filter(place -> !place.name().equals(current.name()))
                .map(PlaceTemplate::name)
                .filter(name -> !alternatives.contains(name))
                .limit(2 - alternatives.size())
                .forEach(alternatives::add);
        return List.copyOf(alternatives);
    }

    private BigDecimal legDistance(
            PlaceTemplate previous,
            PlaceTemplate current,
            PlaceSearchResult searchResult) {
        if (current.latitude() == null || current.longitude() == null) {
            return current.distanceKm();
        }
        double fromLatitude;
        double fromLongitude;
        if (previous != null && previous.latitude() != null && previous.longitude() != null) {
            fromLatitude = previous.latitude();
            fromLongitude = previous.longitude();
        } else if (searchResult.destinationLatitude() != null && searchResult.destinationLongitude() != null) {
            fromLatitude = searchResult.destinationLatitude();
            fromLongitude = searchResult.destinationLongitude();
        } else {
            return current.distanceKm();
        }
        double earthRadiusKm = 6371.0088;
        double latDistance = Math.toRadians(current.latitude() - fromLatitude);
        double lonDistance = Math.toRadians(current.longitude() - fromLongitude);
        double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
                + Math.cos(Math.toRadians(fromLatitude)) * Math.cos(Math.toRadians(current.latitude()))
                * Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);
        double straightLine = earthRadiusKm * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return BigDecimal.valueOf(straightLine * 1.25).setScale(2, RoundingMode.HALF_UP);
    }

    private int travelMinutes(BigDecimal distanceKm, String transportMode) {
        if (distanceKm.signum() == 0) return 0;
        String mode = transportMode.toLowerCase(Locale.ROOT);
        double averageSpeed = mode.contains("walk") ? 5.0
                : mode.contains("public") ? 24.0
                : mode.contains("tuk") ? 28.0
                : 35.0;
        return Math.max(10, (int) Math.ceil(distanceKm.doubleValue() / averageSpeed * 60));
    }

    private int itemsPerDay(String pace) {
        return switch (pace.toLowerCase(Locale.ROOT)) {
            case "relaxed" -> 2;
            case "fast" -> 4;
            default -> 3;
        };
    }

    private BigDecimal adjustedActivityCost(BigDecimal base, BudgetLevel level) {
        return base.multiply(switch (level) {
            case LOW -> BigDecimal.valueOf(0.80);
            case MID -> BigDecimal.ONE;
            case HIGH -> BigDecimal.valueOf(1.25);
        }).setScale(2, RoundingMode.HALF_UP);
    }

    private BigDecimal accommodationRate(String type, BudgetLevel level) {
        String value = type.toLowerCase(Locale.ROOT);
        if (value.contains("luxury") || value.contains("4") || value.contains("5")) {
            return BigDecimal.valueOf(45000);
        }
        if (value.contains("mid") || value.contains("3")) {
            return BigDecimal.valueOf(18000);
        }
        return switch (level) {
            case LOW -> BigDecimal.valueOf(7000);
            case MID -> BigDecimal.valueOf(15000);
            case HIGH -> BigDecimal.valueOf(30000);
        };
    }

    private BigDecimal dailyFoodRate(BudgetLevel level) {
        return switch (level) {
            case LOW -> BigDecimal.valueOf(3500);
            case MID -> BigDecimal.valueOf(6500);
            case HIGH -> BigDecimal.valueOf(12000);
        };
    }

    private BigDecimal dailyTransportRate(String mode, BudgetLevel level) {
        String value = mode.toLowerCase(Locale.ROOT);
        if (value.contains("public")) return BigDecimal.valueOf(2500);
        if (value.contains("tuk")) return BigDecimal.valueOf(4500);
        if (value.contains("rental") || value.contains("private")) return BigDecimal.valueOf(12000);
        return switch (level) {
            case LOW -> BigDecimal.valueOf(3000);
            case MID -> BigDecimal.valueOf(6000);
            case HIGH -> BigDecimal.valueOf(12000);
        };
    }

    record GenerationTotals(
            BigDecimal accommodation,
            BigDecimal food,
            BigDecimal transport,
            BigDecimal activities) {
    }
}
