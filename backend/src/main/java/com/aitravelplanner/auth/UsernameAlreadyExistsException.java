package com.aitravelplanner.auth;

public class UsernameAlreadyExistsException extends RuntimeException {
    public UsernameAlreadyExistsException() {
        super("That username is already in use. Please choose another username.");
    }
}
