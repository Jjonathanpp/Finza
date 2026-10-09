package com.finza.backend.model;

import java.time.LocalDate;
import java.time.LocalDateTime;

import com.finza.backend.security.CryptoConverter;

import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Getter
@Setter
@NoArgsConstructor
public class CuentaMP {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne
    @JoinColumn(name = "cuenta_id", nullable = false, unique = true)
    private Usuario usuario;

    private String mpIdUser;

    @Convert(converter = CryptoConverter.class)
    private String accessToken;

    @Convert(converter = CryptoConverter.class)
    private String refreshToken;

    private LocalDateTime fechaExpiracionToken;
    private LocalDate fechaVisualizacion;
}