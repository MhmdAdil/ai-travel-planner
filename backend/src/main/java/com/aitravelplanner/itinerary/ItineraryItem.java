package com.aitravelplanner.itinerary;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "itinerary_items")
public class ItineraryItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "day_id", nullable = false)
    private ItineraryDay day;

    @Column(name = "start_time", nullable = false)
    private LocalTime startTime;

    @Column(name = "end_time", nullable = false)
    private LocalTime endTime;

    @Column(nullable = false, length = 140)
    private String name;

    @Column(nullable = false, length = 60)
    private String category;

    @Column(nullable = false, length = 500)
    private String description;

    @Column(nullable = false, length = 180)
    private String location;

    @Column(name = "travel_minutes", nullable = false)
    private int travelMinutes;

    @Column(name = "distance_km", nullable = false, precision = 8, scale = 2)
    private BigDecimal distanceKm;

    @Column(name = "estimated_cost_lkr", nullable = false, precision = 14, scale = 2)
    private BigDecimal estimatedCostLkr;

    @ElementCollection
    @CollectionTable(name = "itinerary_item_alternatives", joinColumns = @JoinColumn(name = "item_id"))
    @Column(name = "alternative", nullable = false, length = 180)
    private List<String> alternatives = new ArrayList<>();

    protected ItineraryItem() {
    }

    public ItineraryItem(
            LocalTime startTime,
            LocalTime endTime,
            String name,
            String category,
            String description,
            String location,
            int travelMinutes,
            BigDecimal distanceKm,
            BigDecimal estimatedCostLkr,
            List<String> alternatives) {
        this.startTime = startTime;
        this.endTime = endTime;
        this.name = name;
        this.category = category;
        this.description = description;
        this.location = location;
        this.travelMinutes = travelMinutes;
        this.distanceKm = distanceKm;
        this.estimatedCostLkr = estimatedCostLkr;
        this.alternatives.addAll(alternatives);
    }

    void attachTo(ItineraryDay day) {
        this.day = day;
    }

    public LocalTime getStartTime() { return startTime; }
    public LocalTime getEndTime() { return endTime; }
    public String getName() { return name; }
    public String getCategory() { return category; }
    public String getDescription() { return description; }
    public String getLocation() { return location; }
    public int getTravelMinutes() { return travelMinutes; }
    public BigDecimal getDistanceKm() { return distanceKm; }
    public BigDecimal getEstimatedCostLkr() { return estimatedCostLkr; }
    public List<String> getAlternatives() { return List.copyOf(alternatives); }
}
