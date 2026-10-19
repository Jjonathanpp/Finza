package com.finza.backend.model;

import java.time.LocalDate;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToOne;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Getter
@Setter
@NoArgsConstructor
public class Usuario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private Long dni;

    @Column(unique = true)
    private String telefono;

    @Column(nullable = false)
    private String nombre;

    @Column(nullable = false)
    private String apellido;

    private LocalDate fechaNacimiento;

    @Enumerated(EnumType.STRING)
    private Genero genero;

    @OneToOne(mappedBy = "usuario", cascade = CascadeType.ALL, orphanRemoval = true)
    private CuentaMP cuentaMP;

    public enum Genero {
        MASCULINO,
        FEMENINO,
        OTRO
    }

}
