import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/core/widgets/aviso_exito.dart';
import 'package:frontend/core/widgets/barra_con_volver.dart';
import 'package:frontend/core/widgets/chip_estado.dart';
import 'package:frontend/core/widgets/circulo_categoria.dart';
import 'package:frontend/core/widgets/confirmar.dart';
import 'package:frontend/core/widgets/esqueleto.dart';
import 'package:frontend/core/widgets/fila_movimiento.dart';
import 'package:frontend/core/widgets/monto.dart';
import 'package:frontend/core/widgets/tarjeta.dart';
import 'package:frontend/core/widgets/titulo_seccion.dart';
import 'package:frontend/features/mercadopago/data/datasources/mercadopago_api.dart';
import 'package:frontend/features/mercadopago/presentation/viewmodels/mercadopago_view_model.dart';
import 'package:frontend/features/mercadopago/presentation/screens/sincronizacion_resumen_screen.dart';
import 'package:frontend/features/movimientos/data/models/movimiento.dart';
import 'package:frontend/features/movimientos/presentation/screens/revision_movimiento_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _paddingPantalla = EdgeInsets.fromLTRB(20, 4, 20, 32);

class MercadoPagoScreen extends StatefulWidget {
  const MercadoPagoScreen({super.key});

  @override
  State<MercadoPagoScreen> createState() => _MercadoPagoScreenState();
}

