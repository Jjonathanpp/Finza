import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import '../storage/token_storage.dart';
import '../../features/login/screens/login_screen.dart';
import '../../features/voice/voice_screen.dart';
import '../../features/movimientos/presentation/screens/alta_movimiento_screen.dart';
import '../../features/home/presentation/screens/pantalla_principal.dart';
import 'package:frontend/core/widgets/eliminar_cuenta_dialog.dart';
import 'package:frontend/core/widgets/cuenta_usuario.dart';
import 'package:frontend/features/configuracion/presentation/screens/configuracion_screen.dart';
import 'package:frontend/features/informes/presentation/screens/informes_screen.dart';

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

  void _eliminarCuenta(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pop(); // cierra el drawer
    EliminarCuentaDialog.mostrar(navigator.context);
  }

  void _abrirConfiguracion(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pop(); // cierra el drawer
    navigator.push(
      MaterialPageRoute(builder: (_) => const ConfiguracionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Lo de arriba se desliza si no entra (celular chico o acostado); lo de abajo queda fijo.
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 12),
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.home_outlined,
                      color: AppColors.muted,
                    ),
                    title: const Text(
                      'Inicio',
                      style: TextStyle(color: AppColors.text),
                    ),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PantallaPrincipal(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.list_alt, color: AppColors.muted),
                    title: const Text(
                      'Historial',
                      style: TextStyle(color: AppColors.text),
                    ),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PantallaPrincipal(pestana: 1),
                        ),
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
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PantallaPrincipal(pestana: 2),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bar_chart, color: AppColors.muted),
                    title: const Text(
                      'Informes',
                      style: TextStyle(color: AppColors.text),
                    ),
                    onTap: () {
                      Navigator.pop(context); // cierra el drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InformesScreen()),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const VoiceScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.line),
            ListTile(
              leading: const Icon(
                Icons.delete_forever_outlined,
                color: AppColors.danger,
              ),
              title: const Text(
                'Eliminar cuenta',
                style: TextStyle(color: AppColors.danger),
              ),
              onTap: () => _eliminarCuenta(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(color: AppColors.danger),
              ),
              onTap: () => _cerrarSesion(context),
            ),
            const Divider(color: AppColors.line),
            CuentaUsuario(alTocar: () => _abrirConfiguracion(context)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
