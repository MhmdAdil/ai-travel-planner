package com.aitravelplanner.profile;

import com.aitravelplanner.auth.UsernameAlreadyExistsException;
import com.aitravelplanner.profile.dto.ProfileResponse;
import com.aitravelplanner.user.AppUser;
import com.aitravelplanner.user.UserRepository;
import java.util.Locale;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ProfileService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public ProfileService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional(readOnly = true)
    public ProfileResponse getProfile(String email) {
        return response(findUser(email));
    }

    @Transactional
    public ProfileResponse updateUsername(String email, String requestedUsername) {
        AppUser user = findUser(email);
        String username = requestedUsername.trim();

        if (user.getUsername() != null && user.getUsername().equalsIgnoreCase(username)) {
            return response(user);
        }
        if (userRepository.existsByUsernameIgnoreCase(username)) {
            throw new UsernameAlreadyExistsException();
        }

        user.changeUsername(username);
        return response(userRepository.save(user));
    }

    @Transactional
    public void changePassword(String email, String currentPassword, String newPassword) {
        AppUser user = findUser(email);
        if (!passwordEncoder.matches(currentPassword, user.getPasswordHash())) {
            throw new IncorrectCurrentPasswordException();
        }
        user.changePasswordHash(passwordEncoder.encode(newPassword));
        userRepository.save(user);
    }

    private AppUser findUser(String email) {
        return userRepository.findByEmailIgnoreCase(email.trim().toLowerCase(Locale.ROOT))
                .orElseThrow(() -> new IllegalStateException("Authenticated user was not found"));
    }

    private ProfileResponse response(AppUser user) {
        String username = user.getUsername();
        if (username == null || username.isBlank()) {
            String email = user.getEmail();
            int at = email.indexOf('@');
            username = at > 0 ? email.substring(0, at) : "traveller";
        }
        return new ProfileResponse(user.getId(), username, user.getEmail(), user.getRole().name());
    }
}
