package com.aitravelplanner.auth.dto;

import com.aitravelplanner.user.AppUser;

public record UserSummaryResponse(Long id, String email, String role) {

    public static UserSummaryResponse from(AppUser user) {
        return new UserSummaryResponse(user.getId(), user.getEmail(), user.getRole().name());
    }
}
