import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/session/deep_link_service.dart';
import 'package:frontend/core/session/portero.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/features/invitacion/presentation/viewmodels/invitacion_view_model.dart';
import 'package:frontend/features/lista-invitaciones/data/datasources/invitacion_api.dart';
import 'package:frontend/features/lista-invitaciones/data/models/invitacion_enviada.dart';
import 'package:frontend/features/lista-invitaciones/data/models/invitacion_recibida.dart';
import 'package:frontend/l10n/idioma.dart';

// Sin sesión (o para entrar con otra cuenta): deja la invitación guardada en
// InvitacionPendiente (deep_link_service.dart) y va al login. Después de entrar,
// abrirInvitacionPendiente() la vuelve a abrir.
void _irAlLoginYVolver(String token) {
  InvitacionPendiente.token = token;
  irAlLogin();
}

// La pantalla que abre el enlace de la invitación (finza://invitacion?token=..., t-11.2.2): quién
// invita y a qué cuenta, y los botones para aceptar o rechazar. Al aceptar, la app entra directo
// a la cuenta compartida; al rechazar, vuelve al inicio.
class InvitacionScreen extends StatefulWidget {
  const InvitacionScreen({super.key, required this.token, this.api});

  final String token;
  final InvitacionApi? api; // para los tests

  @override
  State<InvitacionScreen> createState() => _InvitacionScreenState();
}

class _InvitacionScreenState extends State<InvitacionScreen> {
  late final _vm = InvitacionViewModel(widget.api ?? InvitacionApi(ApiClient()), widget.token);

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

  void _avisar(String texto) {
    final contexto = navegador.currentContext;
    if (contexto != null) {
      ScaffoldMessenger.maybeOf(contexto)?.showSnackBar(SnackBar(content: Text(texto)));
    }
  }

  Future<void> _aceptar(InvitacionRecibida invitacion) async {
    final cuenta = await _vm.aceptar();
    if (cuenta == null) return; // el motivo lo muestra la pantalla
    // Entra directo a la cuenta compartida, como si la hubiera elegido en el selector.
    await TokenStorage().guardarCuentaActiva(cuenta);
    irAlInicio();
    _avisar(tr('Ya sos parte de {cuenta}', {'cuenta': invitacion.cuentaCompartidaNombre}));
  }

