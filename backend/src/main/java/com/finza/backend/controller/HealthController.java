package com.finza.backend.controller;

import com.finza.backend.dto.Response;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api")
public class HealthController {

	@GetMapping("/health")
	public ResponseEntity<Object> health() {
		return Response.ok(Map.of("service", "finza-backend"));
	}
} 
