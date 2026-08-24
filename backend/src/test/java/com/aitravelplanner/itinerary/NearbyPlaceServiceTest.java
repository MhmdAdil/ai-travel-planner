package com.aitravelplanner.itinerary;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.util.Set;
import org.junit.jupiter.api.Test;

class NearbyPlaceServiceTest {

    @Test
    void doesNotReturnDemonstrationPlacesWhenEveryLiveProviderFails() {
        OsmPlaceClient client = mock(OsmPlaceClient.class);
        when(client.findNearby(6.9271, 79.8612, 1.0, Set.of()))
                .thenThrow(new PlaceProviderException("Live providers unavailable"));

        NearbyPlaceService service = new NearbyPlaceService(client);

        assertThatThrownBy(() -> service.find(6.9271, 79.8612, 1.0))
                .isInstanceOf(PlaceProviderException.class)
                .hasMessageContaining("Live providers unavailable");
    }
}
