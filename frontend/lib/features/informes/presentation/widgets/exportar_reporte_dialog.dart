import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/core/widgets/campo.dart';
import 'package:frontend/core/widgets/chip_estado.dart';
import 'package:frontend/core/widgets/hoja.dart';
import 'package:frontend/core/widgets/segmento.dart';
import 'package:frontend/core/widgets/tocable.dart';

// La hoja "Exportar reporte" (maqueta L718-727): desde y hasta, qué incluye, el formato y los botones.
class ExportarReporteDialog extends StatefulWidget {
  const ExportarReporteDialog({
    super.key,
    required this.fechaInicial,
    required this.fechaFinal,
    required this.cuentaCompartidaActiva,
    required this.onExportar,
  });

  final DateTime? fechaInicial;
  final DateTime? fechaFinal;
  final bool cuentaCompartidaActiva;
  final Future<void> Function(String alcance, DateTime desde, DateTime hasta) onExportar;

  static Future<void> mostrar(
    BuildContext context, {
    required DateTime? fechaInicial,
    required DateTime? fechaFinal,
    required bool cuentaCompartidaActiva,
    required Future<void> Function(String alcance, DateTime desde, DateTime hasta) onExportar,
  }) {
    return mostrarHoja<void>(
      context,
      titulo: 'Exportar reporte',
      contenido: ExportarReporteDialog(
        fechaInicial: fechaInicial,
        fechaFinal: fechaFinal,
        cuentaCompartidaActiva: cuentaCompartidaActiva,
        onExportar: onExportar,
      ),
    );
  }

  @override
  State<ExportarReporteDialog> createState() => _ExportarReporteDialogState();
}

class _ExportarReporteDialogState extends State<ExportarReporteDialog> {
  late String _alcance = 'solo_propios';
  late DateTime _desde = widget.fechaInicial ?? DateTime.now();
  late DateTime _hasta = widget.fechaFinal ?? DateTime.now();
  bool _cargando = false;
  String? _error;

  bool get _fechasValidas => !_desde.isAfter(_hasta);

  Future<void> _exportar() async {
    if (_cargando || !_fechasValidas) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await widget.onExportar(_alcance, _desde, _hasta);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo generar el reporte. Intentá de nuevo.';
      });
    }
  }

  Future<void> _elegirFecha(bool esDesde) async {
    final inicial = esDesde ? _desde : _hasta;
    final elegida = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (elegida == null) return;
    setState(() {
      if (esDesde) {
        _desde = elegida;
      } else {
        _hasta = elegida;
      }
    });
  }

  String _fecha(DateTime f) => '${f.day}/${f.month}/${f.year}';

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    final compartida = widget.cuentaCompartidaActiva;
    final nombreCuenta = cuentaActiva.value?['nombre'] as String?;
    return PopScope(
      canPop: !_cargando,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Expanded(
                child: Campo(
                  etiqueta: 'Desde',
                  child: _Caja(
                    texto: _fecha(_desde),
                    etiqueta: 'Desde ${_fecha(_desde)}',
                    alTocar: _cargando ? null : () => _elegirFecha(true),
                  ),
                ),
              ),
              Expanded(
                child: Campo(
                  etiqueta: 'Hasta',
                  child: _Caja(
                    texto: _fecha(_hasta),
                    etiqueta: 'Hasta ${_fecha(_hasta)}',
                    alTocar: _cargando ? null : () => _elegirFecha(false),
                  ),
                ),
              ),
            ],
          ),
          if (!_fechasValidas)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                'La fecha "desde" no puede ser posterior a "hasta".',
                style: textos.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: c.coralTexto),
              ),
            ),
          Campo(
            etiqueta: 'Qué incluye',
            ayuda: compartida ? null : 'El consolidado está solo en una cuenta compartida.',
            child: Segmento<String>(
              opciones: [
                const ('solo_propios', 'Mis registros'),
                (
                  'cuenta_completa',
                  compartida && nombreCuenta != null ? 'Todo $nombreCuenta' : 'Consolidado',
                ),
              ],
              valor: _alcance,
              deshabilitadas: {
                if (!compartida || _cargando) 'cuenta_completa',
                if (_cargando) 'solo_propios',
              },
              alCambiar: (v) => setState(() => _alcance = v),
            ),
          ),
          const Campo(
            etiqueta: 'Formato',
            child: Align(
              alignment: Alignment.centerLeft,
              child: ChipEstado('PDF', TonoChip.menta, icono: Icons.picture_as_pdf_outlined),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                _error!,
                style: textos.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: c.coralTexto),
              ),
            ),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cargando ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
              Expanded(
                child: FilledButton(
                  onPressed: (_cargando || !_fechasValidas) ? null : _exportar,
                  child: _cargando
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: c.sobrePrimario),
                        )
                      : const Text('Exportar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// .caja de la maqueta: el botón con la fecha, de 48 px de alto, fondo hundido y radio de control.
class _Caja extends StatelessWidget {
  const _Caja({required this.texto, required this.etiqueta, required this.alTocar});

  final String texto;
  final String etiqueta;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final caja = Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: c.hundido,
        borderRadius: BorderRadius.circular(Radios.control),
      ),
      child: Text(
        texto,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: c.texto),
      ),
    );
    if (alTocar == null) return Opacity(opacity: .45, child: caja);
    return Tocable(alTocar: alTocar, etiqueta: etiqueta, child: caja);
  }
}
