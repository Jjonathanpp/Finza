import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/widgets/campo.dart';
import 'package:frontend/core/widgets/hoja.dart';
import 'package:frontend/features/metas_ahorro/data/models/meta_ahorro.dart';
import 'package:frontend/l10n/idioma.dart';
import 'package:frontend/shared/utils/importe.dart';

class RetirarMetaSheet extends StatefulWidget {
  const RetirarMetaSheet({
    super.key,
    required this.meta,
    required this.alRetirar,
  });

  final MetaAhorro meta;
  final Future<void> Function(double monto) alRetirar;

  static Future<bool?> mostrar(
    BuildContext context, {
    required MetaAhorro meta,
    required Future<void> Function(double monto) alRetirar,
  }) {
    return mostrarHoja<bool>(
      context,
      titulo: context.tr('Retirar dinero'),
      texto:
          '${meta.nombre} · disponible ${importe(meta.montoActual, centavos: true)}',
      contenido: RetirarMetaSheet(meta: meta, alRetirar: alRetirar),
    );
  }

  @override
  State<RetirarMetaSheet> createState() => _RetirarMetaSheetState();
}

class _RetirarMetaSheetState extends State<RetirarMetaSheet> {
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
    if (monto > widget.meta.montoActual) {
      setState(
        () => _error = context.tr(
          'No podés retirar más dinero que el disponible en la meta.',
        ),
      );
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await widget.alRetirar(monto);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = tr('Error al retirar dinero de la meta: {error}', {
            'error': '$e',
          }),
        );
      }
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
          ayuda: context.tr('Hasta {monto}', {
            'monto': importe(widget.meta.montoActual, centavos: true),
          }),
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
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.colores.sobrePrimario,
                  ),
                )
              : Text(context.tr('Retirar dinero')),
        ),
      ],
    );
  }
}
