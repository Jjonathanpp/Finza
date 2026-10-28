package com.finza.backend.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

// La cuenta que comparten varias personas (por ejemplo "Casa"). No tiene login propio:
// cada integrante entra con su cuenta y tiene ahí un perfil que apunta a esta.
@Entity
@Table(name = "cuentas_compartidas")
@Getter
@Setter
@NoArgsConstructor
public class CuentaCompartida {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nombre;

    // El perfil de quien la creó: es ADMIN y nadie le puede cambiar el rol.
    @OneToOne
    @JoinColumn(name = "creador_id")
    private Perfil creador;
}
