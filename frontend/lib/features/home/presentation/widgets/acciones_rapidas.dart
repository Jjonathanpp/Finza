import 'package:flutter/material.dart';
import 'package:frontend/features/movimientos/presentation/screens/movimientos_screen.dart';
import 'package:frontend/features/movimientos/presentation/screens/alta_movimiento_screen.dart';
import 'package:frontend/features/voice/voice_screen.dart';

// Los atajos del Inicio (no están en la maqueta): botones secundarios (.btn.bs) con el estilo del tema.
class AccionesRapidas extends StatelessWidget {
  const AccionesRapidas({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        Expanded(
          flex: 3,
          child: _BotonAccion(
            icono: Icons.south_west,
            texto: 'Ingreso',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AltaMovimientoScreen()),
              );
            },
          ),
        ),
        Expanded(
          flex: 4,
          child: _BotonAccion(
            icono: Icons.format_list_bulleted,
            texto: 'Movimientos',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MovimientosScreen()),
              );
            },
          ),
        ),
        Expanded(
          flex: 3,
          child: _BotonAccion(
            icono: Icons.mic_none,
            texto: 'Voz',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VoiceScreen()),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BotonAccion extends StatelessWidget {
  const _BotonAccion({
    required this.icono,
    required this.texto,
    required this.onPressed,
  });

  final IconData icono;
  final String texto;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icono, size: 18),
      label: FittedBox(fit: BoxFit.scaleDown, child: Text(texto)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      ),
    );
  }
}
