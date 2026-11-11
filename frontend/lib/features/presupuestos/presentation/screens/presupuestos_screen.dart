import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/core/widgets/aviso_en_linea.dart';
import 'package:frontend/core/widgets/barra_progreso.dart';
import 'package:frontend/core/widgets/boton_icono.dart';
import 'package:frontend/core/widgets/chip_estado.dart';
import 'package:frontend/core/widgets/circulo_categoria.dart';
import 'package:frontend/core/widgets/encabezado_pestana.dart';
import 'package:frontend/core/widgets/esqueleto.dart';
import 'package:frontend/core/widgets/monto.dart';
import 'package:frontend/core/widgets/tarjeta.dart';
import 'package:frontend/features/presupuestos/data/models/presupuesto.dart';
import 'package:frontend/features/presupuestos/presentation/nombres_de_meses.dart';
import 'package:frontend/features/presupuestos/presentation/screens/alta_presupuestos_screen.dart'; // Nombre con "s" como lo guardaste
import 'package:frontend/features/presupuestos/presentation/screens/presupuesto_detalle_screen.dart';
import 'package:frontend/features/presupuestos/presentation/viewmodels/presupuestos_view_model.dart';
import 'package:frontend/features/presupuestos/presentation/widgets/barra_progreso_presupuesto.dart';
import 'package:frontend/features/presupuestos/presentation/widgets/categoria_del_presupuesto.dart';
import 'package:frontend/features/presupuestos/presentation/widgets/tarjetas_cargando.dart';
import 'package:provider/provider.dart';

class PresupuestosScreen extends StatefulWidget {
  const PresupuestosScreen({super.key});

  @override
  State<PresupuestosScreen> createState() => _PresupuestosScreenState();
}

class _PresupuestosScreenState extends State<PresupuestosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PresupuestosViewModel>().cargarPresupuestos();
    });
  }

  void _cambiarMes(PresupuestosViewModel vm, int delta) {
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

  Future<void> _nuevo(PresupuestosViewModel vm) async {
    final creado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AltaPresupuestoScreen()),
    );
    // Si se creó uno, recargamos la vista del mes actual
    if (creado == true && mounted) {
      vm.cargarPresupuestos();
    }
  }

  // El detalle usa el mismo view model que la lista: se le pasa con .value para que no lo cree de nuevo.
  void _abrirDetalle(PresupuestosViewModel vm, Presupuesto p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: vm,
          child: PresupuestoDetalleScreen(presupuestoId: p.presupuestoId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PresupuestosViewModel>(
        builder: (context, vm, child) {
          return Column(
            children: [
              // Crear presupuestos: en una cuenta compartida, solo para el admin (t-13.1.2).
              EncabezadoPestana(
                titulo: 'Presupuestos',
                acciones: [
                  if (esAdminDeCuentaActiva)
                    BotonIcono(
                      icono: Icons.add,
                      principal: true,
                      ayuda: 'Nuevo presupuesto',
                      alTocar: () => _nuevo(vm),
                    ),
                ],
              ),
              Expanded(child: _construirContenido(vm)),
            ],
          );
        },
      ),
    );
  }

  Widget _construirContenido(PresupuestosViewModel vm) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    final cuenta = cuentaActiva.value;
    final compartida = cuenta != null;
    final lista = vm.presupuestosOrdenados;

    final Widget debajo;
    if (vm.cargando) {
      debajo = const TarjetasCargando();
    } else if (vm.error != null) {
      debajo = Column(
        spacing: 12,
        children: [
          Text(vm.error!, textAlign: TextAlign.center, style: textos.bodyMedium?.copyWith(color: c.coralTexto)),
          OutlinedButton(onPressed: () => vm.cargarPresupuestos(), child: const Text('Reintentar')),
        ],
      );
    } else if (lista.isEmpty) {
      debajo = Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          cuenta == null
              ? 'No hay presupuestos en ${nombresDeMeses[vm.mesActual]}'
              : '${cuenta['nombre']} no tiene presupuestos en ${nombresDeMeses[vm.mesActual]}',
          textAlign: TextAlign.center,
          style: textos.bodyMedium?.copyWith(color: c.suave),
        ),
      );
    } else {
      debajo = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          for (final p in lista)
            _TarjetaPresupuesto(presupuesto: p, alTocar: () => _abrirDetalle(vm, p)),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () => vm.cargarPresupuestos(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            // La cuenta en la que estás y, si es compartida, tu rol (.ctas).
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const ChipCuenta(),
                if (compartida)
                  ChipEstado(
                    esAdminDeCuentaActiva ? 'Sos administrador' : 'Sos miembro',
                    esAdminDeCuentaActiva ? TonoChip.menta : TonoChip.hundido,
                  ),
              ],
            ),
            if (!esAdminDeCuentaActiva)
              AvisoEnLinea(
                'En ${cuenta!['nombre']} los presupuestos los maneja un administrador. Vos ves cuánto gastó cada uno.',
                icono: Icons.lock_outline,
              ),
            _ResumenMes(vm: vm, onAnterior: () => _cambiarMes(vm, -1), onSiguiente: () => _cambiarMes(vm, 1)),
            debajo,
          ],
        ),
      ),
    );
  }
}

