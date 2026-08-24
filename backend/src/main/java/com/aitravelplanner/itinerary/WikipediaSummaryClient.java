package com.aitravelplanner.itinerary;

import com.fasterxml.jackson.databind.JsonNode;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Component
class WikipediaSummaryClient {

    private final RestClient restClient;
    private final String userAgent;
    private final Map<String, String> cache = new ConcurrentHashMap<>();

    WikipediaSummaryClient(
            RestClient.Builder builder,
            @Value("${app.places.user-agent:AITravelPlannerUniversityProject/0.4}") String userAgent) {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(Duration.ofSeconds(4));
        factory.setReadTimeout(Duration.ofSeconds(6));
        this.restClient = builder.requestFactory(factory).build();
        this.userAgent = userAgent;
    }

    String summary(String wikipediaTag) {
        if (wikipediaTag == null || wikipediaTag.isBlank()) return "";
        return cache.computeIfAbsent(wikipediaTag.trim(), this::fetchSummary);
    }

    private String fetchSummary(String tag) {
        int separator = tag.indexOf(':');
        if (separator < 1 || separator == tag.length() - 1) return "";
        String language = tag.substring(0, separator).toLowerCase(Locale.ROOT);
        if (!language.matches("[a-z]{2,3}")) return "";
        String title = tag.substring(separator + 1).replace(' ', '_');
        String encoded = URLEncoder.encode(title, StandardCharsets.UTF_8).replace("+", "%20");
        try {
            JsonNode response = restClient.get()
                    .uri("https://" + language + ".wikipedia.org/api/rest_v1/page/summary/" + encoded)
                    .header("User-Agent", userAgent)
                    .retrieve()
                    .body(JsonNode.class);
            if (response == null) return "";
            return ShortDescription.limit(response.path("extract").asText(), 20);
        } catch (RestClientException exception) {
            return "";
        }
    }
}
