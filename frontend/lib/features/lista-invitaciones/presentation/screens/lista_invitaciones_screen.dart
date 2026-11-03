import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/features/lista-invitaciones/data/datasources/Invitacion_api.dart';
import 'package:frontend/features/lista-invitaciones/data/models/invitacion_enviada.dart';
import 'package:frontend/features/lista-invitaciones/presentation/viewmodels/lista_invitaciones_view_model.dart';

class ListaInvitacionesScreen extends StatefulWidget {
  const ListaInvitacionesScreen({
    super.key,
    required this.cuentaCompartidaId,
    this.api,
  });

  final int cuentaCompartidaId;
  final InvitacionApi? api; // para los tests

  @override
  State<ListaInvitacionesScreen> createState() =>
      _ListaInvitacionesScreenState();
}

class _ListaInvitacionesScreenState extends State<ListaInvitacionesScreen> {
  late final _vm = ListaInvitacionesViewModel(
    widget.api ?? InvitacionApi(ApiClient()),
    widget.cuentaCompartidaId,
  );

  @override
  void initState() {
    super.initState();
    _vm.cargar();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  String _fecha(DateTime f) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(f.day)}/${dos(f.month)}/${f.year} ${dos(f.hour)}:${dos(f.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(conCuentaActiva('Invitaciones enviadas'))),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          // La ruedita solo la primera vez: al recargar, la lista queda donde estaba.
          if (_vm.cargando && _vm.invitaciones.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final error = _vm.error;
          if (error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error, style: const TextStyle(color: AppColors.muted)),
                  TextButton(
                    onPressed: _vm.cargar,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _vm.cargar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              children: [
                if (_vm.invitaciones.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        'Todavía no enviaste invitaciones',
                        style: TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < _vm.invitaciones.length; i++) ...[
                          if (i > 0)
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: AppColors.line,
                            ),
                          _fila(_vm.invitaciones[i]),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _fila(InvitacionEnviada invitacion) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invitacion.emailInvitado,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Vencimiento: ${_fecha(invitacion.fechaExpiracion)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _EtiquetaEstado(estado: invitacion.estado),
        ],
      ),
    );
  }
}

class _EtiquetaEstado extends StatelessWidget {
  const _EtiquetaEstado({required this.estado});

  final EstadoInvitacion estado;

  @override
  Widget build(BuildContext context) {
    final (texto, color) = switch (estado) {
      EstadoInvitacion.pendiente => ('PENDIENTE', AppColors.blue),
      EstadoInvitacion.aceptada => ('ACEPTADA', AppColors.accent),
      EstadoInvitacion.rechazada => ('RECHAZADA', AppColors.danger),
      EstadoInvitacion.expirada => ('EXPIRADA', AppColors.faint),
      EstadoInvitacion.cancelada => ('CANCELADA', AppColors.faint),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
