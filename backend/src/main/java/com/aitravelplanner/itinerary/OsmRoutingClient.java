package com.aitravelplanner.itinerary;

import com.aitravelplanner.itinerary.dto.RoutePointResponse;
import com.aitravelplanner.itinerary.dto.RouteResponse;
import com.fasterxml.jackson.databind.JsonNode;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Component
class OsmRoutingClient {

    private final RestClient restClient;
    private final String routingUrl;
    private final String userAgent;

    OsmRoutingClient(
            RestClient.Builder builder,
            @Value("${app.places.routing-url:https://router.project-osrm.org}") String routingUrl,
            @Value("${app.places.user-agent:AITravelPlannerUniversityProject/0.4}") String userAgent) {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(Duration.ofSeconds(6));
        factory.setReadTimeout(Duration.ofSeconds(15));
        this.restClient = builder.requestFactory(factory).build();
        this.routingUrl = routingUrl.replaceAll("/+$", "");
        this.userAgent = userAgent;
    }

    RouteResponse route(double startLat, double startLng, double endLat, double endLng) {
        String coordinates = startLng + "," + startLat + ";" + endLng + "," + endLat;
        try {
            JsonNode response = restClient.get()
                    .uri(routingUrl + "/route/v1/driving/" + coordinates
                            + "?overview=full&geometries=geojson&steps=false")
                    .header("User-Agent", userAgent)
                    .retrieve()
                    .body(JsonNode.class);
            return parse(response);
        } catch (RestClientException exception) {
            throw new PlaceProviderException("Directions are temporarily unavailable.", exception);
        }
    }

    static RouteResponse parse(JsonNode response) {
        JsonNode route = response == null ? null : response.path("routes").path(0);
        JsonNode coordinates = route == null ? null : route.path("geometry").path("coordinates");
        if (coordinates == null || !coordinates.isArray() || coordinates.size() < 2) {
            throw new PlaceProviderException("No road route was found for this place.");
        }
        List<RoutePointResponse> points = new ArrayList<>();
        for (JsonNode coordinate : coordinates) {
            if (coordinate.isArray() && coordinate.size() >= 2) {
                points.add(new RoutePointResponse(coordinate.get(1).asDouble(), coordinate.get(0).asDouble()));
            }
        }
        BigDecimal distanceKm = BigDecimal.valueOf(route.path("distance").asDouble() / 1_000.0)
                .setScale(1, RoundingMode.HALF_UP);
        long minutes = Math.max(1, Math.round(route.path("duration").asDouble() / 60.0));
        return new RouteResponse(List.copyOf(points), distanceKm, minutes);
    }
}
