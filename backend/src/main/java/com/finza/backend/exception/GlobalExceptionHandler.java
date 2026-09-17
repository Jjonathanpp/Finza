package com.finza.backend.exception;

import com.finza.backend.dto.Response;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.ErrorResponse;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

import java.util.HashMap;
import java.util.Map;
import java.util.NoSuchElementException;

import lombok.extern.slf4j.Slf4j;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BadRequestException.class)
    public ResponseEntity<Object> badRequest(BadRequestException e) {
        return Response.error(null, e.getMessage());
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Object> handleValidationErrors(MethodArgumentNotValidException ex) {
        Map<String, String> errores = new HashMap<>();
        ex.getBindingResult().getFieldErrors().forEach(error ->
            errores.put(error.getField(), error.getDefaultMessage())
        );
        return Response.error(errores, "Error de validación");
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Object> handleIllegalArgument(IllegalArgumentException ex) {
        return Response.response(HttpStatus.CONFLICT, ex.getMessage(), null);
    }

    @ExceptionHandler(NoSuchElementException.class)
    public ResponseEntity<Object> handleNotFound(NoSuchElementException ex) {
        return Response.notFound(ex.getMessage());
    }

    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<Object> handleParametroFaltante(MissingServletRequestParameterException ex) {
        return Response.error(null, "Falta el parámetro obligatorio '" + ex.getParameterName() + "'");
    }

    
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<Object> handleTipoInvalido(MethodArgumentTypeMismatchException ex) {
        return Response.error(null, "El parámetro '" + ex.getName() + "' no tiene un valor válido");
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<Object> handleCuerpoInvalido(HttpMessageNotReadableException ex) {
        return Response.error(null, "El cuerpo del pedido no es válido");
    }

    @ExceptionHandler(IllegalStateException.class)
    public ResponseEntity<Object> handleEstadoInvalido(IllegalStateException ex) {
        return Response.response(HttpStatus.CONFLICT, ex.getMessage(), null);
    }


    @ExceptionHandler(Exception.class)
    public ResponseEntity<Object> handleNoControlado(Exception ex) {
    
        if (ex instanceof ErrorResponse errorResponse) {
            HttpStatus status = HttpStatus.valueOf(errorResponse.getStatusCode().value());
            return Response.response(status, status.getReasonPhrase(), null);
        }
        log.error("Error no controlado", ex);
        return Response.response(HttpStatus.INTERNAL_SERVER_ERROR, "Error interno del servidor", null);
    }
}