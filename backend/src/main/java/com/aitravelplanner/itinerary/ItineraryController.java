package com.aitravelplanner.itinerary;

import com.aitravelplanner.itinerary.dto.GenerateItineraryRequest;
import com.aitravelplanner.itinerary.dto.ItineraryResponse;
import jakarta.validation.Valid;
import java.security.Principal;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/itinerary")
public class ItineraryController {

    private final ItineraryService itineraryService;

    public ItineraryController(ItineraryService itineraryService) {
        this.itineraryService = itineraryService;
    }

    @PostMapping("/generate")
    @ResponseStatus(HttpStatus.CREATED)
    ItineraryResponse generate(
            Principal principal,
            @Valid @RequestBody GenerateItineraryRequest request) {
        return itineraryService.generate(principal.getName(), request);
    }

    @GetMapping
    List<ItineraryResponse> list(Principal principal) {
        return itineraryService.list(principal.getName());
    }

    @GetMapping("/{id}")
    ItineraryResponse get(Principal principal, @PathVariable Long id) {
        return itineraryService.get(principal.getName(), id);
    }
}
