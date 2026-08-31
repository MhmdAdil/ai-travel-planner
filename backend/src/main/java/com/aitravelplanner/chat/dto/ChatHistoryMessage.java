package com.aitravelplanner.chat.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record ChatHistoryMessage(
        @NotBlank
        @Pattern(regexp = "user|model")
        String role,

        @NotBlank
        @Size(max = 4000)
        String text) {
}
