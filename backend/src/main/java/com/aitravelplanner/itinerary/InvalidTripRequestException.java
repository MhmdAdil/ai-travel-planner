package com.aitravelplanner.itinerary;

public class InvalidTripRequestException extends RuntimeException {
    public InvalidTripRequestException(String message) {
        super(message);
    }
}
