package com.aitravelplanner.chat;

import static org.assertj.core.api.Assertions.assertThat;

import com.aitravelplanner.chat.dto.ChatHistoryMessage;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

class GeminiClientTest {

    @Test
    void sendsConversationToGeminiAndReadsReply() {
        RestClient.Builder builder = RestClient.builder();
        MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();

        GeminiProperties properties = new GeminiProperties(
                "test-api-key",
                "gemini-3.6-flash",
                "https://generativelanguage.googleapis.com");

        GeminiClient client = new GeminiClient(
                builder
                        .baseUrl(properties.baseUrl())
                        .defaultHeader("x-goog-api-key", properties.apiKey())
                        .build(),
                properties);

        server.expect(request ->
                        assertThat(request.getURI().toString())
                                .contains("/v1beta/models/gemini-3.6-flash:generateContent"))
                .andRespond(org.springframework.test.web.client.response.MockRestResponseCreators
                        .withSuccess(
                                """
                                {
                                  "candidates": [
                                    {
                                      "content": {
                                        "parts": [
                                          {"text": "Ella is a good base for hill-country activities."}
                                        ]
                                      }
                                    }
                                  ]
                                }
                                """,
                                MediaType.APPLICATION_JSON));

        GeminiClient.GeminiReply result = client.generate(
                List.of(new ChatHistoryMessage("user", "Tell me about Ella")),
                "What can I do there?",
                "Destination: Ella\nBudget: LKR 100000");

        assertThat(result.text())
                .isEqualTo("Ella is a good base for hill-country activities.");
        assertThat(result.model()).isEqualTo("gemini-3.6-flash");
        server.verify();
    }
}
