import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';

// Envuelve cualquier cosa tocable y la achica a 0,96 mientras se aprieta (.toque de la maqueta).
// Sin animación si el sistema pide reducir movimiento. Se anuncia como botón. Si alTocar es null no
// hace nada (queda deshabilitado). Ojo: el área táctil es la del hijo, que tiene que medir 44 px o más.
class Tocable extends StatefulWidget {
  const Tocable({
    super.key,
    required this.child,
    required this.alTocar,
    this.etiqueta,
  });

  final Widget child;
  final VoidCallback? alTocar;

  // Lo que lee el lector de pantalla. Si es null se lee el texto del hijo.
  final String? etiqueta;

  @override
  State<Tocable> createState() => _TocableState();
}

class _TocableState extends State<Tocable> {
  bool _apretado = false;

  void _apretar(bool valor) {
    if (_apretado != valor) setState(() => _apretado = valor);
  }

  @override
  Widget build(BuildContext context) {
    final activo = widget.alTocar != null;
    final sinAnimacion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      enabled: activo,
      label: widget.etiqueta,
      excludeSemantics: widget.etiqueta != null,
      onTap: widget.alTocar,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: activo ? (_) => _apretar(true) : null,
        onTapUp: activo ? (_) => _apretar(false) : null,
        onTapCancel: activo ? () => _apretar(false) : null,
        onTap: widget.alTocar,
        child: AnimatedScale(
          scale: _apretado ? .96 : 1,
          duration: sinAnimacion ? Duration.zero : Duraciones.toque,
          curve: Curvas.toque,
          child: widget.child,
        ),
      ),
    );
  }
}
