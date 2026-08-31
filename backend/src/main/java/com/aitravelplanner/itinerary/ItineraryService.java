package com.aitravelplanner.itinerary;

import com.aitravelplanner.itinerary.dto.AlternativePlaceResponse;
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
    private final NationwidePlaceCatalog nationwideCatalog;
    private final TransportPlanner transportPlanner;
    private final AccommodationCatalog accommodationCatalog;
    private final BigDecimal lkrPerUsd;

    public ItineraryService(
            UserRepository userRepository,
            TripRepository tripRepository,
            ItineraryGenerator generator,
            NationwidePlaceCatalog nationwideCatalog,
            TransportPlanner transportPlanner,
            AccommodationCatalog accommodationCatalog,
            @Value("${app.currency.lkr-per-usd:310.00}") BigDecimal lkrPerUsd) {
        this.userRepository = userRepository;
        this.tripRepository = tripRepository;
        this.generator = generator;
        this.nationwideCatalog = nationwideCatalog;
        this.transportPlanner = transportPlanner;
        this.accommodationCatalog = accommodationCatalog;
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

        if (request.latitude() != null && request.longitude() != null) {
            trip.setDestinationLatitude(request.latitude());
            trip.setDestinationLongitude(request.longitude());
        }

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
                                        itemVisitMinutes(item),
                                        item.getDistanceKm(),
                                        item.getEstimatedCostLkr(),
                                        toUsd(item.getEstimatedCostLkr(), trip.getLkrPerUsd()),
                                        item.getAlternatives().stream()
                                                .map(name -> alternativeResponse(item, name, trip))
                                                .filter(java.util.Objects::nonNull)
                                                .toList(),
                                        transportPlanner.options(
                                                item.getSourceReference(),
                                                item.getLocation(),
                                                item.getDistanceKm(),
                                                trip.getGroupSize(),
                                                trip.getBudgetLevel()),
                                        item.getLatitude(),
                                        item.getLongitude(),
                                        item.getDataSource(),
                                        item.getSourceReference(),
                                        item.getSourceUrl()))
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
                trip.getGeneratorType(),
                trip.getProviderNote(),
                trip.getDestinationLatitude(),
                trip.getDestinationLongitude(),
                costSummary,
                days,
                trip.getCreatedAt());
    }


    private AlternativePlaceResponse alternativeResponse(ItineraryItem current, String name, Trip trip) {
        var place = nationwideCatalog.findByName(name);
        if (place.isPresent()) {
            var candidate = place.get();
            BigDecimal distance = alternativeDistance(current, candidate);
            BigDecimal cost = nationwideCatalog.estimatedActivityCost(candidate, trip.getBudgetLevel())
                    .multiply(BigDecimal.valueOf(trip.getGroupSize()));
            return new AlternativePlaceResponse(
                    candidate.place().name(),
                    candidate.place().category(),
                    ShortDescription.limit(candidate.place().description(), 40),
                    candidate.region(),
                    alternativeTravelMinutes(current, candidate, trip.getTransportMode()),
                    generator.activityDurationMinutes(candidate),
                    distance,
                    cost,
                    toUsd(cost, trip.getLkrPerUsd()),
                    transportPlanner.options(candidate.place().sourceReference(), candidate.region(), distance,
                            trip.getGroupSize(), trip.getBudgetLevel()),
                    candidate.place().latitude(), candidate.place().longitude(),
                    candidate.place().dataSource(), candidate.place().sourceReference(), candidate.place().sourceUrl());
        }

        var stay = accommodationCatalog.findByName(name, trip.getBudgetLevel(), trip.getGroupSize());
        if (stay.isPresent()) {
            var option = stay.get();
            BigDecimal distance = accommodationDistance(current, option);
            int travel = accommodationTravelMinutes(distance, trip.getTransportMode());
            return new AlternativePlaceResponse(
                    option.name(),
                    "Accommodation",
                    "Alternative nearby overnight stay: " + option.type() + ". " + option.address()
                            + ". Confirm live room availability and price before booking.",
                    option.address(),
                    travel,
                    60,
                    distance,
                    option.estimatedNightCostLkr(),
                    toUsd(option.estimatedNightCostLkr(), trip.getLkrPerUsd()),
                    transportPlanner.options(null, option.address(), distance, trip.getGroupSize(), trip.getBudgetLevel()),
                    option.latitude(), option.longitude(),
                    "SRI_LANKA_OPEN_DATA", null, null);
        }
        return null;
    }

    private BigDecimal accommodationDistance(
            ItineraryItem current, AccommodationCatalog.AccommodationOption option) {
        if (current.getLatitude() == null || current.getLongitude() == null) return BigDecimal.ZERO;
        return BigDecimal.valueOf(NationwidePlaceCatalog.distanceKm(
                        current.getLatitude(), current.getLongitude(), option.latitude(), option.longitude()) * 1.22)
                .setScale(2, RoundingMode.HALF_UP);
    }

    private int accommodationTravelMinutes(BigDecimal distance, String transportMode) {
        if (distance.signum() <= 0) return 0;
        String mode = transportMode == null ? "" : transportMode.toLowerCase(java.util.Locale.ROOT);
        double speed = mode.contains("public") || mode.contains("bus") || mode.contains("train") ? 32.0
                : mode.contains("tuk") ? 28.0 : 42.0;
        return Math.max(10, (int) Math.ceil(distance.doubleValue() / speed * 60));
    }


    private int itemVisitMinutes(ItineraryItem item) {
        int start = item.getStartTime().toSecondOfDay() / 60;
        int end = item.getEndTime().toSecondOfDay() / 60;
        int duration = end - start;
        if (duration < 0) duration += 24 * 60;
        return Math.max(0, duration);
    }

    private BigDecimal alternativeDistance(ItineraryItem current, NationwidePlaceCatalog.TravelCandidate alternative) {
        if (current.getLatitude() == null || current.getLongitude() == null
                || alternative.place().latitude() == null || alternative.place().longitude() == null) {
            return BigDecimal.ZERO;
        }
        return BigDecimal.valueOf(NationwidePlaceCatalog.distanceKm(
                        current.getLatitude(), current.getLongitude(),
                        alternative.place().latitude(), alternative.place().longitude()) * 1.22)
                .setScale(2, RoundingMode.HALF_UP);
    }

    private int alternativeTravelMinutes(
            ItineraryItem current,
            NationwidePlaceCatalog.TravelCandidate alternative,
            String transportMode) {
        BigDecimal distance = alternativeDistance(current, alternative);
        if (distance.signum() <= 0) return 0;
        String mode = transportMode == null ? "" : transportMode.toLowerCase(java.util.Locale.ROOT);
        double speed = mode.contains("public") || mode.contains("bus") || mode.contains("train") ? 32.0
                : mode.contains("tuk") ? 28.0 : 42.0;
        return Math.max(10, (int) Math.ceil(distance.doubleValue() / speed * 60));
    }

    private BigDecimal toUsd(BigDecimal lkr, BigDecimal rate) {
        if (rate == null || rate.signum() <= 0) return BigDecimal.ZERO;
        return lkr.divide(rate, 2, RoundingMode.HALF_UP);
    }
}
