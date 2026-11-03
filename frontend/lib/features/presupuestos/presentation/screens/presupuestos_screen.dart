import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/features/presupuestos/data/models/presupuesto.dart';
import 'package:frontend/features/presupuestos/presentation/screens/alta_presupuestos_screen.dart'; // Nombre con "s" como lo guardaste
import 'package:frontend/features/presupuestos/presentation/viewmodels/presupuestos_view_model.dart';
import 'package:frontend/features/presupuestos/presentation/widgets/barra_progreso_presupuesto.dart';
import 'package:frontend/features/presupuestos/presentation/widgets/desglose_integrantes.dart';
import 'package:frontend/features/presupuestos/presentation/widgets/editar_presupuesto_sheet.dart';
import 'package:frontend/features/presupuestos/presentation/widgets/tarjetas_cargando.dart';
import 'package:frontend/shared/utils/color_hex.dart';
import 'package:frontend/shared/utils/importe.dart';
import 'package:provider/provider.dart';

class PresupuestosScreen extends StatefulWidget {
  const PresupuestosScreen({super.key});

  @override
  State<PresupuestosScreen> createState() => _PresupuestosScreenState();
}

class _PresupuestosScreenState extends State<PresupuestosScreen> {
  final List<String> _meses = [
    '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  // En una cuenta compartida, el presupuesto cuya tarjeta está abierta (una a la vez, t-13.2.2).
  int? _abierto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PresupuestosViewModel>().cargarPresupuestos();
    });
  }

  void _cambiarMes(PresupuestosViewModel vm, int delta) {
    setState(() => _abierto = null);
    int m = vm.mesActual + delta;
    int a = vm.anioActual;
    if (m < 1) {
      m = 12;
      a--;
    } else if (m > 12) {
      m = 1;
      a++;
    }
    vm.cargarPresupuestos(mes: m, anio: a);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(conCuentaActiva('Presupuestos')),
        elevation: 0,
      ),
      body: Consumer<PresupuestosViewModel>(
        builder: (context, vm, child) {
          return Column(
            children: [
              // 1. Selector de Mes y Año
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 28),
                      onPressed: () => _cambiarMes(vm, -1),
                    ),
                    Text(
                      '${_meses[vm.mesActual]} ${vm.anioActual}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 28),
                      onPressed: () => _cambiarMes(vm, 1),
                    ),
                  ],
                ),
              ),

              // 2. Botón Grande "Agregar presupuesto". En una cuenta compartida, solo para el admin (t-13.1.2)
              if (!esAdminDeCuentaActiva)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Text(
                    'Solo los administradores de ${cuentaActiva.value!['nombre']} pueden agregar o cambiar presupuestos.',
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline, size: 22),
                      label: const Text('Agregar presupuesto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final creado = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AltaPresupuestoScreen()),
                        );
                        // Si se creó uno, recargamos la vista del mes actual
                        if (creado == true && mounted) {
                          vm.cargarPresupuestos();
                        }
                      },
                    ),
                  ),
                ),
              
              const SizedBox(height: 12),

              // 3. Lista de presupuestos (o estado de carga/vacio)
              Expanded(
                child: _construirContenido(vm),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _construirContenido(PresupuestosViewModel vm) {
    if (vm.cargando) {
      return const TarjetasCargando();
    }

    if (vm.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(vm.error!, style: const TextStyle(color: AppColors.danger)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => vm.cargarPresupuestos(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (vm.presupuestos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pie_chart_outline, size: 64, color: AppColors.faint),
            const SizedBox(height: 16),
            Text(
              cuentaActiva.value == null
                  ? 'No hay presupuestos en ${_meses[vm.mesActual]}'
                  : '${cuentaActiva.value!['nombre']} no tiene presupuestos en ${_meses[vm.mesActual]}',
              style: const TextStyle(color: AppColors.muted, fontSize: 16),
            ),
            if (cuentaActiva.value != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  esAdminDeCuentaActiva
                      ? 'Cuando agregues uno, acá vas a ver cuánto gastó cada integrante.'
                      : 'Cuando un administrador agregue uno, acá vas a ver cuánto gastó cada integrante.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.45),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      itemCount: vm.presupuestos.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final p = vm.presupuestos[index];
        final colorCat = colorDesdeHex(p.categoriaColor);
        // En una cuenta compartida la tarjeta se abre y muestra cuánto gastó cada integrante; si sos
        // admin, desde ahí se edita el tope (t-13.2.2). En la personal no se abre.
        final enCompartida = cuentaActiva.value != null;
        final abierta = enCompartida && _abierto == p.presupuestoId;

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 2))],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  expanded: enCompartida ? abierta : null,
                  child: InkWell(
                    onTap: enCompartida ? () => setState(() => _abierto = abierta ? null : p.presupuestoId) : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(color: colorCat, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(p.categoriaNombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${p.porcentajeConsumo.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: p.porcentajeConsumo >= 100
                                          ? AppColors.danger
                                          : p.porcentajeConsumo >= 80
                                              ? AppColors.warning
                                              : AppColors.success,
                                    ),
                                  ),
                                  if (enCompartida) ...[
                                    const SizedBox(width: 4),
                                    Icon(abierta ? Icons.expand_less : Icons.expand_more, size: 20, color: AppColors.muted),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          BarraProgresoPresupuesto(porcentaje: p.porcentajeConsumo),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Gastado: ${importe(p.montoGastado)}', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                              Text('Tope: ${importe(p.montoTope)}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: abierta
                      ? DesgloseIntegrantes(
                          presupuesto: p,
                          miPerfilId: cuentaActiva.value!['perfilId'] as int?,
                          alEditar: esAdminDeCuentaActiva ? () => _editar(vm, p) : null,
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _editar(PresupuestosViewModel vm, Presupuesto p) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true, // sube con el teclado
      builder: (_) => EditarPresupuestoSheet(
        presupuesto: p,
        periodo: '${_meses[vm.mesActual]} ${vm.anioActual}',
        cuenta: cuentaActiva.value!['nombre'] as String,
        alGuardar: (tope) => vm.editarTope(p, tope),
        alDesactivar: () => vm.desactivar(p),
      ),
    );
  }
}