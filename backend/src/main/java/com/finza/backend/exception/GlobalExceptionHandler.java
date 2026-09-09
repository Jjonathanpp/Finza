package com.finza.backend.exception;

import com.finza.backend.dto.Response;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BadRequestException.class)
    public ResponseEntity<Object> badRequest(BadRequestException e) {
        return Response.error(null, e.getMessage());
    }
}