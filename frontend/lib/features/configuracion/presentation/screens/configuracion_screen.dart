// features/configuracion/presentation/screens/configuracion_screen.dart
import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/widgets/barra_con_volver.dart';
import 'package:frontend/core/widgets/cuenta_usuario.dart';
import 'package:frontend/features/configuracion/data/datasources/preferencias_api.dart';
import 'package:frontend/features/configuracion/presentation/screens/cambiar_password_screen.dart';
import 'package:frontend/features/configuracion/presentation/viewmodels/configuracion_view_model.dart';
import 'package:frontend/features/cuentas_compartidas/presentation/widgets/selector_de_cuenta.dart';
import 'package:frontend/l10n/idioma.dart';
import 'package:frontend/shared/utils/importe.dart';

// Se abre tocando el usuario, abajo del menú lateral. Tiene la cuenta (personal o compartida, t-13.1.2),
// la moneda (US-8.2), el idioma (US-8.3) y el cambio de contraseña.
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

  Widget _titulo(String texto) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
    child: Text(
      texto,
      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barraConVolver(context, context.tr('Configuración')),
      body: ListenableBuilder(
        listenable: Listenable.merge([_vm, monedaVista]),
        builder: (context, _) {
          final elegida = monedaVista.value.moneda;
          // Eligió dólares o euros, pero el backend no consiguió la cotización: se ve en pesos.
          final sinCotizacion = elegida != 'PESO' && !convierte;
          final error = _vm.error;
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const CuentaUsuario(),
              const Divider(color: AppColors.line),
              const SelectorDeCuenta(),
              const Divider(color: AppColors.line),
              _titulo(context.tr('Moneda')),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  context.tr(
                    'Los montos se cargan siempre en pesos. Con otra moneda, se muestran convertidos con la cotización del día.',
                  ),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.5,
                  ),
                ),
              ),
              RadioGroup<String>(
                groupValue: elegida,
                onChanged: (moneda) {
                  if (moneda != null) _vm.elegirMoneda(moneda);
                },
                child: Column(
                  children: [
                    for (final (valor, nombre) in [
                      ('PESO', context.tr('Pesos')),
                      ('DOLAR', context.tr('Dólares')),
                      ('EURO', context.tr('Euros')),
                    ])
                      RadioListTile<String>(
                        value: valor,
                        title: Text(nombre),
                        enabled: !_vm.guardando,
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  error ??
                      (sinCotizacion
                          ? context.tr(
                              'No se pudo conseguir la cotización: por ahora se ve en pesos.',
                            )
                          : aclaracionCotizacion ?? ''),
                  style: TextStyle(
                    color: error != null ? AppColors.danger : AppColors.muted,
                    fontSize: 12.5,
                  ),
                ),
              ),
              const Divider(color: AppColors.line),
              _titulo(context.tr('Idioma')),
              // Los idiomas salen de los archivos de assets/idiomas/, cada uno con su nombre en su idioma
              RadioGroup<String>(
                groupValue: idioma.value.languageCode,
                onChanged: (codigo) => cambiarIdioma(codigo!),
                child: Column(
                  children: [
                    for (final MapEntry(key: codigo, value: nombre)
                        in idiomas.entries)
                      RadioListTile<String>(value: codigo, title: Text(nombre)),
                  ],
                ),
              ),
              const Divider(color: AppColors.line),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text(context.tr('Cambiar contraseña')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CambiarPasswordScreen(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
