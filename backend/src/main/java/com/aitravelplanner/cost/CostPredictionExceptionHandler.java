package com.aitravelplanner.cost;

import com.aitravelplanner.common.ApiError;
import java.time.Instant;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class CostPredictionExceptionHandler {

    @ExceptionHandler(CostPredictionUnavailableException.class)
    @ResponseStatus(HttpStatus.SERVICE_UNAVAILABLE)
    ApiError handleUnavailable(CostPredictionUnavailableException exception) {
        return new ApiError(
                Instant.now(),
                HttpStatus.SERVICE_UNAVAILABLE.value(),
                HttpStatus.SERVICE_UNAVAILABLE.getReasonPhrase(),
                "AI cost prediction is temporarily unavailable. Make sure the XGBoost API is running on port 8001.",
                Map.of());
    }
}
