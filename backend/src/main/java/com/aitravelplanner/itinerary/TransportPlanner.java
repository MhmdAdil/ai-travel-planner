package com.aitravelplanner.itinerary;

import com.aitravelplanner.itinerary.dto.TransportOptionResponse;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.springframework.stereotype.Component;

@Component
class TransportPlanner {

    private static final String DATASET = "/open-data/sri-lanka-transport-options.csv";
    private final Map<String, List<Profile>> byPlace = load();

    List<TransportOptionResponse> options(
            String sourceReference,
            String region,
            BigDecimal distanceKm,
            int groupSize,
            BudgetLevel budgetLevel) {

        List<Profile> profiles = sourceReference == null ? List.of() : byPlace.getOrDefault(sourceReference, List.of());
        if (profiles.isEmpty()) profiles = fallbackProfiles(region);

        double distance = Math.max(0.0, distanceKm == null ? 0.0 : distanceKm.doubleValue());
        List<TransportOptionResponse> result = new ArrayList<>();
        for (Profile profile : profiles) {
            if (groupSize > profile.capacity()) continue;
            BigDecimal fare = fare(profile, distance, groupSize);
            int minutes = minutes(profile.type(), distance);
            result.add(new TransportOptionResponse(
                    profile.type(),
                    profile.vehicleModel(),
                    profile.serviceName(),
                    profile.capacity(),
                    minutes,
                    fare,
                    fareNote(profile),
                    profile.source()));
        }

        Comparator<TransportOptionResponse> comparator = Comparator
                .comparingInt((TransportOptionResponse option) -> priority(option.type(), budgetLevel))
                .thenComparing(TransportOptionResponse::estimatedFareLkr);
        return result.stream().sorted(comparator).limit(4).toList();
    }

    BigDecimal preferredCost(
            String sourceReference,
            String region,
            BigDecimal distanceKm,
            int groupSize,
            BudgetLevel level) {
        return options(sourceReference, region, distanceKm, groupSize, level).stream()
                .findFirst()
                .map(TransportOptionResponse::estimatedFareLkr)
                .orElse(BigDecimal.ZERO);
    }

    private int priority(String type, BudgetLevel level) {
        String normalized = type.toLowerCase(Locale.ROOT);
        if (level == BudgetLevel.LOW) {
            if (normalized.equals("train")) return 0;
            if (normalized.equals("bus")) return 1;
            if (normalized.contains("tuk")) return 2;
            return 3;
        }
        if (level == BudgetLevel.MID) {
            if (normalized.equals("train") || normalized.equals("bus")) return 0;
            if (normalized.contains("car") || normalized.contains("tuk")) return 1;
            return 2;
        }
        if (normalized.contains("car") || normalized.contains("minivan") || normalized.contains("van")) return 0;
        if (normalized.equals("train")) return 1;
        return 2;
    }

    private BigDecimal fare(Profile p, double distanceKm, int groupSize) {
        double chargeableExtra = Math.max(0.0, distanceKm - 1.0);
        double amount = p.minimumFareLkr() + chargeableExtra * p.perKmLkr();
        if (p.perPassenger()) amount *= Math.max(1, groupSize);
        return BigDecimal.valueOf(amount).setScale(0, RoundingMode.HALF_UP);
    }

    private int minutes(String type, double distanceKm) {
        if (distanceKm <= 0) return 0;
        double speed = switch (type.toLowerCase(Locale.ROOT)) {
            case "train" -> 42.0;
            case "bus" -> 30.0;
            case "tuk tuk" -> 28.0;
            default -> 40.0;
        };
        return Math.max(10, (int) Math.ceil(distanceKm / speed * 60));
    }

    private String fareNote(Profile p) {
        if (p.source().equals("USER_PLANNING_ASSUMPTION")) {
            return "Ride-hailing planning estimate using the supplied first-kilometre minimum and per-kilometre assumption; live app fare can differ.";
        }
        if (p.type().equals("Train")) {
            return "Planning estimate only. Confirm the actual train, class, seat availability and fare with Sri Lanka Railways.";
        }
        return "Planning estimate only. Confirm the exact route, service and current fare with the National Transport Commission/operator.";
    }

    private Map<String, List<Profile>> load() {
        Map<String, List<Profile>> result = new HashMap<>();
        try (InputStream input = TransportPlanner.class.getResourceAsStream(DATASET)) {
            if (input == null) return result;
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(input, StandardCharsets.UTF_8))) {
                String line = reader.readLine();
                while ((line = reader.readLine()) != null) {
                    String[] c = line.split("\\t", -1);
                    if (c.length < 11) continue;
                    Profile profile = new Profile(
                            c[2], c[3], c[4], Integer.parseInt(c[5]),
                            Double.parseDouble(c[6]), Double.parseDouble(c[7]),
                            Boolean.parseBoolean(c[8]), c[9], c[1]);
                    result.computeIfAbsent(c[0], ignored -> new ArrayList<>()).add(profile);
                }
            }
        } catch (IOException | RuntimeException ignored) {
            return Map.of();
        }
        return result;
    }

    private List<Profile> fallbackProfiles(String region) {
        List<Profile> profiles = new ArrayList<>();
        profiles.add(new Profile("Bus", "Public bus", "Intercity / SLTB / private bus", 45, 40, 6.5, true, "NTC_FARE_POLICY", region));
        profiles.add(new Profile("Tuk Tuk", "Tuk Tuk", "PickMe / Uber-type ride", 3, 200, 80, false, "USER_PLANNING_ASSUMPTION", region));
        profiles.add(new Profile("Car", "Car", "PickMe / Uber-type ride", 4, 450, 98, false, "USER_PLANNING_ASSUMPTION", region));
        profiles.add(new Profile("Minivan", "Minivan", "PickMe / Uber-type ride", 7, 800, 120, false, "USER_PLANNING_ASSUMPTION", region));
        profiles.add(new Profile("Van", "Van", "PickMe / Uber-type ride", 15, 1500, 175, false, "USER_PLANNING_ASSUMPTION", region));
        if (railService(region) != null) {
            profiles.add(new Profile("Train", "Train", railService(region), 500, 50, 4, true, "SRI_LANKA_RAILWAYS", region));
        }
        return profiles;
    }

    static String railService(String region) {
        if (region == null) return null;
        String r = region.toLowerCase(Locale.ROOT);
        if (r.contains("kandy") || r.contains("nuwara") || r.contains("haputale") || r.contains("ella")) {
            return "Main Line (e.g. Udarata Menike / Podi Menike where scheduled)";
        }
        if (r.contains("galle") || r.contains("mirissa") || r.contains("weligama") || r.contains("bentota") || r.contains("colombo")) {
            return "Coast Line service where scheduled";
        }
        if (r.contains("negombo") || r.contains("katunayake") || r.contains("kalpitiya")) {
            return "Puttalam Line service where scheduled";
        }
        if (r.contains("anuradhapura") || r.contains("jaffna")) return "Northern Line service where scheduled";
        if (r.contains("trincomalee")) return "Trincomalee Line service where scheduled";
        if (r.contains("polonnaruwa")) return "Batticaloa Line service where scheduled";
        return null;
    }

    private record Profile(
            String type,
            String vehicleModel,
            String serviceName,
            int capacity,
            double minimumFareLkr,
            double perKmLkr,
            boolean perPassenger,
            String source,
            String region) {
    }
}
