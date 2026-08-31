package com.aitravelplanner.auth.dto;

import com.aitravelplanner.user.AppUser;

public record UserSummaryResponse(Long id, String username, String email, String role) {
    public static UserSummaryResponse from(AppUser user) {
        return new UserSummaryResponse(
                user.getId(),
                user.getUsername(),
                user.getEmail(),
                user.getRole().name());
    }
}
