package com.aitravelplanner.itinerary;

import com.aitravelplanner.itinerary.dto.RouteResponse;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import java.math.BigDecimal;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/places")
@Validated
public class RouteController {

    private final OsmRoutingClient routingClient;

    RouteController(OsmRoutingClient routingClient) {
        this.routingClient = routingClient;
    }

    @GetMapping("/route")
    public RouteResponse route(
            @RequestParam @DecimalMin("-90") @DecimalMax("90") BigDecimal startLat,
            @RequestParam @DecimalMin("-180") @DecimalMax("180") BigDecimal startLng,
            @RequestParam @DecimalMin("-90") @DecimalMax("90") BigDecimal endLat,
            @RequestParam @DecimalMin("-180") @DecimalMax("180") BigDecimal endLng) {
        return routingClient.route(
                startLat.doubleValue(), startLng.doubleValue(), endLat.doubleValue(), endLng.doubleValue());
    }
}
