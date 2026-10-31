package com.finza.backend.model;

import java.util.ArrayList;
import java.util.List;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Getter
@Setter
@NoArgsConstructor
public class Categoria {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Predefinida: sin cuenta ni cuenta compartida. Propia: de una cuenta o de una cuenta compartida.
    @ManyToOne
    @JoinColumn(name = "cuenta_id", nullable = true)
    private Cuenta cuenta;

    @ManyToOne
    @JoinColumn(name = "cuenta_compartida_id")
    private CuentaCompartida cuentaCompartida;

    private String nombre;
    private String color;
    private boolean es_predefinida;

    @Enumerated(EnumType.STRING)
    @Column(name = "tipo_categoria_predefinida")
    private TipoCategoria tipoCategoriaPredefinida;

    @OneToMany(mappedBy = "categoria", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Movimiento> movimientos = new ArrayList<>();

    @OneToMany(mappedBy = "categoria", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Presupuesto> presupuestos = new ArrayList<>();

    public enum TipoCategoria {
        INGRESO,
        EGRESO
    }

}