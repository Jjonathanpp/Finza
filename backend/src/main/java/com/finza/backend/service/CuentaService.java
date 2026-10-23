package com.finza.backend.service;

import java.time.LocalDateTime;

import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.finza.backend.dto.cambio_contrasena_EnCuenta.CambioPasswordRequestDTO;
import com.finza.backend.dto.login.LoginRequestDTO;
import com.finza.backend.dto.login.LoginResponseDTO;
import com.finza.backend.dto.registro.CuentaRegistroDTO;
import com.finza.backend.dto.registro.CuentaResponseDTO;
import com.finza.backend.dto.registro.UsuarioRegistroDTO;
import com.finza.backend.exception.BadRequestException;
import com.finza.backend.model.Cuenta;
import com.finza.backend.model.Perfil;
import com.finza.backend.model.Usuario;
import com.finza.backend.repository.CuentaRepository;
import com.finza.backend.repository.PerfilRepository;
import com.finza.backend.repository.UsuarioRepository;
import com.finza.backend.security.JwtService;

@Service
public class CuentaService {

    private final CuentaRepository cuentaRepository;
    private final UsuarioRepository usuarioRepository;
    private final PerfilRepository perfilRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public CuentaService(
            CuentaRepository cuentaRepository,
            UsuarioRepository usuarioRepository,
            PerfilRepository perfilRepository,
            PasswordEncoder passwordEncoder,
            JwtService jwtService) {

        this.cuentaRepository = cuentaRepository;
        this.usuarioRepository = usuarioRepository;
        this.perfilRepository = perfilRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    @Transactional
    public CuentaResponseDTO crear(CuentaRegistroDTO dto) {
        if (cuentaRepository.existsByEmail(dto.getEmail())) {
            throw new IllegalArgumentException("El email ya está registrado");
        }

        UsuarioRegistroDTO usuarioDto = dto.getUsuario();
        if (usuarioRepository.existsByDni(usuarioDto.getDni())) {
            throw new IllegalArgumentException("El DNI ya está registrado");
        }

        Usuario usuario = new Usuario();
        usuario.setNombre(usuarioDto.getNombre());
        usuario.setApellido(usuarioDto.getApellido());
        usuario.setDni(usuarioDto.getDni());
        usuario.setTelefono(usuarioDto.getTelefono());
        usuario.setFechaNacimiento(usuarioDto.getFechaNacimiento());
        usuario.setGenero(usuarioDto.getGenero());
        usuario = usuarioRepository.save(usuario);

        Cuenta cuenta = new Cuenta();
        cuenta.setEmail(dto.getEmail());
        cuenta.setPassword(passwordEncoder.encode(dto.getPassword()));
        cuenta.setUsuario(usuario);
        cuenta.setEmailVerificado(false);
        cuenta.setFechaCreacion(LocalDateTime.now());
        cuenta.setEstado(Cuenta.Estado.PENDIENTE_VERIFICACION);
        cuenta = cuentaRepository.save(cuenta);

        Perfil perfil = new Perfil();
        perfil.setCuenta(cuenta);
        perfil.setNombrePerfil(usuario.getNombre());
        perfil.setEsPrincipal(true);
        perfil.setEsActivo(true);
        perfilRepository.save(perfil);

        return new CuentaResponseDTO(cuenta, perfil);
    }

    @Transactional(readOnly = true)
    public LoginResponseDTO login(LoginRequestDTO dto) {
        Cuenta cuenta = cuentaRepository.findByEmail(dto.getEmail())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Credenciales inválidas"));

        if (!passwordEncoder.matches(dto.getPassword(), cuenta.getPassword())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Credenciales inválidas");
        }

        String accessToken = jwtService.generateAccessToken(cuenta.getId(), cuenta.getEmail());
        String refreshToken = jwtService.generateRefreshToken(cuenta.getId());

        return new LoginResponseDTO(accessToken, refreshToken, cuenta.getEmail());
    }

    @Transactional
    public void cambiarPassword(Long cuentaId, CambioPasswordRequestDTO dto) {
        Cuenta cuenta = cuentaRepository.findById(cuentaId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Cuenta no encontrada"));

        if (!passwordEncoder.matches(dto.getContrasenaActual(), cuenta.getPassword())) {
            throw new BadRequestException("La contraseña actual es incorrecta");
        }

        if (passwordEncoder.matches(dto.getNuevaContrasena(), cuenta.getPassword())) {
            throw new BadRequestException("La nueva contraseña debe ser distinta a la actual");
        }

        cuenta.setPassword(passwordEncoder.encode(dto.getNuevaContrasena()));
        cuentaRepository.save(cuenta);
    }

    @Transactional
    public void eliminarCuenta(Long cuentaId, String passwordActual) {
        Cuenta cuenta = cuentaRepository.findById(cuentaId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Cuenta no encontrada"));

        if (!passwordEncoder.matches(passwordActual, cuenta.getPassword())) {
            throw new BadRequestException("La contraseña es incorrecta");
        }

        cuentaRepository.delete(cuenta);
    }
}