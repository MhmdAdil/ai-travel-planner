package com.aitravelplanner.itinerary;

import com.fasterxml.jackson.databind.JsonNode;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorCompletionService;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Component
class OsmPlaceClient {

    private static final Logger log = LoggerFactory.getLogger(OsmPlaceClient.class);
    private static final Duration CACHE_DURATION = Duration.ofHours(6);

    private final RestClient restClient;
    private final WikipediaSummaryClient wikipediaSummaryClient;
    private final String nominatimUrl;
    private final List<String> overpassUrls;
    private final String userAgent;
    private final int radiusMetres;
    private final Map<String, CacheEntry<DestinationPoint>> destinationCache = new ConcurrentHashMap<>();
    private final Map<String, CacheEntry<List<PlaceTemplate>>> placeCache = new ConcurrentHashMap<>();
    private long lastNominatimRequestMillis;

    OsmPlaceClient(
            RestClient.Builder restClientBuilder,
            WikipediaSummaryClient wikipediaSummaryClient,
            @Value("${app.places.nominatim-url:https://nominatim.openstreetmap.org}") String nominatimUrl,
            @Value("${app.places.overpass-url:https://overpass.private.coffee/api/interpreter}") String overpassUrl,
            @Value("${app.places.user-agent:AITravelPlannerUniversityProject/0.3}") String userAgent,
            @Value("${app.places.search-radius-metres:30000}") int radiusMetres) {
        SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
        requestFactory.setConnectTimeout(Duration.ofSeconds(8));
        requestFactory.setReadTimeout(Duration.ofSeconds(35));
        this.restClient = restClientBuilder.requestFactory(requestFactory).build();
        this.wikipediaSummaryClient = wikipediaSummaryClient;
        this.nominatimUrl = nominatimUrl;
        LinkedHashSet<String> endpoints = new LinkedHashSet<>();
        endpoints.add(overpassUrl);
        endpoints.add("https://overpass.private.coffee/api/interpreter");
        endpoints.add("https://overpass-api.de/api/interpreter");
        endpoints.add("https://overpass.kumi.systems/api/interpreter");
        endpoints.add("https://overpass.nchc.org.tw/api/interpreter");
        this.overpassUrls = endpoints.stream()
                .filter(url -> url != null && !url.isBlank())
                .map(String::trim)
                .toList();
        this.userAgent = userAgent;
        this.radiusMetres = radiusMetres;
    }

    LivePlaceResult find(String destinationRegion) {
        DestinationPoint destination = geocode(destinationRegion)
                .orElseThrow(() -> new PlaceProviderException("Destination could not be found in Sri Lanka."));
        String cacheKey = "destination:" + destinationRegion.trim().toLowerCase(Locale.ROOT);
        List<PlaceTemplate> places = cached(placeCache, cacheKey)
                .orElseGet(() -> {
                    List<PlaceTemplate> fetched = queryPlaces(
                            destinationRegion, destination, radiusMetres, 180);
                    placeCache.put(cacheKey, new CacheEntry<>(fetched, Instant.now()));
                    return fetched;
                });
        return new LivePlaceResult(destination, places);
    }

    List<PlaceTemplate> findNearby(double latitude, double longitude, double radiusKm) {
        return findNearby(latitude, longitude, radiusKm, Set.of());
    }

    List<PlaceTemplate> findNearby(
            double latitude, double longitude, double radiusKm, Set<String> activityFilters) {
        int requestedRadius = Math.max(100, (int) Math.round(radiusKm * 1_000));
        String filterKey = activityFilters.stream()
                .map(value -> value.toLowerCase(Locale.ROOT))
                .sorted()
                .collect(Collectors.joining("|"));
        String key = nearbyCacheKey(latitude, longitude, requestedRadius, filterKey);
        return cached(placeCache, key).orElseGet(() -> {
            DestinationPoint center = new DestinationPoint("Current map location", latitude, longitude);
            List<PlaceTemplate> verifiedPlaces = VerifiedOsmSnapshot.findNearby(
                    latitude, longitude, requestedRadius, activityFilters);

            // A wider radius must retain every successful matching result already confirmed at
            // 1 km or 5 km. This also protects the UI from temporary differences between public
            // Overpass servers without inventing or moving any location.
            List<PlaceTemplate> confirmedInnerPlaces = cachedInnerRadiusBaselines(
                    center, requestedRadius, filterKey);
            List<PlaceTemplate> baselinePlaces = mergeNearbyPlaces(
                    verifiedPlaces, confirmedInnerPlaces, center, requestedRadius);
            List<PlaceTemplate> fetched;
            try {
                fetched = queryPlaces(
                        "your location", center, requestedRadius,
                        activityFilters.isEmpty() ? 1_500 : 2_500, activityFilters, true);
            } catch (PlaceProviderException exception) {
                log.warn(
                        "The {} m live query failed; returning {} places from the bundled nationwide OSM index",
                        requestedRadius, baselinePlaces.size(), exception);
                // A temporary public Overpass outage is not a Discover-page failure. The bundled
                // nationwide index supplies only genuine records inside the requested radius.
                cacheNonEmptyPlaces(key, baselinePlaces);
                return baselinePlaces;
            }
            List<PlaceTemplate> merged = mergeNearbyPlaces(
                    baselinePlaces, fetched, center, requestedRadius);
            cacheNonEmptyPlaces(key, merged);
            return merged;
        });
    }

