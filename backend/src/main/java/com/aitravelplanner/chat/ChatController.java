package com.aitravelplanner.chat;

import com.aitravelplanner.chat.dto.ChatMessageRequest;
import com.aitravelplanner.chat.dto.ChatMessageResponse;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/chat")
public class ChatController {

    private final ChatService chatService;

    public ChatController(ChatService chatService) {
        this.chatService = chatService;
    }

    @PostMapping("/message")
    public ChatMessageResponse message(@Valid @RequestBody ChatMessageRequest request) {
        return chatService.reply(request);
    }

    @ExceptionHandler(ChatServiceException.class)
    public ResponseEntity<ErrorResponse> chatError(ChatServiceException ex) {
        return ResponseEntity.badRequest().body(new ErrorResponse(ex.getMessage()));
    }

    private record ErrorResponse(String message) {
    }
}
