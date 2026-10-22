import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/features/categorias/presentation/screens/categorias_screen.dart';
import 'package:frontend/features/home/presentation/screens/home_screen.dart';
import 'package:frontend/features/mercadopago/presentation/screens/mercadopago_screen.dart';
import 'package:frontend/features/movimientos/presentation/screens/alta_movimiento_screen.dart';
import 'package:frontend/features/movimientos/presentation/screens/movimientos_screen.dart';
import 'package:frontend/features/voice/voice_screen.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/presupuestos/data/datasources/presupuesto_api.dart';
import 'package:frontend/features/presupuestos/presentation/screens/presupuestos_screen.dart';
import 'package:frontend/features/presupuestos/presentation/viewmodels/presupuestos_view_model.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/features/configuracion/data/datasources/preferencias_api.dart';
import 'package:frontend/shared/utils/importe.dart';

const _sombra = [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4))];

// La app con sesión: arriba la pestaña elegida y abajo la barra (Inicio, Historial, Categorías)
// con el botón + aparte, que despliega hacia arriba las formas de cargar un movimiento.
class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key, this.pestana = 0});

  // 0 Inicio, 1 Historial, 2 Categorías. El menú lateral la abre en la que toca.
  final int pestana;

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  late int _pestana = widget.pestana;
  bool _abierto = false;
  // Sube al volver de cargar algo: arma la pestaña de nuevo, así trae lo último (T-5.5.3).
  int _vueltas = 0;

  @override
  void initState() {
    super.initState();
    monedaVista.addListener(_rearmar);
    _cargarMoneda();
  }

  @override
  void dispose() {
    monedaVista.removeListener(_rearmar);
    super.dispose();
  }

  // Cambió la moneda (al entrar, o desde Configuración): se arma la pestaña de nuevo para verla.
  void _rearmar() => setState(() => _vueltas++);

  // Si no se puede pedir, queda la que estaba (al abrir la app, pesos).
  Future<void> _cargarMoneda() async {
    try {
      monedaVista.value = await PreferenciasApi(ApiClient()).moneda();
    } on ApiException catch (_) {}
  }

  void _irA(int pestana) => setState(() {
    _pestana = pestana;
    _abierto = false;
  });

  Future<void> _abrir(Widget pantalla) async {
    setState(() => _abierto = false);
    await Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
    if (mounted) setState(() => _vueltas++);
  }

  @override
  Widget build(BuildContext context) {
    // De arriba para abajo: la más usada queda pegada al +.
    final opciones = [
      ('Mercado Pago', Icons.account_balance_wallet_outlined, const MercadoPagoScreen()),
      ('Registrar por voz', Icons.mic_none, const VoiceScreen()),
      ('Movimiento manual', Icons.edit_outlined, const AltaMovimientoScreen()),
    ];

    return PopScope(
      // Con el + abierto, "atrás" lo cierra en vez de salir de la app.
      canPop: !_abierto,
      onPopInvokedWithResult: (seFue, _) {
        if (!seFue) setState(() => _abierto = false);
      },
      child: Scaffold(
        body: Stack(
          children: [
            KeyedSubtree(
              key: ValueKey(_vueltas),
              child: [
                const HomeScreen(),
                const MovimientosScreen(),
                const CategoriasScreen(),
                ChangeNotifierProvider(
                  create: (_) => PresupuestosViewModel(PresupuestoApi(ApiClient())),
                  child: PresupuestosScreen(),
                ),
              ][_pestana],
            ),
            // El fondo se oscurece un poco y, tocándolo, se cierra.
            if (_abierto)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _abierto = false),
                  child: const ColoredBox(color: Colors.black26),
                ),
              ),
            Positioned(
              right: 26,
              bottom: 12,
              child: IgnorePointer(
                ignoring: !_abierto,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final (i, (texto, icono, pantalla)) in opciones.indexed)
                      AnimatedSlide(
                        offset: _abierto ? Offset.zero : const Offset(0, 0.5),
                        duration: Duration(milliseconds: 150 + (opciones.length - i) * 40),
                        curve: Curves.easeOutCubic,
                        child: AnimatedOpacity(
                          opacity: _abierto ? 1 : 0,
                          duration: Duration(milliseconds: 120 + (opciones.length - i) * 40),
                          child: _Opcion(texto: texto, icono: icono, alTocar: () => _abrir(pantalla)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 64,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: _sombra,
                    ),
                    child: Row(
                      children: [
                        _Pestana(Icons.home_rounded, 'Inicio', _pestana == 0, () => _irA(0)),
                        _Pestana(Icons.history, 'Historial', _pestana == 1, () => _irA(1)),
                        _Pestana(Icons.category_outlined, 'Categorías', _pestana == 2, () => _irA(2)),
                        _Pestana(Icons.pie_chart_outline, 'Presupuestos', _pestana == 3, () => _irA(3)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Tooltip(
                  message: _abierto ? 'Cerrar' : 'Agregar',
                  child: Material(
                    color: AppColors.text,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => _abierto = !_abierto),
                      child: SizedBox.square(
                        dimension: 64,
                        child: AnimatedRotation(
                          turns: _abierto ? 0.125 : 0, // el + gira y queda como ×
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.add, color: AppColors.accent, size: 32),
                        ),
                      ),
                    ),
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

// Un ícono de la barra. La elegida lleva el fondo gris, como en la maqueta.
class _Pestana extends StatelessWidget {
  const _Pestana(this.icono, this.ayuda, this.elegida, this.alTocar);

  final IconData icono;
  final String ayuda;
  final bool elegida;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: ayuda,
        child: Material(
          color: elegida ? AppColors.surface3 : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: alTocar,
            child: Center(child: Icon(icono, color: elegida ? AppColors.text : AppColors.faint, size: 26)),
          ),
        ),
      ),
    );
  }
}

// Una de las opciones del +: el nombre en una pastilla y el ícono en un círculo como el del +.
class _Opcion extends StatelessWidget {
  const _Opcion({required this.texto, required this.icono, required this.alTocar});

  final String texto;
  final IconData icono;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: alTocar,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: _sombra,
              ),
              child: Text(texto, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 10),
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: AppColors.text, shape: BoxShape.circle),
              child: Icon(icono, color: AppColors.accent, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
