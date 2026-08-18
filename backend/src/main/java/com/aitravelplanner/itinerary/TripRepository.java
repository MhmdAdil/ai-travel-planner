package com.aitravelplanner.itinerary;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TripRepository extends JpaRepository<Trip, Long> {

    List<Trip> findAllByUserEmailIgnoreCaseOrderByCreatedAtDesc(String email);

    Optional<Trip> findByIdAndUserEmailIgnoreCase(Long id, String email);
}
