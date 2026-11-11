import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/features/home/presentation/screens/home_screen.dart';
import 'package:frontend/features/mercadopago/presentation/screens/mercadopago_screen.dart';
import 'package:frontend/features/movimientos/presentation/screens/alta_movimiento_screen.dart';
import 'package:frontend/features/movimientos/presentation/screens/movimientos_screen.dart';
import 'package:frontend/features/voice/voice_screen.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/network/estado_conexion.dart';
import 'package:frontend/features/presupuestos/data/datasources/presupuesto_api.dart';
import 'package:frontend/features/presupuestos/presentation/screens/presupuestos_screen.dart';
import 'package:frontend/features/presupuestos/presentation/viewmodels/presupuestos_view_model.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/features/configuracion/data/datasources/preferencias_api.dart';
import 'package:frontend/shared/utils/importe.dart';

// Una pestaña de la barra de abajo. Para sumar una (Metas), se agrega un elemento a _pestanas.
typedef _Pestana = ({String nombre, IconData icono, Widget Function() pantalla});

final List<_Pestana> _pestanas = [
  (nombre: 'Inicio', icono: Icons.home_outlined, pantalla: () => const HomeScreen()),
  (nombre: 'Movimientos', icono: Icons.format_list_bulleted, pantalla: () => const MovimientosScreen()),
  (
    nombre: 'Presupuestos',
    icono: Icons.pie_chart_outline,
    pantalla: () => ChangeNotifierProvider(
      create: (_) => PresupuestosViewModel(PresupuestoApi(ApiClient())),
      child: PresupuestosScreen(),
    ),
  ),
];

// Para pedirle a la pantalla principal que cambie de pestaña desde otra pantalla (el "Ver todos" del Inicio
// pide la 1, Movimientos). La pantalla principal la atiende y la vuelve a dejar en null.
final ValueNotifier<int?> pestanaPedida = ValueNotifier(null);

// Entre qué pestañas va el +: con tres queda después de la segunda; con Metas, también.
const _lugarDelMas = 2;

// La app con sesión: arriba la pestaña elegida y abajo la barra (Inicio, Movimientos, Presupuestos)
// con el botón + en el medio, que abre la hoja con las formas de cargar un movimiento.
class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key, this.pestana = 0});

  // 0 Inicio, 1 Movimientos, 2 Presupuestos (el orden de _pestanas).
  final int pestana;

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  late int _pestana = widget.pestana;
  // Sube al volver de cargar algo: arma la pestaña de nuevo, así trae lo último (T-5.5.3).
  int _vueltas = 0;

  @override
  void initState() {
    super.initState();
    monedaVista.addListener(_rearmar);
    reintentos.addListener(_rearmar);
    pestanaPedida.addListener(_irAPedida);
    _cargarMoneda();
  }

  @override
  void dispose() {
    monedaVista.removeListener(_rearmar);
    reintentos.removeListener(_rearmar);
    pestanaPedida.removeListener(_irAPedida);
    super.dispose();
  }

  // Cambió la moneda (al entrar, o desde Configuración) o se tocó "Reintentar" en el aviso de sin
  // conexión: se arma la pestaña de nuevo para que vuelva a pedir lo suyo.
  void _rearmar() => setState(() => _vueltas++);

  // Si no se puede pedir, queda la que estaba (al abrir la app, pesos).
  Future<void> _cargarMoneda() async {
    try {
      monedaVista.value = await PreferenciasApi(ApiClient()).moneda();
    } on ApiException catch (_) {}
  }

  void _irA(int pestana) => setState(() => _pestana = pestana);

  void _irAPedida() {
    final pedida = pestanaPedida.value;
    if (pedida == null) return;
    pestanaPedida.value = null;
    if (pedida >= 0 && pedida < _pestanas.length) _irA(pedida);
  }

  Future<void> _abrir(Widget pantalla) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
    if (mounted) setState(() => _vueltas++);
  }

  // La hoja del +: elige una forma de cargar y, ya cerrada, se abre esa pantalla.
  Future<void> _agregar() async {
    final pantalla = await showModalBottomSheet<Widget>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _HojaAgregar(),
    );
    if (pantalla != null && mounted) await _abrir(pantalla);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyedSubtree(key: ValueKey(_vueltas), child: _pestanas[_pestana].pantalla()),
      bottomNavigationBar: _Barra(pestana: _pestana, alElegir: _irA, alAgregar: _agregar),
    );
  }
}

// .nav de la maqueta: la barra de abajo con las pestañas y el + que sobresale en el medio.
class _Barra extends StatelessWidget {
  const _Barra({required this.pestana, required this.alElegir, required this.alAgregar});

  final int pestana;
  final ValueChanged<int> alElegir;
  final VoidCallback alAgregar;

