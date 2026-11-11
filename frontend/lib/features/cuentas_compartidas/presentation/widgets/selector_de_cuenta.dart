import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/core/session/portero.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/core/widgets/circulo_categoria.dart';
import 'package:frontend/core/widgets/fila_opcion.dart';
import 'package:frontend/core/widgets/tarjeta.dart';
import 'package:frontend/features/cuentas_compartidas/data/datasources/cuenta_compartida_api.dart';

// El selector de cuenta (t-13.1.2): en cuál está la app y para pasarse a otra, como los perfiles de
// Netflix. Al elegir, la guarda y arma la pantalla principal de cero con los datos de esa cuenta.
// Abajo, el botón para crear una cuenta compartida (t-11.1.4).
// Se abre como hoja con SelectorDeCuenta.mostrar (desde el chip de cuenta y el saludo del Inicio); con
// el constructor suelto es la versión en línea que usa Configuración.
class SelectorDeCuenta extends StatefulWidget {
  const SelectorDeCuenta({super.key, this.api, this.comoHoja = false});

  final CuentaCompartidaApi? api;
  final bool comoHoja;

  static Future<void> mostrar(BuildContext context, {CuentaCompartidaApi? api}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SelectorDeCuenta(api: api, comoHoja: true),
    );
  }

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
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _cuentas,
      builder: (context, respuesta) {
        // La personal siempre está; las compartidas, cuando llegan.
        final opciones = <Map<String, dynamic>?>[null, ...?respuesta.data];
        final filas = [
          for (final (i, cuenta) in opciones.indexed)
            _opcion(
              context,
              cuenta,
              indice: i,
              elegida: cuenta?['perfilId'] == actual?['perfilId'],
              enLinea: !widget.comoHoja,
            ),
        ];
        final error = respuesta.hasError
            ? Text(
                'No se pudieron cargar las cuentas compartidas.',
                style: textos.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: c.coralTexto),
              )
            : null;
        final crear = OutlinedButton.icon(
          onPressed: _crear,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Crear cuenta compartida'),
        );

        // La hoja (maqueta L687-695): título, bajada, las cuentas en una caja hundida y crear.
        if (widget.comoHoja) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Text('¿Qué cuenta querés ver?', style: textos.titleLarge),
                Text(
                  'En una cuenta compartida ves y cargás lo de esa cuenta.',
                  style: textos.bodyMedium?.copyWith(color: c.suave),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: c.hundido,
                    borderRadius: BorderRadius.circular(Radios.tarjeta),
                  ),
                  child: Column(
                    children: [
                      for (final (i, fila) in filas.indexed) ...[
                        if (i > 0) Divider(color: c.linea),
                        fila,
                      ],
                    ],
                  ),
                ),
                ?error,
                crear,
              ],
            ),
          );
        }

        // En línea (Configuración): las cuentas como filas de una lista, con el rol y la marca en la
        // elegida. El título de la sección y los miembros los pone Configuración.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            TarjetaLista(children: filas),
            ?error,
            crear,
          ],
        );
      },
    );
  }

  // Una cuenta (.fila): el ícono en su círculo, nombre y rol, y la marca en la que está la app.
  Widget _opcion(
    BuildContext context,
    Map<String, dynamic>? cuenta, {
    required int indice,
    required bool elegida,
    required bool enLinea,
  }) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    final nombre = cuenta == null ? 'Personal' : cuenta['nombre'] as String;
    final detalle = cuenta == null
        ? 'Solo vos'
        : cuenta['rol'] == 'ADMIN'
            ? 'Compartida · Administrador'
            : 'Compartida · Miembro';
    // La personal va en menta; las compartidas, cada una con un color de la serie.
    final colorSerie = const [3, 2, 4, 1][(indice - 1) % 4];
    final fondoIcono = cuenta == null ? c.menta : c.serieFondo[colorSerie];
    final colorIcono = cuenta == null ? c.primario : c.serie[colorSerie];
    if (enLinea) {
      return FilaOpcion(
        titulo: nombre,
        subtitulo: detalle,
        leading: CirculoCategoria(
          icono: cuenta == null ? Icons.person_outline : Icons.group_outlined,
          color: colorIcono,
          fondo: fondoIcono,
        ),
        trailing: elegida ? Icon(Icons.check, size: 22, color: c.primario, semanticLabel: 'Elegida') : null,
        alTocar: elegida ? null : () => _elegir(cuenta),
      );
    }
    return InkWell(
      onTap: elegida ? null : () => _elegir(cuenta),
      borderRadius: BorderRadius.circular(Radios.control),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          spacing: 12,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: fondoIcono, shape: BoxShape.circle),
              child: Icon(
                cuenta == null ? Icons.person_outline : Icons.group_outlined,
                size: 20,
                color: colorIcono,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textos.bodyMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  Text(detalle, style: textos.bodySmall),
                ],
              ),
            ),
            if (elegida) Icon(Icons.check, size: 22, color: c.primario, semanticLabel: 'Elegida'),
          ],
        ),
      ),
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
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    return PopScope(
      canPop: !_creando,
      child: AlertDialog(
        title: const Text('Nueva cuenta compartida'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre', style: textos.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
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
                errorText: _error,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _creando ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                Expanded(
                  child: FilledButton(
                    onPressed: puedeCrear ? _crear : null,
                    // Mientras crea sigue verde, con la ruedita: no está apagado, está esperando.
                    style: _creando
                        ? FilledButton.styleFrom(
                            disabledBackgroundColor: c.primario,
                            disabledForegroundColor: c.sobrePrimario,
                          )
                        : null,
                    child: _creando
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: c.sobrePrimario),
                              ),
                              const SizedBox(width: 8),
                              const Text('Creando…'),
                            ],
                          )
                        : const Text('Crear'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
