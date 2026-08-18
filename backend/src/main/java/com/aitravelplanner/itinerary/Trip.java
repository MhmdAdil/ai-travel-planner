package com.aitravelplanner.itinerary;

import com.aitravelplanner.user.AppUser;
import jakarta.persistence.CascadeType;
import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "trips")
public class Trip {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private AppUser user;

    @Column(nullable = false, length = 120)
    private String title;

    @Column(name = "destination_region", nullable = false, length = 80)
    private String destinationRegion;

    @Column(name = "start_location", nullable = false, length = 180)
    private String startLocation;

    @Column(name = "arrival_date_time", nullable = false)
    private LocalDateTime arrivalDateTime;

    @Column(name = "departure_date_time", nullable = false)
    private LocalDateTime departureDateTime;

    @Enumerated(EnumType.STRING)
    @Column(name = "budget_level", nullable = false, length = 10)
    private BudgetLevel budgetLevel;

    @Column(name = "budget_lkr", nullable = false, precision = 14, scale = 2)
    private BigDecimal budgetLkr;

    @Column(name = "group_size", nullable = false)
    private int groupSize;

    @Column(name = "accommodation_type", nullable = false, length = 40)
    private String accommodationType;

    @Column(name = "food_preference", nullable = false, length = 60)
    private String foodPreference;

    @Column(name = "transport_mode", nullable = false, length = 40)
    private String transportMode;

    @Column(nullable = false, length = 30)
    private String pace;

    @Column(length = 500)
    private String notes;

    @ElementCollection
    @CollectionTable(name = "trip_interests", joinColumns = @JoinColumn(name = "trip_id"))
    @Column(name = "interest", nullable = false, length = 50)
    private List<String> interests = new ArrayList<>();

    @ElementCollection
    @CollectionTable(name = "trip_activities", joinColumns = @JoinColumn(name = "trip_id"))
    @Column(name = "activity", nullable = false, length = 50)
    private List<String> activities = new ArrayList<>();

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 15)
    private TripStatus status;

    @Column(name = "accommodation_cost_lkr", nullable = false, precision = 14, scale = 2)
    private BigDecimal accommodationCostLkr = BigDecimal.ZERO;

    @Column(name = "food_cost_lkr", nullable = false, precision = 14, scale = 2)
    private BigDecimal foodCostLkr = BigDecimal.ZERO;

    @Column(name = "transport_cost_lkr", nullable = false, precision = 14, scale = 2)
    private BigDecimal transportCostLkr = BigDecimal.ZERO;

    @Column(name = "activities_cost_lkr", nullable = false, precision = 14, scale = 2)
    private BigDecimal activitiesCostLkr = BigDecimal.ZERO;

    @Column(name = "total_cost_lkr", nullable = false, precision = 14, scale = 2)
    private BigDecimal totalCostLkr = BigDecimal.ZERO;

    @Column(name = "lkr_per_usd", nullable = false, precision = 10, scale = 4)
    private BigDecimal lkrPerUsd;

    @OneToMany(mappedBy = "trip", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("dayNumber ASC")
    private List<ItineraryDay> days = new ArrayList<>();

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    protected Trip() {
    }

    public Trip(
            AppUser user,
            String title,
            String destinationRegion,
            String startLocation,
            LocalDateTime arrivalDateTime,
            LocalDateTime departureDateTime,
            BudgetLevel budgetLevel,
            BigDecimal budgetLkr,
            int groupSize,
            String accommodationType,
            String foodPreference,
            String transportMode,
            String pace,
            String notes,
            List<String> interests,
            List<String> activities,
            BigDecimal lkrPerUsd) {
        this.user = user;
        this.title = title;
        this.destinationRegion = destinationRegion;
        this.startLocation = startLocation;
        this.arrivalDateTime = arrivalDateTime;
        this.departureDateTime = departureDateTime;
        this.budgetLevel = budgetLevel;
        this.budgetLkr = budgetLkr;
        this.groupSize = groupSize;
        this.accommodationType = accommodationType;
        this.foodPreference = foodPreference;
        this.transportMode = transportMode;
        this.pace = pace;
        this.notes = notes;
        this.interests.addAll(interests);
        this.activities.addAll(activities);
        this.status = TripStatus.DRAFT;
        this.lkrPerUsd = lkrPerUsd;
    }

    @PrePersist
    void onCreate() {
        createdAt = Instant.now();
    }

    public void addDay(ItineraryDay day) {
        days.add(day);
        day.attachTo(this);
    }

    public void complete(
            BigDecimal accommodation,
            BigDecimal food,
            BigDecimal transport,
            BigDecimal activities) {
        accommodationCostLkr = accommodation;
        foodCostLkr = food;
        transportCostLkr = transport;
        activitiesCostLkr = activities;
        totalCostLkr = accommodation.add(food).add(transport).add(activities);
        status = TripStatus.GENERATED;
    }

    public Long getId() { return id; }
    public String getTitle() { return title; }
    public String getDestinationRegion() { return destinationRegion; }
    public String getStartLocation() { return startLocation; }
    public LocalDateTime getArrivalDateTime() { return arrivalDateTime; }
    public LocalDateTime getDepartureDateTime() { return departureDateTime; }
    public BudgetLevel getBudgetLevel() { return budgetLevel; }
    public BigDecimal getBudgetLkr() { return budgetLkr; }
    public int getGroupSize() { return groupSize; }
    public String getAccommodationType() { return accommodationType; }
    public String getFoodPreference() { return foodPreference; }
    public String getTransportMode() { return transportMode; }
    public String getPace() { return pace; }
    public String getNotes() { return notes; }
    public List<String> getInterests() { return List.copyOf(interests); }
    public List<String> getActivities() { return List.copyOf(activities); }
    public TripStatus getStatus() { return status; }
    public BigDecimal getAccommodationCostLkr() { return accommodationCostLkr; }
    public BigDecimal getFoodCostLkr() { return foodCostLkr; }
    public BigDecimal getTransportCostLkr() { return transportCostLkr; }
    public BigDecimal getActivitiesCostLkr() { return activitiesCostLkr; }
    public BigDecimal getTotalCostLkr() { return totalCostLkr; }
    public BigDecimal getLkrPerUsd() { return lkrPerUsd; }
    public List<ItineraryDay> getDays() { return List.copyOf(days); }
    public Instant getCreatedAt() { return createdAt; }
}
