package com.finza.backend.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "metas_ahorro_aportes")
@Getter
@Setter
@NoArgsConstructor
public class AporteMetaAhorro {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotNull
    @DecimalMin(value = "0.01")
    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal monto;

    @Column(name = "fecha_aporte", nullable = false, updatable = false)
    private LocalDateTime fechaAporte;

    @ManyToOne(optional = false)
    @JoinColumn(name = "meta_id", nullable = false)
    private MetaDeAhorro meta;

    @ManyToOne
    @JoinColumn(name = "perfil_id")
    private Perfil perfil;

    @PrePersist
    private void asignarFechaAporte() {
        if (fechaAporte == null) {
            fechaAporte = LocalDateTime.now();
        }
    }
}
