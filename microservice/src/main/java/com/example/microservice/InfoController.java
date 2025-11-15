package com.example.microservice;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class InfoController {

    @Value("${SECRET_FROM_VAULT:NO_SECRET_DEFINED_IN_CLUSTER_YET}")
    private String secretFromVault;

    @Value("${app.local.config:valor-config-local}")
    private String localConfig;

    @GetMapping("/secret")
    public Map<String, String> getSecret() {
        return Map.of(
                "secretFromVault", secretFromVault
        );
    }

    @GetMapping("/config")
    public Map<String, String> getConfig() {
        return Map.of(
                "localConfig", localConfig
        );
    }
}