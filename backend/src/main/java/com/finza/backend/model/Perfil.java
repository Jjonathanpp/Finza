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
import jakarta.persistence.OneToOne;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Getter
@Setter
@NoArgsConstructor
public class Perfil {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // La cuenta con la que inicia sesión el dueño del perfil. Solo queda vacía en el perfil de una
    // cuenta compartida cuyo dueño se dio de baja.
    @ManyToOne
    @JoinColumn(name = "cuenta_id")
    private Cuenta cuenta;

    // Vacía en el perfil personal; en los demás, la cuenta compartida a la que pertenece el perfil.
    @ManyToOne
    @JoinColumn(name = "cuenta_compartida_id")
    private CuentaCompartida cuentaCompartida;

    @OneToMany(mappedBy = "perfil", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Movimiento> movimientos = new ArrayList<>();

    @OneToMany(mappedBy = "perfil", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Presupuesto> presupuestos = new ArrayList<>();

    @OneToOne(mappedBy = "perfil", cascade = CascadeType.ALL, orphanRemoval = true)
    private PreferenciasSistema preferenciasSistema;
    private String nombrePerfil;
    // El perfil personal es ADMIN. En una cuenta compartida, ADMIN el que la creó y MIEMBRO los invitados.
    @Enumerated(EnumType.STRING)
    private Rol rol;
    @Column(name = "foto_url")
    private String foto;
    private boolean esPrincipal;
    private boolean esActivo;

    public enum Rol {
        ADMIN,
        MIEMBRO
    }

}
