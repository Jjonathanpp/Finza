import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/core/session/portero.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/core/widgets/avatar_inicial.dart';
import 'package:frontend/core/widgets/barra_con_volver.dart';
import 'package:frontend/core/widgets/chip_estado.dart';
import 'package:frontend/core/widgets/confirmar.dart';
import 'package:frontend/core/widgets/esqueleto.dart';
import 'package:frontend/core/widgets/fila_opcion.dart';
import 'package:frontend/core/widgets/hoja.dart';
import 'package:frontend/core/widgets/tarjeta.dart';
import 'package:frontend/core/widgets/titulo_seccion.dart';
import 'package:frontend/core/widgets/tocable.dart';
import 'package:frontend/features/cuentas_compartidas/data/datasources/cuenta_compartida_api.dart';
import 'package:frontend/features/cuentas_compartidas/data/models/miembro.dart';
import 'package:frontend/features/cuentas_compartidas/presentation/viewmodels/miembros_view_model.dart';
import 'package:frontend/features/lista-invitaciones/presentation/screens/lista_invitaciones_screen.dart';
import 'package:frontend/l10n/idioma.dart';

// Configuración → Cuenta → "Miembros y roles" (t-11.3.2): quiénes están en la cuenta
// compartida activa y con qué rol. Un admin toca el rol de otro para ascenderlo a
// administrador o pasarlo a miembro; los demás ven los roles, sin selector.
class MiembrosScreen extends StatefulWidget {
  const MiembrosScreen({super.key, required this.nombreCuenta, this.api});

  final String nombreCuenta;
  final CuentaCompartidaApi? api;

  @override
  State<MiembrosScreen> createState() => _MiembrosScreenState();
}

