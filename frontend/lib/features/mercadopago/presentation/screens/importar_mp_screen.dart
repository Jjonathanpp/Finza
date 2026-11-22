import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/core/widgets/aviso_en_linea.dart';
import 'package:frontend/core/widgets/barra_con_volver.dart';
import 'package:frontend/core/widgets/esqueleto.dart';
import 'package:frontend/core/widgets/monto.dart';
import 'package:frontend/core/widgets/tarjeta.dart';
import 'package:frontend/features/mercadopago/presentation/screens/sincronizacion_resumen_screen.dart';
import 'package:frontend/features/mercadopago/presentation/viewmodels/mercadopago_view_model.dart';
import 'package:frontend/l10n/idioma.dart';

// Elegir qué movimientos de Mercado Pago traer (Eze en main, 408983b), con el diseño nuevo. En una
// cuenta compartida es la única forma de importar: así no se mete todo lo personal en la cuenta.
// Los elegidos quedan por revisar, como los que se importan solos. Al importar se reemplaza por el
// resumen (como en main, 8f532bc) y devuelve true, para que Mercado Pago recargue los pendientes.
class ImportarMPScreen extends StatefulWidget {
  const ImportarMPScreen({super.key, required this.vm});

  final MercadoPagoViewModel vm;

  @override
  State<ImportarMPScreen> createState() => _ImportarMPScreenState();
}

class _ImportarMPScreenState extends State<ImportarMPScreen> {
  MercadoPagoViewModel get _vm => widget.vm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _vm.cargarDisponibles());
  }

  Future<void> _importar() async {
    final resumen = await _vm.importarSeleccionados();
    if (!mounted) return;
    if (resumen != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SincronizacionResumenScreen(resumen: resumen)),
        result: true,
      );
    } else if (_vm.error != null) {
      final c = context.colores;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_vm.error!, style: TextStyle(color: c.coralTexto)), backgroundColor: c.coralFondo),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barraConVolver(
        context,
        context.tr('Elegir de Mercado Pago'),
        subtitulo: cuentaActiva.value?['nombre'] as String?,
      ),
      body: ListenableBuilder(listenable: _vm, builder: (context, _) => _contenido(context)),
      bottomNavigationBar: ListenableBuilder(listenable: _vm, builder: (context, _) => _barraImportar(context)),
    );
  }

  Widget _contenido(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    if (_vm.cargandoDisponibles && _vm.disponibles.isEmpty) {
      return const Padding(padding: EdgeInsets.fromLTRB(20, 4, 20, 32), child: EsqueletoLista(cantidad: 5));
    }
    if (_vm.disponibles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              if (_vm.error != null) AvisoEnLinea(_vm.error!, icono: Icons.cloud_off_outlined),
              Icon(Icons.search_off, size: 40, color: c.suave),
              Text(
                context.tr('No hay movimientos nuevos en tu Mercado Pago.'),
                textAlign: TextAlign.center,
                style: textos.bodyMedium?.copyWith(color: c.suave),
              ),
              OutlinedButton(onPressed: _vm.cargarDisponibles, child: Text(context.tr('Reintentar'))),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _vm.cargarDisponibles,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
            child: Text(
              context.tr('Marcá los que quieras traer. Después los revisás antes de que cuenten.'),
              style: textos.bodySmall?.copyWith(color: c.suave),
            ),
          ),
          TarjetaLista(
            children: [
              for (final item in _vm.disponibles) _FilaDisponible(item, vm: _vm),
            ],
          ),
        ],
      ),
    );
  }

  Widget _barraImportar(BuildContext context) {
    final cantidad = _vm.seleccionados.length;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: FilledButton(
          onPressed: cantidad > 0 && !_vm.cargando ? _importar : null,
          child: _vm.cargando
              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(
                  cantidad == 0
                      ? context.tr('Elegí movimientos')
                      : context.tr('Importar {n} elegidos', {'n': '$cantidad'}),
                ),
        ),
      ),
    );
  }
}

class _FilaDisponible extends StatelessWidget {
  const _FilaDisponible(this.item, {required this.vm});

  final Map<String, dynamic> item;
  final MercadoPagoViewModel vm;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    final id = item['id'].toString();
    final descripcion = item['description']?.toString();
    final monto = (item['transaction_amount'] as num?)?.toDouble() ?? 0;
    // Una carga de saldo es plata que entra; el resto, plata que sale (el mismo criterio que main).
    final esIngreso = item['collector_id'] != null && item['operation_type'] == 'account_fund';
    final fecha = DateTime.tryParse(item['date_created']?.toString() ?? '')?.toLocal();
    String dos(int n) => n.toString().padLeft(2, '0');
    return CheckboxListTile(
      value: vm.seleccionados.contains(id),
      onChanged: (_) => vm.alternarSeleccion(id),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      title: Text(
        descripcion == null || descripcion.isEmpty ? context.tr('Sin descripción') : descripcion,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: textos.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: fecha == null
          ? null
          : Text(
              '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year} ${dos(fecha.hour)}:${dos(fecha.minute)}',
              style: textos.bodySmall?.copyWith(color: c.suave),
            ),
      secondary: Monto(monto, ingreso: esIngreso, estilo: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
    );
  }
}
