import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/features/cuentas_compartidas/data/datasources/cuenta_compartida_api.dart';
import 'package:frontend/features/cuentas_compartidas/data/models/miembro.dart';
import 'package:frontend/features/cuentas_compartidas/presentation/viewmodels/miembros_view_model.dart';

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
  late final _vm = MiembrosViewModel(
    widget.api ?? CuentaCompartidaApi(ApiClient()),
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

  // Confirmar antes: ascender da permisos de administrador, y bajar a miembro los saca.
  Future<void> _cambiarRol(Miembro miembro, String nuevoRol) async {
    final ascender = nuevoRol == 'ADMIN';
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ascender ? 'Hacer administrador' : 'Pasar a miembro'),
        content: Text(
          ascender
              ? '${miembro.nombre} va a poder invitar personas, cambiar roles y manejar los presupuestos de ${widget.nombreCuenta}.'
              : '${miembro.nombre} va a dejar de poder invitar, cambiar roles y manejar presupuestos. Va a seguir viendo y cargando movimientos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.muted),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ascender ? 'Hacer administrador' : 'Pasar a miembro'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    final error = await _vm.cambiarRol(miembro, nuevoRol);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? (ascender ? '${miembro.nombre} ahora es administrador' : '${miembro.nombre} ahora es miembro'),
        ),
        backgroundColor: error != null ? AppColors.danger : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Miembros y roles'),
            Text(widget.nombreCuenta, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) => _contenido(),
      ),
    );
  }

  Widget _contenido() {
    if (_vm.cargando && _vm.miembros.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_vm.error != null && _vm.miembros.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(_vm.error!, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: _vm.cargar, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _vm.cargar,
      color: AppColors.accent,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(18),
        children: [
          _Encabezado(
            soyAdmin: _vm.soyAdmin,
            admins: _vm.cantidadAdmins,
            miembros: _vm.cantidadMiembros,
          ),
          const SizedBox(height: 16),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 2))],
            ),
            child: Column(
              children: [
                for (final (i, m) in _vm.miembros.indexed) ...[
                  if (i > 0) const Divider(height: 1, indent: 66, color: AppColors.line),
                  _FilaMiembro(
                    miembro: m,
                    esVos: _vm.esVos(m),
                    editable: _vm.puedeCambiarRol(m),
                    cambiando: _vm.estaCambiando(m),
                    motivoNoEditable: _vm.motivoNoEditable(m),
                    alElegirRol: (rol) => _cambiarRol(m, rol),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _QueHaceCadaRol(),
        ],
      ),
    );
  }
}

// ======================= PIEZAS =======================

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.soyAdmin, required this.admins, required this.miembros});

  final bool soyAdmin;
  final int admins;
  final int miembros;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          soyAdmin
              ? 'Sos administrador: tocá el rol de alguien para cambiarlo.'
              : 'Solo los administradores pueden cambiar los roles.',
          style: const TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Contador(texto: '$admins ${admins == 1 ? 'administrador' : 'administradores'}', esAdmin: true),
            _Contador(texto: '$miembros ${miembros == 1 ? 'miembro' : 'miembros'}', esAdmin: false),
          ],
        ),
      ],
    );
  }
}

class _Contador extends StatelessWidget {
  const _Contador({required this.texto, required this.esAdmin});

  final String texto;
  final bool esAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: esAdmin ? AppColors.accent.withValues(alpha: 0.12) : AppColors.surface2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: esAdmin ? AppColors.text : AppColors.muted,
        ),
      ),
    );
  }
}

class _FilaMiembro extends StatelessWidget {
  const _FilaMiembro({
    required this.miembro,
    required this.esVos,
    required this.editable,
    required this.cambiando,
    required this.motivoNoEditable,
    required this.alElegirRol,
  });

  final Miembro miembro;
  final bool esVos;
  final bool editable;
  final bool cambiando;
  final String? motivoNoEditable;
  final ValueChanged<String> alElegirRol;

