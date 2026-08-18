package com.aitravelplanner.itinerary;

public class TripNotFoundException extends RuntimeException {
    public TripNotFoundException() {
        super("The requested itinerary was not found.");
    }
}
