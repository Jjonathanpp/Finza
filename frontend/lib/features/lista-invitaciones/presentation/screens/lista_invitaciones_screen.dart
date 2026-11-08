import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/features/lista-invitaciones/data/datasources/invitacion_api.dart';
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

  Future<void> _abrirModalInvitar() async {
    final enviado = await showDialog<bool>(
      context: context,
      builder: (_) => _InvitarDialog(
        onInvitar: (email) async {
          final ok = await _vm.enviarInvitacion(email);
          if (!ok && mounted && _vm.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_vm.error!),
                backgroundColor: AppColors.danger,
              ),
            );
          }
          return ok;
        },
      ),
    );

    if (enviado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invitación enviada'),
          backgroundColor: AppColors.accent,
        ),
      );
    }
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
          if (_vm.cargando && _vm.invitaciones.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final error = _vm.error;
          if (error != null && _vm.invitaciones.isEmpty) {
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
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
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
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.muted,
                              ),
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
                              for (
                                var i = 0;
                                i < _vm.invitaciones.length;
                                i++
                              ) ...[
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
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _abrirModalInvitar,
                    child: const Text('Invitar a cuenta compartida'),
                  ),
                ),
              ),
            ],
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

class _InvitarDialog extends StatefulWidget {
  const _InvitarDialog({required this.onInvitar});

  final Future<bool> Function(String email) onInvitar;

  @override
  State<_InvitarDialog> createState() => _InvitarDialogState();
}

class _InvitarDialogState extends State<_InvitarDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    final exito = await widget.onInvitar(_emailController.text.trim());
    if (mounted) {
      setState(() => _cargando = false);
      if (exito) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Invitar a cuenta compartida',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Correo electrónico',
            hintText: 'ejemplo@correo.com',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Ingresá un correo';
            }
            if (!RegExp(
              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
            ).hasMatch(value.trim())) {
              return 'Ingresá un correo válido';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cargando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _cargando ? null : _submit,
          child: _cargando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enviar'),
        ),
      ],
    );
  }
}
