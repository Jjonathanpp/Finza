import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/widgets/barra_con_volver.dart';
import 'package:frontend/features/mercadopago/presentation/viewmodels/mercadopago_view_model.dart';
import 'package:frontend/features/mercadopago/presentation/screens/sincronizacion_resumen_screen.dart';
import 'package:frontend/l10n/idioma.dart';
import 'package:frontend/shared/utils/importe.dart';

class ImportarMPScreen extends StatefulWidget {
  final MercadoPagoViewModel vm;

  const ImportarMPScreen({super.key, required this.vm});

  @override
  State<ImportarMPScreen> createState() => _ImportarMPScreenState();
}

class _ImportarMPScreenState extends State<ImportarMPScreen> {
  @override
  void initState() {
    super.initState();
    // Cargamos los movimientos disponibles al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.vm.cargarDisponibles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barraConVolver(
        context,
        context.tr('Seleccionar de Mercado Pago'),
      ),
      body: ListenableBuilder(
        listenable: widget.vm,
        builder: (context, child) {
          if (widget.vm.cargando && widget.vm.disponibles.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final disponibles = widget.vm.disponibles;
          if (disponibles.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.search_off,
                      size: 48,
                      color: AppColors.muted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr(
                        'No se encontraron movimientos recientes en tu Mercado Pago.',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: widget.vm.cargarDisponibles,
                      child: Text(context.tr('Reintentar')),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: disponibles.length,
                  separatorBuilder: (context, child) =>
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final item = disponibles[index];
                    final id = item['id'].toString();
                    final descripcion =
                        item['description'] ?? context.tr('Sin descripción');
                    final monto = (item['transaction_amount'] ?? 0).toDouble();
                    final esIngreso =
                        item['collector_id'] != null &&
                        item['operation_type'] == 'account_fund';

                    final fechaStr = item['date_created'] ?? '';

                    DateTime? fecha;
                    try {
                      fecha = DateTime.parse(fechaStr);
                    } catch (_) {}

                    final seleccionado = widget.vm.seleccionados.contains(id);

                    return CheckboxListTile(
                      value: seleccionado,
                      onChanged: (_) => widget.vm.toggleSeleccion(id),
                      activeColor: AppColors.accent,
                      title: Text(
                        descripcion,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: fecha != null
                          ? Text(
                              '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            )
                          : null,
                      secondary: Text(
                        '${esIngreso ? '+ ' : '− '}${importe(monto)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: esIngreso
                              ? AppColors.accent
                              : AppColors.danger,
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                    );
                  },
                ),
              ),
              _botonImportar(),
            ],
          );
        },
      ),
    );
  }

  Widget _botonImportar() {
    final cant = widget.vm.seleccionados.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: cant > 0 && !widget.vm.cargando ? _importar : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.accentInk,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: widget.vm.cargando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  cant == 0
                      ? context.tr('Seleccioná movimientos')
                      : context.tr('Importar {n} seleccionados', {
                          'n': '$cant',
                        }),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _importar() async {
    final resumen = await widget.vm.importarSeleccionados();
    if (!mounted) return;

    if (resumen != null) {
      Navigator.pop(context, true);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SincronizacionResumenScreen(resumen: resumen),
        ),
      );
    } else if (widget.vm.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.vm.error!)));
    }
  }
}
