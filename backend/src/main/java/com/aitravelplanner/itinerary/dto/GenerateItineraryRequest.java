package com.aitravelplanner.itinerary.dto;

import com.aitravelplanner.itinerary.BudgetLevel;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.FutureOrPresent;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record GenerateItineraryRequest(
        @NotBlank @Size(max = 80) String destinationRegion,
        @NotBlank @Size(max = 180) String startLocation,
        @NotNull @FutureOrPresent LocalDateTime arrivalDateTime,
        @NotNull @FutureOrPresent LocalDateTime departureDateTime,
        @NotNull BudgetLevel budgetLevel,
        @NotNull @DecimalMin(value = "1.00") BigDecimal budgetLkr,
        @Min(1) @Max(20) int groupSize,
        @Size(max = 9) List<@NotBlank String> travelRegions,
        @NotEmpty @Size(max = 20) List<@NotBlank String> interests,
        @Size(max = 24) List<@NotBlank String> activities,
        @NotBlank @Size(max = 40) String accommodationType,
        @NotBlank @Size(max = 60) String foodPreference,
        @NotBlank @Size(max = 40) String transportMode,
        @NotBlank @Size(max = 30) String pace,
        @Size(max = 500) String notes,
        Double latitude,
        Double longitude,
        boolean returnToAirport) {
}