    private List<PlaceTemplate> cachedInnerRadiusBaselines(
            DestinationPoint center, int requestedRadius, String filterKey) {
        List<PlaceTemplate> confirmed = List.of();
        for (int baselineRadius : List.of(1_000, 5_000)) {
            if (baselineRadius >= requestedRadius) continue;
            String baselineKey = nearbyCacheKey(
                    center.latitude(), center.longitude(), baselineRadius, filterKey);
            List<PlaceTemplate> baseline = cached(placeCache, baselineKey).orElse(List.of());
            confirmed = mergeNearbyPlaces(confirmed, baseline, center, requestedRadius);
        }
        return confirmed;
    }

    private void cacheNonEmptyPlaces(String key, List<PlaceTemplate> places) {
        if (!places.isEmpty()) {
            placeCache.put(key, new CacheEntry<>(places, Instant.now()));
        } else {
            // Empty live responses can be caused by a transient public-server timeout or an
            // incomplete response. Never make that temporary condition persist for six hours.
            placeCache.remove(key);
        }
    }

    private String nearbyCacheKey(
            double latitude, double longitude, int requestedRadius, String filterKey) {
        return "nearby:%.4f:%.4f:%d:%s"
                .formatted(latitude, longitude, requestedRadius, filterKey);
    }

    static List<PlaceTemplate> mergeNearbyPlaces(
            List<PlaceTemplate> innerPlaces,
            List<PlaceTemplate> widerPlaces,
            DestinationPoint center,
            int requestedRadiusMetres) {
        Map<String, PlaceTemplate> merged = new LinkedHashMap<>();
        for (PlaceTemplate place : innerPlaces) {
            putIfInsideRadius(merged, place, center, requestedRadiusMetres);
        }
        for (PlaceTemplate place : widerPlaces) {
            putIfInsideRadius(merged, place, center, requestedRadiusMetres);
        }
        List<PlaceTemplate> ordered = new ArrayList<>(merged.values());
        ordered.sort((left, right) -> left.distanceKm().compareTo(right.distanceKm()));
        return List.copyOf(ordered);
    }

    private static void putIfInsideRadius(
            Map<String, PlaceTemplate> places,
            PlaceTemplate place,
            DestinationPoint center,
            int requestedRadiusMetres) {
        if (place.latitude() == null || place.longitude() == null) return;
        double actualDistance = haversineKilometres(
                center.latitude(), center.longitude(), place.latitude(), place.longitude());
        if (actualDistance > requestedRadiusMetres / 1_000.0) return;
        String identity = place.sourceReference() == null || place.sourceReference().isBlank()
                ? place.name().toLowerCase(Locale.ROOT)
                : place.sourceReference();
        places.putIfAbsent(identity, place);
    }

    private synchronized Optional<DestinationPoint> geocode(String destinationRegion) {
        String key = destinationRegion.trim().toLowerCase(Locale.ROOT);
        Optional<DestinationPoint> cached = cached(destinationCache, key);
        if (cached.isPresent()) return cached;

        waitForNominatimRateLimit();
        lastNominatimRequestMillis = System.currentTimeMillis();
        JsonNode response = restClient.get()
                .uri(nominatimUrl + "/search?q={query}&format=jsonv2&limit=1&countrycodes=lk",
                        destinationRegion + ", Sri Lanka")
                .header("User-Agent", userAgent)
                .header("Accept-Language", "en")
                .retrieve()
                .body(JsonNode.class);
        if (response == null || !response.isArray() || response.isEmpty()) return Optional.empty();

        JsonNode item = response.get(0);
        DestinationPoint point = new DestinationPoint(
                item.path("display_name").asText(destinationRegion),
                item.path("lat").asDouble(),
                item.path("lon").asDouble());
        destinationCache.put(key, new CacheEntry<>(point, Instant.now()));
        return Optional.of(point);
    }

    private void waitForNominatimRateLimit() {
        long waitMillis = 1_050 - (System.currentTimeMillis() - lastNominatimRequestMillis);
        if (waitMillis <= 0) return;
        try {
            Thread.sleep(waitMillis);
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new PlaceProviderException("Place search was interrupted.", exception);
        }
    }

    private List<PlaceTemplate> queryPlaces(
            String region,
            DestinationPoint destination,
            int requestedRadiusMetres,
            int resultLimit) {
        return queryPlaces(region, destination, requestedRadiusMetres, resultLimit, Set.of());
    }

    private List<PlaceTemplate> queryPlaces(
            String region,
            DestinationPoint destination,
            int requestedRadiusMetres,
            int resultLimit,
            Set<String> activityFilters) {
        return queryPlaces(
                region, destination, requestedRadiusMetres, resultLimit, activityFilters, false);
    }

