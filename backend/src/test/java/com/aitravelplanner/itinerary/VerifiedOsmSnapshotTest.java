package com.aitravelplanner.itinerary;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Set;
import org.junit.jupiter.api.Test;

class VerifiedOsmSnapshotTest {

    private static final double COLOMBO_LATITUDE = 6.9271;
    private static final double COLOMBO_LONGITUDE = 79.8612;

    @Test
    void oneKilometreDoesNotIncludePlacesOutsideTheRadius() {
        assertThat(VerifiedOsmSnapshot.findNearby(
                COLOMBO_LATITUDE, COLOMBO_LONGITUDE, 1_000, Set.of("Beaches")))
                .isEmpty();
    }

    @Test
    void tenKilometresContainsEveryFiveKilometreBeach() {
        var fiveKilometres = VerifiedOsmSnapshot.findNearby(
                COLOMBO_LATITUDE, COLOMBO_LONGITUDE, 5_000, Set.of("Beaches"));
        var tenKilometres = VerifiedOsmSnapshot.findNearby(
                COLOMBO_LATITUDE, COLOMBO_LONGITUDE, 10_000, Set.of("Beaches"));

        assertThat(fiveKilometres).isNotEmpty();
        assertThat(tenKilometres)
                .extracting(PlaceTemplate::sourceReference)
                .containsAll(fiveKilometres.stream().map(PlaceTemplate::sourceReference).toList());
    }

    @Test
    void activityFiltersReturnOnlyMatchingOpenDataRecords() {
        var temples = VerifiedOsmSnapshot.findNearby(
                COLOMBO_LATITUDE, COLOMBO_LONGITUDE, 10_000, Set.of("Temples"));

        assertThat(temples).isNotEmpty();
        assertThat(temples).allMatch(place -> place.category().equals("Temples"));
        assertThat(temples).extracting(PlaceTemplate::name).contains("Gangaramaya Temple");
    }

    @Test
    void nationwideFallbackReturnsKandyPlacesNearKandy() {
        var kandyPlaces = VerifiedOsmSnapshot.findNearby(
                7.2906, 80.6337, 10_000, Set.of("Temples", "Nature & Parks"));

        var natureAndParkCategories = Set.of(
                "Nature",
                "Wildlife",
                "Waterfalls",
                "Rivers",
                "Ponds & Lakes",
                "Rocks & Caves",
                "Mountains & Peaks",
                "Forests",
                "Gardens",
                "Hot Springs");

        assertThat(kandyPlaces).extracting(PlaceTemplate::name)
                .contains(
                        "Temple of the Sacred Tooth Relic",
                        "Bahirawakanda Temple",
                        "Royal Palace Park",
                        "Torrington Public Park");
        assertThat(kandyPlaces).allMatch(place ->
                place.category().equals("Temples")
                        || natureAndParkCategories.contains(place.category()));
    }

    @Test
    void nationwideIndexReturnsFoodPlacesNearChilawWithoutLiveOverpass() {
        var chilawFood = VerifiedOsmSnapshot.findNearby(
                7.5777, 79.7944, 5_000, Set.of("Food & Cafes"));

        assertThat(chilawFood).isNotEmpty();
        assertThat(chilawFood).allMatch(place -> place.category().equals("Food"));
        assertThat(chilawFood).extracting(PlaceTemplate::name)
                .contains("Sri Ram Pastry", "Clement's Chilaw");
    }

    @Test
    void openDataContinuityDatasetCoversMultipleSriLankanRegions() {
        assertThat(VerifiedOsmSnapshot.size()).isGreaterThanOrEqualTo(23_000);
    }

    @Test
    void nationwideIndexContainsEveryRequestedNewActivityCategory() {
        var requestedCategories = Set.of(
                "Waterfalls", "Rivers", "Ponds & Lakes", "Rocks & Caves",
                "Mountains & Peaks", "Farms", "Forests", "Shopping Malls", "Water Parks");

        for (String category : requestedCategories) {
            var results = VerifiedOsmSnapshot.findNearby(
                    7.8731, 80.7718, 500_000, Set.of(category));
            assertThat(results)
                    .as("nationwide offline records for %s", category)
                    .isNotEmpty()
                    .allMatch(place -> place.category().equals(category));
        }
    }

    @Test
    void sparseLocationNeverReturnsActivitiesOutsideTheSelectedRadius() {
        var exact = VerifiedOsmSnapshot.findNearby(
                7.6091, 79.9751, 10_000, Set.of("Food & Cafes"));

        assertThat(exact).allMatch(place -> place.distanceKm().doubleValue() <= 10.0);
    }

    @Test
    void everyNationwideResultRespectsItsRequestedRadius() {
        var locations = java.util.List.of(
                new double[] {6.9271, 79.8612},
                new double[] {7.2906, 80.6337},
                new double[] {7.6091, 79.9751},
                new double[] {9.6615, 80.0255},
                new double[] {6.9497, 80.7891});

        for (double[] location : locations) {
            var results = VerifiedOsmSnapshot.findNearby(
                    location[0], location[1], 5_000,
                    Set.of("Food & Cafes", "Temples", "Nature & Parks", "Attractions"));
            assertThat(results).allMatch(place -> place.distanceKm().doubleValue() <= 5.0);
            assertThat(results).allMatch(place ->
                    place.sourceUrl() != null && !place.sourceUrl().isBlank());
        }
    }
}
