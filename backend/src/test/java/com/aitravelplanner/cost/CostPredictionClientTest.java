package com.aitravelplanner.cost;

import static org.assertj.core.api.Assertions.assertThat;

import com.aitravelplanner.cost.dto.CostPredictionRequest;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

import static org.springframework.test.web.client.match.MockRestRequestMatchers.content;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;
import org.springframework.http.HttpMethod;

class CostPredictionClientTest {

    @Test
    void mapsSpringRequestToPythonSnakeCaseAndBack() {
        RestClient.Builder builder = RestClient.builder().baseUrl("http://127.0.0.1:8001");
        MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
        CostPredictionClient client = new CostPredictionClient(builder.build());

        server.expect(requestTo("http://127.0.0.1:8001/predict"))
                .andExpect(method(HttpMethod.POST))
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(content().json("""
                        {
                          "duration_days":4,
                          "travellers":2,
                          "budget_lkr":120000,
                          "budget_level":"LOW",
                          "accommodation_type":"Budget guesthouse",
                          "food_preference":"Sri Lankan",
                          "transport_mode":"Public transport + Tuk/Taxi",
                          "pace":"Balanced",
                          "region_count":2,
                          "region_cost_index":1.12,
                          "public_transport_coverage":0.40,
                          "public_transport_km":400.0,
                          "private_transport_km":600.0,
                          "public_transport_cost_lkr":6200.0,
                          "private_transport_cost_lkr":59025.0,
                          "calculated_transport_cost_lkr":65225.0,
                          "place_count":7,
                          "activity_count":5,
                          "has_beach":1,
                          "has_culture":1,
                          "has_wildlife":1,
                          "has_nature":0,
                          "has_history":0,
                          "has_adventure":0,
                          "has_hiking":0,
                          "has_surfing":1,
                          "has_safari":1,
                          "has_swimming":0,
                          "has_cycling":0,
                          "has_food_tour":0,
                          "has_shopping":0,
                          "route_distance_km":420.0,
                          "estimated_travel_hours":11.5,
                          "nights":3,
                          "rooms":1
                        }
                        """))
                .andRespond(withSuccess("""
                        {
                          "accommodation_cost_lkr":36077.18,
                          "food_cost_lkr":31702.89,
                          "transport_cost_lkr":65225.0,"public_transport_km":400.0,"private_transport_km":600.0,"public_transport_cost_lkr":6200.0,"private_transport_cost_lkr":59025.0,
                          "activities_cost_lkr":41642.33,
                          "total_predicted_cost_lkr":123308.08,
                          "user_budget_lkr":120000.0,
                          "budget_difference_lkr":-3308.08,
                          "within_budget":false,
                          "model":"XGBoost"
                        }
                        """, MediaType.APPLICATION_JSON));

        var response = client.predict(example());

        assertThat(response.totalPredictedCostLkr()).isEqualTo(123308.08);
        assertThat(response.withinBudget()).isFalse();
        assertThat(response.model()).isEqualTo("XGBoost");

        server.verify();
    }

    private CostPredictionRequest example() {
        return new CostPredictionRequest(
                4,
                2,
                120000,
                "LOW",
                "Budget guesthouse",
                "Sri Lankan",
                "Public transport + Tuk/Taxi",
                "Balanced",
                2,
                1.12,
                0.40,
                400.0,
                600.0,
                6200.0,
                59025.0,
                65225.0,
                7,
                5,
                true,
                true,
                true,
                false,
                false,
                false,
                false,
                true,
                true,
                false,
                false,
                false,
                false,
                420.0,
                11.5,
                3,
                1);
    }
}
