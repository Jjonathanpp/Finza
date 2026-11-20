import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/widgets/campo.dart';
import 'package:frontend/core/widgets/hoja.dart';
import 'package:frontend/features/metas_ahorro/data/models/meta_ahorro.dart';
import 'package:frontend/shared/utils/importe.dart';
import 'package:frontend/l10n/idioma.dart';

// "Ingresar dinero": la hoja para sumarle plata a una meta. No deja pasar de lo que falta.
// Se cierra sola cuando el backend dice que sí (devuelve true); si dice que no, muestra su mensaje.
class AbonarMetaSheet extends StatefulWidget {
  const AbonarMetaSheet({super.key, required this.meta, required this.alAbonar});

  final MetaAhorro meta;
  final Future<void> Function(double monto) alAbonar;

  static Future<bool?> mostrar(
    BuildContext context, {
    required MetaAhorro meta,
    required Future<void> Function(double monto) alAbonar,
  }) {
    return mostrarHoja<bool>(
      context,
      titulo: context.tr('Ingresar dinero'),
      texto: '${meta.nombre} · faltan ${importe(meta.montoRestante, centavos: true)}',
      contenido: AbonarMetaSheet(meta: meta, alAbonar: alAbonar),
    );
  }

  @override
  State<AbonarMetaSheet> createState() => _AbonarMetaSheetState();
}

class _AbonarMetaSheetState extends State<AbonarMetaSheet> {
  final _monto = TextEditingController();
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final monto = double.tryParse(_monto.text.trim().replaceAll(',', '.'));
    if (monto == null || monto <= 0) {
      setState(() => _error = context.tr('Ingresá un monto mayor a cero'));
      return;
    }
    if (monto > widget.meta.montoRestante) {
      setState(() => _error = context.tr('El aporte no puede superar lo que falta para completar la meta.'));
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await widget.alAbonar(monto);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = tr('Error al ingresar dinero a la meta: {error}', {'error': '$e'}));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Campo(
          etiqueta: context.tr('Monto'),
          error: _error,
          ayuda: context.tr('Hasta {monto}', {'monto': importe(widget.meta.montoRestante, centavos: true)}),
          child: TextField(
            controller: _monto,
            autofocus: true,
            enabled: !_guardando,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(prefixText: r'$ '),
            onSubmitted: (_) => _guardar(),
          ),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: context.colores.sobrePrimario),
                )
              : Text(context.tr('Ingresar dinero')),
        ),
      ],
    );
  }
}
