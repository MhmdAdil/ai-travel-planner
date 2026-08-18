package com.aitravelplanner;

import com.aitravelplanner.config.JwtProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

@SpringBootApplication
@EnableConfigurationProperties(JwtProperties.class)
public class AiTravelPlannerApplication {

    public static void main(String[] args) {
        SpringApplication.run(AiTravelPlannerApplication.class, args);
    }
}
