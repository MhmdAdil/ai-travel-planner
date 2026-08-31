package com.aitravelplanner.itinerary;

import java.math.BigDecimal;
import java.util.Comparator;
import java.util.List;
import org.springframework.stereotype.Component;

/**
 * Small offline seed from Sri Lanka's public Accommodation Information for Tourists dataset.
 * The published source has about 2,130 real records. This seed keeps itinerary generation usable
 * offline; it deliberately does not fabricate 50,000 hotels. A normalization script is included
 * with the patch so the full public CSV can replace this seed later without code changes.
 */
@Component
class AccommodationCatalog {

    private static final List<AccommodationOption> OPTIONS = List.of(
            a("THE THEVA RESIDENCY", "Boutique Hotels", "Hantana, Kandy", 7.276036, 80.635411),
            a("HIGHLAND VILLA", "Boutique Hotels", "Weligama, Matara", 5.960334, 80.409972),
            a("ULAGALLA WALAWWA RESORT", "Boutique Hotels", "Thirappane, Anuradhapura", 8.205927, 80.545063),
            a("GALLE FORT HOTEL", "Boutique Hotels", "Church Street, Galle Fort", 6.026649, 80.217563),
            a("THE ELEPHANT CORRIDOR", "Boutique Hotels", "Pothana, Kibissa, Sigiriya", 7.943525, 80.710743),
            a("AMANWELLA", "Boutique Hotels", "Tangalle", 6.006174, 80.777376),
            a("ADITYA", "Boutique Hotels", "Rathgama, Galle", 6.094732, 80.134978),
            a("BUCKINGAM PLACE", "Boutique Hotels", "Rekawa, Tangalle", 6.047336, 80.855462),
            a("CLUB VILLA", "Boutique Hotels", "Bentota", 6.414093, 79.999034),
            a("SAMAN VILLAS", "Boutique Hotels", "Induruwa, Bentota", 6.395518, 80.004447),
            a("MANDARA RESORT", "Boutique Hotels", "Pelena, Mirissa / Weligama", 5.964016, 80.453836),
            a("VIL UYANA", "Boutique Hotels", "Sigiriya", 7.929710, 80.720275),
            a("TAMARIND HILL HOTEL", "Boutique Hotels", "Dadella, Galle", 6.044845, 80.197360),
            a("PARADISE ROAD TINTAGEL COLOMBO", "Boutique Hotels", "Colombo 07", 6.915033, 79.869959),
            a("BROOK BOUTIQUE", "Boutique Hotels", "Melsiripura, Kurunegala", 7.726939, 80.512511),
            a("THE FORTRESS", "Boutique Hotels", "Koggala, Galle", 5.986535, 80.326424),
            a("CASA COLOMBO", "Boutique Hotels", "Colombo 03", 6.888839, 79.857693),
            a("AMANGALLE", "Boutique Hotels", "Galle Fort", 6.028977, 80.216995),
            a("MAALU MAALU RESORTS & SPA", "Boutique Hotels", "Passikudah, Batticaloa", 7.928390, 81.561268),
            a("THE WALAWWA", "Boutique Hotels", "Kotugoda, Gampaha", 7.131981, 79.927908),
            a("BOULDER GARDEN", "Boutique Hotels", "Kalawana, Ratnapura", 6.514558, 80.385872),
            a("JIMS FARM VILLA", "Boutique Hotels", "Pallepola, Matale", 7.621357, 80.619922),
            a("LANGDALE RESORT & SPA", "Boutique Hotels", "Nanu Oya, Nuwara Eliya", 6.929208, 80.718066),
            a("THE FORT BAZAAR", "Boutique Hotels", "Galle Fort", 6.026844, 80.2154963),
            a("WATER GARDEN SIGIRIYA", "Boutique Hotels", "Kibissa, Sigiriya", 7.994399, 80.7441833),
            a("SOORIYA RESORT & SPA", "Boutique Hotels", "Rekawa Beach, Tangalle", 6.048141, 80.8635393),
            a("WILD COAST TENTED LODGE", "Boutique Hotels", "Palatupana, Yala", 6.2607399, 81.4064072),
            a("THE HABITAT", "Boutique Hotels", "Kosgoda", 6.3405694, 80.0258226),
            a("ROCK VILLA", "Boutique Villas", "Bentota", 6.413580, 79.9973733),
            a("MIRAGE KINGS COTTAGE", "Boutique Villas", "Nuwara Eliya", 6.9641218, 80.7723742),
            a("DUNKELD BUNGALOW", "Boutique Villas", "Dickoya, Hatton", 6.858082, 80.572933),
            a("SUMMERVILLE", "Boutique Villas", "Dickoya, Hatton", 6.867271, 80.580983),
            a("MIRISSA HILLS", "Boutique Villas", "Mirissa", 5.963842, 80.465105),
            a("WILD GRASS NATURE RESORT", "Boutique Villas", "Sigiriya", 7.904267, 80.724371),
            a("NORWOOD BUNGALOW", "Boutique Villas", "Nuwara Eliya", 6.834541, 80.604130),
            a("VILLA SAFFRON", "Boutique Villas", "Hikkaduwa", 6.122220, 80.113700),
            a("MOUNT HAVANA LUXURY BOUTIQUE VILLA", "Boutique Villas", "Gampola", 7.144944, 80.599521),
            a("LAKE LODGE BOUTIQUE HOTEL", "Boutique Villas", "Kandalama, Dambulla", 7.863126, 80.690316),
            a("MOUNT BATTEN BUNGALOW", "Boutique Villas", "Kandy", 7.255123, 80.619447),
            a("ELLERTON HOTEL", "Boutique Villas", "Gampola", 7.187229, 80.629261),
            a("ROSYTH ESTATE HOUSE", "Boutique Villas", "Kegalle", 7.276954, 80.352821),
            a("ERAELIYA VILLAS AND GARDENS", "Boutique Villas", "Weligama", 5.958113, 80.413849),
            a("WATERSIDE BENTOTA", "Boutique Villas", "Bentota", 6.430846, 80.007114),
            a("COCO BAY", "Boutique Villas", "Unawatuna", 6.027435, 80.243972),
            a("REEF VILLA & SPA", "Boutique Villas", "Wadduwa, Kalutara", 6.658974, 79.928253),
            a("DVILLAS LUXURY", "Boutique Villas", "Nawala, Colombo", 6.8864696, 79.887256),
            a("ERA BEACH HOTEL", "Boutique Villas", "Thalpe, Galle", 5.9984781, 80.2727742),
            a("THE RIVER HOUSE", "Boutique Villas", "Balapitiya", 6.260578, 80.043303),
            a("KAHANDA KANDA", "Boutique Villas", "Galle", 6.020899, 80.345978),
            a("APA VILLA", "Boutique Villas", "Thalpe, Galle", 6.041730, 80.272720)
    );