  Future<void> _rechazar(InvitacionRecibida invitacion) async {
    final seguro = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('Rechazar invitación')),
        content: Text(
          ctx.tr(
            '¿Rechazar la invitación a {cuenta}? Para entrar después, {invitador} te tendría que mandar otra.',
            {'cuenta': invitacion.cuentaCompartidaNombre, 'invitador': invitacion.invitadoPor},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.muted),
            child: Text(ctx.tr('Cancelar')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(ctx.tr('Rechazar')),
          ),
        ],
      ),
    );
    if (seguro != true) return;
    if (await _vm.rechazar()) {
      irAlInicio();
      _avisar(tr('Rechazaste la invitación a {cuenta}', {'cuenta': invitacion.cuentaCompartidaNombre}));
    }
  }

  // La invitación es para otro email: cerrar esta sesión y entrar con la cuenta correcta.
  Future<void> _entrarConOtraCuenta() async {
    final seguro = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('Entrar con otra cuenta')),
        content: Text(ctx.tr('Se va a cerrar la sesión de esta cuenta. Después de entrar, vas a volver a ver la invitación.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.muted),
            child: Text(ctx.tr('Cancelar')),
          ),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.tr('Cerrar sesión'))),
        ],
      ),
    );
    if (seguro != true) return;
    await TokenStorage().limpiar();
    _irAlLoginYVolver(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Invitación'))),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          if (_vm.cargando) return const Center(child: CircularProgressIndicator());
          if (!_vm.haySesion) return _sinSesion();
          final invitacion = _vm.invitacion;
          if (invitacion == null) return _sinInvitacion();
          return _detalle(invitacion);
        },
      ),
    );
  }

  // ---------------- Estados ----------------

  Widget _sinSesion() {
    return _Centrado(
      icono: Icons.lock_outline,
      titulo: context.tr('Iniciá sesión para ver la invitación'),
      texto: context.tr('La invitación es para una cuenta de Finza. Entrá con esa cuenta y te la mostramos.'),
      acciones: [
        FilledButton(
          onPressed: () => _irAlLoginYVolver(widget.token),
          child: Text(context.tr('Iniciar sesión')),
        ),
      ],
    );
  }

  Widget _sinInvitacion() {
    return _Centrado(
      icono: Icons.link_off,
      titulo: context.tr('No pudimos abrir la invitación'),
      texto: _vm.error ?? context.tr('El enlace puede estar incompleto.'),
      acciones: [
        FilledButton.tonal(onPressed: _vm.cargar, child: Text(context.tr('Reintentar'))),
        TextButton(onPressed: irAlInicio, child: Text(context.tr('Ir al inicio'))),
      ],
    );
  }

  Widget _detalle(InvitacionRecibida inv) {
    final motivo = _motivoSinRespuesta(inv);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      children: [
        Center(
          child: CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.accent.withValues(alpha: 0.15),
            child: const Icon(Icons.group_add_outlined, size: 34, color: AppColors.text),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          context.tr('{invitador} te invitó a', {'invitador': inv.invitadoPor}),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14.5, color: AppColors.muted),
        ),
        const SizedBox(height: 4),
        Text(
          inv.cuentaCompartidaNombre,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              _Dato(icono: Icons.mail_outline, etiqueta: context.tr('Invitación para'), valor: inv.emailInvitado),
              const Divider(height: 1, color: AppColors.line),
              _Dato(icono: Icons.schedule, etiqueta: context.tr('Vence'), valor: _vence(inv.fechaExpiracion)),
              const Divider(height: 1, color: AppColors.line),
              _Dato(
                icono: Icons.person_outline,
                etiqueta: context.tr('Vas a entrar como'),
                valor: context.tr('Miembro: vas a ver y cargar los movimientos de la cuenta'),
              ),
            ],
          ),
        ),
        if (motivo != null) ...[
          const SizedBox(height: 16),
          _Aviso(texto: motivo),
        ],
        if (_vm.error != null) ...[
          const SizedBox(height: 16),
          Text(_vm.error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger, fontSize: 13.5)),
        ],
        const SizedBox(height: 28),
        if (inv.sePuedeResponder) ...[
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _vm.respondiendo ? null : () => _aceptar(inv),
              icon: _vm.respondiendo
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: Text(context.tr('Aceptar y entrar'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: _vm.respondiendo ? null : () => _rechazar(inv),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.line),
              ),
              child: Text(context.tr('Rechazar')),
            ),
          ),
        ] else ...[
          if (inv.estado == EstadoInvitacion.pendiente && !inv.esParaVos) ...[
            SizedBox(
              height: 48,
              child: FilledButton(onPressed: _entrarConOtraCuenta, child: Text(context.tr('Entrar con otra cuenta'))),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            height: 48,
            child: FilledButton.tonal(onPressed: irAlInicio, child: Text(context.tr('Ir al inicio'))),
          ),
        ],
      ],
    );
  }

  // Por qué no se puede aceptar ni rechazar (null si se puede).
  String? _motivoSinRespuesta(InvitacionRecibida inv) {
    if (inv.yaSosMiembro) return context.tr('Ya sos parte de {cuenta}.', {'cuenta': inv.cuentaCompartidaNombre});
    return switch (inv.estado) {
      EstadoInvitacion.aceptada => context.tr('Esta invitación ya fue aceptada.'),
      EstadoInvitacion.rechazada => context.tr('Esta invitación fue rechazada.'),
      EstadoInvitacion.expirada => context.tr('La invitación venció. Pedile a {invitador} que te mande otra.', {'invitador': inv.invitadoPor}),
      EstadoInvitacion.cancelada => context.tr('La invitación fue cancelada.'),
      EstadoInvitacion.pendiente => inv.esParaVos
          ? null
          : context.tr('Esta invitación es para {email}. Entrá con esa cuenta para aceptarla.', {'email': inv.emailInvitado}),
    };
  }

  String _vence(DateTime fecha) {
    String dos(int n) => n.toString().padLeft(2, '0');
    final texto = context.tr('{dia} a las {hora}', {
      'dia': '${dos(fecha.day)}/${dos(fecha.month)}',
      'hora': '${dos(fecha.hour)}:${dos(fecha.minute)}',
    });
    final falta = fecha.difference(DateTime.now());
    if (falta.isNegative) return context.tr('Venció el {fecha}', {'fecha': texto});
    if (falta.inHours >= 1) return context.tr('{fecha} (en {horas} h)', {'fecha': texto, 'horas': '${falta.inHours}'});
    return context.tr('{fecha} (en {minutos} min)', {'fecha': texto, 'minutos': '${falta.inMinutes}'});
  }
}

// ---------------- Piezas ----------------

class _Centrado extends StatelessWidget {
  const _Centrado({required this.icono, required this.titulo, required this.texto, required this.acciones});

  final IconData icono;
  final String titulo;
  final String texto;
  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 52, color: AppColors.muted),
            const SizedBox(height: 16),
            Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(texto, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, height: 1.4)),
            const SizedBox(height: 20),
            for (final accion in acciones) ...[accion, const SizedBox(height: 8)],
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.etiqueta, required this.valor});

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: AppColors.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(height: 2),
                Text(valor, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.muted),
          const SizedBox(width: 10),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 13.5, height: 1.4))),
        ],
      ),
    );
  }
}