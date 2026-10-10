package com.finza.backend.model;

import java.time.LocalDate;

import com.finza.backend.model.PreferenciasSistema.Idioma;
import com.finza.backend.model.PreferenciasSistema.Moneda;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
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
public class PreferenciasSistema {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne
    @JoinColumn(name = "perfil_id", nullable = false, unique = true)
    private Perfil perfil;

    @Enumerated(EnumType.STRING)
    @Column(name = "idioma")
    private Idioma idioma = Idioma.ESPANOL;

    public enum Idioma {
        ESPANOL,
        INGLES
    }

    @Enumerated(EnumType.STRING)
    @Column(name = "moneda")
    private Moneda moneda = Moneda.PESO;

    public enum Moneda {
        PESO,
        DOLAR,
        EURO
    }

    private boolean notificacionesHabilitadas = true;

    @Enumerated(EnumType.STRING)
    @Column(name = "tema")
    private Tema tema = Tema.CLARO;

    public enum Tema {
        CLARO,
        OSCURO
    }

    @Enumerated(EnumType.STRING)
    @Column(name = "vista_balance")
    private VistaBalance vistaBalance = VistaBalance.MENSUAL_ACTUAL;

    public enum VistaBalance {
        MENSUAL_ACTUAL,
        BIMESTRAL,
        TRIMESTRAL,
        CUATRIMESTRAL,
        ANUAL,
        PERSONALIZADO
    }

    @Column(name = "fecha_balance_inicio")
    private LocalDate fechaBalanceInicio;

    @Column(name = "fecha_balance_fin")
    private LocalDate fechaBalanceFin;

}
