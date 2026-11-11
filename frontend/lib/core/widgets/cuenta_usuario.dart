import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/storage/token_storage.dart';

// El nombre que se le dice a la persona: todavía no se guarda uno, así que sale del mail del login.
// Es el primer nombre: lo que está antes del primer punto, guion o guion bajo de la parte local, sin
// números y con mayúscula inicial ('jonathan1.perez750@gmail.com' → 'Jonathan'). Si no queda nada, vacío.
String nombreDeUsuario(String email) {
  final primero = email.split('@').first.split(RegExp(r'[._\-]')).first.replaceAll(RegExp(r'[0-9]'), '');
  return primero.isEmpty ? '' : primero[0].toUpperCase() + primero.substring(1);
}

// Arma lo suyo con el mail del login. Lo lee una sola vez; mientras llega, el mail viene vacío.
class UsuarioActual extends StatefulWidget {
  const UsuarioActual({super.key, required this.builder});

  final Widget Function(BuildContext context, String email) builder;

  @override
  State<UsuarioActual> createState() => _UsuarioActualState();
}

class _UsuarioActualState extends State<UsuarioActual> {
  late final _email = TokenStorage().obtenerEmail();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _email,
      builder: (context, respuesta) => widget.builder(context, respuesta.data ?? ''),
    );
  }
}

// .yo de la maqueta: el círculo menta con la inicial de la persona (todavía no hay foto de perfil).
// Con alTocar es un botón (el del encabezado, que abre el menú); sin él, solo se muestra.
class AvatarUsuario extends StatelessWidget {
  const AvatarUsuario({super.key, this.tamano = 44, this.alTocar, this.ayuda});

  final double tamano;
  final VoidCallback? alTocar;
  final String? ayuda;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return UsuarioActual(
      builder: (context, email) {
        final avatar = Material(
          color: c.menta,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: alTocar,
            child: SizedBox.square(
              dimension: tamano,
              child: Center(
                child: Text(
                  email.isEmpty ? '' : email[0].toUpperCase(),
                  style: TextStyle(
                    color: c.primario,
                    fontSize: tamano * .4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        );
        if (alTocar == null) return ExcludeSemantics(child: avatar);
        return Semantics(button: true, label: ayuda, excludeSemantics: true, child: avatar);
      },
    );
  }
}

// El usuario: el avatar y el mail del login. En Configuración solo se muestra; con alTocar es un botón.
class CuentaUsuario extends StatelessWidget {
  const CuentaUsuario({super.key, this.alTocar});

  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return UsuarioActual(
      builder: (context, email) => ListTile(
        leading: const AvatarUsuario(),
        title: Text(email, overflow: TextOverflow.ellipsis),
        trailing: alTocar == null ? null : Icon(Icons.settings_outlined, color: c.suave),
        onTap: alTocar,
      ),
    );
  }
}
