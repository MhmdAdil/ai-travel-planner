package com.aitravelplanner.itinerary;

import com.aitravelplanner.itinerary.dto.CostSummaryResponse;
import com.aitravelplanner.itinerary.dto.GenerateItineraryRequest;
import com.aitravelplanner.itinerary.dto.ItineraryDayResponse;
import com.aitravelplanner.itinerary.dto.ItineraryItemResponse;
import com.aitravelplanner.itinerary.dto.ItineraryResponse;
import com.aitravelplanner.user.AppUser;
import com.aitravelplanner.user.UserRepository;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.temporal.ChronoUnit;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ItineraryService {

    private final UserRepository userRepository;
    private final TripRepository tripRepository;
    private final ItineraryGenerator generator;
    private final BigDecimal lkrPerUsd;

    public ItineraryService(
            UserRepository userRepository,
            TripRepository tripRepository,
            ItineraryGenerator generator,
            @Value("${app.currency.lkr-per-usd:310.00}") BigDecimal lkrPerUsd) {
        this.userRepository = userRepository;
        this.tripRepository = tripRepository;
        this.generator = generator;
        this.lkrPerUsd = lkrPerUsd;
    }

    @Transactional
    public ItineraryResponse generate(String email, GenerateItineraryRequest request) {
        validateDates(request);
        AppUser user = userRepository.findByEmailIgnoreCase(email)
                .orElseThrow(TripNotFoundException::new);
        List<String> activities = request.activities() == null ? List.of() : request.activities();
        Trip trip = new Trip(
                user,
                request.destinationRegion() + " trip",
                request.destinationRegion(),
                request.startLocation(),
                request.arrivalDateTime(),
                request.departureDateTime(),
                request.budgetLevel(),
                request.budgetLkr(),
                request.groupSize(),
                request.accommodationType(),
                request.foodPreference(),
                request.transportMode(),
                request.pace(),
                request.notes(),
                request.interests(),
                activities,
                lkrPerUsd);

        ItineraryGenerator.GenerationTotals totals = generator.generate(trip, request);
        trip.complete(totals.accommodation(), totals.food(), totals.transport(), totals.activities());
        return toResponse(tripRepository.save(trip));
    }

    @Transactional(readOnly = true)
    public List<ItineraryResponse> list(String email) {
        return tripRepository.findAllByUserEmailIgnoreCaseOrderByCreatedAtDesc(email).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public ItineraryResponse get(String email, Long id) {
        return tripRepository.findByIdAndUserEmailIgnoreCase(id, email)
                .map(this::toResponse)
                .orElseThrow(TripNotFoundException::new);
    }

    private void validateDates(GenerateItineraryRequest request) {
        if (!request.departureDateTime().isAfter(request.arrivalDateTime())) {
            throw new InvalidTripRequestException("Departure must be after arrival.");
        }
        long days = ChronoUnit.DAYS.between(
                request.arrivalDateTime().toLocalDate(),
                request.departureDateTime().toLocalDate()) + 1;
        if (days > 30) {
            throw new InvalidTripRequestException("Trips can contain a maximum of 30 days.");
        }
    }

    private ItineraryResponse toResponse(Trip trip) {
        List<ItineraryDayResponse> days = trip.getDays().stream()
                .map(day -> new ItineraryDayResponse(
                        day.getDayNumber(),
                        day.getDate(),
                        day.getTheme(),
                        day.getEstimatedCostLkr(),
                        toUsd(day.getEstimatedCostLkr(), trip.getLkrPerUsd()),
                        day.getItems().stream()
                                .map(item -> new ItineraryItemResponse(
                                        item.getStartTime(),
                                        item.getEndTime(),
                                        item.getName(),
                                        item.getCategory(),
                                        item.getDescription(),
                                        item.getLocation(),
                                        item.getTravelMinutes(),
                                        item.getDistanceKm(),
                                        item.getEstimatedCostLkr(),
                                        toUsd(item.getEstimatedCostLkr(), trip.getLkrPerUsd()),
                                        item.getAlternatives()))
                                .toList()))
                .toList();
        BigDecimal difference = trip.getBudgetLkr().subtract(trip.getTotalCostLkr());
        CostSummaryResponse costSummary = new CostSummaryResponse(
                trip.getAccommodationCostLkr(),
                trip.getFoodCostLkr(),
                trip.getTransportCostLkr(),
                trip.getActivitiesCostLkr(),
                trip.getTotalCostLkr(),
                toUsd(trip.getTotalCostLkr(), trip.getLkrPerUsd()),
                trip.getBudgetLkr(),
                difference.signum() >= 0,
                difference.abs(),
                trip.getLkrPerUsd(),
                "Approximate USD conversion using the configured LKR-per-USD rate.");
        return new ItineraryResponse(
                trip.getId(),
                trip.getTitle(),
                trip.getDestinationRegion(),
                trip.getStartLocation(),
                trip.getArrivalDateTime(),
                trip.getDepartureDateTime(),
                trip.getBudgetLevel(),
                trip.getGroupSize(),
                trip.getInterests(),
                trip.getActivities(),
                trip.getAccommodationType(),
                trip.getFoodPreference(),
                trip.getTransportMode(),
                trip.getPace(),
                trip.getStatus(),
                "RULE_BASED_BASELINE",
                costSummary,
                days,
                trip.getCreatedAt());
    }

    private BigDecimal toUsd(BigDecimal lkr, BigDecimal rate) {
        if (rate == null || rate.signum() <= 0) return BigDecimal.ZERO;
        return lkr.divide(rate, 2, RoundingMode.HALF_UP);
    }
}
