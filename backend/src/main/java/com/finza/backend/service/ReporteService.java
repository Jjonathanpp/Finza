package com.finza.backend.service;

import java.io.ByteArrayOutputStream;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import lombok.RequiredArgsConstructor;

import com.finza.backend.exception.BadRequestException;
import com.finza.backend.model.Movimiento;
import com.finza.backend.model.Perfil;
import com.finza.backend.repository.MovimientoRepository;
import com.finza.backend.repository.PerfilRepository;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ReporteService {

    private final MovimientoRepository movimientoRepository;
    private final PerfilRepository perfilRepository;

    private static final int MAX_FILAS_POR_PAGINA = 25;
    private static final float MARGEN = 50;
    private static final float ALTURA_FILA = 20;
    private static final float ALTURA_ENCABEZADO = 80;

    public byte[] generarReportePDF(Long cuentaId, String alcance, LocalDate fechaDesde, LocalDate fechaHasta) {
        // Validar alcance
        if (!"solo_propios".equals(alcance) && !"cuenta_completa".equals(alcance)) {
            throw new BadRequestException("Alcance inválido. Use 'solo_propios' o 'cuenta_completa'");
        }

        // Validar fechas
        if (fechaDesde != null && fechaHasta != null && fechaDesde.isAfter(fechaHasta)) {
            throw new BadRequestException("La fecha desde no puede ser posterior a la fecha hasta");
        }

        // Rango por defecto: mes actual
        if (fechaDesde == null) {
            fechaDesde = LocalDate.now().withDayOfMonth(1);
        }
        if (fechaHasta == null) {
            fechaHasta = LocalDate.now();
        }

        Perfil perfil = perfilRepository.findByCuentaIdAndEsPrincipalTrue(cuentaId)
                .orElseThrow(() -> new BadRequestException("No se encontró el perfil principal de la cuenta"));

        List<Movimiento> movimientos;
        String nombreCuenta;
        Long cuentaCompartidaId = null;

        if ("solo_propios".equals(alcance)) {
            nombreCuenta = "Movimientos propios";
            movimientos = movimientoRepository.buscarConFiltros(
                    perfil.getId(), cuentaId, fechaDesde, fechaHasta, null, null, null,
                    org.springframework.data.domain.PageRequest.of(0, 1000)).getContent();
        } else {
            // cuenta_completa: validar admin
            if (perfil.getRol() != Perfil.Rol.ADMIN) {
                throw new AccessDeniedException("Solo el administrador puede exportar la cuenta completa");
            }
            if (perfil.getCuentaCompartida() == null) {
                throw new BadRequestException("La cuenta no pertenece a una cuenta compartida");
            }
            cuentaCompartidaId = perfil.getCuentaCompartida().getId();
            nombreCuenta = perfil.getCuentaCompartida().getNombre();

            // Obtener todos los perfiles de la cuenta compartida
            List<Perfil> perfiles = perfilRepository.findByCuentaCompartidaId(cuentaCompartidaId);
            List<Long> perfilIds = new ArrayList<>();
            for (Perfil p : perfiles) {
                perfilIds.add(p.getId());
            }

            // Consultar movimientos de cada perfil y combinarlos
            movimientos = new ArrayList<>();
            for (Long pId : perfilIds) {
                List<Movimiento> m = movimientoRepository.buscarConFiltros(
                        pId, cuentaId, fechaDesde, fechaHasta, null, null, null,
                        org.springframework.data.domain.PageRequest.of(0, 1000)).getContent();
                movimientos.addAll(m);
            }
            // Ordenar por fecha descendente
            movimientos.sort((m1, m2) -> m2.getFecha().compareTo(m1.getFecha()));
        }

        return generarPDF(nombreCuenta, alcance, fechaDesde, fechaHasta, movimientos);
    }

    private byte[] generarPDF(String nombreCuenta, String alcance, LocalDate fechaDesde,
            LocalDate fechaHasta, List<Movimiento> movimientos) {

        try (PDDocument document = new PDDocument()) {
            int totalPaginas = (int) Math.ceil((double) movimientos.size() / MAX_FILAS_POR_PAGINA);
            if (totalPaginas == 0) {
                totalPaginas = 1;
            }

            // Calcular totales una sola vez
            double totalIngresos = 0;
            double totalEgresos = 0;
            for (Movimiento m : movimientos) {
                if (m.isEsIngreso()) {
                    totalIngresos += m.getMonto().doubleValue();
                } else {
                    totalEgresos += m.getMonto().doubleValue();
                }
            }

            for (int pagina = 0; pagina < totalPaginas; pagina++) {
                PDPage page = new PDPage();
                document.addPage(page);

                try (PDPageContentStream content = new PDPageContentStream(document, page)) {
                    float pageHeight = page.getMediaBox().getHeight();
                    float y = pageHeight - MARGEN;

                    // === ENCABEZADO ===
                    if (pagina == 0) {
                        // Primera página: encabezado completo
                        content.beginText();
                        content.setFont(PDType1Font.HELVETICA_BOLD, 16);
                        content.newLineAtOffset(MARGEN, y);
                        content.showText("Reporte de Movimientos");
                        content.newLineAtOffset(0, -16);
                        content.setFont(PDType1Font.HELVETICA, 11);
                        content.showText("Cuenta: " + nombreCuenta);
                        content.newLineAtOffset(0, -12);
                        content.showText("Alcance: " + alcance);
                        content.newLineAtOffset(0, -12);
                        content.showText("Período: " + fechaDesde + " al " + fechaHasta);
                        content.newLineAtOffset(0, -12);
                        content.showText("Página " + (pagina + 1) + " de " + totalPaginas);
                        content.endText();

                        y -= 70;
                    } else {
                        // Páginas siguientes: encabezado breve
                        content.beginText();
                        content.setFont(PDType1Font.HELVETICA_BOLD, 10);
                        content.newLineAtOffset(MARGEN, y);
                        content.showText("Reporte de Movimientos - " + nombreCuenta);
                        content.newLineAtOffset(0, -12);
                        content.setFont(PDType1Font.HELVETICA, 9);
                        content.showText("Página " + (pagina + 1) + " de " + totalPaginas);
                        content.endText();

                        y -= 40;
                    }

                    // === TABLA DE MOVIMIENTOS ===
                    content.beginText();
                    content.setFont(PDType1Font.HELVETICA_BOLD, 10);
                    content.newLineAtOffset(MARGEN, y);
                    content.showText("Fecha");
                    content.newLineAtOffset(80, 0);
                    content.showText("Descripción");
                    content.newLineAtOffset(200, 0);
                    content.showText("Tipo");
                    content.newLineAtOffset(60, 0);
                    content.showText("Monto");
                    content.endText();

                    y -= ALTURA_FILA;

                    content.moveTo(MARGEN, y);
                    content.lineTo(page.getMediaBox().getWidth() - MARGEN, y);
                    content.stroke();

                    y -= ALTURA_FILA;

                    int inicio = pagina * MAX_FILAS_POR_PAGINA;
                    int fin = Math.min(inicio + MAX_FILAS_POR_PAGINA, movimientos.size());

                    content.setFont(PDType1Font.HELVETICA, 9);
                    for (int i = inicio; i < fin; i++) {
                        Movimiento m = movimientos.get(i);
                        if (y < MARGEN + 50) {
                            break;
                        }

                        content.beginText();
                        content.newLineAtOffset(MARGEN, y);
                        content.showText(m.getFecha() != null ? m.getFecha().toString() : "-");
                        content.newLineAtOffset(80, 0);
                        content.showText(m.getDescripcion() != null ? m.getDescripcion() : "-");
                        content.newLineAtOffset(200, 0);
                        content.showText(m.isEsIngreso() ? "Ingreso" : "Egreso");
                        content.newLineAtOffset(60, 0);
                        content.showText(String.format("%,.2f", m.getMonto()));
                        content.endText();

                        y -= ALTURA_FILA;
                    }

                    // === TOTALES SOLO EN LA ÚLTIMA PÁGINA ===
                    if (pagina == totalPaginas - 1) {
                        y -= 20;
                        content.beginText();
                        content.setFont(PDType1Font.HELVETICA_BOLD, 11);
                        content.newLineAtOffset(MARGEN, y);
                        content.showText("Totales:");
                        content.newLineAtOffset(0, -14);
                        content.setFont(PDType1Font.HELVETICA, 10);
                        content.showText("Ingresos:  " + String.format("%,.2f", totalIngresos));
                        content.newLineAtOffset(0, -12);
                        content.showText("Egresos:   " + String.format("%,.2f", totalEgresos));
                        content.newLineAtOffset(0, -12);
                        content.showText("Saldo:     " + String.format("%,.2f", totalIngresos - totalEgresos));
                        content.endText();
                    }
                }
            }

            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            document.save(baos);
            return baos.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("Error generando PDF", e);
        }
    }
}