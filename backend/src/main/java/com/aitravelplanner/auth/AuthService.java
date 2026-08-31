package com.aitravelplanner.auth;

import com.aitravelplanner.auth.dto.AuthResponse;
import com.aitravelplanner.auth.dto.LoginRequest;
import com.aitravelplanner.auth.dto.RegisterRequest;
import com.aitravelplanner.auth.dto.RegisterResponse;
import com.aitravelplanner.auth.dto.UserSummaryResponse;
import com.aitravelplanner.user.AppUser;
import com.aitravelplanner.user.Role;
import com.aitravelplanner.user.UserRepository;
import java.util.Locale;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;

    public AuthService(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            AuthenticationManager authenticationManager,
            JwtService jwtService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.authenticationManager = authenticationManager;
        this.jwtService = jwtService;
    }

    @Transactional
    public RegisterResponse register(RegisterRequest request) {
        String email = normalizeEmail(request.email());
        String username = request.username().trim();
        if (userRepository.existsByEmailIgnoreCase(email)) {
            throw new EmailAlreadyExistsException();
        }
        if (userRepository.existsByUsernameIgnoreCase(username)) {
            throw new UsernameAlreadyExistsException();
        }

        AppUser user = userRepository.save(
                new AppUser(
                        email,
                        username,
                        passwordEncoder.encode(request.password()),
                        Role.TRAVELLER));
        return new RegisterResponse("Account created successfully.", UserSummaryResponse.from(user));
    }

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        String email = normalizeEmail(request.email());
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(email, request.password()));

        AppUser user = userRepository.findByEmailIgnoreCase(email)
                .orElseThrow(() -> new IllegalStateException("Authenticated user was not found"));
        return new AuthResponse(
                jwtService.issueToken(user),
                "Bearer",
                jwtService.expiresInSeconds(),
                UserSummaryResponse.from(user));
    }

    private String normalizeEmail(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }
}
