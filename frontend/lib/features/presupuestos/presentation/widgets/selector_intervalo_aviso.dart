import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';

// "Avisarme cada": el intervalo del popup de presupuesto (ver core/avisos/aviso_de_presupuestos.dart).
// Opciones rápidas y "Otro" para escribir cualquier valor entre 5 y 100. Debajo dice en qué
// porcentajes va a avisar, para que se entienda qué se está eligiendo.
const intervaloAvisoMinimo = 5;
const intervaloAvisoMaximo = 100;

class SelectorIntervaloAviso extends StatefulWidget {
  const SelectorIntervaloAviso({
    super.key,
    required this.valor,
    required this.alCambiar,
    this.habilitado = true,
  });

  final int valor;
  final ValueChanged<int> alCambiar;
  final bool habilitado;

  @override
  State<SelectorIntervaloAviso> createState() => _SelectorIntervaloAvisoState();
}

class _SelectorIntervaloAvisoState extends State<SelectorIntervaloAviso> {
  static const _opciones = [20, 25, 33, 50];

  late bool _otro = !_opciones.contains(widget.valor);
  late final _texto = TextEditingController(text: _otro ? '${widget.valor}' : '');

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  String? get _errorOtro {
    if (!_otro || _texto.text.trim().isEmpty) return null;
    final v = int.tryParse(_texto.text.trim());
    if (v == null || v < intervaloAvisoMinimo || v > intervaloAvisoMaximo) {
      return 'Entre $intervaloAvisoMinimo y $intervaloAvisoMaximo';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final opcion in _opciones)
              ChoiceChip(
                label: Text('$opcion%'),
                selected: !_otro && widget.valor == opcion,
                onSelected: widget.habilitado
                    ? (_) {
                        setState(() => _otro = false);
                        widget.alCambiar(opcion);
                      }
                    : null,
              ),
            ChoiceChip(
              label: const Text('Otro'),
              selected: _otro,
              onSelected: widget.habilitado ? (_) => setState(() => _otro = true) : null,
            ),
          ],
        ),
        if (_otro) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: 160,
            child: TextField(
              controller: _texto,
              enabled: widget.habilitado,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Cada cuánto',
                suffixText: '%',
                errorText: _errorOtro,
              ),
              onChanged: (texto) {
                setState(() {}); // para el mensaje de error
                final v = int.tryParse(texto.trim());
                if (v != null && v >= intervaloAvisoMinimo && v <= intervaloAvisoMaximo) {
                  widget.alCambiar(v);
                }
              },
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.notifications_active_outlined, size: 16, color: AppColors.muted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                describirAvisos(widget.valor),
                style: const TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// "Te avisamos al 33%, 66%, 99% y si te pasás del tope."
String describirAvisos(int intervalo) {
  if (intervalo < 1) return '';
  final marcas = [for (var k = 1; k * intervalo <= 100; k++) '${k * intervalo}%'];
  final tocaElTope = marcas.isNotEmpty && marcas.last == '100%';
  if (marcas.length == 1 && tocaElTope) return 'Te avisamos cuando llegues al tope.';
  final lista = marcas.length == 1
      ? marcas.first
      : '${marcas.sublist(0, marcas.length - 1).join(', ')}${tocaElTope ? ' y ' : ', '}${marcas.last}';
  return tocaElTope
      ? 'Te avisamos al $lista (el tope).'
      : 'Te avisamos al $lista y si te pasás del tope.';
}