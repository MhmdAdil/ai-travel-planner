package com.aitravelplanner.itinerary;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.util.List;
import org.junit.jupiter.api.Test;

class PlaceSearchServiceTest {

    private final OsmPlaceClient osmPlaceClient = mock(OsmPlaceClient.class);
    private final PlaceCatalog fallbackCatalog = new PlaceCatalog();

    @Test
    void returnsLiveOpenStreetMapPlacesWhenProviderSucceeds() {
        PlaceTemplate livePlace = new PlaceTemplate(
                "Live Museum",
                "Culture",
                "Live place",
                "Kandy",
                120,
                BigDecimal.valueOf(2_000),
                BigDecimal.ONE,
                7.29,
                80.63,
                "OPENSTREETMAP",
                "node/1",
                "https://www.openstreetmap.org/node/1");
        when(osmPlaceClient.find("Kandy")).thenReturn(new OsmPlaceClient.LivePlaceResult(
                new OsmPlaceClient.DestinationPoint("Kandy", 7.29, 80.63),
                List.of(livePlace)));

        PlaceSearchResult result = new PlaceSearchService(osmPlaceClient, fallbackCatalog, true)
                .findPlaces("Kandy");

        assertThat(result.generatorType()).isEqualTo("OPENSTREETMAP_LIVE");
        assertThat(result.places()).containsExactly(livePlace);
        assertThat(result.destinationLatitude()).isEqualTo(7.29);
    }

    @Test
    void fallsBackWithoutFailingItineraryWhenPublicProviderFails() {
        when(osmPlaceClient.find("Kandy")).thenThrow(new PlaceProviderException("Unavailable"));

        PlaceSearchResult result = new PlaceSearchService(osmPlaceClient, fallbackCatalog, true)
                .findPlaces("Kandy");

        assertThat(result.generatorType()).isEqualTo("FALLBACK_CATALOG");
        assertThat(result.places()).isNotEmpty();
        assertThat(result.providerNote()).contains("unavailable");
    }
}
