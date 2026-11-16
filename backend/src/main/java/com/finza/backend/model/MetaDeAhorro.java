package com.finza.backend.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.FutureOrPresent;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Getter 
@Setter 
@Table(name = "metas_ahorro")
public class MetaDeAhorro {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "El nombre de la meta es obligatorio")
    @Size(max = 100, message = "El nombre de la meta no puede superar los 100 caracteres")
    @Column(nullable = false, length = 100)
    private String nombre;

    @NotNull(message = "El monto objetivo es obligatorio")
    @DecimalMin(value = "0.01", message = "El monto objetivo debe ser mayor a cero")
    @Column(name = "monto_objetivo", nullable = false, precision = 12, scale = 2)
    private BigDecimal montoObjetivo;

    @NotNull
    @DecimalMin(value = "0.00", message = "El monto actual no puede ser negativo")
    @Column(name = "monto_actual", nullable = false, precision = 12, scale = 2)
    private BigDecimal montoActual = BigDecimal.ZERO;

    @FutureOrPresent(message = "La fecha límite no puede estar en el pasado")
    @Column(name = "fecha_limite")
    private LocalDate fechaLimite;

    @ManyToOne
    @JoinColumn(name = "perfil_id")
    private Perfil perfil;
    
    @ManyToOne
    @JoinColumn(name = "cuenta_compartida_id")
    private CuentaCompartida cuentaCompartida;

    @Column(name = "fecha_creacion", nullable = false, updatable = false)
    private LocalDateTime fechaCreacion;

    @PrePersist
    private void asignarFechaCreacion() {
        if (fechaCreacion == null) {
            fechaCreacion = LocalDateTime.now();
        }
    }

}