class _MiembrosScreenState extends State<MiembrosScreen> {
  late final _api = widget.api ?? CuentaCompartidaApi(ApiClient());
  late final _vm = MiembrosViewModel(
    _api,
    miPerfilId: cuentaActiva.value?['perfilId'] as int?,
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

  // Elegir el rol en la hoja ya es la confirmación: lista qué puede hacer cada uno.
  Future<void> _cambiarRol(Miembro miembro) async {
    final nuevoRol = await mostrarHoja<String>(
      context,
      titulo: context.tr('Cambiar el rol de {nombre}', {'nombre': miembro.nombre}),
      contenido: _HojaRol(rolActual: miembro.rol),
    );
    if (nuevoRol == null || nuevoRol == miembro.rol) return;

    final error = await _vm.cambiarRol(miembro, nuevoRol);
    if (!mounted) return;
    final c = context.colores;
    final texto = error ?? (nuevoRol == 'ADMIN' ? '${miembro.nombre} ahora es administrador' : '${miembro.nombre} ahora es miembro');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto, style: error != null ? TextStyle(color: c.coralTexto) : null),
        backgroundColor: error != null ? c.coralFondo : null,
      ),
    );
  }

  void _invitar() {
    final cuenta = cuentaActiva.value;
    final id = cuenta?['id'] as int?;
    if (id == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ListaInvitacionesScreen(cuentaCompartidaId: id)),
    );
  }

  bool _saliendo = false;

  // Salir (cualquiera) o eliminar la cuenta (el admin), con confirmación. Después la app vuelve a la
  // personal y al Inicio, como al elegirla en el selector.
  Future<void> _salirOEliminar({required bool eliminar}) async {
    final id = cuentaActiva.value?['id'] as int?;
    if (id == null) return;
    final datos = {'cuenta': widget.nombreCuenta};
    final ok = await confirmar(
      context,
      titulo: eliminar ? context.tr('¿Eliminar {cuenta}?', datos) : context.tr('¿Salir de {cuenta}?', datos),
      texto: eliminar
          ? context.tr('Se borran sus movimientos, presupuestos, metas y categorías para todos los integrantes. No se puede deshacer.')
          : context.tr('Ya no vas a ver sus movimientos, presupuestos ni metas. Si sos el último integrante, la cuenta se borra.'),
      textoAccion: eliminar ? context.tr('Eliminar') : context.tr('Salir'),
      peligro: true,
    );
    if (!ok || !mounted) return;
    setState(() => _saliendo = true);
    try {
      eliminar ? await _api.eliminar(id) : await _api.abandonar(id);
      await TokenStorage().guardarCuentaActiva(null);
      irAlInicio();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saliendo = false);
      final c = context.colores;
      final texto = e is ApiException ? e.message : context.tr('No pudimos completar la acción. Probá de nuevo.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(texto, style: TextStyle(color: c.coralTexto)), backgroundColor: c.coralFondo),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barraConVolver(context, context.tr('Miembros y roles'), subtitulo: widget.nombreCuenta),
      body: ListenableBuilder(listenable: _vm, builder: (context, _) => _contenido()),
    );
  }

  Widget _contenido() {
    if (_vm.cargando && _vm.miembros.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: EsqueletoLista(cantidad: 3),
      );
    }

    if (_vm.error != null && _vm.miembros.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              Text(_vm.error!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
              FilledButton(onPressed: _vm.cargar, child: Text(context.tr('Reintentar'))),
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
              const _QueHaceCadaRol(),
              TituloSeccion(context.tr('Integrantes · {cantidad}', {'cantidad': '${_vm.miembros.length}'})),
              TarjetaLista(
                children: [
                  for (final m in _vm.miembros)
                    _FilaMiembro(
                      miembro: m,
                      esVos: _vm.esVos(m),
                      editable: _vm.puedeCambiarRol(m),
                      cambiando: _vm.estaCambiando(m),
                      motivoNoEditable: _vm.motivoNoEditable(m),
                      alCambiarRol: () => _cambiarRol(m),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  _vm.soyAdmin
                      ? context.tr(
                          'Sos administrador: tocá el rol de alguien para cambiarlo. A quien creó la cuenta compartida no se le puede cambiar el rol, y nadie puede cambiar el suyo.',
                        )
                      : context.tr('Solo los administradores pueden cambiar los roles.'),
                  style: textos.bodySmall,
                ),
              ),
              if (_vm.soyAdmin)
                FilledButton.icon(
                  onPressed: _invitar,
                  icon: const Icon(Icons.mail_outline, size: 18),
                  label: Text(context.tr('Invitar a alguien')),
                ),
              // Al final y en coral: salir de la cuenta y, para el admin, eliminarla.
              const SizedBox(height: 12),
              FilledButton.icon(
                style: estiloBotonPeligro(context),
                onPressed: _saliendo ? null : () => _salirOEliminar(eliminar: false),
                icon: const Icon(Icons.logout, size: 18),
                label: Text(context.tr('Salir de {cuenta}', {'cuenta': widget.nombreCuenta})),
              ),
              if (_vm.soyAdmin)
                FilledButton.icon(
                  style: estiloBotonPeligro(context),
                  onPressed: _saliendo ? null : () => _salirOEliminar(eliminar: true),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(context.tr('Eliminar {cuenta}', {'cuenta': widget.nombreCuenta})),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ======================= PIEZAS =======================

// Arriba de la lista: qué puede hacer cada rol, para decidir antes de cambiarlo.
class _QueHaceCadaRol extends StatelessWidget {
  const _QueHaceCadaRol();

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(
            context.tr('Qué puede hacer cada rol'),
            style: textos.labelMedium?.copyWith(color: textos.bodySmall?.color),
          ),
          for (final (rol, detalle) in const [
            ('ADMIN', 'Invita personas, cambia roles, crea categorías y maneja los presupuestos de la cuenta.'),
            ('MIEMBRO', 'Ve y carga movimientos de la cuenta compartida.'),
          ])
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                _chipRol(rol),
                Expanded(child: Text(context.tr(detalle), style: textos.bodySmall)),
              ],
            ),
        ],
      ),
    );
  }
}

ChipEstado _chipRol(String rol, {bool chico = true}) {
  return rol == 'ADMIN'
      ? ChipEstado(tr('Admin'), TonoChip.menta, chico: chico)
      : ChipEstado(tr('Miembro'), TonoChip.hundido, chico: chico);
}

class _FilaMiembro extends StatelessWidget {
  const _FilaMiembro({
    required this.miembro,
    required this.esVos,
    required this.editable,
    required this.cambiando,
    required this.motivoNoEditable,
    required this.alCambiarRol,
  });

