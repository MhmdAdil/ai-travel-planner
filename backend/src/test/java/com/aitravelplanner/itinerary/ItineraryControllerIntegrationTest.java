package com.aitravelplanner.itinerary;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.aitravelplanner.user.UserRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ItineraryControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private TripRepository tripRepository;

    @Autowired
    private UserRepository userRepository;

    @BeforeEach
    void cleanDatabase() {
        tripRepository.deleteAll();
        userRepository.deleteAll();
    }

    @Test
    void generatesAndPersistsDayByDayItinerary() throws Exception {
        String token = registerAndLogin();
        LocalDateTime arrival = LocalDateTime.now().plusDays(2).withHour(9).withMinute(0).withSecond(0).withNano(0);
        LocalDateTime departure = arrival.plusDays(2).withHour(18);
        String request = """
                {
                  "destinationRegion": "Kandy",
                  "startLocation": "Bandaranaike International Airport",
                  "arrivalDateTime": "%s",
                  "departureDateTime": "%s",
                  "budgetLevel": "MID",
                  "budgetLkr": 180000,
                  "groupSize": 2,
                  "interests": ["Culture", "Nature"],
                  "activities": ["Hiking", "Food tours"],
                  "accommodationType": "Mid-range hotel",
                  "foodPreference": "Sri Lankan",
                  "transportMode": "Public transport",
                  "pace": "Balanced",
                  "notes": "Prefer early mornings"
                }
                """.formatted(
                arrival.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME),
                departure.format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));

        mockMvc.perform(post("/api/itinerary/generate")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(request))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNumber())
                .andExpect(jsonPath("$.destinationRegion").value("Kandy"))
                .andExpect(jsonPath("$.generatorType").value("OPENSTREETMAP_PREFERENCE_ROUTE"))
                .andExpect(jsonPath("$.providerNote").isNotEmpty())
                .andExpect(jsonPath("$.days.length()").value(3))
                .andExpect(jsonPath("$.days[0].items[0].name").isNotEmpty())
                .andExpect(jsonPath("$.days[0].items[0].dataSource").value("OPENSTREETMAP_OFFLINE"))
                .andExpect(jsonPath("$.costSummary.totalLkr").isNumber())
                .andExpect(jsonPath("$.costSummary.totalUsd").isNumber())
                .andExpect(jsonPath("$.costSummary.lkrPerUsd").value(310.0));

        mockMvc.perform(get("/api/itinerary")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].days.length()").value(3));
    }

    @Test
    void rejectsItineraryWithoutAuthentication() throws Exception {
        mockMvc.perform(get("/api/itinerary"))
                .andExpect(status().isUnauthorized());
    }

    private String registerAndLogin() throws Exception {
    String registerCredentials =
            "{\"username\":\"planner01\",\"email\":\"planner@example.com\",\"password\":\"secret123\"}";

    String loginCredentials =
            "{\"email\":\"planner@example.com\",\"password\":\"secret123\"}";

    mockMvc.perform(post("/api/auth/register")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(registerCredentials))
            .andExpect(status().isCreated());

    String response = mockMvc.perform(post("/api/auth/login")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(loginCredentials))
            .andExpect(status().isOk())
            .andReturn()
            .getResponse()
            .getContentAsString();

    JsonNode json = objectMapper.readTree(response);
    return json.get("token").asText();
}
}