class _MercadoPagoScreenState extends State<MercadoPagoScreen> with WidgetsBindingObserver {
  final _vm = MercadoPagoViewModel(MercadoPagoApi(ApiClient()));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _vm.cargar();
    if (_vm.estaConectado) {
      _vm.cargarPendientes();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _vm.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _vm.cargar();
      if (_vm.estaConectado) {
        _vm.cargarPendientes();
      }
    }
  }

  Future<void> _desvincular() async {
    final confirmado = await confirmar(
      context,
      titulo: '¿Desvincular Mercado Pago?',
      texto: 'No se borrarán los movimientos ya importados.',
      textoAccion: 'Desvincular',
      peligro: true,
    );

    if (!confirmado) return;

    final error = await _vm.desvincular();
    if (!mounted) return;

    if (error == null) {
      mostrarExito(context, 'Cuenta desvinculada exitosamente');
    } else {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error al desvincular'),
          content: Text(error),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _vincular() async {
    try {
      final url = await _vm.obtenerUrlAutorizacion();
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _WebViewMercadoPago(url: url),
        ),
      );

      if (!mounted) return;
      await _vm.cargar();
      if (_vm.estaConectado && mounted) {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al iniciar vinculación: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombreCuenta = cuentaActiva.value?['nombre'] as String? ?? 'Personal';
    return Scaffold(
      appBar: barraConVolver(context, 'Mercado Pago', subtitulo: nombreCuenta),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          if (_vm.cargando && _vm.estado == null) {
            return const Padding(
              padding: _paddingPantalla,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  Esqueleto(alto: 120),
                  EsqueletoLista(cantidad: 3),
                ],
              ),
            );
          }

          final error = _vm.error;
          if (error != null && _vm.estado == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 12,
                  children: [
                    Text(error, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                    FilledButton(
                      onPressed: _vm.cargar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final conectado = _vm.estaConectado;

          if (conectado && _vm.pendientes.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _vm.cargarPendientes();
            });
          }

          return ListView(
            padding: _paddingPantalla,
            children: [
              if (conectado) ...[
                _tarjetaEstadoConectado(),
                if (_vm.pendientes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  TituloSeccion('Para revisar · ${_vm.pendientes.length}'),
                  const SizedBox(height: 12),
                  TarjetaLista(
                    children: [
                      for (final m in _vm.pendientes) _filaPendiente(m),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                _seccionDesvincular(),
              ] else ...[
                _tarjetaEstadoDesconectado(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _tarjetaEstadoConectado() {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    return Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            spacing: 12,
            children: [
              CirculoCategoria(
                icono: Icons.credit_card,
                color: c.serie[2],
                fondo: c.serieFondo[2],
                tamano: 44,
                tamanoIcono: 22,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      'Cuenta vinculada',
                      style: textos.bodyMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    Text('Traemos tus pagos para que los revises', style: textos.bodySmall),
                  ],
                ),
              ),
              const ChipEstado('Activa', TonoChip.menta, chico: true),
            ],
          ),
          OutlinedButton.icon(
            onPressed: _vm.cargando ? null : _sincronizar,
            icon: _vm.cargando
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync, size: 18),
            label: Text(_vm.cargando ? 'Importando...' : 'Importar ahora'),
          ),
        ],
      ),
    );
  }

  Widget _seccionDesvincular() {
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        Align(
          child: TextButton(
            onPressed: _vm.cargando ? null : _desvincular,
            style: TextButton.styleFrom(
              foregroundColor: context.colores.coralTexto,
              disabledForegroundColor: context.colores.coralTexto.withValues(alpha: .45),
              minimumSize: const Size(44, 44),
            ),
            child: const Text('Desvincular la cuenta'),
          ),
        ),
        Text(
          'No se borran los movimientos que ya importaste.',
          textAlign: TextAlign.center,
          style: textos.bodySmall,
        ),
      ],
    );
  }

  Widget _tarjetaEstadoDesconectado() {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    return Tarjeta(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            child: CirculoCategoria(
              icono: Icons.link,
              color: c.serie[2],
              fondo: c.serieFondo[2],
              tamano: 52,
              tamanoIcono: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text('Conectá tu Mercado Pago', textAlign: TextAlign.center, style: textos.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Sincronizá tus ingresos y gastos automáticamente sin tener que cargarlos a mano.',
            textAlign: TextAlign.center,
            style: textos.bodySmall,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _vincular,
            child: const Text('Vincular cuenta'),
          ),
        ],
      ),
    );
  }

  // "Hoy", "Ayer" o dd/MM/yyyy, como el subtítulo de las filas de la maqueta.
  String _textoFecha(DateTime fecha) {
    final hoy = DateTime.now();
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    final diferencia = DateTime(hoy.year, hoy.month, hoy.day).difference(dia).inDays;
    if (diferencia == 0) return 'Hoy';
    if (diferencia == 1) return 'Ayer';
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year}';
  }

  Widget _filaPendiente(Movimiento m) {
    return FilaMovimiento(
      leading: CirculoCategoria.de(m.categoria),
      titulo: m.descripcion ?? 'Movimiento Mercado Pago',
      subtitulo: '${_textoFecha(m.fecha)} · ${m.categoria.nombre}',
      monto: Monto.texto(m.monto, ingreso: m.esIngreso),
      colorMonto: Monto.color(context, m.esIngreso),
      chip: const ChipEstado('Por revisar', TonoChip.ambar, chico: true),
      alTocar: () => _revisarMovimiento(m),
    );
  }

  Future<void> _sincronizar() async {
    final resumen = await _vm.sincronizar();
    if (!mounted) return;

    if (resumen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SincronizacionResumenScreen(resumen: resumen),
        ),
      );
    } else if (_vm.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_vm.error!)),
      );
    }
  }

  Future<void> _revisarMovimiento(Movimiento movimiento) async {
    final modificado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RevisionMovimientoScreen(movimiento: movimiento),
      ),
    );

    if (modificado == true && mounted) {
      _vm.cargarPendientes();
    }
  }
}

class _WebViewMercadoPago extends StatefulWidget {
  final String url;
  const _WebViewMercadoPago({required this.url});

  @override
  State<_WebViewMercadoPago> createState() => _WebViewMercadoPagoState();
}

class _WebViewMercadoPagoState extends State<_WebViewMercadoPago> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (url.startsWith('finza://mercadopago/callback')) {
              if (mounted) {
                Navigator.pop(context);
              }
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barraConVolver(context, 'Mercado Pago'),
      body: WebViewWidget(controller: _controller),
    );
  }
}