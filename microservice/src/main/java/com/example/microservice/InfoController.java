package com.example.microservice;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class InfoController {

    @Value("${app.local.config:default-local-config}")
    private String localConfig;

    @GetMapping("/secret")
    public String secret() {
        String secret = System.getenv("SECRET_FROM_VAULT");
        if (secret == null) {
            secret = "NO_SECRET_DEFINED";
        }
        return secret;
    }

    @GetMapping("/config")
    public String config() {
        return localConfig;
    }
}