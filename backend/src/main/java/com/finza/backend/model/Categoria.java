package com.finza.backend.model;

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
public class Categoria {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "cuenta_id", nullable = true)
    private Cuenta cuenta;

    private String nombre;
    private String color;
    private boolean es_predefinida;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "tipo_categoria_predefinida")
    private TipoCategoria tipoCategoriaPredefinida;

    public enum TipoCategoria {
        INGRESO,
        EGRESO
    }



}