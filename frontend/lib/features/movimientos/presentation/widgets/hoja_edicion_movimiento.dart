import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/campo.dart';
import 'package:frontend/core/widgets/selector_tipo.dart';
import 'package:frontend/features/movimientos/data/models/movimiento.dart';
import 'package:frontend/features/movimientos/presentation/widgets/caja_fecha.dart';
import 'package:frontend/shared/utils/importe.dart';

typedef GuardarMovimiento =
    Future<String?> Function({
      required bool esIngreso,
      required String monto,
      required String categoria,
      required String descripcion,
      required DateTime fecha,
    });

// El contenido de la hoja "Editar movimiento". Al guardar llama a alGuardar (que devuelve el mensaje de
// error, o null si salió bien) y cierra la hoja con ese resultado: (error: ...). Si se cierra sin guardar,
// la hoja devuelve null.
class HojaEdicionMovimiento extends StatefulWidget {
  const HojaEdicionMovimiento({
    super.key,
    required this.movimiento,
    required this.alGuardar,
  });

  final Movimiento movimiento;
  final GuardarMovimiento alGuardar;

  @override
  State<HojaEdicionMovimiento> createState() => _HojaEdicionMovimientoState();
}

class _HojaEdicionMovimientoState extends State<HojaEdicionMovimiento> {
  late final _monto = TextEditingController(
    text: widget.movimiento.monto.toString(),
  );
  late final _categoria = TextEditingController(
    text: widget.movimiento.categoria.nombre,
  );
  late final _descripcion = TextEditingController(
    text: widget.movimiento.descripcion ?? '',
  );
  late bool _esIngreso = widget.movimiento.esIngreso;
  late DateTime _fecha = widget.movimiento.fecha;
  bool _guardando = false;

  @override
  void dispose() {
    _monto.dispose();
    _categoria.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      // Escrita a mano, la app (todavía en inglés) la lee como mes/día/año: solo calendario.
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final error = await widget.alGuardar(
        esIngreso: _esIngreso,
        monto: _monto.text,
        categoria: _categoria.text,
        descripcion: _descripcion.text,
        fecha: _fecha,
      );
      if (!mounted) return;
      Navigator.pop(context, (error: error));
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
          etiqueta: 'Tipo de movimiento',
          child: SelectorTipo(
            esIngreso: _esIngreso,
            alCambiar: (v) => setState(() => _esIngreso = v),
          ),
        ),
        Campo(
          etiqueta: convierte ? 'Monto en pesos' : 'Monto',
          child: TextField(
            controller: _monto,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
        Campo(
          etiqueta: 'Categoría',
          child: TextField(controller: _categoria),
        ),
        CajaFecha(etiqueta: 'Fecha', fecha: _fecha, alTocar: _elegirFecha),
        Campo(
          etiqueta: 'Descripción',
          child: TextField(controller: _descripcion),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
