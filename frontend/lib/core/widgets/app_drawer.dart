import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import '../storage/token_storage.dart';
import '../../features/login/screens/login_screen.dart';
import 'package:frontend/core/actualizacion/aviso_de_version.dart';
import 'package:frontend/core/widgets/cuenta_usuario.dart';
import 'package:frontend/core/widgets/encabezado_pestana.dart';
import 'package:frontend/features/categorias/presentation/screens/categorias_screen.dart';
import 'package:frontend/features/configuracion/presentation/screens/configuracion_screen.dart';
import 'package:frontend/features/cuentas_compartidas/presentation/screens/miembros_screen.dart';
import 'package:frontend/features/informes/presentation/screens/informes_screen.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/features/lista-invitaciones/presentation/screens/lista_invitaciones_screen.dart';
import 'package:frontend/features/mercadopago/presentation/screens/mercadopago_screen.dart';

// Abre el menú J por encima de toda la pantalla (la barra de abajo incluida): entra desde la
// izquierda con el velo detrás, como .menu de la maqueta. Es el que usa el avatar del encabezado.
Future<void> abrirMenu(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar el menú',
    barrierColor: context.colores.velo,
    transitionDuration: Duraciones.hoja,
    pageBuilder: (_, _, _) => const Align(alignment: Alignment.centerLeft, child: AppDrawer()),
    transitionBuilder: (_, animacion, _, hijo) {
      final curva = CurvedAnimation(parent: animacion, curve: Curvas.salida);
      return FadeTransition(
        opacity: curva,
        child: SlideTransition(
          position: Tween(begin: const Offset(-24 / 308, 0), end: Offset.zero).animate(curva),
          child: hijo,
        ),
      );
    },
  );
}

// El menú J (maqueta L669-685). Se abre con abrirMenu; las pantallas de pestaña que todavía no usan
// el encabezado nuevo lo siguen poniendo como `drawer:` de su Scaffold.
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

  // Cierra el menú y abre la pantalla.
  void _ir(BuildContext context, Widget pantalla) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(MaterialPageRoute(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    return Drawer(
      width: 308,
      backgroundColor: c.tarjeta,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(Radios.menu)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            children: [
              // Lo de arriba se desliza si no entra (celular chico o acostado); lo de abajo queda fijo.
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    UsuarioActual(
                      builder: (context, email) {
                        final nombre = nombreDeUsuario(email);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            spacing: 12,
                            children: [
                              const AvatarUsuario(tamano: 48),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 2,
                                  children: [
                                    // Si del mail no sale un nombre, va el mail solo.
                                    Text(
                                      nombre.isEmpty ? email : nombre,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textos.bodyMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w800),
                                    ),
                                    if (nombre.isNotEmpty)
                                      Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: textos.bodySmall),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(padding: EdgeInsets.only(bottom: 8), child: ChipCuenta()),
                    ),
                    _Opcion(
                      icono: Icons.bar_chart,
                      texto: 'Informes',
                      alTocar: () => _ir(context, const InformesScreen()),
                    ),
                    _Opcion(
                      icono: Icons.category_outlined,
                      texto: 'Categorías',
                      alTocar: () => _ir(context, const CategoriasScreen()),
                    ),
                    _Opcion(
                      icono: Icons.account_balance_wallet_outlined,
                      texto: 'Mercado Pago',
                      alTocar: () => _ir(context, const MercadoPagoScreen()),
                    ),
                    // Las opciones de una cuenta compartida se ven solo estando en una; las de
                    // administrador, solo siendo admin de esa.
                    ValueListenableBuilder<Map<String, dynamic>?>(
                      valueListenable: cuentaActiva,
                      builder: (context, cuenta, _) {
                        if (cuenta == null) return const SizedBox.shrink();
                        final admin = cuenta['rol'] == 'ADMIN';
                        return Column(
                          children: [
                            _Opcion(
                              icono: Icons.group_outlined,
                              texto: admin ? 'Miembros y roles' : 'Ver miembros',
                              alTocar: () => _ir(
                                context,
                                MiembrosScreen(nombreCuenta: cuenta['nombre'] as String),
                              ),
                            ),
                            if (admin)
                              _Opcion(
                                icono: Icons.mail_outline,
                                texto: 'Invitaciones',
                                alTocar: () => _ir(
                                  context,
                                  ListaInvitacionesScreen(cuentaCompartidaId: cuenta['id'] as int),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    _Opcion(
                      icono: Icons.settings_outlined,
                      texto: 'Configuración',
                      alTocar: () => _ir(context, const ConfiguracionScreen()),
                    ),
                  ],
                ),
              ),
              _Opcion(
                icono: Icons.logout,
                texto: 'Cerrar sesión',
                conLinea: true,
                alTocar: () => _cerrarSesion(context),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    versionInstalada.isEmpty ? 'Finza' : 'Finza $versionInstalada',
                    style: textos.bodySmall?.copyWith(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// .op de la maqueta: el ícono en su círculo gris (.cat c0), el nombre y, abajo, una línea si hace falta.
class _Opcion extends StatelessWidget {
  const _Opcion({required this.icono, required this.texto, required this.alTocar, this.conLinea = false});

  final IconData icono;
  final String texto;
  final VoidCallback alTocar;
  final bool conLinea;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: conLinea ? Border(top: BorderSide(color: c.linea)) : null,
      ),
      child: InkWell(
        onTap: alTocar,
        borderRadius: BorderRadius.circular(Radios.control),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              spacing: 14,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: c.serieFondo[0], shape: BoxShape.circle),
                  child: Icon(icono, size: 20, color: c.serie[0]),
                ),
                Expanded(
                  child: Text(
                    texto,
                    style: textos.bodyMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
