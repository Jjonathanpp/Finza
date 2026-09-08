package com.finza.backend.model;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

import com.finza.backend.model.Movimiento.EstadoMovimiento;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Getter
@Setter
@NoArgsConstructor
public class Movimiento {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "perfil_id", nullable = false)
    private Perfil perfil;

    @ManyToOne
    @JoinColumn(name = "categoria_id", nullable = false)
    private Categoria categoria;

    @Column(precision = 12, scale = 2)
    private BigDecimal monto;
    private boolean esIngreso;
    private LocalDate fecha;
    private String descripcion;
    @Enumerated(EnumType.STRING)
    @Column(name = "estado")
    private EstadoMovimiento estado;

    public enum EstadoMovimiento {
        PENDIENTE,
        APROBADO,
        RECHAZADO
    }

    @Enumerated(EnumType.STRING)
    @Column(name = "origen")
    private OrigenMovimiento origen;

    public enum OrigenMovimiento {
        MANUAL,
        VOZ,
        MERCADOPAGO
    }

    private LocalDateTime fechaCreacion;

    @Column(name = "external_id", unique = true)
    private String externalId; //Para la integracion con MP



    
}
