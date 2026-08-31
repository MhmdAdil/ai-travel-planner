package com.aitravelplanner.cost;

import com.aitravelplanner.cost.dto.CostPredictionRequest;
import com.aitravelplanner.cost.dto.CostPredictionResponse;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/cost")
public class CostPredictionController {

    private final CostPredictionClient costPredictionClient;

    public CostPredictionController(CostPredictionClient costPredictionClient) {
        this.costPredictionClient = costPredictionClient;
    }

    @PostMapping("/predict")
    CostPredictionResponse predict(@Valid @RequestBody CostPredictionRequest request) {
        return costPredictionClient.predict(request);
    }
}
