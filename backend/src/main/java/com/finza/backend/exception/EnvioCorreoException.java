package com.finza.backend.exception;

public class EnvioCorreoException extends RuntimeException {

    public EnvioCorreoException(String mensaje, Throwable causa) {
        super(mensaje, causa);
    }
}