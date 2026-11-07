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
                      tooltip: 'Mes anterior',
                    ),
                    Text(
                      '${_meses[vm.mesActual]} ${vm.anioActual}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 28),
                      onPressed: () => _cambiarMes(vm, 1),
                      tooltip: 'Mes siguiente',
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

              const SizedBox(height: 4),

              // 3. Resumen + lista de presupuestos (o estado de carga/vacío)
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

    final lista = vm.presupuestosOrdenados;
    // En una cuenta compartida la tarjeta se abre y muestra cuánto gastó cada integrante; si sos
    // admin, desde ahí se edita el tope (t-13.2.2). En la personal no se abre.
    final enCompartida = cuentaActiva.value != null;

    return RefreshIndicator(
      onRefresh: () => vm.cargarPresupuestos(),
      color: AppColors.accent,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        itemCount: lista.length + 1,
        // Entre el resumen y la primera tarjeta va el título de la sección.
        separatorBuilder: (_, i) => i == 0
            ? const Padding(
                padding: EdgeInsets.fromLTRB(4, 24, 4, 10),
                child: Text(
                  'POR CATEGORÍA',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.8),
                ),
              )
            : const SizedBox(height: 14),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _ResumenMes(vm: vm, nombreMes: _meses[vm.mesActual]);
          }

          final p = lista[index - 1];
          final abierta = enCompartida && _abierto == p.presupuestoId;

          return _TarjetaPresupuesto(
            presupuesto: p,
            enCompartida: enCompartida,
            abierta: abierta,
            diasRestantes: vm.diasRestantes,
            alTocar: enCompartida ? () => setState(() => _abierto = abierta ? null : p.presupuestoId) : null,
            desglose: abierta
                ? DesgloseIntegrantes(
                    presupuesto: p,
                    miPerfilId: cuentaActiva.value!['perfilId'] as int?,
                    alEditar: esAdminDeCuentaActiva ? () => _editar(vm, p) : null,
                  )
                : null,
          );
        },
      ),
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

// ======================= RESUMEN DEL MES =======================

// Tarjeta de arriba: cuánto se gastó del total presupuestado, cuánto queda (y a
// qué ritmo diario se puede gastar) y cuántas categorías están bien, cerca del
// tope o pasadas. El fondo toma el color del consumo total.
class _ResumenMes extends StatelessWidget {
  const _ResumenMes({required this.vm, required this.nombreMes});

  final PresupuestosViewModel vm;
  final String nombreMes;

