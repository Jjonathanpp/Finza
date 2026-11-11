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
    _avisar('Ya sos parte de ${invitacion.cuentaCompartidaNombre}');
  }

  Future<void> _rechazar(InvitacionRecibida invitacion) async {
    final seguro = await confirmar(
      context,
      titulo: 'Rechazar invitación',
      texto: '¿Rechazar la invitación a ${invitacion.cuentaCompartidaNombre}? '
          'Para entrar después, ${invitacion.invitadoPor} te tendría que mandar otra.',
      textoAccion: 'Rechazar',
      peligro: true,
    );
    if (!seguro) return;
    if (await _vm.rechazar()) {
      irAlInicio();
      _avisar('Rechazaste la invitación a ${invitacion.cuentaCompartidaNombre}');
    }
  }

  // La invitación es para otro email: cerrar esta sesión y entrar con la cuenta correcta.
  Future<void> _entrarConOtraCuenta() async {
    final seguro = await confirmar(
      context,
      titulo: 'Entrar con otra cuenta',
      texto: 'Se va a cerrar la sesión de esta cuenta. Después de entrar, vas a volver a ver la invitación.',
      textoAccion: 'Cerrar sesión',
    );
    if (!seguro) return;
    await TokenStorage().limpiar();
    _irAlLoginYVolver(widget.token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barraConVolver(context, 'Te invitaron'),
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
      titulo: 'Iniciá sesión para ver la invitación',
      texto: 'La invitación es para una cuenta de Finza. Entrá con esa cuenta y te la mostramos.',
      acciones: [
        FilledButton(
          onPressed: () => _irAlLoginYVolver(widget.token),
          child: const Text('Iniciar sesión'),
        ),
      ],
    );
  }

  Widget _sinInvitacion() {
    return _Centrado(
      icono: Icons.link_off,
      titulo: 'No pudimos abrir la invitación',
      texto: _vm.error ?? 'El enlace puede estar incompleto.',
      acciones: [
        FilledButton(onPressed: _vm.cargar, child: const Text('Reintentar')),
        TextButton(onPressed: irAlInicio, child: const Text('Ir al inicio')),
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
              'Si aceptás, vas a ver y cargar los movimientos de ${inv.cuentaCompartidaNombre}.',
              textAlign: TextAlign.center,
              style: textos.bodyMedium?.copyWith(fontSize: 14.5, color: c.suave),
            ),
            TarjetaLista(
              children: [
                _Dato(etiqueta: 'Cuenta compartida', valor: inv.cuentaCompartidaNombre),
                _Dato(etiqueta: 'Invitación para', valor: inv.emailInvitado),
                const _Dato(etiqueta: 'Vas a ser', valor: 'Miembro'),
                _Dato(etiqueta: 'Vence', valor: _vence(inv.fechaExpiracion)),
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
                    : const Text('Aceptar y entrar'),
              ),
              OutlinedButton(
                onPressed: _vm.respondiendo ? null : () => _rechazar(inv),
                child: const Text('Rechazar'),
              ),
            ] else ...[
              if (inv.estado == EstadoInvitacion.pendiente && !inv.esParaVos)
                FilledButton(onPressed: _entrarConOtraCuenta, child: const Text('Entrar con otra cuenta')),
              OutlinedButton(onPressed: irAlInicio, child: const Text('Ir al inicio')),
            ],
          ],
        ),
      ],
    );
  }

  // Por qué no se puede aceptar ni rechazar (null si se puede).
  String? _motivoSinRespuesta(InvitacionRecibida inv) {
    if (inv.yaSosMiembro) return 'Ya sos parte de ${inv.cuentaCompartidaNombre}.';
    return switch (inv.estado) {
      EstadoInvitacion.aceptada => 'Esta invitación ya fue aceptada.',
      EstadoInvitacion.rechazada => 'Esta invitación fue rechazada.',
      EstadoInvitacion.expirada => 'La invitación venció. Pedile a ${inv.invitadoPor} que te mande otra.',
      EstadoInvitacion.cancelada => 'La invitación fue cancelada.',
      EstadoInvitacion.pendiente => inv.esParaVos
          ? null
          : 'Esta invitación es para ${inv.emailInvitado}. Entrá con esa cuenta para aceptarla.',
    };
  }

  String _vence(DateTime fecha) {
    String dos(int n) => n.toString().padLeft(2, '0');
    final texto = '${dos(fecha.day)}/${dos(fecha.month)} a las ${dos(fecha.hour)}:${dos(fecha.minute)}';
    final falta = fecha.difference(DateTime.now());
    if (falta.isNegative) return 'Venció el $texto';
    if (falta.inHours >= 1) return '$texto (en ${falta.inHours} h)';
    return '$texto (en ${falta.inMinutes} min)';
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
