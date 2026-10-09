import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/widgets/aviso_exito.dart';
import 'package:frontend/core/widgets/barra_con_volver.dart';
import 'package:frontend/features/mercadopago/data/datasources/mercadopago_api.dart';
import 'package:frontend/features/mercadopago/presentation/viewmodels/mercadopago_view_model.dart';
import 'package:frontend/config/constants/sesion_temporal.dart';
import 'package:frontend/config/constants/api_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class MercadoPagoScreen extends StatefulWidget {
  const MercadoPagoScreen({super.key});

  @override
  State<MercadoPagoScreen> createState() => _MercadoPagoScreenState();
}

class _MercadoPagoScreenState extends State<MercadoPagoScreen> with WidgetsBindingObserver {
  final _vm = MercadoPagoViewModel(MercadoPagoApi(ApiClient()));
  Timer? _timerVerificacion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _vm.cargar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timerVerificacion?.cancel();
    _vm.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _vm.cargar();
    }
  }

  void _iniciarVerificacionAutomatica() {
    _timerVerificacion?.cancel();
    int intentos = 0;
    _timerVerificacion = Timer.periodic(const Duration(seconds: 2), (timer) async {
      intentos++;
      await _vm.cargar();
      if (_vm.estaConectado || intentos >= 30) {
        timer.cancel();
      }
    });
  }

  Future<void> _desvincular() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Desvincular Mercado Pago?'),
        content: const Text('No se borrarán los movimientos ya importados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Desvincular'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

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
    final base = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    final uri = Uri.parse('$base/api/mercadopago/autorizar?usuarioId=$cuentaIdTemporal');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    _iniciarVerificacionAutomatica();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barraConVolver(context, 'Mercado Pago'),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          if (_vm.cargando && _vm.estado == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final error = _vm.error;
          if (error != null && _vm.estado == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _vm.cargar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final conectado = _vm.estaConectado;

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              if (conectado) ...[
                _tarjetaEstadoConectado(),
                const SizedBox(height: 24),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF009EE3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.credit_card, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cuenta vinculada',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 2),
                Text(
                  'Sincronización activa con Finza',
                  style: TextStyle(fontSize: 12.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF00A650).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'ACTIVA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF00A650),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _seccionDesvincular() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Desvincular la cuenta',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 3),
                Text(
                  'No borra los movimientos ya importados',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: _vm.cargando ? null : _desvincular,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.line),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Desvincular', style: TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaEstadoDesconectado() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF009EE3).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.link, color: Color(0xFF009EE3), size: 30),
          ),
          const SizedBox(height: 14),
          const Text(
            'Conectá tu Mercado Pago',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sincronizá tus ingresos y gastos automáticamente sin tener que cargarlos a mano.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _vincular,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009EE3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Vincular cuenta', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}