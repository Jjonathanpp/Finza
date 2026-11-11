import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/widgets/tocable.dart';

// .op de la maqueta: una fila de opción de 56 px como mínimo, con un elemento adelante (leading,
// normalmente un CirculoCategoria), título (.t1), subtítulo (.t2) y algo a la derecha: una flecha
// (flecha = true), un valor en verde (valor: "Cambiar"), el widget que se pase en trailing, o un switch
// con FilaOpcion.interruptor. Sirve también como la .fila genérica (avatar + dos textos + algo).
// colorTitulo es para las acciones peligrosas (coralTexto).
class FilaOpcion extends StatelessWidget {
  const FilaOpcion({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.leading,
    this.trailing,
    this.valor,
    this.flecha = false,
    this.colorTitulo,
    this.alTocar,
    this.etiqueta,
  }) : _interruptor = null,
       _alCambiar = null;

  // Una fila con un Switch a la derecha; tocar cualquier parte de la fila lo cambia.
  const FilaOpcion.interruptor({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.leading,
    required bool activo,
    required this._alCambiar,
    this.etiqueta,
  }) : _interruptor = activo,
       trailing = null,
       valor = null,
       flecha = false,
       colorTitulo = null,
       alTocar = null;

  final String titulo;
  final String? subtitulo;
  final Widget? leading;
  final Widget? trailing;
  final String? valor;
  final bool flecha;
  final Color? colorTitulo;
  final VoidCallback? alTocar;
  final String? etiqueta;
  final bool? _interruptor;
  final ValueChanged<bool>? _alCambiar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    final conSwitch = _interruptor != null;
    Widget? derecha = trailing;
    if (conSwitch) {
      derecha = ExcludeSemantics(
        child: IgnorePointer(
          child: Switch(value: _interruptor, onChanged: (_) {}),
        ),
      );
    } else if (valor != null) {
      derecha = Text(
        valor!,
        style: textos.labelLarge?.copyWith(fontSize: 14, color: c.primario),
      );
    } else if (flecha) {
      derecha = Icon(Icons.chevron_right_rounded, size: 18, color: c.suave);
    }
    final fila = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: LayoutBuilder(
          builder: (context, restriccion) => Row(
            spacing: 14,
            children: [
              ?leading,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      titulo,
                      style: textos.bodyMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorTitulo,
                      ),
                    ),
                    if (subtitulo != null)
                      Text(subtitulo!, style: textos.bodySmall),
                  ],
                ),
              ),
              // Lo de la derecha no pasa de poco más de la mitad de la fila, para que el título conserve
              // su lugar. Un chip largo adentro tiene que ir en un Flexible para cortarse con puntos.
              if (derecha != null)
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: restriccion.maxWidth * 0.55,
                    ),
                    child: derecha,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (conSwitch) {
      return Semantics(
        toggled: _interruptor,
        label: etiqueta,
        excludeSemantics: etiqueta != null,
        onTap: () => _alCambiar!(!_interruptor),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _alCambiar!(!_interruptor),
          child: fila,
        ),
      );
    }
    return alTocar == null
        ? fila
        : Tocable(alTocar: alTocar, etiqueta: etiqueta, child: fila);
  }
}
