import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/core/session/portero.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/features/cuentas_compartidas/data/datasources/cuenta_compartida_api.dart';

// Configuración → "Cuenta" (t-13.1.2): en cuál está la app y para pasarse a otra, como los perfiles
// de Netflix. Al elegir, la guarda y arma la pantalla principal de cero con los datos de esa cuenta.
class SelectorDeCuenta extends StatefulWidget {
  const SelectorDeCuenta({super.key, this.api});

  final CuentaCompartidaApi? api;

  @override
  State<SelectorDeCuenta> createState() => _SelectorDeCuentaState();
}

class _SelectorDeCuentaState extends State<SelectorDeCuenta> {
  late final _cuentas = (widget.api ?? CuentaCompartidaApi(ApiClient())).listarMias();

  Future<void> _elegir(Map<String, dynamic>? cuenta) async {
    await TokenStorage().guardarCuentaActiva(cuenta);
    irAlInicio();
  }

  @override
  Widget build(BuildContext context) {
    final actual = cuentaActiva.value;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _cuentas,
      builder: (context, respuesta) {
        // La personal siempre está; las compartidas, cuando llegan.
        final opciones = <Map<String, dynamic>?>[null, ...?respuesta.data];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 12, 18, 4),
              child: Text('Cuenta', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                'Estás en ${actual == null ? 'tu cuenta personal' : actual['nombre']}. '
                'En una cuenta compartida se ve y se carga lo de esa cuenta.',
                style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
              ),
            ),
            for (final cuenta in opciones)
              _opcion(cuenta, elegida: cuenta?['perfilId'] == actual?['perfilId']),
            if (respuesta.hasError)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  'No se pudieron cargar las cuentas compartidas.',
                  style: TextStyle(color: AppColors.danger, fontSize: 12.5),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _opcion(Map<String, dynamic>? cuenta, {required bool elegida}) {
    final nombre = cuenta == null ? 'Personal' : cuenta['nombre'] as String;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: elegida ? AppColors.accent : AppColors.surface2,
        child: Text(
          nombre.isEmpty ? '' : nombre[0].toUpperCase(),
          style: TextStyle(color: elegida ? Colors.white : AppColors.text, fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(nombre),
      subtitle: Text(
        cuenta == null
            ? 'Solo vos'
            : cuenta['rol'] == 'ADMIN'
                ? 'Compartida · Administrador'
                : 'Compartida · Miembro',
      ),
      trailing: elegida ? const Icon(Icons.check_circle, color: AppColors.accent) : null,
      onTap: elegida ? null : () => _elegir(cuenta),
    );
  }
}
