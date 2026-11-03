import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/core/session/portero.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/features/cuentas_compartidas/data/datasources/cuenta_compartida_api.dart';

// Configuración → "Cuenta" (t-13.1.2): en cuál está la app y para pasarse a otra, como los perfiles
// de Netflix. Al elegir, la guarda y arma la pantalla principal de cero con los datos de esa cuenta.
// Abajo, el botón para crear una cuenta compartida (t-11.1.4).
class SelectorDeCuenta extends StatefulWidget {
  const SelectorDeCuenta({super.key, this.api});

  final CuentaCompartidaApi? api;

  @override
  State<SelectorDeCuenta> createState() => _SelectorDeCuentaState();
}

class _SelectorDeCuentaState extends State<SelectorDeCuenta> {
  late final _api = widget.api ?? CuentaCompartidaApi(ApiClient());
  late final _cuentas = _api.listarMias();

  Future<void> _elegir(Map<String, dynamic>? cuenta) async {
    await TokenStorage().guardarCuentaActiva(cuenta);
    irAlInicio();
  }

  // Al crearla, la app pasa directo a la cuenta nueva. El backend no devuelve el rol, pero el que la
  // crea siempre es el administrador.
  Future<void> _crear() async {
    final creada = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _CuadroNuevaCuenta(api: _api),
    );
    if (creada != null) await _elegir({...creada, 'rol': 'ADMIN'});
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
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: OutlinedButton.icon(
                onPressed: _crear,
                icon: const Icon(Icons.add),
                label: const Text('Crear cuenta compartida'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: AppColors.text,
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.line),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
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

// El cuadro para crear la cuenta compartida: devuelve la cuenta creada, o null si se cancela.
// Mientras espera al backend no se puede cerrar ni crear dos veces; si falla, muestra el mensaje y
// queda abierto con el nombre escrito.
class _CuadroNuevaCuenta extends StatefulWidget {
  const _CuadroNuevaCuenta({required this.api});

  final CuentaCompartidaApi api;

  @override
  State<_CuadroNuevaCuenta> createState() => _CuadroNuevaCuentaState();
}

class _CuadroNuevaCuentaState extends State<_CuadroNuevaCuenta> {
  final _nombre = TextEditingController();
  bool _creando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    setState(() {
      _creando = true;
      _error = null;
    });
    try {
      final creada = await widget.api.crear(_nombre.text.trim());
      if (mounted) Navigator.of(context).pop(creada);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _creando = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final puedeCrear = _nombre.text.trim().isNotEmpty && !_creando;
    const borde = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: AppColors.danger),
    );
    return PopScope(
      canPop: !_creando,
      child: AlertDialog(
        title: const Text('Nueva cuenta compartida'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nombre', style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
            const SizedBox(height: 6),
            TextField(
              controller: _nombre,
              autofocus: true,
              readOnly: _creando,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) {
                if (puedeCrear) _crear();
              },
              decoration: InputDecoration(
                hintText: 'Por ejemplo, Casa',
                counterText: '',
                helperText: 'Vas a ser el administrador.',
                helperStyle: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                errorText: _error,
                errorStyle: const TextStyle(color: AppColors.danger, fontSize: 12.5),
                errorBorder: borde,
                focusedErrorBorder: borde,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _creando ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: AppColors.muted),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: puedeCrear ? _crear : null,
            // Mientras crea sigue verde, con la ruedita: no está apagado, está esperando.
            style: _creando
                ? FilledButton.styleFrom(
                    disabledBackgroundColor: AppColors.accent,
                    disabledForegroundColor: AppColors.accentInk,
                  )
                : null,
            child: _creando
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentInk),
                      ),
                      SizedBox(width: 8),
                      Text('Creando…'),
                    ],
                  )
                : const Text('Crear'),
          ),
        ],
      ),
    );
  }
}
