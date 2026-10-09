import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import '../storage/token_storage.dart';
import '../../features/login/screens/login_screen.dart';
import '../../features/voice/voice_screen.dart';
import '../../features/categorias/presentation/screens/categorias_screen.dart';
import '../../features/movimientos/presentation/screens/alta_movimiento_screen.dart';
import '../../features/movimientos/presentation/screens/movimientos_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    await TokenStorage().limpiar();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(
                Icons.list_alt,
                color: AppColors.muted,
              ),
              title: const Text(
                'Historial',
                style: TextStyle(color: AppColors.text),
              ),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MovimientosScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.add_circle_outline,
                color: AppColors.muted,
              ),
              title: const Text(
                'Nuevo movimiento',
                style: TextStyle(color: AppColors.text),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AltaMovimientoScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.category_outlined,
                color: AppColors.muted,
              ),
              title: const Text(
                'Categorías',
                style: TextStyle(color: AppColors.text),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoriasScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic, color: AppColors.muted),
              title: const Text(
                'Registro por voz',
                style: TextStyle(color: AppColors.text),
              ),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const VoiceScreen()),
                );
              },
            ),
            const Spacer(),
            const Divider(color: AppColors.line),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(color: AppColors.danger),
              ),
              onTap: () => _cerrarSesion(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}