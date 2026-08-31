package com.aitravelplanner.chat.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.List;

public record ChatMessageRequest(
        @NotBlank
        @Size(max = 2000)
        String message,

        @Valid
        @Size(max = 20)
        List<ChatHistoryMessage> history,

        @Size(max = 12000)
        String travelContext) {

    public ChatMessageRequest {
        history = history == null ? List.of() : List.copyOf(history);
        travelContext = travelContext == null ? "" : travelContext.trim();
    }
}
