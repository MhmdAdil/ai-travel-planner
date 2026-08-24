package com.aitravelplanner.itinerary;

final class ShortDescription {

    private ShortDescription() {}

    static String limit(String value, int maximumWords) {
        if (value == null || value.isBlank()) return "";
        String normalized = value.replaceAll("\\s+", " ").trim();
        String[] words = normalized.split(" ");
        if (words.length <= maximumWords) return normalized;
        return String.join(" ", java.util.Arrays.copyOf(words, maximumWords)) + "…";
    }
}
