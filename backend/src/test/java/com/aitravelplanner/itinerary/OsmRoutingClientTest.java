package com.aitravelplanner.itinerary;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

class OsmRoutingClientTest {
    @Test
    void parsesGeoJsonLongitudeLatitudeOrder() throws Exception {
        var json = new ObjectMapper().readTree("""
                {"routes":[{"distance":2500,"duration":600,"geometry":{"coordinates":[[79.86,6.92],[79.87,6.93]]}}]}
                """);
        var route = OsmRoutingClient.parse(json);
        assertThat(route.distanceKm()).isEqualByComparingTo("2.5");
        assertThat(route.durationMinutes()).isEqualTo(10);
        assertThat(route.points().getFirst().latitude()).isEqualTo(6.92);
        assertThat(route.points().getFirst().longitude()).isEqualTo(79.86);
    }
}
