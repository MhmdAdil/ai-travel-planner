package com.aitravelplanner.chat;

import com.aitravelplanner.chat.dto.ChatHistoryMessage;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Component
public class GeminiClient {

    private static final String SYSTEM_INSTRUCTION = """
            You are the AI Travel Assistant inside a Sri Lanka travel-planning mobile application.
            Help travellers with destinations, activities, culture, practical trip planning,
            transport choices, accommodation considerations, budgeting, packing and itinerary advice.

            Important rules:
            - Focus primarily on travel in Sri Lanka.
            - Be concise, friendly and practical.
            - Use Sri Lankan Rupees (LKR) when discussing local costs unless the user asks otherwise.
            - Never pretend that estimated prices, opening hours, weather, transport schedules,
              availability or safety conditions are live/current when they have not been supplied.
            - When information can change, clearly tell the traveller to verify it with an official
              or current source.
            - Do not invent bookings, tickets, reservations or confirmations.
            - Respect the conversation history so follow-up questions such as "what can I do there?"
              refer to the previous destination when possible.
            - If the question is unrelated to travel, answer briefly and steer back toward travel help.
            - Reply in clean plain text. Do not use Markdown headings such as #, ## or ###.
              Do not use Markdown bold markers such as **. If a list helps, use simple hyphen bullets.
            - When CURRENT TRIP CONTEXT is supplied, treat it as the traveller's actual current
              generated itinerary and preferences. Use it to answer questions such as "what is my
              next place?", "how much is my transport?", "what did I choose for accommodation?",
              and "what is on day 2?". Do not invent trip details that are absent from that context.
            """;

    private final RestClient restClient;
    private final GeminiProperties properties;

    @Autowired
    public GeminiClient(GeminiProperties properties) {
        this(
                RestClient.builder()
                        .baseUrl(properties.baseUrl())
                        .defaultHeader(
                                "x-goog-api-key",
                                properties.apiKey() == null ? "" : properties.apiKey())
                        .build(),
                properties);
    }

    // Package-private constructor used only by unit tests with a mocked RestClient.
    GeminiClient(RestClient restClient, GeminiProperties properties) {
        this.restClient = restClient;
        this.properties = properties;
    }

    public GeminiReply generate(
            List<ChatHistoryMessage> history,
            String message,
            String travelContext) {

        if (!properties.configured()) {
            throw new ChatServiceException(
                    "Gemini API is not configured. Set GEMINI_API_KEY before starting the backend.");
        }

        List<Map<String, Object>> contents = new ArrayList<>();

        if (travelContext != null && !travelContext.isBlank()) {
            contents.add(content(
                    "user",
                    "CURRENT TRIP CONTEXT (application data; use this as factual context for this conversation):\n"
                            + travelContext.trim()));
            contents.add(content(
                    "model",
                    "Understood. I will use the supplied current trip context when it is relevant."));
        }

        int start = Math.max(0, history.size() - 12);
        for (int i = start; i < history.size(); i++) {
            ChatHistoryMessage item = history.get(i);
            contents.add(content(item.role(), item.text()));
        }
        contents.add(content("user", message));

        Map<String, Object> requestBody = new LinkedHashMap<>();
        requestBody.put(
                "systemInstruction",
                Map.of("parts", List.of(Map.of("text", SYSTEM_INSTRUCTION))));
        requestBody.put("contents", contents);
        requestBody.put(
                "generationConfig",
                Map.of(
                        "temperature", 0.6,
                        "maxOutputTokens", 700));

        try {
            Map<?, ?> response = restClient.post()
                    .uri("/v1beta/models/{model}:generateContent", properties.model())
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(requestBody)
                    .retrieve()
                    .body(Map.class);

            String text = extractText(response);
            if (text == null || text.isBlank()) {
                throw new ChatServiceException(
                        "The AI service returned an empty response. Please try again.");
            }

            return new GeminiReply(text.trim(), properties.model());
        } catch (ChatServiceException ex) {
            throw ex;
        } catch (RestClientException ex) {
            throw new ChatServiceException(
                    "Could not reach the AI service. Please try again in a moment.", ex);
        }
    }

    private static Map<String, Object> content(String role, String text) {
        return Map.of(
                "role", role,
                "parts", List.of(Map.of("text", text)));
    }

    private static String extractText(Map<?, ?> response) {
        if (response == null) {
            return null;
        }

        Object candidatesValue = response.get("candidates");
        if (!(candidatesValue instanceof List<?> candidates) || candidates.isEmpty()) {
            return null;
        }

        Object firstValue = candidates.get(0);
        if (!(firstValue instanceof Map<?, ?> first)) {
            return null;
        }

        Object contentValue = first.get("content");
        if (!(contentValue instanceof Map<?, ?> content)) {
            return null;
        }

        Object partsValue = content.get("parts");
        if (!(partsValue instanceof List<?> parts) || parts.isEmpty()) {
            return null;
        }

        StringBuilder answer = new StringBuilder();
        for (Object partValue : parts) {
            if (partValue instanceof Map<?, ?> part) {
                Object textValue = part.get("text");
                if (textValue instanceof String text && !text.isBlank()) {
                    if (!answer.isEmpty()) {
                        answer.append('\n');
                    }
                    answer.append(text);
                }
            }
        }
        return answer.toString();
    }

    public record GeminiReply(String text, String model) {
    }
}
