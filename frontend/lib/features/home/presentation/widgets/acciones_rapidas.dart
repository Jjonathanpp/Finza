import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/features/movimientos/presentation/screens/movimientos_screen.dart';
import 'package:frontend/features/movimientos/presentation/screens/alta_movimiento_screen.dart';
import 'package:frontend/features/voice/voice_screen.dart';

class AccionesRapidas extends StatelessWidget {
  const AccionesRapidas({super.key});

  static const _colorMovimientos = Color(0xFF2F6B9A);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _BotonAccion(
            icono: Icons.arrow_upward,
            texto: 'Ingreso',
            color: AppColors.accent,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AltaMovimientoScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 4,
          child: _BotonAccion(
            icono: Icons.list,
            texto: 'Movimientos',
            color: _colorMovimientos,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MovimientosScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: _BotonAccion(
            icono: Icons.arrow_downward,
            texto: 'Voz',
            color: const Color.fromARGB(255, 146, 151, 12),
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
    required this.color,
    required this.onPressed,
  });

  final IconData icono;
  final String texto;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icono, size: 18, color: color),
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          texto,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color, width: 1.5),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      ),
    );
  }
}
