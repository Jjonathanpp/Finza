package com.finza.backend.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;
import lombok.Getter;
import lombok.Setter;

@Configuration
@ConfigurationProperties(prefix = "mercadopago")
@Getter
@Setter
public class MercadoPagoProperties {
    private String clientId;
    private String clientSecret;
    private String redirectUri;
}