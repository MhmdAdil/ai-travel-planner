package com.aitravelplanner.cost;

public class CostPredictionUnavailableException extends RuntimeException {
    public CostPredictionUnavailableException(String message, Throwable cause) {
        super(message, cause);
    }

    public CostPredictionUnavailableException(String message) {
        super(message);
    }
}
