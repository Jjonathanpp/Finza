import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/widgets/campo.dart';
import 'package:frontend/core/widgets/confirmar.dart';
import 'package:frontend/core/widgets/hoja.dart';
import 'package:frontend/features/presupuestos/data/models/presupuesto.dart';
import 'package:frontend/features/presupuestos/presentation/widgets/selector_intervalo_aviso.dart';
import 'package:frontend/l10n/idioma.dart';

// "Editar tope": la hoja que sube desde abajo en el detalle de un presupuesto, si podés cambiarlo (sos
// admin de la cuenta compartida, t-13.1.2, o es tu cuenta personal): cambiar el tope y el aviso, o
// desactivarlo. Se cierra sola cuando el backend dice que sí; si dice que no, muestra su mensaje.
// Se abre con EditarPresupuestoSheet.mostrar: la hoja (título, texto y agarre) la pone mostrarHoja y
// este widget es lo de adentro.
class EditarPresupuestoSheet extends StatefulWidget {
  const EditarPresupuestoSheet({
    super.key,
    required this.presupuesto,
    required this.periodo,
    this.cuenta,
    required this.alGuardar,
    required this.alDesactivar,
  });

  final Presupuesto presupuesto;
  final String periodo;
  // El nombre de la cuenta compartida; null en la personal.
  final String? cuenta;
  final Future<void> Function(double tope, int intervaloAviso) alGuardar;
  final Future<void> Function() alDesactivar;

  static Future<void> mostrar(
    BuildContext context, {
    required Presupuesto presupuesto,
    required String periodo,
    String? cuenta,
    required Future<void> Function(double tope, int intervaloAviso) alGuardar,
    required Future<void> Function() alDesactivar,
  }) {
    return mostrarHoja<void>(
      context,
      titulo: context.tr('Editar tope · {categoria}', {'categoria': context.tr(presupuesto.categoriaNombre)}),
      texto:
          '${cuenta ?? context.tr('Personal')} · ${periodo.toLowerCase()}${cuenta == null ? '.' : '. Lo ven todos.'}',
      contenido: EditarPresupuestoSheet(
        presupuesto: presupuesto,
        periodo: periodo,
        cuenta: cuenta,
        alGuardar: alGuardar,
        alDesactivar: alDesactivar,
      ),
    );
  }

  @override
  State<EditarPresupuestoSheet> createState() => _EditarPresupuestoSheetState();
}

class _EditarPresupuestoSheetState extends State<EditarPresupuestoSheet> {
  late final _tope = TextEditingController(
    text: widget.presupuesto.montoTope.toStringAsFixed(widget.presupuesto.montoTope % 1 == 0 ? 0 : 2),
  );
  late int _intervaloAviso = widget.presupuesto.intervaloAviso;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _tope.dispose();
    super.dispose();
  }

  Future<void> _enviar(Future<void> Function() pedido) async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await pedido();
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _guardar() {
    final tope = double.tryParse(_tope.text.trim().replaceAll(',', '.'));
    if (tope == null || tope <= 0) {
      setState(() => _error = context.tr('Ingresá un tope mayor a cero'));
      return;
    }
    _enviar(() => widget.alGuardar(tope, _intervaloAviso));
  }

  Future<void> _desactivar() async {
    final datos = {
      'categoria': context.tr(widget.presupuesto.categoriaNombre),
      'periodo': widget.periodo,
      'cuenta': '${widget.cuenta}',
    };
    final seguro = await confirmar(
      context,
      titulo: context.tr('Desactivar presupuesto'),
      texto: widget.cuenta == null
          ? context.tr('¿Desactivar el presupuesto de {categoria} de {periodo}?', datos)
          : context.tr('¿Desactivar el presupuesto de {categoria} de {periodo} para todos los de {cuenta}?', datos),
      textoAccion: context.tr('Desactivar'),
      peligro: true,
    );
    if (seguro) await _enviar(widget.alDesactivar);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Campo(
          etiqueta: context.tr('Tope del mes'),
          child: TextField(
            controller: _tope,
            enabled: !_guardando,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(prefixText: r'$ '),
          ),
        ),
        Campo(
          etiqueta: context.tr('Avisarme cada'),
          child: SelectorIntervaloAviso(
            valor: _intervaloAviso,
            habilitado: !_guardando,
            alCambiar: (valor) => setState(() => _intervaloAviso = valor),
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
        FilledButton(onPressed: _guardando ? null : _guardar, child: Text(context.tr('Guardar'))),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _guardando ? null : _desactivar,
          style: estiloBotonPeligro(context),
          child: Text(context.tr('Desactivar presupuesto')),
        ),
      ],
    );
  }
}
