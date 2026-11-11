import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/estado_conexion.dart';
import 'package:frontend/core/widgets/circulo_categoria.dart';

// El aviso "No pudimos conectarnos" (maqueta L643-646, role=alert). Aparece arriba de todo mientras
// sinConexion sea true (lo prende ApiClient cuando un pedido falla por falta de conexión y lo apaga con
// cualquier respuesta). "Reintentar" lo apaga y sube reintentos, que la pantalla principal escucha para
// volver a pedir sus datos. Se anuncia solo en los lectores de pantalla (liveRegion). Va en el builder del
// MaterialApp, sobre el Navigator.
class AvisoSinConexion extends StatefulWidget {
  const AvisoSinConexion({super.key});

  @override
  State<AvisoSinConexion> createState() => _AvisoSinConexionState();
}

class _AvisoSinConexionState extends State<AvisoSinConexion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador = AnimationController(
    vsync: this,
    duration: Duraciones.aparece,
    value: sinConexion.value ? 1 : 0,
  );
  late final Animation<double> _curva = CurvedAnimation(
    parent: _controlador,
    curve: Curvas.salida,
  );

  @override
  void initState() {
    super.initState();
    sinConexion.addListener(_cambio);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controlador.duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : Duraciones.aparece;
  }

  @override
  void dispose() {
    sinConexion.removeListener(_cambio);
    _controlador.dispose();
    super.dispose();
  }

  void _cambio() =>
      sinConexion.value ? _controlador.forward() : _controlador.reverse();

  void _reintentar() {
    sinConexion.value = false;
    reintentos.value++;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curva,
      builder: (context, hijo) {
        if (_controlador.isDismissed) return const SizedBox.shrink();
        return Opacity(
          opacity: _curva.value,
          child: Transform.translate(
            offset: Offset(0, -8 * (1 - _curva.value)),
            child: hijo,
          ),
        );
      },
      child: _Aviso(alReintentar: _reintentar),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.alReintentar});

  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    return SafeArea(
      bottom: false,
      // En la maqueta va a 66 px del borde de arriba, debajo del encabezado de la pantalla.
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 66, 12, 0),
        child: Material(
          color: c.tarjeta,
          borderRadius: BorderRadius.circular(Radios.aviso),
          // En claro la sombra de la tarjeta; en oscuro, su borde fino.
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radios.aviso),
              boxShadow: c.sombra,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
              child: Row(
                spacing: 12,
                children: [
                  CirculoCategoria(
                    icono: Icons.wifi_off_rounded,
                    color: c.coralTexto,
                    fondo: c.coralFondo,
                  ),
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      container: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2,
                        children: [
                          Text(
                            'No pudimos conectarnos',
                            style: textos.titleSmall?.copyWith(fontSize: 15),
                          ),
                          Text(
                            'Revisá tu conexión a internet y probá de nuevo.',
                            style: textos.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: alReintentar,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
