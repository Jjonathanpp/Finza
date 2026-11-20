import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/core/widgets/avatar_inicial.dart';
import 'package:frontend/core/widgets/aviso_en_linea.dart';
import 'package:frontend/core/widgets/aviso_exito.dart';
import 'package:frontend/core/widgets/barra_con_volver.dart';
import 'package:frontend/core/widgets/barra_progreso.dart';
import 'package:frontend/core/widgets/boton_icono.dart';
import 'package:frontend/core/widgets/chip_estado.dart';
import 'package:frontend/core/widgets/confirmar.dart';
import 'package:frontend/core/widgets/encabezado_pestana.dart';
import 'package:frontend/core/widgets/esqueleto.dart';
import 'package:frontend/core/widgets/monto.dart';
import 'package:frontend/core/widgets/tarjeta.dart';
import 'package:frontend/features/metas_ahorro/data/datasources/metas_ahorro_api.dart';
import 'package:frontend/features/metas_ahorro/data/models/meta_ahorro.dart';
import 'package:frontend/features/metas_ahorro/presentation/viewmodels/metas_ahorro_view_model.dart';
import 'package:frontend/features/metas_ahorro/presentation/widgets/abonar_meta_sheet.dart';
import 'package:frontend/features/metas_ahorro/presentation/widgets/formulario_meta_sheet.dart';
import 'package:frontend/l10n/idioma.dart';

// Metas de ahorro de la cuenta activa (la personal o una compartida). Cualquiera puede ingresar dinero;
// crear, editar y borrar, solo el admin en una compartida. En una compartida cada tarjeta muestra
// cuánto puso cada integrante.
class MetasAhorroScreen extends StatefulWidget {
  const MetasAhorroScreen({super.key, this.enPestana = false, this.viewModel});

  // En la barra de abajo va con el encabezado de pestaña (título grande y el menú); empujada, con volver.
  final bool enPestana;

  // Para las pruebas; si es null usa el backend.
  final MetasAhorroViewModel? viewModel;

  @override
  State<MetasAhorroScreen> createState() => _MetasAhorroScreenState();
}

class _MetasAhorroScreenState extends State<MetasAhorroScreen> {
  late final _vm = widget.viewModel ?? MetasAhorroViewModel(MetasAhorroApi(ApiClient()));

  int? get _cuentaId => (cuentaActiva.value?['id'] as num?)?.toInt();

  Future<void> _cargar() => _vm.cargarMetas(cuentaCompartidaId: _cuentaId);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _formulario({MetaAhorro? meta}) async {
    final guardado = await FormularioMetaSheet.mostrar(
      context,
      meta: meta,
      alGuardar: (nombre, monto, fecha) => meta == null
          ? _vm.crear(nombre: nombre, montoObjetivo: monto, fechaLimite: fecha, cuentaCompartidaId: _cuentaId)
          : _vm.editar(
              meta: meta,
              nombre: nombre,
              montoObjetivo: monto,
              fechaLimite: fecha,
              cuentaCompartidaId: _cuentaId,
            ),
    );
    if (guardado == true && mounted) {
      mostrarExito(context, meta == null ? context.tr('Meta creada') : context.tr('Meta actualizada'));
    }
  }

  Future<void> _abonar(MetaAhorro meta) async {
    final abonado = await AbonarMetaSheet.mostrar(
      context,
      meta: meta,
      alAbonar: (monto) => _vm.abonar(meta: meta, monto: monto, cuentaCompartidaId: _cuentaId),
    );
    if (abonado == true && mounted) mostrarExito(context, context.tr('Dinero ingresado'));
  }

