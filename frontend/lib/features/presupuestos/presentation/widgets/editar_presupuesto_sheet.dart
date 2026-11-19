import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/features/presupuestos/data/models/presupuesto.dart';
import 'package:frontend/features/presupuestos/presentation/widgets/selector_intervalo_aviso.dart';

// El panel que sube desde abajo (showModalBottomSheet) al tocar un presupuesto para cambiar 
// el tope o desactivarlo.
class EditarPresupuestoSheet extends StatefulWidget {
  const EditarPresupuestoSheet({
    super.key,
    required this.presupuesto,
    required this.periodo,
    required this.cuenta,
    required this.enCompartida,
    required this.alGuardar,
    required this.alDesactivar,
  });

  final Presupuesto presupuesto;
  final String periodo;
  final String cuenta;
  final bool enCompartida;
  final Future<void> Function(double tope, int intervaloAviso) alGuardar;
  final Future<void> Function() alDesactivar;

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
      setState(() => _error = 'Ingresá un tope mayor a cero');
      return;
    }
    _enviar(() => widget.alGuardar(tope, _intervaloAviso));
  }

  Future<void> _desactivar() async {
    final nombre = widget.presupuesto.categoriaNombre;
    final seguro = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desactivar presupuesto'),
        // ACÁ ESTÁ EL CAMBIO: Modificamos el texto si es cuenta propia o compartida
        content: Text(widget.enCompartida 
            ? '¿Desactivar el presupuesto de $nombre de ${widget.periodo} para todos los integrantes de ${widget.cuenta}?'
            : '¿Estás seguro de que querés desactivar el presupuesto de $nombre de ${widget.periodo}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
    if (seguro == true) await _enviar(widget.alDesactivar);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.presupuesto.categoriaNombre} · ${widget.periodo}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _tope,
            enabled: !_guardando,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: r'Tope ($)'),
          ),
          const SizedBox(height: 18),
          const Text('Avisarme cada', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SelectorIntervaloAviso(
            valor: _intervaloAviso,
            habilitado: !_guardando,
            alCambiar: (valor) => setState(() => _intervaloAviso = valor),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Guardar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: _guardando ? null : _desactivar,
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Desactivar presupuesto'),
          ),
        ],
        ),
      ),
    );
  }
}