import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';

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
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ExportarReporteDialog(
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Exportar reporte', style: TextStyle(color: AppColors.text)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Formato', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('PDF', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            const Text('Alcance', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            RadioGroup<String>(
              groupValue: _alcance,
              onChanged: (v) => setState(() => _alcance = v!),
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'solo_propios',
                    enabled: !_cargando,
                    title: const Text('Mis registros', style: TextStyle(color: AppColors.text)),
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<String>(
                    value: 'cuenta_completa',
                    enabled: widget.cuentaCompartidaActiva && !_cargando,
                    title: Text(
                      'Consolidado grupal',
                      style: TextStyle(
                        color: widget.cuentaCompartidaActiva ? AppColors.text : AppColors.muted,
                      ),
                    ),
                    subtitle: widget.cuentaCompartidaActiva
                        ? null
                        : const Text('Solo disponible en cuenta compartida',
                            style: TextStyle(color: AppColors.muted, fontSize: 12)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          onPressed: _cargando ? null : () => _elegirFecha(true),
          child: Text('Desde: ${_desde.day.toString().padLeft(2, '0')}/${_desde.month.toString().padLeft(2, '0')}/${_desde.year}'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _cargando ? null : () => _elegirFecha(false),
          child: Text('Hasta: ${_hasta.day.toString().padLeft(2, '0')}/${_hasta.month.toString().padLeft(2, '0')}/${_hasta.year}'),
        ),
      ],
    ),
            if (!_fechasValidas)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('La fecha "desde" no puede ser posterior a "hasta".',
                    style: TextStyle(color: AppColors.danger, fontSize: 12)),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cargando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: (_cargando || !_fechasValidas) ? null : _exportar,
          child: _cargando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Exportar'),
        ),
      ],
    );
  }
}