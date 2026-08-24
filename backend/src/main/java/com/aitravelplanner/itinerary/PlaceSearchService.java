package com.aitravelplanner.itinerary;

import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
class PlaceSearchService {

    private static final Logger log = LoggerFactory.getLogger(PlaceSearchService.class);

    private final OsmPlaceClient osmPlaceClient;
    private final PlaceCatalog fallbackCatalog;
    private final boolean liveEnabled;

    PlaceSearchService(
            OsmPlaceClient osmPlaceClient,
            PlaceCatalog fallbackCatalog,
            @Value("${app.places.live-enabled:true}") boolean liveEnabled) {
        this.osmPlaceClient = osmPlaceClient;
        this.fallbackCatalog = fallbackCatalog;
        this.liveEnabled = liveEnabled;
    }

    PlaceSearchResult findPlaces(String destinationRegion) {
        if (liveEnabled) {
            try {
                OsmPlaceClient.LivePlaceResult live = osmPlaceClient.find(destinationRegion);
                return new PlaceSearchResult(
                        live.places(),
                        "OPENSTREETMAP_LIVE",
                        "Live places from OpenStreetMap. Activity prices remain planning estimates.",
                        live.destination().latitude(),
                        live.destination().longitude());
            } catch (RuntimeException exception) {
                log.warn("Live place lookup failed for '{}'; using the fallback catalogue: {}",
                        destinationRegion, exception.getMessage());
            }
        }

        List<PlaceTemplate> fallback = fallbackCatalog.forRegion(destinationRegion);
        return new PlaceSearchResult(
                fallback,
                "FALLBACK_CATALOG",
                liveEnabled
                        ? "The live place service was unavailable, so the verified development catalogue was used."
                        : "Live place lookup is disabled in this environment; the development catalogue was used.",
                null,
                null);
    }
}
