package com.finza.backend.service;

import java.io.ByteArrayOutputStream;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
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
    private final PerfilService perfilService;

    private static final int MAX_FILAS_POR_PAGINA = 25;
    private static final float MARGEN = 50;
    private static final float ALTURA_FILA = 20;
    private static final float ALTURA_ENCABEZADO = 80;

    private String t(String lang, String es, String en) {
        return lang != null && lang.toLowerCase().startsWith("en") ? en : es;
    }

    private String alcanceTexto(String alcance, String lang) {
        if ("solo_propios".equals(alcance)) {
            return t(lang, "solo_propios", "own movements only");
        }
        return t(lang, "cuenta_completa", "whole account");
    }

    public byte[] generarReportePDF(Long cuentaId, String alcance, LocalDate fechaDesde, LocalDate fechaHasta,
            String lang) {
        if (!"solo_propios".equals(alcance) && !"cuenta_completa".equals(alcance)) {
            throw new BadRequestException("Alcance inválido. Use 'solo_propios' o 'cuenta_completa'");
        }

        if (fechaDesde != null && fechaHasta != null && fechaDesde.isAfter(fechaHasta)) {
            throw new BadRequestException("La fecha desde no puede ser posterior a la fecha hasta");
        }

        if (fechaDesde == null) {
            fechaDesde = LocalDate.now().withDayOfMonth(1);
        }
        if (fechaHasta == null) {
            fechaHasta = LocalDate.now();
        }

        // El perfil en el que está parado el usuario (header X-Perfil-Id), no el
        // principal
        Perfil perfil = perfilService.perfilActivo(cuentaId);

        List<Movimiento> movimientos;
        String nombreCuenta;

        if ("solo_propios".equals(alcance)) {
            nombreCuenta = t(lang, "Movimientos propios", "Own movements");
            movimientos = movimientoRepository.buscarConFiltros(
                    perfil.getId(), cuentaId, null, fechaDesde, fechaHasta, null, null, null,
                    PageRequest.of(0, 1000, Sort.by(Sort.Direction.DESC, "fecha"))).getContent();
        } else {
            if (perfil.getCuentaCompartida() == null) {
                throw new BadRequestException("La cuenta no pertenece a una cuenta compartida");
            }

            Long cuentaCompartidaId = perfil.getCuentaCompartida().getId();
            nombreCuenta = perfil.getCuentaCompartida().getNombre();

            // perfilId = null: todos los perfiles de la cuenta compartida
            movimientos = movimientoRepository.buscarConFiltros(
                    null, cuentaId, cuentaCompartidaId, fechaDesde, fechaHasta, null, null, null,
                    PageRequest.of(0, 1000, Sort.by(Sort.Direction.DESC, "fecha"))).getContent();
        }

        return generarPDF(nombreCuenta, alcance, fechaDesde, fechaHasta, movimientos, lang);
    }

    private byte[] generarPDF(String nombreCuenta, String alcance, LocalDate fechaDesde,
            LocalDate fechaHasta, List<Movimiento> movimientos, String lang) {

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
                        content.showText(t(lang, "Reporte de Movimientos", "Movement Report"));
                        content.newLineAtOffset(0, -16);
                        content.setFont(PDType1Font.HELVETICA, 11);
                        content.showText(t(lang, "Cuenta: ", "Account: ") + nombreCuenta);
                        content.newLineAtOffset(0, -12);
                        content.showText(t(lang, "Alcance: ", "Scope: ") + alcanceTexto(alcance, lang));
                        content.newLineAtOffset(0, -12);
                        content.showText(
                                t(lang, "Período: ", "Period: ") + fechaDesde + t(lang, " al ", " to ") + fechaHasta);
                        content.newLineAtOffset(0, -12);
                        content.showText(
                                t(lang, "Página ", "Page ") + (pagina + 1) + t(lang, " de ", " of ") + totalPaginas);
                        content.endText();

                        y -= 70;
                    } else {
                        // Páginas siguientes: encabezado breve
                        content.beginText();
                        content.setFont(PDType1Font.HELVETICA_BOLD, 10);
                        content.newLineAtOffset(MARGEN, y);
                        content.showText(t(lang, "Reporte de Movimientos - ", "Movement Report - ") + nombreCuenta);
                        content.newLineAtOffset(0, -12);
                        content.setFont(PDType1Font.HELVETICA, 9);
                        content.showText(
                                t(lang, "Página ", "Page ") + (pagina + 1) + t(lang, " de ", " of ") + totalPaginas);
                        content.endText();

                        y -= 40;
                    }

                    // === TABLA DE MOVIMIENTOS ===
                    content.beginText();
                    content.setFont(PDType1Font.HELVETICA_BOLD, 10);
                    content.newLineAtOffset(MARGEN, y);
                    content.showText(t(lang, "Fecha", "Date"));
                    content.newLineAtOffset(70, 0);
                    content.showText(t(lang, "Quién", "Who"));
                    content.newLineAtOffset(140, 0);
                    content.showText(t(lang, "Descripción", "Description"));
                    content.newLineAtOffset(160, 0);
                    content.showText(t(lang, "Tipo", "Type"));
                    content.newLineAtOffset(50, 0);
                    content.showText(t(lang, "Monto", "Amount"));
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

                        String quien = "cuenta_completa".equals(alcance) && m.getPerfil() != null
                                ? m.getPerfil().getNombrePerfil()
                                : "-";

                        content.beginText();
                        content.newLineAtOffset(MARGEN, y);
                        content.showText(
                                m.getFecha() != null ? m.getFecha().format(DateTimeFormatter.ofPattern("dd/MM/yyyy"))
                                        : "-");
                        content.newLineAtOffset(70, 0);
                        content.showText(quien);
                        content.newLineAtOffset(80, 0);
                        content.showText(m.getDescripcion() != null ? m.getDescripcion() : "-");
                        content.newLineAtOffset(160, 0);
                        content.showText(m.isEsIngreso() ? t(lang, "Ingreso", "Income") : t(lang, "Egreso", "Expense"));
                        String montoTexto = String.format("%,.2f", m.getMonto());
                        float montoAncho = PDType1Font.HELVETICA.getStringWidth(montoTexto) / 1000 * 9;
                        content.newLineAtOffset(50 - montoAncho, 0);
                        content.showText(montoTexto);
                        content.endText();

                        content.moveTo(MARGEN, y);
                        content.lineTo(page.getMediaBox().getWidth() - MARGEN, y);
                        content.stroke();

                        y -= ALTURA_FILA;
                    }

                    // === TOTALES SOLO EN LA ÚLTIMA PÁGINA ===
                    if (pagina == totalPaginas - 1) {
                        y -= 20;
                        content.beginText();
                        content.setFont(PDType1Font.HELVETICA_BOLD, 11);
                        content.newLineAtOffset(MARGEN, y);
                        content.showText(t(lang, "Totales:", "Totals:"));
                        content.newLineAtOffset(0, -14);
                        content.setFont(PDType1Font.HELVETICA, 10);
                        content.showText(t(lang, "Ingresos:  ", "Income:   ") + String.format("%,.2f", totalIngresos));
                        content.newLineAtOffset(0, -12);
                        content.showText(t(lang, "Egresos:   ", "Expense:  ") + String.format("%,.2f", totalEgresos));
                        content.newLineAtOffset(0, -12);
                        content.showText(t(lang, "Saldo:     ", "Balance:  ")
                                + String.format("%,.2f", totalIngresos - totalEgresos));
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