  @override
  Widget build(BuildContext context) {
    final porcentaje = vm.porcentajeTotal;
    final color = colorPorConsumo(porcentaje);
    final disponible = vm.totalTope - vm.totalGastado;
    final dias = vm.diasRestantes;

    final String textoSaldo;
    if (disponible < 0) {
      textoSaldo = 'Te pasaste ${importe(-disponible)} del total presupuestado';
    } else if (vm.esMesPasado) {
      textoSaldo = 'Te sobraron ${importe(disponible)} ese mes';
    } else {
      textoSaldo = 'Te quedan ${importe(disponible)} para el resto del mes';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.18), AppColors.surface],
        ),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Resumen de $nombreMes',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
              ),
              const Spacer(),
              _ChipPorcentaje(porcentaje: porcentaje),
            ],
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: importe(vm.totalGastado),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.text),
                ),
                TextSpan(
                  text: '  de ${importe(vm.totalTope)}',
                  style: const TextStyle(fontSize: 15, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          BarraProgresoPresupuesto(porcentaje: porcentaje, altura: 12),
          const SizedBox(height: 14),
          Text(
            textoSaldo,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: disponible < 0 ? AppColors.danger : AppColors.text,
            ),
          ),
          if (disponible > 0 && dias != null) ...[
            const SizedBox(height: 4),
            Text(
              'Unos ${importe(disponible / dias)} por día durante ${dias == 1 ? 'el último día' : '$dias días'}',
              style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (vm.cantidadEnOrden > 0)
                _ChipEstado(cantidad: vm.cantidadEnOrden, texto: 'en orden', color: colorPorConsumo(0)),
              if (vm.cantidadCercaDelTope > 0)
                _ChipEstado(cantidad: vm.cantidadCercaDelTope, texto: 'cerca del tope', color: colorPorConsumo(80)),
              if (vm.cantidadExcedidos > 0)
                _ChipEstado(
                  cantidad: vm.cantidadExcedidos,
                  texto: vm.cantidadExcedidos == 1 ? 'excedido' : 'excedidos',
                  color: colorPorConsumo(100),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ======================= TARJETA DE UN PRESUPUESTO =======================

class _TarjetaPresupuesto extends StatelessWidget {
  const _TarjetaPresupuesto({
    required this.presupuesto,
    required this.enCompartida,
    required this.abierta,
    required this.diasRestantes,
    required this.alTocar,
    required this.desglose,
  });

  final Presupuesto presupuesto;
  final bool enCompartida;
  final bool abierta;
  final int? diasRestantes;
  final VoidCallback? alTocar;
  // El detalle por integrante (solo con la tarjeta abierta en una cuenta compartida).
  final Widget? desglose;

  @override
  Widget build(BuildContext context) {
    final p = presupuesto;
    final porcentaje = p.porcentajeConsumo;
    final color = colorPorConsumo(porcentaje);
    final colorTexto = colorTextoPorConsumo(porcentaje);
    final colorCat = colorDesdeHex(p.categoriaColor);
    final disponible = p.montoTope - p.montoGastado;
    final (iconoEstado, textoEstado) = _estado(porcentaje);
    final inicial = p.categoriaNombre.isEmpty ? '?' : p.categoriaNombre.characters.first.toUpperCase();
    final sinAnimaciones = MediaQuery.disableAnimationsOf(context);

    return AnimatedContainer(
      duration: sinAnimaciones ? Duration.zero : const Duration(milliseconds: 300),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        // Desde el 80% el borde toma el color del consumo: se nota sin abrir nada.
        border: Border.all(
          color: porcentaje >= 80 ? color.withValues(alpha: 0.5) : Colors.transparent,
          width: 1.2,
        ),
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
                onTap: alTocar,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado: categoría, estado y porcentaje
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colorCat.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              inicial,
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: colorCat),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.categoriaNombre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(iconoEstado, size: 14, color: colorTexto),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        textoEstado,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: colorTexto),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _ChipPorcentaje(porcentaje: porcentaje),
                          if (enCompartida) ...[
                            const SizedBox(width: 2),
                            Icon(abierta ? Icons.expand_less : Icons.expand_more, size: 20, color: AppColors.muted),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      BarraProgresoPresupuesto(porcentaje: porcentaje, altura: 10),
                      const SizedBox(height: 12),
                      // Gastado · Disponible (o Excedido) · Tope
                      Row(
                        children: [
                          Expanded(child: _Dato(etiqueta: 'Gastado', valor: importe(p.montoGastado))),
                          Expanded(
                            child: _Dato(
                              etiqueta: disponible >= 0 ? 'Disponible' : 'Excedido',
                              valor: importe(disponible.abs()),
                              color: disponible < 0 ? AppColors.danger : null,
                              alineacion: CrossAxisAlignment.center,
                            ),
                          ),
                          Expanded(
                            child: _Dato(
                              etiqueta: 'Tope',
                              valor: importe(p.montoTope),
                              alineacion: CrossAxisAlignment.end,
                            ),
                          ),
                        ],
                      ),
                      if (disponible > 0 && diasRestantes != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.muted),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Podés gastar ${importe(disponible / diasRestantes!)} por día',
                                style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: sinAnimaciones ? Duration.zero : const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: desglose ?? const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

// Qué decir según el consumo. Los cortes de 80% y 100% son los de la alerta del backend.
(IconData, String) _estado(double porcentaje) {
  if (porcentaje >= 100) return (Icons.error_outline, 'Tope superado');
  if (porcentaje >= 80) return (Icons.warning_amber_rounded, 'Cerca del tope');
  if (porcentaje >= 50) return (Icons.info_outline, 'Usaste más de la mitad');
  if (porcentaje > 0) return (Icons.check_circle_outline, 'Vas bien');
  return (Icons.check_circle_outline, 'Sin gastos todavía');
}

// ======================= PIEZAS CHICAS =======================

// El porcentaje en una pastilla del color del consumo.
class _ChipPorcentaje extends StatelessWidget {
  const _ChipPorcentaje({required this.porcentaje});

  final double porcentaje;

  @override
  Widget build(BuildContext context) {
    // Sin decimales si es entero (50%), con uno si no (79,6% no es lo mismo que 80%).
    final texto = porcentaje == porcentaje.roundToDouble()
        ? porcentaje.toStringAsFixed(0)
        : porcentaje.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorPorConsumo(porcentaje).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$texto%',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: colorTextoPorConsumo(porcentaje),
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

// "3 en orden", "1 cerca del tope", "1 excedido".
class _ChipEstado extends StatelessWidget {
  const _ChipEstado({required this.cantidad, required this.texto, required this.color});

  final int cantidad;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            '$cantidad $texto',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: oscurecerParaTexto(color)),
          ),
        ],
      ),
    );
  }
}

// Una cifra con su etiqueta chiquita arriba.
class _Dato extends StatelessWidget {
  const _Dato({
    required this.etiqueta,
    required this.valor,
    this.color,
    this.alineacion = CrossAxisAlignment.start,
  });

  final String etiqueta;
  final String valor;
  final Color? color;
  final CrossAxisAlignment alineacion;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alineacion,
      children: [
        Text(etiqueta, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
        const SizedBox(height: 2),
        Text(
          valor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.text,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}