package com.aitravelplanner.common;

import com.aitravelplanner.auth.EmailAlreadyExistsException;
import com.aitravelplanner.itinerary.InvalidTripRequestException;
import com.aitravelplanner.itinerary.PlaceProviderException;
import com.aitravelplanner.itinerary.TripNotFoundException;
import jakarta.validation.ConstraintViolationException;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(EmailAlreadyExistsException.class)
    @ResponseStatus(HttpStatus.CONFLICT)
    ApiError handleDuplicateEmail(EmailAlreadyExistsException exception) {
        return error(HttpStatus.CONFLICT, exception.getMessage(), Map.of());
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    @ResponseStatus(HttpStatus.CONFLICT)
    ApiError handleDataIntegrityViolation() {
        return error(HttpStatus.CONFLICT, "An account with that email already exists.", Map.of());
    }

    @ExceptionHandler(BadCredentialsException.class)
    @ResponseStatus(HttpStatus.UNAUTHORIZED)
    ApiError handleBadCredentials() {
        return error(HttpStatus.UNAUTHORIZED, "Invalid email or password.", Map.of());
    }

    @ExceptionHandler(InvalidTripRequestException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    ApiError handleInvalidTrip(InvalidTripRequestException exception) {
        return error(HttpStatus.BAD_REQUEST, exception.getMessage(), Map.of());
    }

    @ExceptionHandler(TripNotFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    ApiError handleTripNotFound(TripNotFoundException exception) {
        return error(HttpStatus.NOT_FOUND, exception.getMessage(), Map.of());
    }

    @ExceptionHandler(PlaceProviderException.class)
    @ResponseStatus(HttpStatus.SERVICE_UNAVAILABLE)
    ApiError handlePlaceProvider(PlaceProviderException exception) {
        return error(HttpStatus.SERVICE_UNAVAILABLE,
                "Live places are temporarily unavailable. Please try again.", Map.of());
    }

    @ExceptionHandler(ConstraintViolationException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    ApiError handleConstraintViolation(ConstraintViolationException exception) {
        return error(HttpStatus.BAD_REQUEST, "The map coordinates or radius are invalid.", Map.of());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    ApiError handleValidation(MethodArgumentNotValidException exception) {
        Map<String, String> fieldErrors = new LinkedHashMap<>();
        exception.getBindingResult().getFieldErrors().forEach(fieldError ->
                fieldErrors.putIfAbsent(fieldError.getField(), fieldError.getDefaultMessage()));
        String message = fieldErrors.values().stream().findFirst().orElse("Request validation failed.");
        return error(HttpStatus.BAD_REQUEST, message, fieldErrors);
    }

    private ApiError error(HttpStatus status, String message, Map<String, String> fieldErrors) {
        return new ApiError(Instant.now(), status.value(), status.getReasonPhrase(), message, fieldErrors);
    }
}
