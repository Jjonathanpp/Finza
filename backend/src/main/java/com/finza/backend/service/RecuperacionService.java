package com.finza.backend.service;

import java.security.SecureRandom;
import java.time.LocalDateTime;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import com.finza.backend.exception.BadRequestException;
import com.finza.backend.model.CodigoRecuperacion;
import com.finza.backend.model.Cuenta;
import com.finza.backend.repository.CodigoRecuperacionRepository;
import com.finza.backend.repository.CuentaRepository;

import jakarta.transaction.Transactional;

@Service
public class RecuperacionService {

    private static final int EXPIRACION_MINUTOS = 5;
    private static final int MAX_INTENTOS = 5;

    private final SecureRandom random = new SecureRandom();

    private final CuentaRepository cuentaRepository;
    private final CodigoRecuperacionRepository codigoRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;

    public RecuperacionService(CuentaRepository cuentaRepository,
                               CodigoRecuperacionRepository codigoRepository,
                               PasswordEncoder passwordEncoder,
                               EmailService emailService) {
        this.cuentaRepository = cuentaRepository;
        this.codigoRepository = codigoRepository;
        this.passwordEncoder = passwordEncoder;
        this.emailService = emailService;
    }

    @Transactional
    public void solicitarCodigo(String email) {
        cuentaRepository.findByEmail(email).ifPresent(cuenta -> {
            codigoRepository.deleteByCuenta(cuenta); // invalida códigos anteriores

            String codigo = String.format("%06d", random.nextInt(1_000_000));

            CodigoRecuperacion cr = new CodigoRecuperacion();
            cr.setCuenta(cuenta);
            cr.setCodigoHash(passwordEncoder.encode(codigo));
            cr.setExpiraEn(LocalDateTime.now().plusMinutes(EXPIRACION_MINUTOS));
            codigoRepository.save(cr);

            emailService.enviarCodigoRecuperacion(cuenta.getEmail(), codigo);
        });
    }

    @Transactional(dontRollbackOn = BadRequestException.class)
    public void restablecer(String email, String codigo, String nuevaContrasena) {
        Cuenta cuenta = cuentaRepository.findByEmail(email)
                .orElseThrow(() -> new BadRequestException("Código inválido o expirado"));

        CodigoRecuperacion cr = codigoRepository
                .findFirstByCuentaAndUsadoFalseOrderByExpiraEnDesc(cuenta)
                .orElseThrow(() -> new BadRequestException("Código inválido o expirado"));

        if (cr.getExpiraEn().isBefore(LocalDateTime.now()) || cr.getIntentos() >= MAX_INTENTOS) {
            throw new BadRequestException("Código inválido o expirado");
        }

        if (!passwordEncoder.matches(codigo, cr.getCodigoHash())) {
            cr.setIntentos(cr.getIntentos() + 1);
            codigoRepository.save(cr);
            throw new BadRequestException("Código inválido o expirado");
        }

        cuenta.setPassword(passwordEncoder.encode(nuevaContrasena));
        cuentaRepository.save(cuenta);

        cr.setUsado(true);
        codigoRepository.save(cr);
    }
}