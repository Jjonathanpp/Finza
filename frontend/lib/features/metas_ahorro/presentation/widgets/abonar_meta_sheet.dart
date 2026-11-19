import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/features/metas_ahorro/data/models/meta_ahorro.dart';
import 'package:frontend/l10n/idioma.dart';
import 'package:frontend/shared/utils/importe.dart';

class AbonarMetaSheet extends StatefulWidget {
  const AbonarMetaSheet({
    super.key,
    required this.meta,
    required this.alAbonar,
  });

  final MetaAhorro meta;
  final Future<void> Function(double monto) alAbonar;

  @override
  State<AbonarMetaSheet> createState() => _AbonarMetaSheetState();
}

class _AbonarMetaSheetState extends State<AbonarMetaSheet> {
  final _formKey = GlobalKey<FormState>();
  final _monto = TextEditingController();
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final monto = double.parse(_monto.text.trim().replaceAll(',', '.'));
    if (monto > widget.meta.montoRestante) {
      setState(
        () => _error = context.tr(
          'El aporte no puede superar lo que falta para completar la meta.',
        ),
      );
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
      if (mounted) {
        setState(
          () => _error = tr('Error al ingresar dinero a la meta: {error}', {
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
    final metaCompleta = widget.meta.montoRestante <= 0;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('Ingresar dinero'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.meta.nombre,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('Faltan {monto}', {
                  'monto': importe(widget.meta.montoRestante),
                }),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _monto,
                autofocus: true,
                enabled: !_guardando,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*[,.]?\d{0,2}'),
                  ),
                ],
                decoration: InputDecoration(
                  labelText: context.tr('Monto a ingresar'),
                  prefixText: '\$ ',
                  helperText: context.tr('Máximo: {monto}', {
                    'monto': importe(widget.meta.montoRestante, centavos: true),
                  }),
                ),
                validator: (value) {
                  final monto = double.tryParse(
                    (value ?? '').trim().replaceAll(',', '.'),
                  );
                  if (monto == null || monto <= 0) {
                    return context.tr('Ingresá un monto mayor a cero');
                  }
                  if (monto > widget.meta.montoRestante) {
                    return context.tr(
                      'El aporte no puede superar lo que falta para completar la meta.',
                    );
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ],
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _guardando || metaCompleta ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.tr('Ingresar dinero')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