    private List<PlaceTemplate> queryPlaces(
            String region,
            DestinationPoint destination,
            int requestedRadiusMetres,
            int resultLimit,
            Set<String> activityFilters,
            boolean allowEmptyResults) {
        int overpassTimeoutSeconds = requestedRadiusMetres >= 10_000 ? 35 : 25;
        log.info("Searching nearby OpenStreetMap data within {} m for {}",
                requestedRadiusMetres,
                activityFilters.isEmpty() ? "all supported activities" : activityFilters);
        String selectors = overpassSelectors(destination, requestedRadiusMetres, activityFilters);
        String query = """
                [out:json][timeout:%d];
                (
                %s
                );
                out center %d;
                """.formatted(
                overpassTimeoutSeconds, selectors, resultLimit);

        String body = "data=" + URLEncoder.encode(query, StandardCharsets.UTF_8);
        JsonNode response = firstValidOverpassResponse(body);
        if (response == null) {
            throw new PlaceProviderException(
                    "Live OpenStreetMap place data is temporarily unavailable. Please try again shortly.");
        }

        Map<String, PlaceTemplate> unique = new LinkedHashMap<>();
        for (JsonNode element : response.path("elements")) {
            JsonNode tags = element.path("tags");
            String name = preferredName(tags);
            if (name.isBlank()) continue;
            Double latitude = coordinate(element, "lat");
            Double longitude = coordinate(element, "lon");
            if (latitude == null || longitude == null) continue;

            String category = category(tags);
            if (!isReliableDiscoverPlace(tags, category)) continue;
            if (!matchesRequestedActivities(category, activityFilters)) continue;
            BigDecimal distance = haversine(
                    destination.latitude(), destination.longitude(), latitude, longitude);
            String type = element.path("type").asText("node");
            long id = element.path("id").asLong();
            String reference = type + "/" + id;
            String description = description(tags, name, category);
            FeeInfo fee = feeInfo(tags);
            PlaceTemplate place = new PlaceTemplate(
                    name,
                    category,
                    description,
                    address(tags, region),
                    visitMinutes(category),
                    estimatedEntryCost(category),
                    distance,
                    latitude,
                    longitude,
                    "OPENSTREETMAP",
                    reference,
                    "https://www.openstreetmap.org/" + reference,
                    tags.path("opening_hours").asText(),
                    firstNonBlank(tags.path("website").asText(), tags.path("contact:website").asText()),
                    firstNonBlank(tags.path("phone").asText(), tags.path("contact:phone").asText()),
                    fee.status(),
                    fee.details());
            unique.putIfAbsent(reference, place);
        }
        List<PlaceTemplate> places = new ArrayList<>(unique.values());
        places.sort((left, right) -> left.distanceKm().compareTo(right.distanceKm()));
        if (places.isEmpty() && !allowEmptyResults) {
            throw new PlaceProviderException("No named places were returned by OpenStreetMap.");
        }
        log.info("Loaded {} live OpenStreetMap places for {}", places.size(), region);
        return List.copyOf(places);
    }

    private JsonNode firstValidOverpassResponse(String body) {
        ExecutorService executor = Executors.newFixedThreadPool(overpassUrls.size());
        ExecutorCompletionService<JsonNode> completion = new ExecutorCompletionService<>(executor);
        JsonNode best = null;
        try {
            for (String endpoint : overpassUrls) {
                completion.submit(() -> fetchOverpass(endpoint, body));
            }
            long deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(38);
            long validResponseDeadline = Long.MAX_VALUE;
            for (int completed = 0; completed < overpassUrls.size(); completed++) {
                long remaining = Math.min(deadline, validResponseDeadline) - System.nanoTime();
                if (remaining <= 0) break;
                Future<JsonNode> future = completion.poll(remaining, TimeUnit.NANOSECONDS);
                if (future == null) break;
                JsonNode candidate = future.get();
                if (candidate == null) continue;
                if (best == null) {
                    best = candidate;
                    validResponseDeadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(3);
                } else if (candidate.path("elements").size() > best.path("elements").size()) {
                    best = candidate;
                }
            }
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new PlaceProviderException("Place search was interrupted.", exception);
        } catch (Exception exception) {
            log.warn("OpenStreetMap place search failed while collecting server responses", exception);
        } finally {
            executor.shutdownNow();
        }
        return best;
    }

    private JsonNode fetchOverpass(String endpoint, String body) {
        try {
            JsonNode candidate = restClient.post()
                    .uri(endpoint)
                    .header("User-Agent", userAgent)
                    .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                    .body(body)
                    .retrieve()
                    .body(JsonNode.class);
            String remark = candidate == null ? "" : candidate.path("remark").asText();
            if (!remark.isBlank()) {
                log.warn("Overpass endpoint {} returned a runtime remark ({})",
                        endpoint, truncate(remark, 180));
                return null;
            }
            if (candidate != null && candidate.path("elements").isArray()) return candidate;
            log.warn("Overpass endpoint {} returned an invalid response", endpoint);
        } catch (RestClientException exception) {
            log.warn("Overpass endpoint {} failed ({})",
                    endpoint, exception.getClass().getSimpleName());
        }
        return null;
    }

