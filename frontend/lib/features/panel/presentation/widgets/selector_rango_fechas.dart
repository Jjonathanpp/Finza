import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/filtro_pastilla.dart';
import 'package:frontend/l10n/idioma.dart';

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
      // Los últimos 2 meses, con el actual (igual que el backend desde 8555abb de Eze).
      start = DateTime(hoy.year, hoy.month - 1, 1);
      end = DateTime(hoy.year, hoy.month + 1, 0);
    } else if (opcion == 'Trimestral') {
      // Los últimos 3 meses, con el actual.
      start = DateTime(hoy.year, hoy.month - 2, 1);
      end = DateTime(hoy.year, hoy.month + 1, 0);
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
      lastDate: hoy,
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
    if (f == null) return context.tr('Seleccionar');
    return '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        FilaFiltros(
          etiqueta: context.tr('Período de informes'),
          children: [
            for (final op in _opciones)
              FiltroPastilla(texto: context.tr(op), activo: op == _opcionElegida, alTocar: () => _aplicarFiltro(op)),
          ],
        ),
        if (_opcionElegida == 'Personalizado')
          Row(
            spacing: 12,
            children: [
              Expanded(child: _campoFecha(textos, context.tr('Desde'), _inicioPersonalizado, true)),
              Expanded(child: _campoFecha(textos, context.tr('Hasta'), _finPersonalizado, false)),
            ],
          ),
      ],
    );
  }

  Widget _campoFecha(TextTheme textos, String etiqueta, DateTime? fecha, bool esInicio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        Text(etiqueta, style: textos.bodySmall),
        OutlinedButton.icon(
          onPressed: () => _elegirFechaPersonalizada(esInicio),
          icon: const Icon(Icons.calendar_today, size: 16),
          label: Text(_formatoFecha(fecha), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
