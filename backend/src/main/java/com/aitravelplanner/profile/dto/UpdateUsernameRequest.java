package com.aitravelplanner.profile.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record UpdateUsernameRequest(
        @NotBlank(message = "Username is required")
        @Size(min = 3, max = 30, message = "Username must be between 3 and 30 characters")
        @Pattern(
                regexp = "^[A-Za-z0-9._-]+$",
                message = "Username can contain letters, numbers, dot, underscore and hyphen only")
        String username) {
}
