import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/storage/token_storage.dart';

// El usuario: un círculo con la inicial (todavía no hay foto de perfil) y el mail del login.
// Abajo del menú lateral abre Configuración; arriba de Configuración, solo se muestra.
class CuentaUsuario extends StatelessWidget {
  const CuentaUsuario({super.key, this.alTocar});

  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: TokenStorage().obtenerEmail(),
      builder: (context, respuesta) {
        final email = respuesta.data ?? '';
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.surface2,
            child: Text(
              email.isEmpty ? '' : email[0].toUpperCase(),
              style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
            ),
          ),
          title: Text(email, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.text)),
          trailing: alTocar == null ? null : const Icon(Icons.settings_outlined, color: AppColors.muted),
          onTap: alTocar,
        );
      },
    );
  }
}
