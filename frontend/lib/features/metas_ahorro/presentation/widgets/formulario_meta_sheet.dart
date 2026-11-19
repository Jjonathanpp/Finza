import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/features/metas_ahorro/data/models/meta_ahorro.dart';
import 'package:frontend/l10n/idioma.dart';

class FormularioMetaSheet extends StatefulWidget {
  const FormularioMetaSheet({super.key, this.meta, required this.alGuardar});

  final MetaAhorro? meta;
  final Future<void> Function(String nombre, double monto, DateTime? fecha)
  alGuardar;

  @override
  State<FormularioMetaSheet> createState() => _FormularioMetaSheetState();
}

class _FormularioMetaSheetState extends State<FormularioMetaSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.meta?.nombre ?? '');
  late final _monto = TextEditingController(
    text: widget.meta == null ? '' : _numero(widget.meta!.montoObjetivo),
  );
  late DateTime? _fechaLimite = widget.meta?.fechaLimite;
  bool _fechaModificada = false;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _monto.dispose();
    super.dispose();
  }

  String _numero(double valor) => valor.toStringAsFixed(valor % 1 == 0 ? 0 : 2);

  Future<void> _seleccionarFecha() async {
    final hoy = DateUtils.dateOnly(DateTime.now());
    final fechaInicial = _fechaLimite == null || _fechaLimite!.isBefore(hoy)
        ? hoy
        : _fechaLimite!;
    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: hoy,
      lastDate: DateTime(2100),
    );
    if (fecha != null) {
      setState(() {
        _fechaLimite = fecha;
        _fechaModificada = true;
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final valor = double.parse(_monto.text.trim().replaceAll(',', '.'));
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await widget.alGuardar(
        _nombre.text.trim(),
        valor,
        _fechaModificada || widget.meta == null ? _fechaLimite : null,
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(
          () =>
              _error = tr('Error al guardar la meta: {error}', {'error': '$e'}),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  String _formatoFecha(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}/'
      '${fecha.year}';

  @override
  Widget build(BuildContext context) {
    final editando = widget.meta != null;
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
                context.tr(
                  editando ? 'Editar meta de ahorro' : 'Nueva meta de ahorro',
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nombre,
                enabled: !_guardando,
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: context.tr('Nombre de la meta'),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.tr('El nombre es obligatorio');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _monto,
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
                  labelText: context.tr('Monto objetivo'),
                  prefixText: '\$ ',
                ),
                validator: (value) {
                  final monto = double.tryParse(
                    (value ?? '').trim().replaceAll(',', '.'),
                  );
                  if (monto == null || monto <= 0) {
                    return context.tr('Ingresá un monto mayor a cero');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _guardando ? null : _seleccionarFecha,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  _fechaLimite == null
                      ? context.tr('Agregar fecha límite (opcional)')
                      : context.tr('Fecha límite: {fecha}', {
                          'fecha': _formatoFecha(_fechaLimite!),
                        }),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ],
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        context.tr(editando ? 'Guardar cambios' : 'Crear meta'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
