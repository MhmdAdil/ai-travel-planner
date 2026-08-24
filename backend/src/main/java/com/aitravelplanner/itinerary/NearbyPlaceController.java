package com.aitravelplanner.itinerary;

import com.aitravelplanner.itinerary.dto.NearbyPlaceResponse;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import java.math.BigDecimal;
import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/places")
@Validated
public class NearbyPlaceController {

    private final NearbyPlaceService nearbyPlaceService;

    NearbyPlaceController(NearbyPlaceService nearbyPlaceService) {
        this.nearbyPlaceService = nearbyPlaceService;
    }

    @GetMapping("/nearby")
    public List<NearbyPlaceResponse> nearby(
            @RequestParam @DecimalMin("-90.0") @DecimalMax("90.0") BigDecimal lat,
            @RequestParam @DecimalMin("-180.0") @DecimalMax("180.0") BigDecimal lng,
            @RequestParam(name = "radius") @DecimalMin("0.1") @DecimalMax("10.0") BigDecimal radiusKm,
            @RequestParam(name = "activities", defaultValue = "") String activities) {
        return nearbyPlaceService.find(
                lat.doubleValue(), lng.doubleValue(), radiusKm.doubleValue(), parseActivities(activities));
    }

    private Set<String> parseActivities(String activities) {
        if (activities == null || activities.isBlank()) return Set.of();
        Set<String> parsed = new LinkedHashSet<>();
        Arrays.stream(activities.split(","))
                .map(String::trim)
                .filter(value -> !value.isBlank())
                .forEach(parsed::add);
        return Set.copyOf(parsed);
    }
}
