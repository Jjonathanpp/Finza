import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/features/metas_ahorro/data/datasources/metas_ahorro_api.dart';
import 'package:frontend/features/metas_ahorro/data/models/meta_ahorro.dart';
import 'package:frontend/features/metas_ahorro/presentation/viewmodels/metas_ahorro_view_model.dart';
import 'package:frontend/features/metas_ahorro/presentation/widgets/abonar_meta_sheet.dart';
import 'package:frontend/features/metas_ahorro/presentation/widgets/formulario_meta_sheet.dart';
import 'package:frontend/l10n/idioma.dart';
import 'package:frontend/shared/utils/importe.dart';

class MetasAhorroScreen extends StatefulWidget {
  const MetasAhorroScreen({super.key});

  @override
  State<MetasAhorroScreen> createState() => _MetasAhorroScreenState();
}

class _MetasAhorroScreenState extends State<MetasAhorroScreen> {
  late final _viewModel = MetasAhorroViewModel(MetasAhorroApi(ApiClient()));

  int? get _cuentaCompartidaId {
    final id = cuentaActiva.value?['id'];
    return id is num ? id.toInt() : null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _viewModel.cargarMetas(cuentaCompartidaId: _cuentaCompartidaId),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _abrirFormulario({MetaAhorro? meta}) async {
    final creado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FormularioMetaSheet(
        meta: meta,
        alGuardar: (nombre, monto, fecha) async {
          if (meta == null) {
            await _viewModel.crear(
              nombre: nombre,
              montoObjetivo: monto,
              fechaLimite: fecha,
              cuentaCompartidaId: _cuentaCompartidaId,
            );
          } else {
            await _viewModel.editar(
              meta: meta,
              nombre: nombre,
              montoObjetivo: monto,
              fechaLimite: fecha,
              cuentaCompartidaId: _cuentaCompartidaId,
            );
          }
        },
      ),
    );
    if (creado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(meta == null ? 'Meta creada' : 'Meta actualizada'),
          ),
        ),
      );
    }
  }

  Future<void> _eliminar(MetaAhorro meta) async {
    final cuenta = cuentaActiva.value?['nombre']?.toString();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Eliminar meta')),
        content: Text(
          cuenta == null
              ? context.tr(
                  '¿Eliminar la meta "{nombre}"? Esta acción no se puede deshacer.',
                  {'nombre': meta.nombre},
                )
              : context.tr(
                  '¿Eliminar la meta "{nombre}" de {cuenta} para todos sus integrantes? Esta acción no se puede deshacer.',
                  {'nombre': meta.nombre, 'cuenta': cuenta},
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Cancelar')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(context.tr('Eliminar')),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    try {
      await _viewModel.eliminar(meta, cuentaCompartidaId: _cuentaCompartidaId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('Meta eliminada'))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _abonar(MetaAhorro meta) async {
    final abonado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AbonarMetaSheet(
        meta: meta,
        alAbonar: (monto) => _viewModel.abonar(
          meta: meta,
          monto: monto,
          cuentaCompartidaId: _cuentaCompartidaId,
        ),
      ),
    );
    if (abonado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Dinero ingresado a la meta'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final compartida = cuentaActiva.value != null;
    final puedeAdministrar = esAdminDeCuentaActiva;
    return Scaffold(
      appBar: AppBar(
        title: Text(conCuentaActiva(context.tr('Metas de ahorro'))),
      ),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          if (_viewModel.cargando && _viewModel.metas.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_viewModel.error != null && _viewModel.metas.isEmpty) {
            return _ErrorMetas(
              mensaje: _viewModel.error!,
              reintentar: () => _viewModel.cargarMetas(
                cuentaCompartidaId: _cuentaCompartidaId,
              ),
            );
          }
          return Column(
            children: [
              if (compartida && !puedeAdministrar)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                  child: Text(
                    context.tr(
                      'Solo los administradores de {cuenta} pueden crear, editar o eliminar metas.',
                      {'cuenta': '${cuentaActiva.value!['nombre']}'},
                    ),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ),
              if (puedeAdministrar)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _abrirFormulario(),
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(context.tr('Crear meta de ahorro')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              if (_viewModel.error != null && _viewModel.metas.isNotEmpty)
                MaterialBanner(
                  content: Text(_viewModel.error!),
                  actions: [
                    TextButton(
                      onPressed: () => _viewModel.cargarMetas(
                        cuentaCompartidaId: _cuentaCompartidaId,
                      ),
                      child: Text(context.tr('Reintentar')),
                    ),
                  ],
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _viewModel.cargarMetas(
                    cuentaCompartidaId: _cuentaCompartidaId,
                  ),
                  child: _viewModel.metas.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.sizeOf(context).height * 0.18,
                            ),
                            Icon(
                              Icons.savings_outlined,
                              size: 64,
                              color: AppColors.faint,
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                compartida
                                    ? context.tr(
                                        '{cuenta} todavía no tiene metas de ahorro.',
                                        {
                                          'cuenta':
                                              '${cuentaActiva.value!['nombre']}',
                                        },
                                      )
                                    : context.tr(
                                        'Todavía no tenés metas de ahorro.',
                                      ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (compartida && !puedeAdministrar) ...[
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  context.tr(
                                    'Un administrador puede crear una meta para compartirla con la cuenta.',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _viewModel.metas.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final meta = _viewModel.metas[index];
                            return _TarjetaMeta(
                              meta: meta,
                              mostrarAcciones: puedeAdministrar,
                              mostrarAportes: compartida,
                              abonar: () => _abonar(meta),
                              editar: () => _abrirFormulario(meta: meta),
                              eliminar: () => _eliminar(meta),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ErrorMetas extends StatelessWidget {
  const _ErrorMetas({required this.mensaje, required this.reintentar});

  final String mensaje;
  final VoidCallback reintentar;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.danger),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: reintentar,
            child: Text(context.tr('Reintentar')),
          ),
        ],
      ),
    ),
  );
}

class _TarjetaMeta extends StatelessWidget {
  const _TarjetaMeta({
    required this.meta,
    required this.mostrarAcciones,
    required this.mostrarAportes,
    required this.abonar,
    required this.editar,
    required this.eliminar,
  });

  final MetaAhorro meta;
  final bool mostrarAcciones;
  final bool mostrarAportes;
  final VoidCallback abonar;
  final VoidCallback editar;
  final VoidCallback eliminar;

  String _fecha(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/'
      '${fecha.month.toString().padLeft(2, '0')}/'
      '${fecha.year}';

  @override
  Widget build(BuildContext context) {
    final cuotas = meta.cuotasRecomendadas();
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    meta.nombre,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (mostrarAcciones) ...[
                  IconButton(
                    onPressed: editar,
                    tooltip: context.tr('Editar meta'),
                    icon: const Icon(Icons.edit_outlined),
                    color: AppColors.muted,
                  ),
                  IconButton(
                    onPressed: eliminar,
                    tooltip: context.tr('Eliminar meta'),
                    icon: const Icon(Icons.delete_outline),
                    color: AppColors.danger,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  importe(meta.montoActual),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  context.tr('de {monto}', {
                    'monto': importe(meta.montoObjetivo),
                  }),
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: meta.progreso,
                minHeight: 9,
                backgroundColor: AppColors.surface3,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('{porcentaje}% completado', {
                    'porcentaje': (meta.progreso * 100).round().toString(),
                  }),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                Text(
                  context.tr('Faltan {monto}', {
                    'monto': importe(meta.montoRestante),
                  }),
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: meta.montoRestante <= 0 ? null : abonar,
                icon: Icon(
                  meta.montoRestante <= 0
                      ? Icons.check_circle_outline
                      : Icons.add_circle_outline,
                ),
                label: Text(
                  context.tr(
                    meta.montoRestante <= 0
                        ? 'Meta completada'
                        : 'Ingresar dinero',
                  ),
                ),
              ),
            ),
            if (mostrarAportes) ...[
              const SizedBox(height: 8),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                title: Text(
                  context.tr('Aportes por integrante'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                children: [
                  for (final aporte in meta.aportes)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            color: AppColors.muted,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              aporte.nombre,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            importe(aporte.monto),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (meta.aportes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        context.tr('Todavía no hay aportes registrados.'),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (meta.fechaLimite != null || cuotas.isNotEmpty) ...[
              const Divider(height: 24),
              Wrap(
                spacing: 18,
                runSpacing: 8,
                children: [
                  if (meta.fechaLimite != null)
                    _DatoMeta(
                      icono: Icons.event_outlined,
                      texto: context.tr('Hasta {fecha}', {
                        'fecha': _fecha(meta.fechaLimite!),
                      }),
                    ),
                  for (final cuota in cuotas)
                    _DatoMeta(
                      icono: switch (cuota.periodo) {
                        'diaria' => Icons.today_outlined,
                        'semanal' => Icons.date_range_outlined,
                        _ => Icons.calendar_month_outlined,
                      },
                      texto: context.tr(
                        switch (cuota.periodo) {
                          'diaria' => 'Ingresar {monto} por día',
                          'semanal' => 'Ingresar {monto} por semana',
                          _ => 'Ingresar {monto} por mes',
                        },
                        {'monto': importe(cuota.monto, centavos: true)},
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DatoMeta extends StatelessWidget {
  const _DatoMeta({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icono, size: 16, color: AppColors.muted),
      const SizedBox(width: 6),
      Text(texto, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
    ],
  );
}
