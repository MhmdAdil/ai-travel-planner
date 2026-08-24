package com.aitravelplanner.itinerary;

public class PlaceProviderException extends RuntimeException {
    PlaceProviderException(String message) {
        super(message);
    }

    PlaceProviderException(String message, Throwable cause) {
        super(message, cause);
    }
}
