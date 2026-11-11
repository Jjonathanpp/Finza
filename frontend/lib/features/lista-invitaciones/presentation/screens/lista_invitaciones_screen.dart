import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/core/widgets/barra_con_volver.dart';
import 'package:frontend/core/widgets/campo.dart';
import 'package:frontend/core/widgets/chip_estado.dart';
import 'package:frontend/core/widgets/circulo_categoria.dart';
import 'package:frontend/core/widgets/esqueleto.dart';
import 'package:frontend/core/widgets/fila_opcion.dart';
import 'package:frontend/core/widgets/tarjeta.dart';
import 'package:frontend/core/widgets/titulo_seccion.dart';
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

  String? get _nombreCuenta => cuentaActiva.value?['nombre'] as String?;

  Future<void> _abrirModalInvitar() async {
    final enviado = await showDialog<bool>(
      context: context,
      builder: (_) => _InvitarDialog(
        nombreCuenta: _nombreCuenta,
        onInvitar: (email) async {
          final ok = await _vm.enviarInvitacion(email);
          if (!ok && mounted && _vm.error != null) {
            final c = context.colores;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _vm.error!,
                  style: TextStyle(color: c.coralTexto),
                ),
                backgroundColor: c.coralFondo,
              ),
            );
          }
          return ok;
        },
      ),
    );

    if (enviado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitación enviada')),
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
      appBar: barraConVolver(
        context,
        'Invitaciones',
        subtitulo: _nombreCuenta,
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          if (_vm.cargando && _vm.invitaciones.isEmpty) {
            return const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 32),
              child: EsqueletoLista(cantidad: 3),
            );
          }
          final error = _vm.error;
          if (error != null && _vm.invitaciones.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 12,
                  children: [
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    FilledButton(
                      onPressed: _vm.cargar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          final textos = Theme.of(context).textTheme;
          return RefreshIndicator(
            onRefresh: _vm.cargar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: _abrirModalInvitar,
                      icon: const Icon(Icons.mail_outline, size: 18),
                      label: const Text('Invitar por mail'),
                    ),
                    const TituloSeccion('Enviadas'),
                    if (_vm.invitaciones.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'Todavía no enviaste invitaciones',
                          style: textos.bodySmall,
                        ),
                      )
                    else
                      TarjetaLista(
                        children: [
                          for (final invitacion in _vm.invitaciones)
                            _fila(context, invitacion),
                        ],
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Las invitaciones vencen a las 24 horas. Si vence, la mandás de nuevo.',
                        style: textos.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _fila(BuildContext context, InvitacionEnviada invitacion) {
    final c = context.colores;
    final fecha = _fecha(invitacion.fechaExpiracion);
    // El ícono y el color de cada estado, como en la maqueta (mail, persona y reloj).
    final (icono, serie) = switch (invitacion.estado) {
      EstadoInvitacion.pendiente => (Icons.mail_outline, 2),
      EstadoInvitacion.aceptada => (Icons.person_outline, 3),
      EstadoInvitacion.rechazada => (Icons.person_off_outlined, 1),
      EstadoInvitacion.expirada => (Icons.schedule, 0),
      EstadoInvitacion.cancelada => (Icons.block, 0),
    };
    final subtitulo = switch (invitacion.estado) {
      EstadoInvitacion.pendiente => 'Vence el $fecha',
      EstadoInvitacion.expirada => 'Venció el $fecha',
      _ => 'Vencimiento: $fecha',
    };
    return FilaOpcion(
      leading: CirculoCategoria(
        icono: icono,
        color: c.serie[serie],
        fondo: c.serieFondo[serie],
      ),
      titulo: invitacion.emailInvitado,
      subtitulo: subtitulo,
      trailing: _EtiquetaEstado(estado: invitacion.estado),
    );
  }
}

class _EtiquetaEstado extends StatelessWidget {
  const _EtiquetaEstado({required this.estado});

  final EstadoInvitacion estado;

  @override
  Widget build(BuildContext context) {
    final (texto, tono) = switch (estado) {
      EstadoInvitacion.pendiente => ('Pendiente', TonoChip.ambar),
      EstadoInvitacion.aceptada => ('Aceptada', TonoChip.menta),
      EstadoInvitacion.rechazada => ('Rechazada', TonoChip.coral),
      EstadoInvitacion.expirada => ('Vencida', TonoChip.hundido),
      EstadoInvitacion.cancelada => ('Cancelada', TonoChip.hundido),
    };
    return ChipEstado(texto, tono, chico: true);
  }
}

class _InvitarDialog extends StatefulWidget {
  const _InvitarDialog({required this.onInvitar, this.nombreCuenta});

  final Future<bool> Function(String email) onInvitar;
  final String? nombreCuenta;

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
    final textos = Theme.of(context).textTheme;
    final nombre = widget.nombreCuenta;
    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: [
              Semantics(
                header: true,
                child: Text(
                  nombre == null ? 'Invitar a cuenta compartida' : 'Invitar a $nombre',
                  style: textos.titleLarge,
                ),
              ),
              Campo(
                etiqueta: 'Correo electrónico',
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  decoration: const InputDecoration(
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
              Text(
                'Le llega un mail con un link que vence en 24 horas. Tiene que tener cuenta en Finza.',
                style: textos.bodyMedium?.copyWith(
                  color: context.colores.suave,
                ),
              ),
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _cargando
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  Expanded(
                    child: FilledButton(
                      onPressed: _cargando ? null : _submit,
                      child: _cargando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Enviar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
