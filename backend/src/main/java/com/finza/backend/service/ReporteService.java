package com.finza.backend.service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

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

    private static final float COL_FECHA_W = 70f;
    private static final float COL_QUIEN_W = 110f;
    private static final float COL_TIPO_W = 55f;
    private static final float COL_MONTO_W = 75f;
    private static final float GAP = 10f;

    private String t(String lang, String es, String en) {
        return lang != null && lang.toLowerCase().startsWith("en") ? en : es;
    }

    private String alcanceTexto(String alcance, String lang) {
        if ("solo_propios".equals(alcance)) {
            return t(lang, "solo_propios", "own movements only");
        }
        return t(lang, "cuenta_completa", "whole account");
    }

    private String truncate(String text, float maxWidth, PDType1Font font, float fontSize) {
        if (text == null || text.isEmpty())
            return "-";
        try {
            float textWidth = font.getStringWidth(text) / 1000f * fontSize;
            if (textWidth <= maxWidth)
                return text;
            String ellipsis = "…";
            float ellipsisWidth = font.getStringWidth(ellipsis) / 1000f * fontSize;
            float available = maxWidth - ellipsisWidth;
            if (available <= 0)
                return ellipsis;
            int low = 0, high = text.length();
            while (low < high) {
                int mid = (low + high + 1) / 2;
                String sub = text.substring(0, mid);
                float w = font.getStringWidth(sub) / 1000f * fontSize;
                if (w <= available)
                    low = mid;
                else
                    high = mid - 1;
            }
            return text.substring(0, low) + ellipsis;
        } catch (IOException e) {
            return text; // fallback: si falla medir, devolvé el original
        }
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

            movimientos = movimientoRepository.buscarConFiltros(
                    null, cuentaId, cuentaCompartidaId, fechaDesde, fechaHasta, null, null, null,
                    PageRequest.of(0, 1000, Sort.by(Sort.Direction.DESC, "fecha"))).getContent();
        }

        // === NUEVO: calcular si hay que mostrar la columna "Quién" ===
        long distinctOwners = movimientos.stream()
                .map(Movimiento::getPerfil)
                .filter(Objects::nonNull)
                .map(Perfil::getId)
                .distinct()
                .count();
        boolean mostrarQuien = distinctOwners >= 2;

        return generarPDF(nombreCuenta, alcance, fechaDesde, fechaHasta, movimientos, lang, mostrarQuien);
    }

    private byte[] generarPDF(String nombreCuenta, String alcance, LocalDate fechaDesde,
            LocalDate fechaHasta, List<Movimiento> movimientos, String lang, boolean mostrarQuien) {

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
                    float colFechaX = MARGEN;
                    float colQuienX = colFechaX + COL_FECHA_W + GAP;
                    float colDescX = mostrarQuien ? colQuienX + COL_QUIEN_W + GAP : colQuienX; // si no hay Quién,
                                                                                               // Descripción empieza
                                                                                               // ahí
                    float colTipoX = colDescX + (mostrarQuien
                            ? (page.getMediaBox().getWidth() - MARGEN - colDescX - COL_TIPO_W - GAP - COL_MONTO_W)
                            : (page.getMediaBox().getWidth() - MARGEN - colDescX - COL_TIPO_W - GAP - COL_MONTO_W));
                    float colMontoX = page.getMediaBox().getWidth() - MARGEN - COL_MONTO_W;

                    float colDescW = colTipoX - GAP - colDescX;

                    content.beginText();
                    content.setFont(PDType1Font.HELVETICA_BOLD, 10);
                    content.newLineAtOffset(colFechaX, y);
                    content.showText(t(lang, "Fecha", "Date"));
                    if (mostrarQuien) {
                        content.newLineAtOffset(COL_FECHA_W + GAP, 0);
                        content.showText(t(lang, "Quién", "Who"));
                    }
                    content.newLineAtOffset(mostrarQuien ? COL_QUIEN_W + GAP : 0, 0);
                    content.showText(t(lang, "Descripción", "Description"));
                    content.newLineAtOffset(colDescW + GAP, 0);
                    content.showText(t(lang, "Tipo", "Type"));
                    content.newLineAtOffset(COL_TIPO_W + GAP, 0);
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

                        String quien = m.getPerfil() != null ? m.getPerfil().getNombrePerfil() : "-";
                        String fechaTexto = m.getFecha() != null
                                ? m.getFecha().format(DateTimeFormatter.ofPattern("dd/MM/yyyy"))
                                : "-";
                        String descTexto = m.getDescripcion() != null ? m.getDescripcion() : "-";
                        String tipoTexto = m.isEsIngreso() ? t(lang, "Ingreso", "Income")
                                : t(lang, "Egreso", "Expense");
                        String montoTexto = String.format("%,.2f", m.getMonto());

                        fechaTexto = truncate(fechaTexto, COL_FECHA_W, PDType1Font.HELVETICA, 9);
                        if (mostrarQuien)
                            quien = truncate(quien, COL_QUIEN_W, PDType1Font.HELVETICA, 9);
                        descTexto = truncate(descTexto, colDescW, PDType1Font.HELVETICA, 9);
                        tipoTexto = truncate(tipoTexto, COL_TIPO_W, PDType1Font.HELVETICA, 9);

                        content.beginText();
                        content.newLineAtOffset(colFechaX, y);
                        content.showText(fechaTexto);
                        if (mostrarQuien) {
                            content.newLineAtOffset(COL_FECHA_W + GAP, 0);
                            content.showText(quien);
                        }
                        content.newLineAtOffset(mostrarQuien ? COL_QUIEN_W + GAP : 0, 0);
                        content.showText(descTexto);
                        content.newLineAtOffset(colDescW + GAP, 0);
                        content.showText(tipoTexto);
                        float montoAncho;
                        try {
                            montoAncho = PDType1Font.HELVETICA.getStringWidth(montoTexto) / 1000f * 9;
                        } catch (IOException e) {
                            montoAncho = 0;
                        }
                        content.newLineAtOffset(COL_TIPO_W + GAP + COL_MONTO_W - montoAncho, 0);
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