  Future<void> _eliminar(MetaAhorro meta) async {
    final cuenta = cuentaActiva.value?['nombre'] as String?;
    final seguro = await confirmar(
      context,
      titulo: context.tr('Eliminar meta'),
      texto: cuenta == null
          ? '¿Eliminar "${meta.nombre}"? No se puede deshacer.'
          : '¿Eliminar "${meta.nombre}" para todos los de $cuenta? No se puede deshacer.',
      textoAccion: context.tr('Eliminar'),
      peligro: true,
    );
    if (!seguro || !mounted) return;
    try {
      await _vm.eliminar(meta, cuentaCompartidaId: _cuentaId);
      if (mounted) mostrarExito(context, context.tr('Meta eliminada'));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cuenta = cuentaActiva.value?['nombre'] as String?;
    final admin = esAdminDeCuentaActiva;
    final nueva = [
      if (admin) BotonIcono(icono: Icons.add, principal: true, ayuda: context.tr('Nueva meta'), alTocar: _formulario),
    ];
    final lista = ListenableBuilder(
      listenable: _vm,
      builder: (context, _) => RefreshIndicator(
        onRefresh: _cargar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            if (cuenta != null && !admin)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AvisoEnLinea(
                  context.tr('Solo un administrador de {cuenta} puede crear, editar o eliminar metas.', {
                    'cuenta': cuenta,
                  }),
                  icono: Icons.lock_outline,
                ),
              ),
            ..._contenido(context, cuenta, admin),
          ],
        ),
      ),
    );
    if (widget.enPestana) {
      return Scaffold(
        body: Column(
          children: [
            EncabezadoPestana(titulo: context.tr('Metas de ahorro'), acciones: nueva),
            Expanded(child: lista),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: barraConVolver(
        context,
        context.tr('Metas de ahorro'),
        subtitulo: cuenta ?? context.tr('Personal'),
        acciones: nueva,
      ),
      body: lista,
    );
  }

  List<Widget> _contenido(BuildContext context, String? cuenta, bool admin) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    if (_vm.cargando && _vm.metas.isEmpty) return const [EsqueletoLista(cantidad: 3, conBloques: true)];
    if (_vm.error != null && _vm.metas.isEmpty) {
      return [
        const SizedBox(height: 24),
        Text(
          _vm.error!,
          textAlign: TextAlign.center,
          style: textos.bodyMedium?.copyWith(color: c.coralTexto),
        ),
        const SizedBox(height: 12),
        Center(
          child: OutlinedButton(onPressed: _cargar, child: Text(context.tr('Reintentar'))),
        ),
      ];
    }
    if (_vm.metas.isEmpty) {
      return [
        Tarjeta(
          padding: const EdgeInsets.all(24),
          child: Column(
            spacing: 10,
            children: [
              Icon(Icons.savings_outlined, size: 40, color: c.primario),
              Text(
                cuenta == null
                    ? context.tr('Todavía no tenés metas de ahorro')
                    : '$cuenta todavía no tiene metas de ahorro',
                textAlign: TextAlign.center,
                style: textos.bodyMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              Text(
                context.tr(
                  'Poné un objetivo, una fecha si querés, y Finza te dice cuánto separar por día, semana o mes.',
                ),
                textAlign: TextAlign.center,
                style: textos.bodySmall?.copyWith(color: c.suave),
              ),
              if (admin) ...[
                const SizedBox(height: 4),
                FilledButton(onPressed: _formulario, child: Text(context.tr('Crear una meta'))),
              ],
            ],
          ),
        ),
      ];
    }
    return [
      if (_vm.error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AvisoEnLinea(_vm.error!, icono: Icons.cloud_off_outlined),
        ),
      for (final meta in _vm.metas)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _TarjetaMeta(
            meta: meta,
            aportes: _vm.aportesDe(meta),
            miPerfilId: (cuentaActiva.value?['perfilId'] as num?)?.toInt(),
            admin: admin,
            compartida: cuenta != null,
            alAbonar: () => _abonar(meta),
            alEditar: () => _formulario(meta: meta),
            alEliminar: () => _eliminar(meta),
          ),
        ),
    ];
  }
}

class _TarjetaMeta extends StatelessWidget {
  const _TarjetaMeta({
    required this.meta,
    required this.aportes,
    required this.miPerfilId,
    required this.admin,
    required this.compartida,
    required this.alAbonar,
    required this.alEditar,
    required this.alEliminar,
  });

  final MetaAhorro meta;
  final List<AporteMetaAhorro> aportes;
  final int? miPerfilId;
  final bool admin;
  final bool compartida;
  final VoidCallback alAbonar;
  final VoidCallback alEditar;
  final VoidCallback alEliminar;

