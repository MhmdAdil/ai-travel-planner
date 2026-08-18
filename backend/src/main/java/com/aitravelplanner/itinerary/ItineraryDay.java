package com.aitravelplanner.itinerary;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "itinerary_days")
public class ItineraryDay {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "trip_id", nullable = false)
    private Trip trip;

    @Column(name = "day_number", nullable = false)
    private int dayNumber;

    @Column(name = "trip_date", nullable = false)
    private LocalDate date;

    @Column(nullable = false, length = 120)
    private String theme;

    @Column(name = "estimated_cost_lkr", nullable = false, precision = 14, scale = 2)
    private BigDecimal estimatedCostLkr;

    @OneToMany(mappedBy = "day", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("startTime ASC")
    private List<ItineraryItem> items = new ArrayList<>();

    protected ItineraryDay() {
    }

    public ItineraryDay(int dayNumber, LocalDate date, String theme) {
        this.dayNumber = dayNumber;
        this.date = date;
        this.theme = theme;
        this.estimatedCostLkr = BigDecimal.ZERO;
    }

    void attachTo(Trip trip) {
        this.trip = trip;
    }

    public void addItem(ItineraryItem item) {
        items.add(item);
        item.attachTo(this);
        estimatedCostLkr = estimatedCostLkr.add(item.getEstimatedCostLkr());
    }

    public int getDayNumber() { return dayNumber; }
    public LocalDate getDate() { return date; }
    public String getTheme() { return theme; }
    public BigDecimal getEstimatedCostLkr() { return estimatedCostLkr; }
    public List<ItineraryItem> getItems() { return List.copyOf(items); }
}
