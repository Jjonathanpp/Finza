// features/configuracion/presentation/screens/configuracion_screen.dart
import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/config/theme/apariencia.dart';
import 'package:frontend/core/actualizacion/aviso_de_version.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/core/widgets/barra_con_volver.dart';
import 'package:frontend/core/widgets/campo.dart';
import 'package:frontend/core/widgets/circulo_categoria.dart';
import 'package:frontend/core/widgets/cuenta_usuario.dart';
import 'package:frontend/core/widgets/eliminar_cuenta_dialog.dart';
import 'package:frontend/core/widgets/fila_opcion.dart';
import 'package:frontend/core/widgets/segmento.dart';
import 'package:frontend/core/widgets/tarjeta.dart';
import 'package:frontend/core/widgets/titulo_seccion.dart';
import 'package:frontend/features/configuracion/data/datasources/preferencias_api.dart';
import 'package:frontend/features/configuracion/presentation/screens/cambiar_password_screen.dart';
import 'package:frontend/features/configuracion/presentation/viewmodels/configuracion_view_model.dart';
import 'package:frontend/features/cuentas_compartidas/presentation/screens/miembros_screen.dart';
import 'package:frontend/features/cuentas_compartidas/presentation/widgets/selector_de_cuenta.dart';
import 'package:frontend/features/lista-invitaciones/presentation/screens/lista_invitaciones_screen.dart';
import 'package:frontend/features/login/screens/login_screen.dart';
import 'package:frontend/features/mercadopago/presentation/screens/mercadopago_screen.dart';
import 'package:frontend/shared/utils/importe.dart';

// Se abre desde el menú J. Tiene la cuenta (personal o compartida, t-13.1.2), la moneda (US-8.2),
// la apariencia, Mercado Pago, la seguridad (contraseña y borrar la cuenta) y cerrar sesión.
class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key, this.api});

  final PreferenciasApi? api;

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  late final _vm = ConfiguracionViewModel(
    widget.api ?? PreferenciasApi(ApiClient()),
  );

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _cerrarSesion() async {
    await TokenStorage().limpiar();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _ir(Widget pantalla) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    return Scaffold(
      appBar: barraConVolver(context, 'Configuración'),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          _vm,
          monedaVista,
          apariencia,
          cuentaActiva,
        ]),
        builder: (context, _) {
          final elegida = monedaVista.value.moneda;
          // Eligió dólares o euros, pero el backend no consiguió la cotización: se ve en pesos.
          final sinCotizacion = elegida != 'PESO' && !convierte;
          final nota = sinCotizacion
              ? 'No se pudo conseguir la cotización: por ahora se ve en pesos.'
              : aclaracionCotizacion;
          const explicacion =
              'Los montos se cargan en pesos. En otra moneda se ven con la cotización del día.';
          final cuenta = cuentaActiva.value;
          final admin = cuenta?['rol'] == 'ADMIN';
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                // El perfil (.yo de 56).
                Tarjeta(
                  padding: const EdgeInsets.all(16),
                  child: UsuarioActual(
                    builder: (context, email) {
                      final nombre = nombreDeUsuario(email);
                      return Row(
                        spacing: 14,
                        children: [
                          const AvatarUsuario(tamano: 56),
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
                                  style: textos.bodyMedium?.copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (nombre.isNotEmpty)
                                  Text(
                                    email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textos.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const TituloSeccion('Cuenta que estás usando'),
                const SelectorDeCuenta(),
                if (cuenta != null) ...[
                  TituloSeccion(cuenta['nombre'] as String),
                  TarjetaLista(
                    children: [
                      FilaOpcion(
                        titulo: admin ? 'Miembros y roles' : 'Ver miembros',
                        leading: CirculoCategoria(
                          icono: Icons.group_outlined,
                          color: c.serie[3],
                          fondo: c.serieFondo[3],
                        ),
                        flecha: true,
                        alTocar: () => _ir(
                          MiembrosScreen(nombreCuenta: cuenta['nombre'] as String),
                        ),
                      ),
                      if (admin)
                        FilaOpcion(
                          titulo: 'Invitaciones',
                          leading: CirculoCategoria(
                            icono: Icons.mail_outline,
                            color: c.serie[2],
                            fondo: c.serieFondo[2],
                          ),
                          flecha: true,
                          alTocar: () => _ir(
                            ListaInvitacionesScreen(
                              cuentaCompartidaId: cuenta['id'] as int,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const TituloSeccion('Preferencias'),
                Tarjeta(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Campo(
                        etiqueta: 'Moneda',
                        error: _vm.error,
                        ayuda: nota == null ? explicacion : '$explicacion $nota',
                        child: Segmento<String>(
                          opciones: const [
                            ('PESO', 'Pesos'),
                            ('DOLAR', 'Dólares'),
                            ('EURO', 'Euros'),
                          ],
                          valor: elegida,
                          deshabilitadas: _vm.guardando
                              ? const {'PESO', 'DOLAR', 'EURO'}
                              : const {},
                          alCambiar: _vm.elegirMoneda,
                        ),
                      ),
                      Campo(
                        etiqueta: 'Apariencia',
                        child: Segmento<ThemeMode>(
                          opciones: const [
                            (ThemeMode.light, 'Claro'),
                            (ThemeMode.dark, 'Oscuro'),
                          ],
                          valor: apariencia.value,
                          alCambiar: guardarApariencia,
                        ),
                      ),
                    ],
                  ),
                ),
                const TituloSeccion('Conexiones'),
                TarjetaLista(
                  children: [
                    FilaOpcion(
                      titulo: 'Mercado Pago',
                      leading: CirculoCategoria(
                        icono: Icons.account_balance_wallet_outlined,
                        color: c.serie[2],
                        fondo: c.serieFondo[2],
                      ),
                      flecha: true,
                      alTocar: () => _ir(const MercadoPagoScreen()),
                    ),
                  ],
                ),
                const TituloSeccion('Seguridad'),
                TarjetaLista(
                  children: [
                    FilaOpcion(
                      titulo: 'Cambiar contraseña',
                      leading: CirculoCategoria(
                        icono: Icons.lock_outline,
                        color: c.serie[0],
                        fondo: c.serieFondo[0],
                      ),
                      flecha: true,
                      alTocar: () => _ir(const CambiarPasswordScreen()),
                    ),
                    FilaOpcion(
                      titulo: 'Eliminar cuenta',
                      subtitulo: 'Borra todos tus datos',
                      colorTitulo: c.coralTexto,
                      leading: CirculoCategoria(
                        icono: Icons.delete_outline_rounded,
                        color: c.coralTexto,
                        fondo: c.coralFondo,
                      ),
                      alTocar: () => EliminarCuentaDialog.mostrar(context),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: _cerrarSesion,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Cerrar sesión'),
                ),
                Center(
                  child: Text(
                    versionInstalada.isEmpty
                        ? 'Finza'
                        : 'Finza $versionInstalada',
                    style: textos.bodySmall,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
