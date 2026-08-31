package com.aitravelplanner.chat;

import com.aitravelplanner.chat.dto.ChatMessageRequest;
import com.aitravelplanner.chat.dto.ChatMessageResponse;
import org.springframework.stereotype.Service;

@Service
public class ChatService {

    private final GeminiClient geminiClient;

    public ChatService(GeminiClient geminiClient) {
        this.geminiClient = geminiClient;
    }

    public ChatMessageResponse reply(ChatMessageRequest request) {
        GeminiClient.GeminiReply reply =
                geminiClient.generate(request.history(), request.message(), request.travelContext());

        return new ChatMessageResponse(reply.text(), reply.model());
    }
}