// ======================= RESUMEN DEL MES =======================

// Tarjeta de arriba: el mes con las flechas para cambiarlo y, si hay presupuestos, cuánto se gastó del total
// presupuestado, la barra grande y cuánto queda. El tono sale del consumo total.
class _ResumenMes extends StatelessWidget {
  const _ResumenMes({required this.vm, required this.onAnterior, required this.onSiguiente});

  final PresupuestosViewModel vm;
  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    final conDatos = !vm.cargando && vm.error == null && vm.presupuestos.isNotEmpty;

    return Tarjeta(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 22),
                color: c.suave,
                tooltip: 'Mes anterior',
                onPressed: onAnterior,
              ),
              Flexible(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    '${nombresDeMeses[vm.mesActual]} ${vm.anioActual}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textos.bodyMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 22),
                color: c.suave,
                tooltip: 'Mes siguiente',
                onPressed: onSiguiente,
              ),
            ],
          ),
          if (vm.cargando) ...[
            const Esqueleto(ancho: 160, alto: 28, radio: Radios.pastilla),
            const Esqueleto(alto: 10, radio: Radios.pastilla),
          ] else if (conDatos)
            ..._totales(context),
        ],
      ),
    );
  }

  List<Widget> _totales(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    final estado = EstadoConsumo.de(vm.porcentajeTotal);
    final disponible = vm.totalTope - vm.totalGastado;
    final dias = vm.diasRestantes;

    final String textoSaldo;
    if (disponible < 0) {
      textoSaldo = 'Te pasaste ${Monto.texto(-disponible)} del total presupuestado.';
    } else if (disponible == 0) {
      textoSaldo = 'Llegaste al total de los topes.';
    } else if (dias == null) {
      textoSaldo = 'Te sobraron ${Monto.texto(disponible)} ese mes.';
    } else {
      textoSaldo = 'Te quedan ${Monto.texto(disponible)} para ${dias == 1 ? 'el último día' : 'los próximos $dias días'}.';
    }

    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Text('Llevás gastado', style: textos.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          Text.rich(
            TextSpan(
              text: Monto.texto(vm.totalGastado),
              style: textos.displaySmall?.copyWith(fontSize: 26, letterSpacing: -0.26),
              children: [
                TextSpan(
                  text: ' de ${Monto.texto(vm.totalTope)}',
                  style: textos.bodyMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: c.suave),
                ),
              ],
            ),
          ),
        ],
      ),
      BarraProgreso(
        grande: true,
        valor: vm.porcentajeTotal / 100,
        tono: estado.tonoBarra,
        etiqueta: 'Gastado del total',
      ),
      Text(textoSaldo, style: textos.bodySmall),
    ];
  }
}

// ======================= TARJETA DE UN PRESUPUESTO =======================

// Una categoría con su presupuesto: la inicial con su color, el nombre, el porcentaje, la barra y cuánto
// se gastó y cuánto queda. Al tocarla se abre el detalle.
class _TarjetaPresupuesto extends StatelessWidget {
  const _TarjetaPresupuesto({required this.presupuesto, required this.alTocar});

  final Presupuesto presupuesto;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final p = presupuesto;
    final textos = Theme.of(context).textTheme;
    final estado = EstadoConsumo.de(p.porcentajeConsumo);
    final porcentaje = textoPorcentaje(p.porcentajeConsumo);
    final restante = textoRestante(p.montoGastado, p.montoTope);
    final gastado = '${Monto.texto(p.montoGastado)} de ${Monto.texto(p.montoTope)}';

    return Tarjeta(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      alTocar: alTocar,
      etiqueta: '${p.categoriaNombre}, $porcentaje usado. $gastado. $restante',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Row(
            spacing: 12,
            children: [
              CirculoCategoria.de(categoriaDelPresupuesto(p), tamano: 36),
              Expanded(
                child: Text(
                  p.categoriaNombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textos.bodyMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                porcentaje,
                style: textos.bodyMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: estado.colorTexto(context),
                ),
              ),
            ],
          ),
          BarraProgreso(valor: p.porcentajeConsumo / 100, tono: estado.tonoBarra),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 8,
            children: [
              Flexible(child: Text(gastado, maxLines: 1, overflow: TextOverflow.ellipsis, style: textos.bodySmall)),
              Flexible(
                child: Text(
                  restante,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: textos.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: estado.colorSecundario(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
