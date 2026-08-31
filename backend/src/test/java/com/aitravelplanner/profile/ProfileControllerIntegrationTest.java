package com.aitravelplanner.profile;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.aitravelplanner.itinerary.TripRepository;
import com.aitravelplanner.user.UserRepository;
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
class ProfileControllerIntegrationTest {

    @Autowired MockMvc mockMvc;
    @Autowired ObjectMapper objectMapper;
    @Autowired UserRepository userRepository;
    @Autowired TripRepository tripRepository;

    @BeforeEach
    void cleanDatabase() {
        tripRepository.deleteAll();
        userRepository.deleteAll();
    }

    @Test
    void readsAndUpdatesUsernameAndChangesPassword() throws Exception {
        register();
        String token = login("secret123");

        mockMvc.perform(get("/api/profile").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.username").value("adil01"))
                .andExpect(jsonPath("$.email").value("adil@example.com"));

        mockMvc.perform(patch("/api/profile/username")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"adil_traveller\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.username").value("adil_traveller"));

        mockMvc.perform(patch("/api/profile/password")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"currentPassword\":\"secret123\",\"newPassword\":\"newsecret456\"}"))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"adil@example.com\",\"password\":\"newsecret456\"}"))
                .andExpect(status().isOk());
    }

    @Test
    void rejectsWrongCurrentPassword() throws Exception {
        register();
        String token = login("secret123");

        mockMvc.perform(patch("/api/profile/password")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"currentPassword\":\"wrongpass\",\"newPassword\":\"newsecret456\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Current password is incorrect."));
    }

    private void register() throws Exception {
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"username\":\"adil01\",\"email\":\"adil@example.com\",\"password\":\"secret123\"}"))
                .andExpect(status().isCreated());
    }

    private String login(String password) throws Exception {
        String json = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"adil@example.com\",\"password\":\"" + password + "\"}"))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();
        JsonNode root = objectMapper.readTree(json);
        return root.get("token").asText();
    }
}
