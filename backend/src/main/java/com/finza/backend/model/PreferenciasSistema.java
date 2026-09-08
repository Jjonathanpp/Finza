package com.finza.backend.model;

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
    @JoinColumn(name = "cuenta_id", nullable = false, unique = true)
    private Cuenta cuenta;

    @Enumerated(EnumType.STRING)
    @Column(name = "idioma")
    private Idioma idioma;

    public enum Idioma {
        ESPANOL,
        INGLES
    }

    @Enumerated(EnumType.STRING)
    @Column(name = "moneda")
    private Moneda moneda;

    public enum Moneda {
        PESO,
        DOLAR,
        EURO
    }

    private boolean notificacionesHabilitadas;

    @Enumerated(EnumType.STRING)
    @Column(name = "tema")
    private Tema tema;

    public enum Tema {
        CLARO,
        OSCURO
    }

}
