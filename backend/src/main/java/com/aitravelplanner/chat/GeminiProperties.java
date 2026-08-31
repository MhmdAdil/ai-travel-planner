package com.aitravelplanner.chat;

public record GeminiProperties(
        String apiKey,
        String model,
        String baseUrl) {

    public GeminiProperties {
        model = (model == null || model.isBlank()) ? "gemini-3.6-flash" : model.trim();
        baseUrl = (baseUrl == null || baseUrl.isBlank())
                ? "https://generativelanguage.googleapis.com"
                : baseUrl.trim();
    }

    public boolean configured() {
        return apiKey != null && !apiKey.isBlank();
    }
}
