package com.aitravelplanner.itinerary;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.util.List;
import org.junit.jupiter.api.Test;

class OsmPlaceClientRadiusTest {

    private static final OsmPlaceClient.DestinationPoint COLOMBO =
            new OsmPlaceClient.DestinationPoint("Colombo", 6.9271, 79.8612);

    @Test
    void tenKilometresKeepsConfirmedFiveKilometrePlaces() {
        PlaceTemplate goldenBeach = place(
                "Golden Beach", "way/1357708800", 6.9291029, 79.8248767, "3.95");
        PlaceTemplate galleFaceGreen = place(
                "Galle Face Green", "way/27712165", 6.9249607, 79.8444586, "1.88");

        List<PlaceTemplate> result = OsmPlaceClient.mergeNearbyPlaces(
                List.of(goldenBeach), List.of(galleFaceGreen), COLOMBO, 10_000);

        assertThat(result)
                .extracting(PlaceTemplate::name)
                .containsExactly("Galle Face Green", "Golden Beach");
    }

    @Test
    void fiveKilometresKeepsConfirmedOneKilometrePlaces() {
        PlaceTemplate nearbyTemple = place(
                "Nearby Temple", "node/100", 6.9280, 79.8612, "0.10");
        PlaceTemplate widerBeach = place(
                "Wider Beach", "way/200", 6.9291, 79.8249, "3.95");

        List<PlaceTemplate> result = OsmPlaceClient.mergeNearbyPlaces(
                List.of(nearbyTemple), List.of(widerBeach), COLOMBO, 5_000);

        assertThat(result)
                .extracting(PlaceTemplate::name)
                .containsExactly("Nearby Temple", "Wider Beach");
    }

    @Test
    void oneKilometreDoesNotIncludeAPlaceThreeKilometresAway() {
        PlaceTemplate goldenBeach = place(
                "Golden Beach", "way/1357708800", 6.9291029, 79.8248767, "3.95");

        List<PlaceTemplate> result = OsmPlaceClient.mergeNearbyPlaces(
                List.of(goldenBeach), List.of(), COLOMBO, 1_000);

        assertThat(result).isEmpty();
    }

    @Test
    void mergingTheSameOsmReferenceDoesNotCreateDuplicateMarkers() {
        PlaceTemplate goldenBeach = place(
                "Golden Beach", "way/1357708800", 6.9291029, 79.8248767, "3.95");

        List<PlaceTemplate> result = OsmPlaceClient.mergeNearbyPlaces(
                List.of(goldenBeach), List.of(goldenBeach), COLOMBO, 10_000);

        assertThat(result).hasSize(1);
    }

    private PlaceTemplate place(
            String name, String reference, double latitude, double longitude, String distanceKm) {
        return new PlaceTemplate(
                name,
                "Beaches",
                "OpenStreetMap-listed waterfront place.",
                "Colombo",
                180,
                BigDecimal.ZERO,
                new BigDecimal(distanceKm),
                latitude,
                longitude,
                "OPENSTREETMAP",
                reference,
                "https://www.openstreetmap.org/" + reference);
    }
}