    private String overpassSelectors(
            DestinationPoint destination, int requestedRadiusMetres, Set<String> activityFilters) {
        Set<String> normalized = activityFilters.stream()
                .map(value -> value.trim().toLowerCase(Locale.ROOT))
                .collect(Collectors.toSet());
        List<String> selectors = new ArrayList<>();

        if (normalized.isEmpty()) {
            selectors.add(selector(destination, requestedRadiusMetres,
                    "[\"tourism\"~\"attraction|museum|viewpoint|gallery|zoo\"]"));
            selectors.add(selector(destination, requestedRadiusMetres, "[\"historic\"]"));
            selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"natural\"~\"beach|peak|volcano|ridge|waterfall|cave_entrance|rock|stone|wood|wetland|spring|hot_spring|cliff|water\"]"));
            selectors.add(selector(destination, requestedRadiusMetres,
                    "[\"waterway\"~\"river|stream|canal\"]"));
            selectors.add(selector(destination, requestedRadiusMetres,
                    "[\"water\"~\"lake|pond|reservoir|river\"]"));
            selectors.add(selector(destination, requestedRadiusMetres,
                    "[\"landuse\"~\"forest|farmland|farmyard\"]"));
            selectors.add(selector(destination, requestedRadiusMetres,
                    "[\"leisure\"~\"park|nature_reserve|garden|recreation_ground|beach_resort\"]"));
            selectors.add(selector(destination, requestedRadiusMetres,
                    "[\"leisure\"~\"playground|sports_centre|swimming_pool|fitness_centre|golf_course|water_park|marina\"]"));
            selectors.add(selector(destination, requestedRadiusMetres,
                    "[\"boundary\"~\"national_park|protected_area\"]"));
            selectors.add(selector(destination, requestedRadiusMetres,
                    "[\"amenity\"~\"place_of_worship|restaurant|cafe|fast_food|food_court|bar|pub|ice_cream|biergarten|arts_centre|cinema|theatre|community_centre|marketplace\"]"));
            selectors.add(selector(destination, requestedRadiusMetres,
                    "[\"shop\"~\"bakery|confectionery|coffee|tea|deli\"]"));
            selectors.add(selector(destination, requestedRadiusMetres,
                    "[\"tourism\"~\"theme_park|aquarium|artwork|picnic_site\"]"));
            selectors.add(selector(destination, requestedRadiusMetres,
                    "[\"route\"~\"hiking|walking|bicycle|mtb\"]"));
            selectors.add(selector(destination, requestedRadiusMetres,
                    "[\"shop\"=\"mall\"]"));
            selectors.add(selector(destination, requestedRadiusMetres,
                    "[\"sport\"~\"surfing|swimming|diving|canoe|kayak|sailing|climbing\"]"));
        } else {
            if (normalized.contains("temples")) {
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"amenity\"=\"place_of_worship\"][\"religion\"~\"buddhist|hindu\"]"));
                selectors.add(selector(destination, requestedRadiusMetres, "[\"building\"=\"temple\"]"));
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"historic\"=\"religious\"][\"religion\"~\"buddhist|hindu\"]"));
            }
            if (normalized.contains("beaches")) {
                selectors.add(selector(destination, requestedRadiusMetres, "[\"natural\"=\"beach\"]"));
                selectors.add(selector(destination, requestedRadiusMetres, "[\"leisure\"=\"beach_resort\"]"));
                selectors.add(selector(destination, requestedRadiusMetres, "[\"place\"=\"beach\"]"));
                // Some real waterfront places are mapped by their public name or as a promenade,
                // park, attraction or locality instead of natural=beach.  Search those names but
                // keep the returned OSM record and tags visible to the user.
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"name\"~\"beach|coast|shore|seafront|seaside|Galle Face\",i]"));
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"name:en\"~\"beach|coast|shore|seafront|seaside|Galle Face\",i]"));
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"alt_name\"~\"beach|coast|shore|seafront|seaside|Galle Face\",i]"));
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"official_name\"~\"beach|coast|shore|seafront|seaside|Galle Face\",i]"));
            }
            if (normalized.contains("nature & parks")) {
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"natural\"~\"peak|volcano|ridge|waterfall|cave_entrance|rock|stone|wood|wetland|spring|hot_spring|cliff|water\"]"));
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"waterway\"~\"river|stream|canal|waterfall\"]"));
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"water\"~\"lake|pond|reservoir|river\"]"));
                selectors.add(selector(destination, requestedRadiusMetres, "[\"landuse\"=\"forest\"]"));
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"leisure\"~\"park|nature_reserve|garden\"]"));
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"leisure\"=\"recreation_ground\"]"));
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"boundary\"~\"national_park|protected_area\"]"));
                selectors.add(selector(destination, requestedRadiusMetres, "[\"tourism\"=\"zoo\"]"));
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"tourism\"~\"picnic_site|camp_site|alpine_hut\"]"));
            }
            if (normalized.contains("museums & history")) {
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"tourism\"~\"museum|gallery\"]"));
                selectors.add(selector(destination, requestedRadiusMetres, "[\"historic\"]"));
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"archaeological_site\"]"));
            }
            if (normalized.contains("food & cafes")) {
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"amenity\"~\"restaurant|cafe|fast_food|food_court|bar|pub|ice_cream|biergarten\"]"));
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"shop\"~\"bakery|confectionery|coffee|tea|deli\"]"));
            }
            if (normalized.contains("adventure & viewpoints")) {
                selectors.add(selector(destination, requestedRadiusMetres, "[\"tourism\"=\"viewpoint\"]"));
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"route\"~\"hiking|walking|bicycle|mtb\"]"));
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"natural\"~\"peak|waterfall|cave_entrance\"]"));
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"leisure\"~\"sports_centre|swimming_pool|fitness_centre|golf_course|water_park|marina\"]"));
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"tourism\"~\"camp_site|alpine_hut\"]"));
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"sport\"~\"surfing|swimming|diving|scuba_diving|canoe|kayak|sailing|climbing\"]"));
            }
            if (normalized.contains("attractions")) {
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"tourism\"~\"attraction|theme_park|aquarium|artwork|picnic_site\"]"));
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"amenity\"~\"cinema|theatre|community_centre|marketplace\"]"));
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"leisure\"=\"playground\"]"));
                selectors.add(selector(destination, requestedRadiusMetres, "[\"shop\"=\"mall\"]"));
                selectors.add(selector(destination, requestedRadiusMetres, "[\"leisure\"=\"water_park\"]"));
            }
            if (normalized.contains("waterfalls")) {
                selectors.add(selector(destination, requestedRadiusMetres, "[\"natural\"=\"waterfall\"]"));
                selectors.add(selector(destination, requestedRadiusMetres, "[\"waterway\"=\"waterfall\"]"));
            }
            if (normalized.contains("rivers")) {
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"waterway\"~\"river|stream|canal\"]"));
                selectors.add(selector(destination, requestedRadiusMetres, "[\"water\"=\"river\"]"));
            }
            if (normalized.contains("ponds & lakes")) {
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"natural\"=\"water\"][\"water\"~\"lake|pond|reservoir\"]"));
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"water\"~\"lake|pond|reservoir\"]"));
            }
            if (normalized.contains("rocks & caves")) {
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"natural\"~\"rock|stone|cave_entrance|cliff\"]"));
            }
            if (normalized.contains("mountains & peaks")) {
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"natural\"~\"peak|volcano|ridge|saddle\"]"));
            }
            if (normalized.contains("farms")) {
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"landuse\"~\"farmland|farmyard\"]"));
                selectors.add(selector(destination, requestedRadiusMetres, "[\"place\"=\"farm\"]"));
                selectors.add(selector(destination, requestedRadiusMetres, "[\"tourism\"=\"farm\"]"));
            }
            if (normalized.contains("forests")) {
                selectors.add(selector(destination, requestedRadiusMetres, "[\"landuse\"=\"forest\"]"));
                selectors.add(selector(destination, requestedRadiusMetres, "[\"natural\"=\"wood\"]"));
            }
            if (normalized.contains("shopping malls")) {
                selectors.add(selector(destination, requestedRadiusMetres, "[\"shop\"=\"mall\"]"));
            }
            if (normalized.contains("water parks")) {
                selectors.add(selector(destination, requestedRadiusMetres, "[\"leisure\"=\"water_park\"]"));
            }
            if (normalized.contains("wildlife & zoos")) {
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"tourism\"~\"zoo|aquarium\"]"));
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"leisure\"=\"nature_reserve\"]"));
            }
            if (normalized.contains("gardens")) {
                selectors.add(selector(destination, requestedRadiusMetres, "[\"leisure\"=\"garden\"]"));
            }
            if (normalized.contains("camping & picnics")) {
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"tourism\"~\"camp_site|caravan_site|picnic_site|alpine_hut\"]"));
            }
            if (normalized.contains("hiking & trails")) {
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"route\"~\"hiking|walking\"]"));
            }
            if (normalized.contains("cycling")) {
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"route\"~\"bicycle|mtb\"]"));
            }
            if (normalized.contains("surfing & water sports")) {
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"sport\"~\"surfing|swimming|diving|scuba_diving|canoe|kayak|sailing|water_ski\"]"));
                selectors.add(selector(destination, requestedRadiusMetres, "[\"leisure\"=\"water_sports\"]"));
            }
            if (normalized.contains("boating & marinas")) {
                selectors.add(selector(destination, requestedRadiusMetres, "[\"leisure\"=\"marina\"]"));
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"amenity\"~\"boat_rental|ferry_terminal\"]"));
            }
            if (normalized.contains("sports & recreation")) {
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"leisure\"~\"sports_centre|stadium|fitness_centre|golf_course|swimming_pool\"]"));
            }
            if (normalized.contains("cinemas & theatres")) {
                selectors.add(selector(destination, requestedRadiusMetres,
                        "[\"amenity\"~\"cinema|theatre\"]"));
            }
            if (normalized.contains("markets")) {
                selectors.add(selector(destination, requestedRadiusMetres, "[\"amenity\"=\"marketplace\"]"));
            }
            if (normalized.contains("playgrounds")) {
                selectors.add(selector(destination, requestedRadiusMetres, "[\"leisure\"=\"playground\"]"));
            }
            if (normalized.contains("hot springs")) {
                selectors.add(selector(destination, requestedRadiusMetres, "[\"natural\"=\"hot_spring\"]"));
            }
        }

        if (selectors.isEmpty()) {
            selectors.add(selector(destination, requestedRadiusMetres, "[\"tourism\"=\"attraction\"]"));
        }
        return String.join("\n", selectors);
    }

    private boolean matchesRequestedActivities(String category, Set<String> activityFilters) {
        if (activityFilters.isEmpty()) return true;
        Set<String> normalized = activityFilters.stream()
                .map(value -> value.trim().toLowerCase(Locale.ROOT))
                .collect(Collectors.toSet());
        String value = category.toLowerCase(Locale.ROOT);
        if (normalized.contains(value)) return true;
        if (normalized.contains("nature & parks")
                && Set.of("nature", "wildlife", "waterfalls", "rivers", "ponds & lakes",
                        "rocks & caves", "mountains & peaks", "forests", "gardens", "hot springs")
                        .contains(value)) {
            return true;
        }
        if (normalized.contains("museums & history")
                && (value.equals("culture") || value.equals("history"))) return true;
        if (normalized.contains("food & cafes") && value.equals("food")) return true;
        if (normalized.contains("attractions")
                && Set.of("attraction", "water parks", "wildlife", "cinemas & theatres",
                        "markets", "shopping malls", "playgrounds").contains(value)) return true;
        if (normalized.contains("adventure & viewpoints")
                && Set.of("adventure", "hiking", "cycling", "water sports", "camping & picnics",
                        "rocks & caves", "mountains & peaks", "waterfalls", "boating & marinas")
                        .contains(value)) return true;
        if (normalized.contains("wildlife & zoos") && value.equals("wildlife")) return true;
        if (normalized.contains("hiking & trails") && value.equals("hiking")) return true;
        if (normalized.contains("surfing & water sports") && value.equals("water sports")) return true;
        return normalized.contains("sports & recreation") && value.equals("sports");
    }

    private String selector(
            DestinationPoint destination, int requestedRadiusMetres, String osmTags) {
        return "  nwr(around:%d,%f,%f)%s;".formatted(
                requestedRadiusMetres,
                destination.latitude(),
                destination.longitude(),
                osmTags);
    }

    private String preferredName(JsonNode tags) {
        String english = tags.path("name:en").asText();
        return firstNonBlank(
                english,
                tags.path("name").asText(),
                tags.path("official_name").asText(),
                tags.path("short_name").asText());
    }

    private Double coordinate(JsonNode element, String field) {
        if (element.has(field)) return element.path(field).asDouble();
        JsonNode center = element.path("center");
        return center.has(field) ? center.path(field).asDouble() : null;
    }

    private String category(JsonNode tags) {
        String natural = tags.path("natural").asText();
        String tourism = tags.path("tourism").asText();
        String leisure = tags.path("leisure").asText();
        String amenity = tags.path("amenity").asText();
        String historic = tags.path("historic").asText();
        String building = tags.path("building").asText();
        String route = tags.path("route").asText();
        String shop = tags.path("shop").asText();
        String water = tags.path("water").asText();
        String waterway = tags.path("waterway").asText();
        String landuse = tags.path("landuse").asText();
        String sport = tags.path("sport").asText();
        if (leisure.equals("beach_resort")) return "Beaches";
        if (natural.equals("beach")) return "Beaches";
        if (tags.path("place").asText().equals("beach")) return "Beaches";
        if (looksLikeBeachName(tags)) return "Beaches";
        if (natural.equals("waterfall") || waterway.equals("waterfall")) return "Waterfalls";
        if (waterway.matches("river|stream|canal") || water.equals("river")) return "Rivers";
        if (water.matches("lake|pond|reservoir")) return "Ponds & Lakes";
        if (natural.matches("rock|stone|cave_entrance|cliff")) return "Rocks & Caves";
        if (natural.matches("peak|volcano|ridge|saddle")) return "Mountains & Peaks";
        if (natural.equals("wood") || landuse.equals("forest")) return "Forests";
        if (landuse.matches("farmland|farmyard") || tags.path("place").asText().equals("farm")
                || tourism.equals("farm")) return "Farms";
        if (natural.equals("hot_spring")) return "Hot Springs";
        if (leisure.equals("garden")) return "Gardens";
        if (shop.equals("mall")) return "Shopping Malls";
        if (leisure.equals("water_park")) return "Water Parks";
        if (tourism.matches("zoo|aquarium") || leisure.equals("nature_reserve")) return "Wildlife";
        if (tourism.matches("camp_site|caravan_site|picnic_site|alpine_hut")) return "Camping & Picnics";
        if (route.matches("hiking|walking")) return "Hiking";
        if (route.matches("bicycle|mtb")) return "Cycling";
        if (leisure.equals("water_sports")
                || sport.matches("surfing|swimming|diving|scuba_diving|canoe|kayak|sailing|water_ski")) {
            return "Water Sports";
        }
        if (leisure.equals("marina") || amenity.matches("boat_rental|ferry_terminal")) return "Boating & Marinas";
        if (leisure.matches("sports_centre|stadium|fitness_centre|golf_course|swimming_pool")) return "Sports";
        if (amenity.matches("cinema|theatre")) return "Cinemas & Theatres";
        if (amenity.equals("marketplace")) return "Markets";
        if (leisure.equals("playground")) return "Playgrounds";
        if (natural.matches("wetland|spring") || leisure.matches("park|recreation_ground")) return "Nature";
        if (tags.path("boundary").asText().matches("national_park|protected_area")) return "Nature";
        if (building.equals("temple")) return "Temples";
        if (amenity.matches("restaurant|cafe|fast_food|food_court|bar|pub|ice_cream|biergarten")) return "Food";
        if (shop.matches("bakery|confectionery|coffee|tea|deli")) return "Food";
        if (amenity.equals("place_of_worship")) {
            String religion = tags.path("religion").asText();
            if (religion.matches("buddhist|hindu") || building.equals("temple")) return "Temples";
            return "Culture";
        }
        if (amenity.equals("arts_centre")) return "Culture";
        if (tourism.matches("museum|gallery|arts_centre")) return "Culture";
        if (!historic.isBlank()) return "History";
        if (tourism.equals("viewpoint")) return "Adventure";
        if (amenity.equals("community_centre")) return "Attraction";
        return "Attraction";
    }

    private String description(JsonNode tags, String name, String category) {
        String description = tags.path("description:en").asText();
        if (description.isBlank()) description = tags.path("description").asText();
        if (!description.isBlank()) {
            return ShortDescription.limit(description + " " + activitySummary(tags, category), 40);
        }

        String wikipediaSummary = wikipediaSummaryClient.summary(tags.path("wikipedia").asText());
        if (!wikipediaSummary.isBlank()) {
            return ShortDescription.limit(wikipediaSummary + " " + activitySummary(tags, category), 40);
        }

        String operator = tags.path("operator").asText();
        String detail = switch (category) {
            case "Temples" -> {
                String religion = tags.path("religion").asText();
                yield religion.isBlank()
                        ? "a place of worship"
                        : "a " + religion.replace('_', ' ') + " place of worship";
            }
            case "Beaches" -> beachDescription(tags);
            case "Nature" -> {
                String kind = firstNonBlank(
                        tags.path("leisure").asText(),
                        tags.path("natural").asText(),
                        tags.path("boundary").asText());
                yield kind.isBlank() ? "a nature place" : "a " + kind.replace('_', ' ');
            }
            case "Food" -> {
                String cuisine = tags.path("cuisine").asText();
                String amenity = tags.path("amenity").asText("food venue").replace('_', ' ');
                yield cuisine.isBlank()
                        ? "a " + amenity
                        : "a " + amenity + " serving " + cuisine.replace(';', ',').replace('_', ' ');
            }
            case "History" -> "a historic " + tags.path("historic").asText("place").replace('_', ' ');
            case "Culture" -> "a cultural place";
            case "Adventure" -> "a mapped viewpoint";
            case "Hiking" -> "a hiking route";
            case "Wildlife" -> "a wildlife attraction";
            case "Waterfalls" -> "a mapped waterfall";
            case "Rivers" -> "a named river or waterway";
            case "Ponds & Lakes" -> "a named pond, lake or reservoir";
            case "Rocks & Caves" -> "a mapped rock, cliff or cave";
            case "Mountains & Peaks" -> "a named mountain, peak or ridge";
            case "Farms" -> "a named farm";
            case "Forests" -> "a named forest or woodland";
            case "Gardens" -> "a public or visitor garden";
            case "Shopping Malls" -> "a shopping mall";
            case "Water Parks" -> "a water park";
            case "Camping & Picnics" -> "a camping or picnic place";
            case "Cycling" -> "a cycling route";
            case "Water Sports" -> "a water-sports place";
            case "Boating & Marinas" -> "a marina or boating place";
            case "Sports" -> "a sports or recreation facility";
            case "Cinemas & Theatres" -> "a cinema or theatre";
            case "Markets" -> "a marketplace";
            case "Playgrounds" -> "a playground";
            case "Hot Springs" -> "a natural hot spring";
            default -> "a visitor attraction";
        };
        String operatorText = operator.isBlank() ? "" : " It is operated by " + operator + ".";
        String result = name + " is listed on OpenStreetMap as " + detail + "." + operatorText;
        if (category.equals("Beaches") || category.equals("Water Sports")) {
            result = name + " is mapped as " + detail
                    + ". Swimming and surfing suitability is unverified; follow local safety signs.";
        }
        return ShortDescription.limit(result + " " + activitySummary(tags, category), 40);
    }

    private String activitySummary(JsonNode tags, String category) {
        String cuisine = tags.path("cuisine").asText().replace(';', ',').replace('_', ' ');
        return switch (category) {
            case "Beaches" -> "Visitors can enjoy coastal views, beach walks, photography and sunset watching. Water activities should only be attempted where local conditions and safety guidance allow.";
            case "Temples" -> "Visitors can appreciate religious architecture, observe worship respectfully and learn about local culture.";
            case "Food" -> cuisine.isBlank()
                    ? "Visitors can stop for food or refreshments."
                    : "Visitors can stop for " + cuisine + " food or refreshments.";
            case "Waterfalls" -> "Visitors can view the waterfall, enjoy the landscape and take photographs. Swimming is not assumed safe.";
            case "Rivers", "Ponds & Lakes" -> "Visitors can enjoy waterside scenery, walking, birdwatching and photography where public access is available.";
            case "Rocks & Caves" -> "Visitors can explore the geological setting, sightsee and take photographs where access is permitted.";
            case "Mountains & Peaks" -> "Visitors can enjoy elevated scenery, hiking and photography on permitted routes.";
            case "Forests", "Nature" -> "Visitors can enjoy nature walks, scenery, birdwatching and photography on permitted paths.";
            case "Farms" -> "Visitors can learn about the farm setting where visitor access is offered.";
            case "Gardens" -> "Visitors can walk, relax, view plants and take photographs.";
            case "Shopping Malls" -> "Visitors can shop, dine and use available leisure facilities.";
            case "Water Parks" -> "Visitors can enjoy the water-based attractions offered by the venue.";
            case "Wildlife" -> "Visitors can observe wildlife and enjoy nature-based activities subject to site rules.";
            case "Camping & Picnics" -> "Visitors can camp or picnic where site rules permit.";
            case "Hiking" -> "Visitors can walk or hike the mapped route and enjoy nearby scenery.";
            case "Cycling" -> "Visitors can cycle the mapped route subject to access and safety conditions.";
            case "Water Sports" -> "Visitors can take part in the mapped water sport subject to local safety conditions.";
            case "Boating & Marinas" -> "Visitors can access boating or marina services where offered.";
            case "Sports" -> "Visitors can use the mapped sports or recreation facilities subject to venue access.";
            case "Cinemas & Theatres" -> "Visitors can attend films, performances or other scheduled entertainment.";
            case "Markets" -> "Visitors can browse local stalls and shop for available goods.";
            case "Playgrounds" -> "Children and families can use the mapped play facilities.";
            case "Adventure" -> "Visitors can enjoy the viewpoint, scenery and photography.";
            case "Culture" -> "Visitors can learn about arts, heritage or local culture.";
            case "History" -> "Visitors can explore the historic setting and learn about local heritage.";
            default -> "Visitors can sightsee and explore the mapped attraction.";
        };
    }

    private boolean isReliableDiscoverPlace(JsonNode tags, String category) {
        // Every result already has a real OSM element ID, coordinates and a name. Do not hide a
        // genuine named activity merely because optional description/address tags are absent.
        return !preferredName(tags).isBlank();
    }

    private FeeInfo feeInfo(JsonNode tags) {
        String fee = tags.path("fee").asText().trim().toLowerCase(Locale.ROOT);
        String charge = tags.path("charge").asText().trim();
        if (fee.equals("no") || fee.equals("free")) {
            return new FeeInfo("FREE", "Free entry is stated in OpenStreetMap.");
        }
        if (!charge.isBlank()) {
            return new FeeInfo("PAID", "OpenStreetMap lists this charge: " + charge);
        }
        if (fee.equals("yes")) {
            return new FeeInfo("PAID", "An entry fee is stated, but the amount is not published by the source.");
        }
        return new FeeInfo("UNKNOWN", "Price: not published by the source.");
    }

    private boolean hasAnyTag(JsonNode tags, String... keys) {
        for (String key : keys) {
            if (!tags.path(key).asText().isBlank()) return true;
        }
        return false;
    }

    private boolean looksLikeBeachName(JsonNode tags) {
        String names = String.join(" ",
                tags.path("name").asText(),
                tags.path("name:en").asText(),
                tags.path("alt_name").asText(),
                tags.path("official_name").asText(),
                tags.path("short_name").asText()).toLowerCase(Locale.ROOT);
        String amenity = tags.path("amenity").asText();
        String tourism = tags.path("tourism").asText();
        if (amenity.matches("restaurant|cafe|bar|pub|fast_food")
                || tourism.matches("hotel|guest_house|hostel")) {
            return false;
        }
        boolean waterfrontName = names.matches(".*\\b(beach|coast|shore|seafront|seaside)\\b.*")
                || names.matches(".*\\bgalle face (beach|green|promenade)\\b.*");
        boolean compatibleMapFeature = hasAnyTag(tags,
                "natural", "leisure", "place", "highway", "man_made", "tourism", "waterfront");
        return waterfrontName && compatibleMapFeature;
    }

    private String beachDescription(JsonNode tags) {
        String name = firstNonBlank(tags.path("name:en").asText(), tags.path("name").asText())
                .toLowerCase(Locale.ROOT);
        if (name.contains("galle face green")) {
            return "an OpenStreetMap-listed oceanfront recreation area beside the Galle Face shoreline";
        }
        String kind = firstNonBlank(
                tags.path("natural").asText(),
                tags.path("leisure").asText(),
                tags.path("tourism").asText(),
                tags.path("highway").asText());
        return kind.isBlank()
                ? "a named OpenStreetMap waterfront or beach place"
                : "an OpenStreetMap-listed " + kind.replace('_', ' ') + " associated with the waterfront";
    }

    private String firstNonBlank(String... values) {
        for (String value : values) {
            if (value != null && !value.isBlank()) return value;
        }
        return "";
    }

    private String address(JsonNode tags, String region) {
        List<String> parts = new ArrayList<>();
        addIfPresent(parts, tags.path("addr:street").asText());
        addIfPresent(parts, tags.path("addr:city").asText());
        addIfPresent(parts, tags.path("addr:district").asText());
        return parts.isEmpty() ? region : String.join(", ", parts);
    }

    private void addIfPresent(List<String> values, String value) {
        if (!value.isBlank() && !values.contains(value)) values.add(value);
    }

    private int visitMinutes(String category) {
        return switch (category) {
            case "Beaches", "Wildlife", "Adventure" -> 180;
            case "Nature", "History", "Culture" -> 120;
            case "Food" -> 90;
            default -> 105;
        };
    }

    private BigDecimal estimatedEntryCost(String category) {
        return switch (category) {
            case "Wildlife" -> BigDecimal.valueOf(8000);
            case "Adventure" -> BigDecimal.valueOf(2500);
            case "Culture", "History" -> BigDecimal.valueOf(2000);
            case "Food" -> BigDecimal.valueOf(3000);
            case "Beaches", "Nature" -> BigDecimal.valueOf(800);
            default -> BigDecimal.valueOf(1200);
        };
    }

    private BigDecimal haversine(double lat1, double lon1, double lat2, double lon2) {
        return haversineDistance(lat1, lon1, lat2, lon2);
    }

    private static BigDecimal haversineDistance(double lat1, double lon1, double lat2, double lon2) {
        return BigDecimal.valueOf(haversineKilometres(lat1, lon1, lat2, lon2))
                .setScale(2, RoundingMode.HALF_UP);
    }

    private static double haversineKilometres(double lat1, double lon1, double lat2, double lon2) {
        double earthRadiusKm = 6371.0088;
        double latDistance = Math.toRadians(lat2 - lat1);
        double lonDistance = Math.toRadians(lon2 - lon1);
        double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);
        return earthRadiusKm * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }

    private String truncate(String value, int maximum) {
        return value.length() <= maximum ? value : value.substring(0, maximum - 1) + "…";
    }

    private <T> Optional<T> cached(Map<String, CacheEntry<T>> cache, String key) {
        CacheEntry<T> entry = cache.get(key);
        if (entry == null || entry.createdAt().plus(CACHE_DURATION).isBefore(Instant.now())) {
            cache.remove(key);
            return Optional.empty();
        }
        return Optional.of(entry.value());
    }

    record DestinationPoint(String displayName, double latitude, double longitude) {
    }

    record LivePlaceResult(DestinationPoint destination, List<PlaceTemplate> places) {
    }

    private record FeeInfo(String status, String details) {
    }

    private record CacheEntry<T>(T value, Instant createdAt) {
    }
}
