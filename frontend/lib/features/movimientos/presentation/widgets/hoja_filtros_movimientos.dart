import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/campo.dart';
import 'package:frontend/features/categorias/data/models/categoria.dart';
import 'package:frontend/features/movimientos/presentation/viewmodels/movimientos_view_model.dart';
import 'package:frontend/features/movimientos/presentation/widgets/caja_fecha.dart';

// El contenido de la hoja "Filtrar movimientos": lo que no entra en las pastillas de la pantalla (fechas y
// categoría). Tipo, estado e integrante se eligen con las pastillas y acá se conservan tal cual están.
class HojaFiltrosMovimientos extends StatefulWidget {
  const HojaFiltrosMovimientos({super.key, required this.vm});

  final MovimientosViewModel vm;

  @override
  State<HojaFiltrosMovimientos> createState() => _HojaFiltrosMovimientosState();
}

class _HojaFiltrosMovimientosState extends State<HojaFiltrosMovimientos> {
  late DateTime? _desde = widget.vm.desde;
  late DateTime? _hasta = widget.vm.hasta;
  late Categoria? _categoria = widget.vm.categoriaFiltro;

  Future<void> _elegirFecha(bool esDesde) async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: (esDesde ? _desde : _hasta) ?? hoy,
      firstDate: DateTime(hoy.year - 5),
      lastDate: hoy,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
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

  void _limpiar() {
    widget.vm.limpiarFiltros();
    Navigator.pop(context);
  }

  void _aplicar() {
    widget.vm.aplicarFiltros(
      nuevoDesde: _desde,
      nuevoHasta: _hasta,
      nuevaCategoria: _categoria,
      nuevoEsIngreso: widget.vm.esIngresoFiltro,
      nuevoEstado: widget.vm.estadoFiltro,
      nuevoPerfilId: widget.vm.perfilFiltroId,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CajaFecha(
                etiqueta: 'Desde',
                fecha: _desde,
                textoVacio: 'Elegir',
                alTocar: () => _elegirFecha(true),
              ),
            ),
            Expanded(
              child: CajaFecha(
                etiqueta: 'Hasta',
                fecha: _hasta,
                textoVacio: 'Elegir',
                alTocar: () => _elegirFecha(false),
              ),
            ),
          ],
        ),
        Campo(
          etiqueta: 'Categoría',
          child: DropdownButtonFormField<Categoria>(
            initialValue: _categoria,
            isExpanded: true,
            hint: const Text('Todas las categorías'),
            items: [
              const DropdownMenuItem<Categoria>(
                value: null,
                child: Text('Todas las categorías'),
              ),
              ...widget.vm.categorias.map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(
                    '${c.emoji ?? ''} ${c.nombre}'.trim(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (cat) => setState(() => _categoria = cat),
          ),
        ),
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _limpiar,
                child: const Text('Limpiar'),
              ),
            ),
            Expanded(
              child: FilledButton(
                onPressed: _aplicar,
                child: const Text('Aplicar filtros'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