  static const _alto = 80.0; // .nav height
  static const _sobresale = 6.0; // lo que el + pasa del borde de arriba de la barra
  static const _tamanoMas = 58.0;
  static const _anchoHueco = 72.0; // la columna del + en la grilla de la maqueta

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: _alto + _sobresale,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: _sobresale,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.tarjeta,
                  border: Border(top: BorderSide(color: c.linea)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Row(
                    children: [
                      for (final (i, p) in _pestanas.indexed) ...[
                        if (i == _lugarDelMas) const SizedBox(width: _anchoHueco),
                        Expanded(
                          child: _ItemBarra(
                            nombre: p.nombre,
                            icono: p.icono,
                            elegida: i == pestana,
                            alTocar: () => alElegir(i),
                          ),
                        ),
                      ],
                      if (_pestanas.length <= _lugarDelMas) const SizedBox(width: _anchoHueco),
                    ],
                  ),
                ),
              ),
            ),
            // El + va sobre el hueco que queda entre las pestañas, no en el medio de la pantalla.
            LayoutBuilder(
              builder: (context, medidas) {
                final porPestana = (medidas.maxWidth - 16 - _anchoHueco) / _pestanas.length;
                final centro = 8 + porPestana * _lugarDelMas.clamp(0, _pestanas.length) + _anchoHueco / 2;
                return Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: centro - _tamanoMas / 2,
                      child: Tooltip(
                        message: 'Cargar algo',
                        child: Material(
                          color: c.primario,
                          shape: const CircleBorder(),
                          child: DecoratedBox(
                            decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: c.sombraBoton),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: alAgregar,
                              child: SizedBox.square(
                                dimension: _tamanoMas,
                                child: Icon(Icons.add, color: c.sobrePrimario, size: 28),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// .ni: el ícono en una pastilla (menta si es la elegida) y el nombre abajo.
class _ItemBarra extends StatelessWidget {
  const _ItemBarra({required this.nombre, required this.icono, required this.elegida, required this.alTocar});

  final String nombre;
  final IconData icono;
  final bool elegida;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final color = elegida ? c.primario : c.suave;
    return Semantics(
      button: true,
      selected: elegida,
      excludeSemantics: true,
      label: nombre,
      child: InkWell(
        onTap: alTocar,
        borderRadius: BorderRadius.circular(Radios.control),
        child: SizedBox(
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 3,
            children: [
              AnimatedContainer(
                duration: Duraciones.toque,
                curve: Curvas.toque,
                width: 52,
                height: 30,
                decoration: BoxDecoration(
                  color: elegida ? c.menta : Colors.transparent,
                  borderRadius: BorderRadius.circular(Radios.pastilla),
                ),
                child: Icon(icono, size: 22, color: color),
              ),
              Text(
                nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: elegida ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// La hoja "agregar" (maqueta L697-707). Al elegir una forma, se cierra devolviendo la pantalla a abrir.
class _HojaAgregar extends StatelessWidget {
  const _HojaAgregar();

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    final cuenta = cuentaActiva.value;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Text('¿Qué querés cargar?', style: textos.titleLarge),
          if (cuenta != null)
            Text('Se guarda en ${cuenta['nombre']}.', style: textos.bodyMedium?.copyWith(color: c.suave)),
          _OpcionAgregar(
            icono: Icons.edit_outlined,
            colorSerie: 1,
            titulo: 'Gasto o ingreso',
            detalle: 'Lo cargás a mano, en segundos',
            alTocar: () => Navigator.pop<Widget>(context, const AltaMovimientoScreen()),
          ),
          _OpcionAgregar(
            icono: Icons.mic_none,
            colorSerie: 3,
            titulo: 'Por voz',
            detalle: 'Lo contás y la IA completa el resto',
            alTocar: () => Navigator.pop<Widget>(context, const VoiceScreen()),
          ),
          _OpcionAgregar(
            icono: Icons.account_balance_wallet_outlined,
            colorSerie: 2,
            titulo: 'Desde Mercado Pago',
            detalle: 'Traé tus pagos para revisarlos',
            alTocar: () => Navigator.pop<Widget>(context, const MercadoPagoScreen()),
          ),
          OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ],
      ),
    );
  }
}

// Una de las formas de cargar: ícono en círculo de color, nombre, detalle y flecha.
class _OpcionAgregar extends StatelessWidget {
  const _OpcionAgregar({
    required this.icono,
    required this.colorSerie,
    required this.titulo,
    required this.detalle,
    required this.alTocar,
  });

  final IconData icono;
  final int colorSerie;
  final String titulo;
  final String detalle;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    return Material(
      color: c.hundido,
      borderRadius: BorderRadius.circular(Radios.tarjeta),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            spacing: 14,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: c.serieFondo[colorSerie], shape: BoxShape.circle),
                child: Icon(icono, size: 24, color: c.serie[colorSerie]),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(titulo, style: textos.bodyMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
                    Text(detalle, style: textos.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: c.suave),
            ],
          ),
        ),
      ),
    );
  }
}
