import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/session/deep_link_service.dart';
import 'package:frontend/core/session/portero.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/core/widgets/aviso_en_linea.dart';
import 'package:frontend/core/widgets/avatar_inicial.dart';
import 'package:frontend/core/widgets/barra_con_volver.dart';
import 'package:frontend/core/widgets/circulo_categoria.dart';
import 'package:frontend/core/widgets/confirmar.dart';
import 'package:frontend/core/widgets/tarjeta.dart';
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
    final seguro = await confirmar(
      context,
      titulo: context.tr('Rechazar invitación'),
      texto: context.tr(
        '¿Rechazar la invitación a {cuenta}? Para entrar después, {quien} te tendría que mandar otra.',
        {'cuenta': invitacion.cuentaCompartidaNombre, 'quien': invitacion.invitadoPor},
      ),
      textoAccion: context.tr('Rechazar'),
      peligro: true,
    );
    if (!seguro) return;
    if (await _vm.rechazar()) {
      irAlInicio();
      _avisar(tr('Rechazaste la invitación a {cuenta}', {'cuenta': invitacion.cuentaCompartidaNombre}));
    }
  }

  // La invitación es para otro email: cerrar esta sesión y entrar con la cuenta correcta.
  Future<void> _entrarConOtraCuenta() async {
    final seguro = await confirmar(
      context,
      titulo: context.tr('Entrar con otra cuenta'),
      texto: context.tr(
        'Se va a cerrar la sesión de esta cuenta. Después de entrar, vas a volver a ver la invitación.',
      ),
      textoAccion: context.tr('Cerrar sesión'),
    );
    if (!seguro) return;
    await TokenStorage().limpiar();
    _irAlLoginYVolver(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barraConVolver(context, context.tr('Te invitaron')),
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
        FilledButton(onPressed: () => _irAlLoginYVolver(widget.token), child: Text(context.tr('Iniciar sesión'))),
      ],
    );
  }

  Widget _sinInvitacion() {
    return _Centrado(
      icono: Icons.link_off,
      titulo: context.tr('No pudimos abrir la invitación'),
      texto: _vm.error ?? context.tr('El enlace puede estar incompleto.'),
      acciones: [
        FilledButton(onPressed: _vm.cargar, child: Text(context.tr('Reintentar'))),
        TextButton(onPressed: irAlInicio, child: Text(context.tr('Ir al inicio'))),
      ],
    );
  }

  Widget _detalle(InvitacionRecibida inv) {
    final motivo = _motivoSinRespuesta(inv);
    final textos = Theme.of(context).textTheme;
    final c = context.colores;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 4),
              child: Center(
                child: AvatarInicial(inv.invitadoPor, serie: 0, tamano: 64),
              ),
            ),
            Semantics(
              header: true,
              child: Text(
                '${inv.invitadoPor} te invitó a ${inv.cuentaCompartidaNombre}',
                textAlign: TextAlign.center,
                style: textos.titleLarge?.copyWith(fontSize: 22),
              ),
            ),
            Text(
              context.tr('Si aceptás, vas a ver y cargar los movimientos de {cuenta}.', {
                'cuenta': inv.cuentaCompartidaNombre,
              }),
              textAlign: TextAlign.center,
              style: textos.bodyMedium?.copyWith(fontSize: 14.5, color: c.suave),
            ),
            TarjetaLista(
              children: [
                _Dato(etiqueta: context.tr('Cuenta compartida'), valor: inv.cuentaCompartidaNombre),
                _Dato(etiqueta: context.tr('Invitación para'), valor: inv.emailInvitado),
                _Dato(etiqueta: context.tr('Vas a ser'), valor: context.tr('Miembro')),
                _Dato(etiqueta: context.tr('Vence'), valor: _vence(inv.fechaExpiracion)),
              ],
            ),
            if (motivo != null) AvisoEnLinea(motivo, icono: Icons.info_outline),
            if (_vm.error != null)
              Text(
                _vm.error!,
                textAlign: TextAlign.center,
                style: textos.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: c.coralTexto),
              ),
            if (inv.sePuedeResponder) ...[
              FilledButton(
                onPressed: _vm.respondiendo ? null : () => _aceptar(inv),
                child: _vm.respondiendo
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(context.tr('Aceptar y entrar')),
              ),
              OutlinedButton(
                onPressed: _vm.respondiendo ? null : () => _rechazar(inv),
                child: Text(context.tr('Rechazar')),
              ),
            ] else ...[
              if (inv.estado == EstadoInvitacion.pendiente && !inv.esParaVos)
                FilledButton(onPressed: _entrarConOtraCuenta, child: Text(context.tr('Entrar con otra cuenta'))),
              OutlinedButton(onPressed: irAlInicio, child: Text(context.tr('Ir al inicio'))),
            ],
          ],
        ),
      ],
    );
  }

  // Por qué no se puede aceptar ni rechazar (null si se puede).
  String? _motivoSinRespuesta(InvitacionRecibida inv) {
    if (inv.yaSosMiembro) return context.tr('Ya sos parte de {cuenta}.', {'cuenta': inv.cuentaCompartidaNombre});
    return switch (inv.estado) {
      EstadoInvitacion.aceptada => context.tr('Esta invitación ya fue aceptada.'),
      EstadoInvitacion.rechazada => context.tr('Esta invitación fue rechazada.'),
      EstadoInvitacion.expirada => context.tr('La invitación venció. Pedile a {quien} que te mande otra.', {
        'quien': inv.invitadoPor,
      }),
      EstadoInvitacion.cancelada => context.tr('La invitación fue cancelada.'),
      EstadoInvitacion.pendiente =>
        inv.esParaVos
            ? null
            : context.tr('Esta invitación es para {email}. Entrá con esa cuenta para aceptarla.', {
                'email': inv.emailInvitado,
              }),
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
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Center(
              child: CirculoCategoria(
                icono: icono,
                color: c.suave,
                fondo: c.hundido,
                tamano: 72,
                tamanoIcono: 32,
              ),
            ),
            Semantics(
              header: true,
              child: Text(titulo, textAlign: TextAlign.center, style: textos.titleSmall),
            ),
            Text(texto, textAlign: TextAlign.center, style: textos.bodyMedium?.copyWith(color: c.suave)),
            ...acciones,
          ],
        ),
      ),
    );
  }
}

// Una fila de la tarjeta: lo que es arriba (chico, en suave) y el dato abajo.
class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 2,
          children: [
            Text(etiqueta, style: textos.bodySmall),
            Text(valor, style: textos.bodyMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
