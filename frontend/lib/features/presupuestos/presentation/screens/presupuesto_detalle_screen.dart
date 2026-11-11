import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/core/widgets/aviso_en_linea.dart';
import 'package:frontend/core/widgets/barra_con_volver.dart';
import 'package:frontend/core/widgets/barra_progreso.dart';
import 'package:frontend/core/widgets/chip_estado.dart';
import 'package:frontend/core/widgets/circulo_categoria.dart';
import 'package:frontend/core/widgets/confirmar.dart';
import 'package:frontend/core/widgets/encabezado_pestana.dart';
import 'package:frontend/core/widgets/fila_opcion.dart';
import 'package:frontend/core/widgets/monto.dart';
import 'package:frontend/core/widgets/tarjeta.dart';
import 'package:frontend/features/presupuestos/data/models/presupuesto.dart';
import 'package:frontend/features/presupuestos/presentation/nombres_de_meses.dart';
import 'package:frontend/features/presupuestos/presentation/viewmodels/presupuestos_view_model.dart';
import 'package:frontend/features/presupuestos/presentation/widgets/barra_progreso_presupuesto.dart';
import 'package:frontend/features/presupuestos/presentation/widgets/desglose_integrantes.dart';
import 'package:frontend/features/presupuestos/presentation/widgets/editar_presupuesto_sheet.dart';
import 'package:frontend/features/presupuestos/presentation/widgets/categoria_del_presupuesto.dart';
import 'package:frontend/features/presupuestos/presentation/widgets/selector_intervalo_aviso.dart';
import 'package:provider/provider.dart';

// El detalle de un presupuesto: se abre al tocar su tarjeta en la lista. Muestra el consumo, cada cuánto
// avisa, cuánto gastó cada integrante (solo en una cuenta compartida) y, si se puede cambiar (sos admin
// de la cuenta compartida o es la personal), "Editar tope" y "Desactivar presupuesto".
// El view model es el de la lista: llega por provider (ChangeNotifierProvider.value al empujar la pantalla).
// Se busca por id en cada armado, así que al editar el tope se ve el valor nuevo; si el presupuesto ya no
// está (se desactivó), la pantalla se cierra sola.
class PresupuestoDetalleScreen extends StatefulWidget {
  const PresupuestoDetalleScreen({super.key, required this.presupuestoId});

  final int presupuestoId;

  @override
  State<PresupuestoDetalleScreen> createState() => _PresupuestoDetalleScreenState();
}

class _PresupuestoDetalleScreenState extends State<PresupuestoDetalleScreen> {
  bool _cerrando = false;

  Future<void> _editar(PresupuestosViewModel vm, Presupuesto p) {
    return EditarPresupuestoSheet.mostrar(
      context,
      presupuesto: p,
      periodo: '${nombresDeMeses[vm.mesActual]} ${vm.anioActual}',
      cuenta: cuentaActiva.value?['nombre'] as String?,
      alGuardar: (tope, intervalo) => vm.editarTope(p, tope, intervaloAviso: intervalo),
      alDesactivar: () => vm.desactivar(p),
    );
  }

  Future<void> _desactivar(PresupuestosViewModel vm, Presupuesto p) async {
    final cuenta = cuentaActiva.value?['nombre'] as String?;
    final paraTodos = cuenta == null ? '' : ' para todos los de $cuenta';
    final seguro = await confirmar(
      context,
      titulo: 'Desactivar presupuesto',
      texto: '¿Desactivar el presupuesto de ${p.categoriaNombre} de ${nombresDeMeses[vm.mesActual]} ${vm.anioActual}$paraTodos?',
      textoAccion: 'Desactivar',
      peligro: true,
    );
    if (!seguro || !mounted) return;
    try {
      // Al recargar, el presupuesto ya no está y la pantalla se cierra sola.
      await vm.desactivar(p);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PresupuestosViewModel>();
    final p = vm.presupuestos.where((x) => x.presupuestoId == widget.presupuestoId).firstOrNull;

    if (p == null) {
      if (!_cerrando && !vm.cargando) {
        _cerrando = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).maybePop();
        });
      }
      return Scaffold(appBar: barraConVolver(context, 'Presupuesto'));
    }

    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    final estado = EstadoConsumo.de(p.porcentajeConsumo);
    final colorEstado = estado.colorTexto(context);
    final compartida = cuentaActiva.value != null;
    final puede = esAdminDeCuentaActiva;

    return Scaffold(
      appBar: barraConVolver(
        context,
        p.categoriaNombre,
        subtitulo: '${nombreDeCuentaActiva()} · ${nombresDeMeses[vm.mesActual].toLowerCase()} ${vm.anioActual}',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Tarjeta(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  Row(
                    spacing: 12,
                    children: [
                      CirculoCategoria.de(categoriaDelPresupuesto(p), tamano: 48),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            textoPorcentaje(p.porcentajeConsumo),
                            style: textos.displaySmall?.copyWith(color: colorEstado, letterSpacing: -0.8),
                          ),
                        ),
                      ),
                      ChipEstado(estado.texto, estado.tonoChip),
                    ],
                  ),
                  BarraProgreso(
                    grande: true,
                    valor: p.porcentajeConsumo / 100,
                    tono: estado.tonoBarra,
                    etiqueta: p.categoriaNombre,
                  ),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        'Gastado ${Monto.texto(p.montoGastado)} de ${Monto.texto(p.montoTope)}',
                        style: textos.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        textoRestante(p.montoGastado, p.montoTope),
                        style: textos.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: estado.colorSecundario(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Tarjeta(
              padding: Tarjeta.paddingLista,
              child: FilaOpcion(
                leading: CirculoCategoria(icono: Icons.notifications_none, color: c.primario, fondo: c.menta),
                titulo: 'Avisarme cada ${p.intervaloAviso}%',
                subtitulo: describirAvisos(p.intervaloAviso),
              ),
            ),
            if (compartida)
              DesgloseIntegrantes(presupuesto: p, miPerfilId: cuentaActiva.value!['perfilId'] as int?),
            if (puede) ...[
              FilledButton.icon(
                onPressed: () => _editar(vm, p),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar tope'),
              ),
              FilledButton(
                onPressed: () => _desactivar(vm, p),
                style: estiloBotonPeligro(context),
                child: const Text('Desactivar presupuesto'),
              ),
            ] else
              const AvisoEnLinea('Solo un administrador puede cambiar este presupuesto.', icono: Icons.lock_outline),
          ],
        ),
      ),
    );
  }
}
