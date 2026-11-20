import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/core/widgets/campo.dart';
import 'package:frontend/core/widgets/hoja.dart';
import 'package:frontend/features/metas_ahorro/data/models/meta_ahorro.dart';
import 'package:frontend/l10n/idioma.dart';

// Crear o editar una meta (meta == null es crear): nombre, monto objetivo y una fecha límite opcional.
// Se cierra sola cuando el backend dice que sí (devuelve true); si dice que no, muestra su mensaje.
class FormularioMetaSheet extends StatefulWidget {
  const FormularioMetaSheet({super.key, this.meta, required this.alGuardar});

  final MetaAhorro? meta;
  final Future<void> Function(String nombre, double montoObjetivo, DateTime? fechaLimite) alGuardar;

  static Future<bool?> mostrar(
    BuildContext context, {
    MetaAhorro? meta,
    required Future<void> Function(String nombre, double montoObjetivo, DateTime? fechaLimite) alGuardar,
  }) {
    final cuenta = cuentaActiva.value?['nombre'] as String?;
    return mostrarHoja<bool>(
      context,
      titulo: meta == null ? context.tr('Nueva meta') : context.tr('Editar meta'),
      texto: cuenta == null ? context.tr('Personal.') : '$cuenta. La ven todos.',
      contenido: FormularioMetaSheet(meta: meta, alGuardar: alGuardar),
    );
  }

  @override
  State<FormularioMetaSheet> createState() => _FormularioMetaSheetState();
}

class _FormularioMetaSheetState extends State<FormularioMetaSheet> {
  late final _nombre = TextEditingController(text: widget.meta?.nombre ?? '');
  late final _monto = TextEditingController(text: widget.meta == null ? '' : _numero(widget.meta!.montoObjetivo));
  late DateTime? _fechaLimite = widget.meta?.fechaLimite;
  bool _fechaModificada = false;
  bool _guardando = false;
  String? _errorNombre;
  String? _errorMonto;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _monto.dispose();
    super.dispose();
  }

  String _numero(double valor) => valor.toStringAsFixed(valor % 1 == 0 ? 0 : 2);

  Future<void> _elegirFecha() async {
    final hoy = DateUtils.dateOnly(DateTime.now());
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaLimite == null || _fechaLimite!.isBefore(hoy) ? hoy : _fechaLimite!,
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
    final nombre = _nombre.text.trim();
    final monto = double.tryParse(_monto.text.trim().replaceAll(',', '.'));
    setState(() {
      _errorNombre = nombre.isEmpty ? context.tr('El nombre es obligatorio') : null;
      _errorMonto = monto == null || monto <= 0 ? context.tr('Ingresá un monto mayor a cero') : null;
      _error = null;
    });
    if (_errorNombre != null || _errorMonto != null) return;
    setState(() => _guardando = true);
    try {
      // Al editar, la fecha va solo si se cambió.
      await widget.alGuardar(nombre, monto!, _fechaModificada || widget.meta == null ? _fechaLimite : null);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = tr('Error al guardar la meta: {error}', {'error': '$e'}));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final fecha = _fechaLimite;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Campo(
          etiqueta: context.tr('Nombre'),
          error: _errorNombre,
          child: TextField(
            controller: _nombre,
            enabled: !_guardando,
            maxLength: 100,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: context.tr('Vacaciones, un auto, el fondo de emergencia…'),
              counterText: '',
            ),
          ),
        ),
        Campo(
          etiqueta: context.tr('Objetivo'),
          error: _errorMonto,
          child: TextField(
            controller: _monto,
            enabled: !_guardando,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(prefixText: r'$ '),
          ),
        ),
        Campo(
          etiqueta: context.tr('Fecha límite (opcional)'),
          ayuda: context.tr('Con fecha, Finza te dice cuánto separar por día, semana o mes.'),
          child: OutlinedButton.icon(
            onPressed: _guardando ? null : _elegirFecha,
            icon: const Icon(Icons.event_outlined),
            label: Text(fecha == null ? context.tr('Elegir fecha') : '${fecha.day}/${fecha.month}/${fecha.year}'),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: c.coralTexto),
            ),
          ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: c.sobrePrimario))
              : Text(widget.meta == null ? context.tr('Crear meta') : context.tr('Guardar cambios')),
        ),
      ],
    );
  }
}
