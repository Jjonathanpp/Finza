package com.finza.backend.config;

import java.time.LocalDateTime;

import com.finza.backend.model.Cuenta;
import com.finza.backend.model.Perfil;
import com.finza.backend.model.Usuario;
import com.finza.backend.repository.CuentaRepository;
import com.finza.backend.repository.PerfilRepository;
import com.finza.backend.repository.UsuarioRepository;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import lombok.RequiredArgsConstructor;

@Component
@RequiredArgsConstructor
public class DataInitializer implements ApplicationRunner {

    private final UsuarioRepository usuarioRepository;
    private final CuentaRepository cuentaRepository;
    private final PerfilRepository perfilRepository;

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (perfilRepository.count() > 0) {
            return;
        }

        Usuario usuario = new Usuario();
        usuario.setDni(0L);
        usuario.setNombre("Usuario");
        usuario.setApellido("Por Defecto");
        usuarioRepository.save(usuario);

        Cuenta cuenta = new Cuenta();
        cuenta.setUsuario(usuario);
        cuenta.setEmail("default@finza.local");
        cuenta.setPassword("default");
        cuenta.setEstado(Cuenta.Estado.ACTIVA);
        cuenta.setFechaCreacion(LocalDateTime.now());
        cuentaRepository.save(cuenta);

        Perfil perfil = new Perfil();
        perfil.setCuenta(cuenta);
        perfil.setNombrePerfil("Perfil por defecto");
        perfil.setRol("ADMIN");
        perfil.setEsPrincipal(true);
        perfil.setEsActivo(true);
        perfilRepository.save(perfil);
    }
}