  static const _porPeriodo = {'diaria': 'por día', 'semanal': 'por semana', 'mensual': 'por mes'};

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    final completa = meta.montoRestante <= 0;
    final porcentaje = (meta.progreso * 100).floor();
    final cuotas = meta.cuotasRecomendadas();
    final limite = meta.fechaLimite;
    return Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          // Nombre, cuánto va y el estado
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: Text(
                  meta.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textos.bodyMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              completa
                  ? ChipEstado(context.tr('Completada'), TonoChip.menta, chico: true, icono: Icons.check)
                  : ChipEstado('$porcentaje%', TonoChip.hundido, chico: true),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: 6,
            children: [
              Monto(meta.montoActual, estilo: const TextStyle(fontSize: 24)),
              Flexible(
                child: Text(
                  'de ${Monto.texto(meta.montoObjetivo)}',
                  overflow: TextOverflow.ellipsis,
                  style: textos.bodyMedium?.copyWith(color: c.suave),
                ),
              ),
            ],
          ),
          BarraProgreso(valor: meta.progreso, grande: true, etiqueta: meta.nombre),
          Row(
            children: [
              Expanded(
                child: Text(
                  completa
                      ? context.tr('¡Llegaste al objetivo!')
                      : context.tr('Faltan {monto}', {'monto': Monto.texto(meta.montoRestante)}),
                  style: textos.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: completa ? c.primario : c.texto,
                  ),
                ),
              ),
              if (limite != null)
                Row(
                  spacing: 4,
                  children: [
                    Icon(Icons.event_outlined, size: 15, color: c.suave),
                    Text(
                      context.tr('Hasta el {fecha}', {'fecha': '${limite.day}/${limite.month}/${limite.year}'}),
                      style: textos.bodySmall?.copyWith(color: c.suave),
                    ),
                  ],
                ),
            ],
          ),
          // Cuánto separar para llegar a tiempo
          if (cuotas.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: c.hundido, borderRadius: BorderRadius.circular(Radios.control)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  Text(context.tr('Para llegar a tiempo, separá'), style: textos.bodySmall?.copyWith(color: c.suave)),
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      for (final cuota in cuotas)
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: Monto.texto(cuota.monto),
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              TextSpan(
                                text: ' ${context.tr(_porPeriodo[cuota.periodo] ?? '')}',
                                style: TextStyle(color: c.suave),
                              ),
                            ],
                          ),
                          style: textos.bodyMedium?.copyWith(fontSize: 14),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          // En una compartida: cuánto puso cada uno
          if (compartida) ...[
            Divider(height: 1, color: c.linea),
            Text(
              context.tr('Aportes'),
              style: textos.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: c.suave),
            ),
            if (aportes.isEmpty)
              Text(context.tr('Todavía nadie ingresó dinero.'), style: textos.bodySmall?.copyWith(color: c.suave))
            else
              // Cada integrante con lo que puso y qué parte del objetivo es; "Vos" para el propio y
              // "Ya no está" para quien salió de la cuenta (el desglose de Tomás en main).
              for (final (i, aporte) in aportes.indexed)
                Row(
                  spacing: 10,
                  children: [
                    AvatarInicial(aporte.nombre.isEmpty ? '?' : aporte.nombre[0].toUpperCase(), serie: i, tamano: 28),
                    Flexible(
                      child: Text(
                        aporte.nombre,
                        overflow: TextOverflow.ellipsis,
                        style: textos.bodyMedium?.copyWith(color: aporte.activo ? null : c.suave),
                      ),
                    ),
                    if (miPerfilId != null && aporte.perfilId == miPerfilId)
                      ChipEstado(context.tr('Vos'), TonoChip.menta, chico: true),
                    if (!aporte.activo) ChipEstado(context.tr('Ya no está'), TonoChip.hundido, chico: true),
                    const Spacer(),
                    Monto(aporte.monto, estilo: const TextStyle(fontSize: 14)),
                    if (aporte.porcentaje != null)
                      SizedBox(
                        width: 44,
                        child: Text(
                          '${aporte.porcentaje!.round()}%',
                          textAlign: TextAlign.right,
                          style: textos.bodySmall?.copyWith(color: c.suave),
                        ),
                      ),
                  ],
                ),
          ],
          // Acciones: ingresar dinero (si falta) y, para el admin, editar y eliminar
          if (!completa || admin)
            Row(
              spacing: 8,
              children: [
                if (!completa)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: alAbonar,
                      icon: const Icon(Icons.add),
                      label: Text(context.tr('Ingresar dinero')),
                    ),
                  )
                else
                  const Spacer(),
                if (admin) ...[
                  BotonIcono(icono: Icons.edit_outlined, ayuda: context.tr('Editar meta'), alTocar: alEditar),
                  BotonIcono(icono: Icons.delete_outline, ayuda: context.tr('Eliminar meta'), alTocar: alEliminar),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
