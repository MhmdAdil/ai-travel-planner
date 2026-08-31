package com.aitravelplanner.profile;

public class IncorrectCurrentPasswordException extends RuntimeException {
    public IncorrectCurrentPasswordException() {
        super("Current password is incorrect.");
    }
}