  @override
  Widget build(BuildContext context) {
    final m = miembro;
    final inicial = m.nombre.characters.first.toUpperCase();

    final Widget rol;
    if (cambiando) {
      rol = const Padding(
        padding: EdgeInsets.all(8),
        child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    } else if (editable) {
      rol = _SelectorRol(rolActual: m.rol, alElegir: alElegirRol);
    } else {
      rol = Tooltip(message: motivoNoEditable ?? '', child: _EtiquetaRol(rol: m.rol));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: m.esAdmin ? AppColors.accent.withValues(alpha: 0.15) : AppColors.surface2,
            child: Text(
              inicial,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: m.esAdmin ? AppColors.text : AppColors.muted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        m.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (esVos) ...[
                      const SizedBox(width: 6),
                      const _Marca('vos'),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  m.esCreador ? 'Creó la cuenta compartida' : (m.esAdmin ? 'Administrador' : 'Miembro'),
                  style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          rol,
        ],
      ),
    );
  }
}

// La etiqueta distintiva del rol. Con desplegable: muestra la flechita del selector.
class _EtiquetaRol extends StatelessWidget {
  const _EtiquetaRol({required this.rol, this.desplegable = false});

  final String rol;
  final bool desplegable;

  @override
  Widget build(BuildContext context) {
    final esAdmin = rol == 'ADMIN';
    final colorTexto = esAdmin ? AppColors.text : AppColors.muted;

    return Container(
      padding: EdgeInsets.fromLTRB(10, 5, desplegable ? 4 : 10, 5),
      decoration: BoxDecoration(
        color: esAdmin ? AppColors.accent.withValues(alpha: 0.15) : AppColors.surface2,
        borderRadius: BorderRadius.circular(999),
        border: desplegable ? Border.all(color: AppColors.line) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            esAdmin ? Icons.admin_panel_settings_outlined : Icons.person_outline,
            size: 15,
            color: colorTexto,
          ),
          const SizedBox(width: 4),
          Text(
            esAdmin ? 'Admin' : 'Miembro',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: colorTexto),
          ),
          if (desplegable) Icon(Icons.arrow_drop_down, size: 18, color: colorTexto),
        ],
      ),
    );
  }
}

// El selector de rol: la etiqueta con flechita abre un menú con las dos opciones.
class _SelectorRol extends StatelessWidget {
  const _SelectorRol({required this.rolActual, required this.alElegir});

  final String rolActual;
  final ValueChanged<String> alElegir;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Cambiar rol',
      initialValue: rolActual,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (rol) {
        if (rol != rolActual) alElegir(rol);
      },
      itemBuilder: (_) => [
        _opcion('ADMIN', 'Administrador', 'Invita, cambia roles y maneja presupuestos', Icons.admin_panel_settings_outlined),
        _opcion('MIEMBRO', 'Miembro', 'Ve y carga movimientos', Icons.person_outline),
      ],
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: _EtiquetaRol(rol: rolActual, desplegable: true),
      ),
    );
  }

  PopupMenuItem<String> _opcion(String valor, String titulo, String detalle, IconData icono) {
    final actual = valor == rolActual;
    return PopupMenuItem<String>(
      value: valor,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        leading: Icon(icono),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(detalle),
        trailing: actual ? const Icon(Icons.check, color: AppColors.accent) : null,
      ),
    );
  }
}

class _Marca extends StatelessWidget {
  const _Marca(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(texto, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.text)),
    );
  }
}

// Abajo de la lista: qué puede hacer cada rol, para decidir antes de cambiarlo.
class _QueHaceCadaRol extends StatelessWidget {
  const _QueHaceCadaRol();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUÉ PUEDE HACER CADA ROL',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.8),
        ),
        const SizedBox(height: 12),
        for (final (rol, detalle) in const [
          ('ADMIN', 'Invita personas, cambia roles, crea categorías y maneja los presupuestos de la cuenta.'),
          ('MIEMBRO', 'Ve y carga movimientos de la cuenta compartida.'),
        ]) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 96, child: Align(alignment: Alignment.centerLeft, child: _EtiquetaRol(rol: rol))),
              const SizedBox(width: 10),
              Expanded(
                child: Text(detalle, style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4)),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        const Text(
          'A quien creó la cuenta compartida no se le puede cambiar el rol, y nadie puede cambiar el suyo.',
          style: TextStyle(fontSize: 12.5, color: AppColors.faint, height: 1.4),
        ),
      ],
    );
  }
}