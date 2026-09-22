package com.finza.backend.controller;

import java.time.LocalDate;
import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import com.finza.backend.dto.Response;
import com.finza.backend.dto.movimiento.MovimientoResponseDTO;
import com.finza.backend.dto.movimiento.MovimientosRegistroRequest;
import com.finza.backend.dto.movimiento.MovimientoIADTO;
import com.finza.backend.dto.movimiento.MovimientoRequest;
import com.finza.backend.service.MovimientoService;
import com.finza.backend.service.IAService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/movimientos")
@RequiredArgsConstructor
public class MovimientoController {

    private final MovimientoService movimientoService;
    private final IAService iaService;
    
    private final ObjectMapper objectMapper = new ObjectMapper();

    @PostMapping
    public ResponseEntity<Object> registrar(@RequestBody MovimientosRegistroRequest requests) {
        List<MovimientoResponseDTO> creados = movimientoService.registrar(requests);
        return Response.response(HttpStatus.CREATED, "Movimiento registrado exitosamente", creados);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Object> eliminar(@PathVariable Long id) {
        movimientoService.eliminar(id);
        return Response.response(HttpStatus.OK, "Movimiento eliminado exitosamente", null);
    }

    @GetMapping
    public ResponseEntity<Page<MovimientoResponseDTO>> obtenerMovimientos(
            @RequestParam(name = "perfilId", required = false, defaultValue = "1") Long perfilId, // <-- Ahora lo recibe por URL
            @RequestParam(name = "fechaInicio", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fechaInicio,
            @RequestParam(name = "fechaFin", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fechaFin,
            @RequestParam(name = "categoriaId", required = false) Long categoriaId,
            @RequestParam(name = "esIngreso", required = false) String esIngresoStr,
            @RequestParam(name = "estado", required = false) String estadoStr,
            @PageableDefault(size = 20, sort = "fecha", direction = Sort.Direction.DESC) Pageable pageable) {

        Boolean esIngreso = esIngresoStr != null ? Boolean.parseBoolean(esIngresoStr) : null;

        Page<MovimientoResponseDTO> resultado = movimientoService.listarMovimientos(
                perfilId, fechaInicio, fechaFin, categoriaId, esIngreso, estadoStr, pageable);

        return ResponseEntity.ok(resultado);
    }

    @PutMapping("/{id}/estado")
    public ResponseEntity<Object> cambiarEstado(
            @PathVariable Long id, 
            @RequestParam("nuevoEstado") String nuevoEstado) {
        MovimientoResponseDTO actualizado = movimientoService.cambiarEstado(id, nuevoEstado);
        return Response.response(HttpStatus.OK, "Estado actualizado correctamente", actualizado);
    }

    @PostMapping("/procesar-audio")
    public ResponseEntity<Object> procesarAudio(@RequestParam("audio") MultipartFile audio) {
        try {
            String jsonCrudoGemini = iaService.procesarAudio(audio);
            
            JsonNode rootNode = objectMapper.readTree(jsonCrudoGemini);
            String textoDeLaIA = rootNode.path("candidates").path(0)
                                         .path("content")
                                         .path("parts").path(0)
                                         .path("text").asText();
            
            textoDeLaIA = textoDeLaIA.replace("```json", "").replace("```", "").trim();
            
            MovimientoIADTO datosExtraidos = objectMapper.readValue(textoDeLaIA, MovimientoIADTO.class);
            
            return Response.response(HttpStatus.OK, "Audio procesado con éxito", datosExtraidos);
        } catch (Exception e) {
            return Response.response(HttpStatus.INTERNAL_SERVER_ERROR, "Error procesando el audio con IA: " + e.getMessage(), null);
        }
    }


    // --- CUMPLE OPEN-CLOSED, ESTO DESPUES SE ELIMINA ES SOLO PARA LA DEMO PORQUE NO HAY FRONTEND OJOJOJOJOJO ---
    @PostMapping("/procesar-audio/demo")
    public ResponseEntity<Object> procesarAudioYGuardarDemo(@RequestParam("audio") MultipartFile audio) {
        try {
            String jsonCrudoGemini = iaService.procesarAudio(audio);
            com.fasterxml.jackson.databind.JsonNode rootNode = objectMapper.readTree(jsonCrudoGemini);
            String textoDeLaIA = rootNode.path("candidates").path(0)
                                         .path("content")
                                         .path("parts").path(0)
                                         .path("text").asText();
            textoDeLaIA = textoDeLaIA.replace("```json", "").replace("```", "").trim();
            
            MovimientoIADTO datosExtraidos = objectMapper.readValue(textoDeLaIA, MovimientoIADTO.class);
            
            MovimientoRequest requestIndividual = new MovimientoRequest();
            requestIndividual.setTipo(datosExtraidos.getTipo());
            requestIndividual.setMonto(datosExtraidos.getMonto());
            requestIndividual.setCategoria(datosExtraidos.getCategoria());
            requestIndividual.setDescripcion(datosExtraidos.getDescripcion());
            requestIndividual.setFecha(datosExtraidos.getFecha());
            requestIndividual.setOrigen("VOZ");

            
            MovimientosRegistroRequest requestFinal = new MovimientosRegistroRequest();
            requestFinal.setPerfilId(1L); // Perfil simulado para la demo
            requestFinal.setMovimientos(java.util.Collections.singletonList(requestIndividual));

            List<MovimientoResponseDTO> creados = movimientoService.registrar(requestFinal);

            return Response.response(HttpStatus.CREATED, "MOVIMIENTO REGISTRADO CORRECTAMENTE", creados);
        } catch (Exception e) {
            return Response.response(HttpStatus.INTERNAL_SERVER_ERROR, "ERROR, MOVIMIENTO NO REGISTRADO: " + e.getMessage(), null);
        }
    }
}