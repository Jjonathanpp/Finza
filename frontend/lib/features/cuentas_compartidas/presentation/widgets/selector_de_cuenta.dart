import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/core/session/portero.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/features/cuentas_compartidas/data/datasources/cuenta_compartida_api.dart';
import 'package:frontend/features/cuentas_compartidas/presentation/screens/miembros_screen.dart';

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
  late Future<List<Map<String, dynamic>>> _cuentas;
  final Set<int> _eliminando = {};
  bool _abandonando = false;

  @override
  void initState() {
    super.initState();
    _cuentas = _api.listarMias();
  }

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

  Future<void> _eliminar(Map<String, dynamic> cuenta) async {
    final id = cuenta['id'] as int;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Eliminar cuenta compartida'),
        content: Text(
          'Se eliminarán definitivamente ${cuenta['nombre']} y sus movimientos, '
          'presupuestos y categorías para todos sus integrantes. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.muted),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    setState(() => _eliminando.add(id));
    try {
      await _api.eliminarCuenta(id);
      if (!mounted) return;

      if (cuentaActiva.value?['id'] == id) {
        await _elegir(null);
        return;
      }

      setState(() {
        _eliminando.remove(id);
        _cuentas = _api.listarMias();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cuenta compartida eliminada')));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _eliminando.remove(id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.danger));
    } catch (_) {
      if (!mounted) return;
      setState(() => _eliminando.remove(id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo eliminar la cuenta compartida. Intentá de nuevo.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _abandonar(Map<String, dynamic> cuenta) async {
    final id = cuenta['id'] as int;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Abandonar cuenta compartida'),
        content: Text(
          'Vas a dejar de formar parte de ${cuenta['nombre']}. '
          'Ya no tendrás acceso a sus movimientos, presupuestos ni categorías. '
          'Si sos la última persona de la cuenta, esta se eliminará con sus datos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.muted),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(contexto).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: const Text('Sí, abandonar'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    setState(() => _abandonando = true);
    try {
      await _api.abandonarCuenta(id);
      if (!mounted) return;
      await _elegir(null);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _abandonando = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.danger));
    } catch (_) {
      if (!mounted) return;
      setState(() => _abandonando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abandonar la cuenta compartida. Intentá de nuevo.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
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
            // En una cuenta compartida: quiénes están y con qué rol (t-11.3.2). La pantalla
            // trabaja sobre la cuenta activa, así que solo se ofrece para esa.
            if (actual != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MiembrosScreen(nombreCuenta: actual['nombre'] as String, api: _api),
                    ),
                  ),
                  icon: const Icon(Icons.group_outlined),
                  label: Text(actual['rol'] == 'ADMIN' ? 'Miembros y roles' : 'Ver miembros'),
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
            if (actual != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _abandonando ? null : () => _abandonar(actual),
                    icon: _abandonando
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.exit_to_app),
                    label: Text(_abandonando ? 'Abandonando…' : 'Abandonar cuenta compartida'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
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
    final id = cuenta?['id'] as int?;
    final eliminando = id != null && _eliminando.contains(id);
    final puedeEliminar = cuenta != null && cuenta['rol'] == 'ADMIN';
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
      trailing: cuenta == null
          ? (elegida ? const Icon(Icons.check_circle, color: AppColors.accent) : null)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (elegida) const Icon(Icons.check_circle, color: AppColors.accent),
                if (puedeEliminar)
                  eliminando
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : IconButton(
                          tooltip: 'Eliminar cuenta compartida',
                          onPressed: () => _eliminar(cuenta),
                          icon: const Icon(Icons.delete_outline),
                          color: AppColors.danger,
                        ),
              ],
            ),
      onTap: elegida || eliminando ? null : () => _elegir(cuenta),
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
