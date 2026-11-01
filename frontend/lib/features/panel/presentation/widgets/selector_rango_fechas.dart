import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';

class SelectorRangoFechas extends StatefulWidget {
  const SelectorRangoFechas({super.key, required this.onCambio});
  final void Function(DateTime? start, DateTime? end) onCambio;

  @override
  State<SelectorRangoFechas> createState() => _SelectorRangoFechasState();
}

class _SelectorRangoFechasState extends State<SelectorRangoFechas> with AutomaticKeepAliveClientMixin<SelectorRangoFechas> {
  String _opcionElegida = 'Mensual';
  DateTime? _inicioPersonalizado;
  DateTime? _finPersonalizado;

  final List<String> _opciones = [
    'Mensual',
    'Bimestral',
    'Trimestral',
    'Anual',
    'Personalizado'
  ];

  void _aplicarFiltro(String opcion) {
    setState(() {
      _opcionElegida = opcion;
    });

    final hoy = DateTime.now();
    DateTime? start;
    DateTime? end;

    if (opcion == 'Mensual') {
      start = DateTime(hoy.year, hoy.month, 1);
      end = DateTime(hoy.year, hoy.month + 1, 0);
    } else if (opcion == 'Bimestral') {
      int mesInicio = hoy.month % 2 == 0 ? hoy.month - 1 : hoy.month;
      start = DateTime(hoy.year, mesInicio, 1);
      end = DateTime(hoy.year, mesInicio + 2, 0);
    } else if (opcion == 'Trimestral') {
      int mesInicio = ((hoy.month - 1) ~/ 3) * 3 + 1;
      start = DateTime(hoy.year, mesInicio, 1);
      end = DateTime(hoy.year, mesInicio + 3, 0);
    } else if (opcion == 'Anual') {
      start = DateTime(hoy.year, 1, 1);
      end = DateTime(hoy.year, 12, 31);
    } else if (opcion == 'Personalizado') {
      start = _inicioPersonalizado;
      end = _finPersonalizado;
    }

    if (opcion != 'Personalizado' || (start != null && end != null)) {
      widget.onCambio(start, end);
    }
  }

  Future<void> _elegirFechaPersonalizada(bool esInicio) async {
    final hoy = DateTime.now();
    final inicial = esInicio ? (_inicioPersonalizado ?? hoy) : (_finPersonalizado ?? hoy);
    
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2020),
      lastDate: DateTime(hoy.year + 1),
    );

    if (seleccionada != null) {
      setState(() {
        if (esInicio) {
          _inicioPersonalizado = seleccionada;
        } else {
          _finPersonalizado = seleccionada;
        }
      });
      
      if (_inicioPersonalizado != null && _finPersonalizado != null) {
        widget.onCambio(_inicioPersonalizado, _finPersonalizado);
      }
    }
  }

  String _formatoFecha(DateTime? f) {
    if (f == null) return 'Seleccionar';
    return '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
      super.build(context);
      return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Período de informes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _opcionElegida,
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
            items: _opciones.map((op) => DropdownMenuItem(value: op, child: Text(op))).toList(),
            onChanged: (val) {
              if (val != null) _aplicarFiltro(val);
            },
          ),
          if (_opcionElegida == 'Personalizado') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Desde', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        onPressed: () => _elegirFechaPersonalizada(true),
                        icon: const Icon(Icons.calendar_today, size: 14),
                        label: Text(_formatoFecha(_inicioPersonalizado), style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hasta', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        onPressed: () => _elegirFechaPersonalizada(false),
                        icon: const Icon(Icons.calendar_today, size: 14),
                        label: Text(_formatoFecha(_finPersonalizado), style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}