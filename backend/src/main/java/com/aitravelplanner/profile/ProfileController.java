package com.aitravelplanner.profile;

import com.aitravelplanner.profile.dto.ChangePasswordRequest;
import com.aitravelplanner.profile.dto.ProfileResponse;
import com.aitravelplanner.profile.dto.UpdateUsernameRequest;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/profile")
public class ProfileController {
    private final ProfileService profileService;

    public ProfileController(ProfileService profileService) {
        this.profileService = profileService;
    }

    @GetMapping
    public ProfileResponse profile(Authentication authentication) {
        return profileService.getProfile(authentication.getName());
    }

    @PatchMapping("/username")
    public ProfileResponse updateUsername(
            Authentication authentication,
            @Valid @RequestBody UpdateUsernameRequest request) {
        return profileService.updateUsername(authentication.getName(), request.username());
    }

    @PatchMapping("/password")
    public Map<String, String> changePassword(
            Authentication authentication,
            @Valid @RequestBody ChangePasswordRequest request) {
        profileService.changePassword(
                authentication.getName(),
                request.currentPassword(),
                request.newPassword());
        return Map.of("message", "Password changed successfully.");
    }
}
