package com.aitravelplanner.cost;

import com.aitravelplanner.cost.dto.CostPredictionRequest;
import com.aitravelplanner.cost.dto.CostPredictionResponse;
import com.aitravelplanner.cost.dto.PythonCostPredictionRequest;
import com.aitravelplanner.cost.dto.PythonCostPredictionResponse;
import java.time.Duration;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Service
public class CostPredictionClient {

    private static final String DEFAULT_BASE_URL = "http://127.0.0.1:8001";

    private final RestClient restClient;

    /**
     * Spring uses this constructor.
     * COST_PREDICTION_URL can override the default endpoint.
     */
    public CostPredictionClient() {
        this(createRestClient(resolveBaseUrl()));
    }

    /**
     * Package-private constructor used only by unit tests.
     */
    CostPredictionClient(RestClient restClient) {
        this.restClient = restClient;
    }

    private static String resolveBaseUrl() {
        String configured = System.getenv("COST_PREDICTION_URL");
        if (configured == null || configured.isBlank()) {
            return DEFAULT_BASE_URL;
        }
        return configured.trim();
    }

    private static RestClient createRestClient(String baseUrl) {
        SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
        requestFactory.setConnectTimeout(Duration.ofSeconds(3));
        requestFactory.setReadTimeout(Duration.ofSeconds(15));

        return RestClient.builder()
                .baseUrl(baseUrl)
                .requestFactory(requestFactory)
                .build();
    }

    public CostPredictionResponse predict(CostPredictionRequest request) {
        try {
            PythonCostPredictionResponse response = restClient.post()
                    .uri("/predict")
                    .body(PythonCostPredictionRequest.from(request))
                    .retrieve()
                    .body(PythonCostPredictionResponse.class);

            if (response == null) {
                throw new CostPredictionUnavailableException(
                        "The XGBoost cost service returned an empty response.");
            }

            return response.toPublicResponse();
        } catch (CostPredictionUnavailableException exception) {
            throw exception;
        } catch (RestClientException exception) {
            throw new CostPredictionUnavailableException(
                    "The XGBoost cost prediction service is unavailable.", exception);
        }
    }
}
