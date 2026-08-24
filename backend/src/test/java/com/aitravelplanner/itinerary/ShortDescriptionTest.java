package com.aitravelplanner.itinerary;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class ShortDescriptionTest {
    @Test
    void limitsDescriptionsToTwentyWords() {
        String text = "one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty twenty-one";
        assertThat(ShortDescription.limit(text, 20).split(" ")).hasSize(20);
    }
}
