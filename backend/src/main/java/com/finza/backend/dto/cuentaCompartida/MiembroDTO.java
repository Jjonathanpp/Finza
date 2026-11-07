package com.finza.backend.dto.cuentaCompartida;

// esCreador: a quien creó la cuenta compartida nadie le puede cambiar el rol (PerfilService.cambiarRol),
// así la pantalla de miembros lo muestra sin selector (t-11.3.2).
public record MiembroDTO(Long perfilId, Long usuarioId, String nombre, String rol, boolean esCreador) {
}