    AccommodationOption nearest(double latitude, double longitude, BudgetLevel level, int groupSize) {
        AccommodationOption nearest = OPTIONS.stream()
                .min(Comparator.comparingDouble(option -> NationwidePlaceCatalog.distanceKm(
                        latitude, longitude, option.latitude(), option.longitude())))
                .orElse(OPTIONS.get(0));
        int rooms = Math.max(1, (groupSize + 1) / 2);
        BigDecimal perRoom = switch (level) {
            case LOW -> BigDecimal.valueOf(6_500);
            case MID -> BigDecimal.valueOf(15_000);
            case HIGH -> BigDecimal.valueOf(40_000);
        };
        return nearest.withEstimatedNightCost(perRoom.multiply(BigDecimal.valueOf(rooms)));
    }


    List<AccommodationOption> alternatives(
            double latitude,
            double longitude,
            BudgetLevel level,
            int groupSize,
            String excludeName,
            int limit) {
        int rooms = Math.max(1, (groupSize + 1) / 2);
        BigDecimal perRoom = switch (level) {
            case LOW -> BigDecimal.valueOf(6_500);
            case MID -> BigDecimal.valueOf(15_000);
            case HIGH -> BigDecimal.valueOf(40_000);
        };
        BigDecimal nightCost = perRoom.multiply(BigDecimal.valueOf(rooms));
        return OPTIONS.stream()
                .filter(option -> excludeName == null || !option.name().equalsIgnoreCase(excludeName))
                .sorted(Comparator.comparingDouble(option -> NationwidePlaceCatalog.distanceKm(
                        latitude, longitude, option.latitude(), option.longitude())))
                .limit(Math.max(0, limit))
                .map(option -> option.withEstimatedNightCost(nightCost))
                .toList();
    }

    java.util.Optional<AccommodationOption> findByName(String name, BudgetLevel level, int groupSize) {
        if (name == null || name.isBlank()) return java.util.Optional.empty();
        int rooms = Math.max(1, (groupSize + 1) / 2);
        BigDecimal perRoom = switch (level) {
            case LOW -> BigDecimal.valueOf(6_500);
            case MID -> BigDecimal.valueOf(15_000);
            case HIGH -> BigDecimal.valueOf(40_000);
        };
        BigDecimal nightCost = perRoom.multiply(BigDecimal.valueOf(rooms));
        return OPTIONS.stream()
                .filter(option -> option.name().equalsIgnoreCase(name))
                .findFirst()
                .map(option -> option.withEstimatedNightCost(nightCost));
    }

    private static AccommodationOption a(String name, String type, String address, double lat, double lng) {
        return new AccommodationOption(name, type, address, lat, lng, BigDecimal.ZERO);
    }

    record AccommodationOption(
            String name,
            String type,
            String address,
            double latitude,
            double longitude,
            BigDecimal estimatedNightCostLkr) {
        AccommodationOption withEstimatedNightCost(BigDecimal cost) {
            return new AccommodationOption(name, type, address, latitude, longitude, cost);
        }
    }
}
