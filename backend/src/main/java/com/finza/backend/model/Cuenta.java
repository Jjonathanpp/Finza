package com.finza.backend.model;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "cuentas")
@Getter
@Setter
@NoArgsConstructor  
public class Cuenta {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne
    @JoinColumn(name = "usuario_id", nullable = false, unique = true)
    private Usuario usuario;

    @Column(unique = true, nullable = false)
    private String email;
    
    @Column(nullable = false)
    private String password;

    private boolean emailVerificado;

    private LocalDateTime fechaCreacion;

    @Enumerated(EnumType.STRING)
    private Estado estado;

    public enum Estado {
        ACTIVA,
        INACTIVA,
        BLOQUEADA,
        PENDIENTE_VERIFICACION
    }



    
}
