package com.aitravelplanner.chat;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class GeminiConfig {

    @Bean
    GeminiProperties geminiProperties(
            @Value("${GEMINI_API_KEY:}") String apiKey,
            @Value("${GEMINI_MODEL:gemini-3.6-flash}") String model,
            @Value("${GEMINI_BASE_URL:https://generativelanguage.googleapis.com}") String baseUrl) {
        return new GeminiProperties(apiKey, model, baseUrl);
    }
}