  final Miembro miembro;
  final bool esVos;
  final bool editable;
  final bool cambiando;
  final String? motivoNoEditable;
  final VoidCallback alCambiarRol;

  @override
  Widget build(BuildContext context) {
    final m = miembro;

    final Widget rol;
    if (cambiando) {
      rol = const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    } else if (editable) {
      rol = _ChipRolTocable(rol: m.rol, nombre: m.nombre, alTocar: alCambiarRol);
    } else {
      rol = Tooltip(message: motivoNoEditable ?? '', child: _chipRol(m.rol, chico: false));
    }

    return FilaOpcion(
      leading: AvatarInicial(
        m.nombre.characters.first,
        serie: esVos ? null : m.perfilId,
        tamano: 40,
      ),
      titulo: esVos ? '${m.nombre} (vos)' : m.nombre,
      subtitulo: m.esCreador
          ? context.tr('Creó la cuenta compartida')
          : (m.esAdmin ? context.tr('Administrador') : context.tr('Miembro')),
      trailing: rol,
    );
  }
}

// El chip de rol de alguien que se puede cambiar: con la flechita, abre la hoja "Cambiar rol". El chip
// mide 36 px de alto y el área táctil, 44.
class _ChipRolTocable extends StatelessWidget {
  const _ChipRolTocable({required this.rol, required this.nombre, required this.alTocar});

  final String rol;
  final String nombre;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final esAdmin = rol == 'ADMIN';
    final fondo = esAdmin ? c.menta : c.hundido;
    final color = esAdmin ? c.primario : c.texto;
    return Tocable(
      alTocar: alTocar,
      etiqueta: esAdmin
          ? context.tr('Cambiar el rol de {nombre}, ahora administrador', {'nombre': nombre})
          : context.tr('Cambiar el rol de {nombre}, ahora miembro', {'nombre': nombre}),
      child: SizedBox(
        height: 44,
        child: Center(
          child: Container(
            height: 36,
            padding: const EdgeInsets.only(left: 12, right: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(Radios.pastilla)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Text(
                  esAdmin ? context.tr('Admin') : context.tr('Miembro'),
                  maxLines: 1,
                  softWrap: false,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
                ),
                Icon(Icons.expand_more, size: 16, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// El contenido de la hoja "Cambiar rol": las dos opciones como radio y Cancelar / Guardar. Devuelve el rol
// elegido (o nada, si se cancela).
class _HojaRol extends StatefulWidget {
  const _HojaRol({required this.rolActual});

  final String rolActual;

  @override
  State<_HojaRol> createState() => _HojaRolState();
}

class _HojaRolState extends State<_HojaRol> {
  late String _elegido = widget.rolActual;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        _OpcionRol(
          titulo: context.tr('Administrador'),
          detalle: context.tr('Invita, cambia roles, crea categorías y maneja los presupuestos.'),
          activa: _elegido == 'ADMIN',
          alTocar: () => setState(() => _elegido = 'ADMIN'),
        ),
        _OpcionRol(
          titulo: context.tr('Miembro'),
          detalle: context.tr('Ve y carga movimientos.'),
          activa: _elegido == 'MIEMBRO',
          alTocar: () => setState(() => _elegido = 'MIEMBRO'),
        ),
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.tr('Cancelar'))),
            ),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_elegido),
                child: Text(context.tr('Guardar')),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// .opr de la maqueta: una opción con un radio, el título y qué puede hacer ese rol.
class _OpcionRol extends StatelessWidget {
  const _OpcionRol({required this.titulo, required this.detalle, required this.activa, required this.alTocar});

  final String titulo;
  final String detalle;
  final bool activa;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: activa,
      child: Tocable(
        alTocar: alTocar,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: activa ? c.menta : c.hundido,
            borderRadius: BorderRadius.circular(Radios.aviso),
            border: activa ? Border.all(color: c.primario, width: 2) : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: activa ? c.primario : c.suave, width: activa ? 6 : 2),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      titulo,
                      style: textos.bodyMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    Text(detalle, style: textos.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
