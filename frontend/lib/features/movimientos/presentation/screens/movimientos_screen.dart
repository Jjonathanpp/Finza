import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/core/widgets/boton_icono.dart';
import 'package:frontend/core/widgets/chip_estado.dart';
import 'package:frontend/core/widgets/circulo_categoria.dart';
import 'package:frontend/core/widgets/confirmar.dart';
import 'package:frontend/core/widgets/encabezado_pestana.dart';
import 'package:frontend/core/widgets/esqueleto.dart';
import 'package:frontend/core/widgets/fila_opcion.dart';
import 'package:frontend/core/widgets/filtro_pastilla.dart';
import 'package:frontend/core/widgets/hoja.dart';
import 'package:frontend/core/widgets/monto.dart';
import 'package:frontend/features/categorias/data/datasources/categoria_api.dart';
import 'package:frontend/features/movimientos/data/datasources/movimiento_api.dart';
import 'package:frontend/features/movimientos/data/models/movimiento.dart';
import 'package:frontend/features/movimientos/presentation/screens/revision_movimiento_screen.dart';
import 'package:frontend/features/movimientos/presentation/viewmodels/movimientos_view_model.dart';
import 'package:frontend/features/movimientos/presentation/widgets/controles_paginacion.dart';
import 'package:frontend/features/movimientos/presentation/widgets/grupos_de_movimientos.dart';
import 'package:frontend/features/movimientos/presentation/widgets/hoja_edicion_movimiento.dart';
import 'package:frontend/features/movimientos/presentation/widgets/hoja_filtros_movimientos.dart';

enum _Accion { editar, eliminar }

class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({super.key});

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  late final _vm = MovimientosViewModel(
    MovimientoApi(ApiClient()),
    CategoriaApi(ApiClient()),
  );

  // Hasta que termina la primera carga todavía no se sabe si hay movimientos: se ve el esqueleto.
  bool _primeraCarga = true;

  @override
  void initState() {
    super.initState();
    _vm.cargarInicial().whenComplete(() {
      if (mounted) setState(() => _primeraCarga = false);
    });
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _abrirFiltros() {
    mostrarHoja<void>(
      context,
      titulo: 'Filtrar movimientos',
      contenido: HojaFiltrosMovimientos(vm: _vm),
    );
  }

  // Tipo, estado e integrante van en las pastillas: cada una cambia lo suyo y conserva el resto.
  void _filtrar({bool? esIngreso, String? estado, int? perfilId}) {
    _vm.aplicarFiltros(
      nuevoDesde: _vm.desde,
      nuevoHasta: _vm.hasta,
      nuevaCategoria: _vm.categoriaFiltro,
      nuevoEsIngreso: esIngreso,
      nuevoEstado: estado,
      nuevoPerfilId: perfilId,
    );
  }

  Future<void> _revisarMovimiento(Movimiento movimientoPendiente) async {
    final modificado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RevisionMovimientoScreen(movimiento: movimientoPendiente),
      ),
    );

    // Solo recargamos si guardó o descartó (retorna true)
    if (modificado == true) {
      _vm.cargarInicial();
    }
  }

  // Al tocar un movimiento propio: elegir qué hacer con él.
  Future<void> _abrirAcciones(Movimiento m) async {
    final c = context.colores;
    final accion = await mostrarHoja<_Accion>(
      context,
      titulo: m.categoria.nombre,
      texto: Monto.texto(m.monto, ingreso: m.esIngreso),
      contenido: Builder(
        builder: (contexto) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilaOpcion(
              titulo: 'Editar',
              leading: CirculoCategoria(
                icono: Icons.edit_outlined,
                color: c.primario,
                fondo: c.menta,
              ),
              alTocar: () => Navigator.pop(contexto, _Accion.editar),
            ),
            FilaOpcion(
              titulo: 'Eliminar',
              colorTitulo: c.coralTexto,
              leading: CirculoCategoria(
                icono: Icons.delete_outline,
                color: c.coralTexto,
                fondo: c.coralFondo,
              ),
              alTocar: () => Navigator.pop(contexto, _Accion.eliminar),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (accion) {
      case _Accion.editar:
        await _mostrarEdicion(m);
      case _Accion.eliminar:
        await _confirmarEliminar(m);
      case null:
        break;
    }
  }

  Future<void> _confirmarEliminar(Movimiento m) async {
    final confirmado = await confirmar(
      context,
      titulo: 'Eliminar movimiento',
      texto: '¿Estás seguro de eliminar este movimiento?',
      textoAccion: 'Eliminar',
      peligro: true,
    );

    if (!confirmado) return;

    final error = await _vm.eliminar(m);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      _avisoDeResultado(error ?? 'Movimiento eliminado', esError: error != null),
    );
  }

  Future<void> _mostrarEdicion(Movimiento movimiento) async {
    final resultado = await mostrarHoja<({String? error})>(
      context,
      titulo: 'Editar movimiento',
      contenido: HojaEdicionMovimiento(
        movimiento: movimiento,
        alGuardar:
            ({
              required esIngreso,
              required monto,
              required categoria,
              required descripcion,
              required fecha,
            }) => _vm.editar(
              movimiento,
              esIngreso: esIngreso,
              monto: monto,
              categoria: categoria,
              descripcion: descripcion,
              fecha: fecha,
              origen: movimiento.origen,
            ),
      ),
    );
    if (resultado == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      _avisoDeResultado(
        resultado.error ?? 'Movimiento actualizado con éxito',
        esError: resultado.error != null,
      ),
    );
  }

  // Los errores se ven en coral; los éxitos, con el estilo común del SnackBar.
  SnackBar _avisoDeResultado(String texto, {required bool esError}) {
    final c = context.colores;
    return SnackBar(
      backgroundColor: esError ? c.coralFondo : null,
      content: Text(
        texto,
        style: esError ? TextStyle(color: c.coralTexto) : null,
      ),
    );
  }

  // Un movimiento ajeno no se toca; uno pendiente se revisa; uno confirmado se edita o se elimina.
  VoidCallback? _alTocarDe(Movimiento m) {
    if (esMovimientoAjeno(m)) return null;
    if (m.estado == 'PENDIENTE') return () => _revisarMovimiento(m);
    return () => _abrirAcciones(m);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ListenableBuilder(
            listenable: _vm,
            builder: (context, _) {
              // Fechas y categoría son lo único que vive en la hoja; el resto se ve en las pastillas.
              final conFiltrosDeLaHoja =
                  _vm.desde != null ||
                  _vm.hasta != null ||
                  _vm.categoriaFiltro != null;
              return EncabezadoPestana(
                titulo: 'Movimientos',
                acciones: [
                  BotonIcono(
                    icono: conFiltrosDeLaHoja
                        ? Icons.filter_alt
                        : Icons.filter_alt_outlined,
                    ayuda: 'Filtrar',
                    alTocar: _abrirFiltros,
                  ),
                ],
              );
            },
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _vm,
              builder: (context, _) => _cuerpo(context),
            ),
          ),
          ListenableBuilder(
            listenable: _vm,
            builder: (context, _) => ControlesPaginacion(vm: _vm),
          ),
        ],
      ),
    );
  }

  Widget _cuerpo(BuildContext context) {
    final lista = _vm.movimientos;
    final cargandoLista = _primeraCarga || (_vm.cargando && lista.isEmpty);
    final conError = _vm.error != null && lista.isEmpty && !cargandoLista;

    final Widget contenido;
    if (cargandoLista) {
      contenido = const EsqueletoLista();
    } else if (conError) {
      contenido = _VistaError(
        mensaje: _vm.error!,
        alReintentar: _vm.cargarInicial,
      );
    } else if (lista.isEmpty) {
      contenido = _SinResultados(
        conFiltros: _vm.tieneFiltrosActivos,
        alLimpiarFiltros: _vm.limpiarFiltros,
      );
    } else {
      contenido = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          GruposDeMovimientos(
            movimientos: lista,
            mostrarAutor: _vm.mostrarAutor,
            alTocarDe: _alTocarDe,
          ),
        ],
      );
    }

    return Column(
      children: [
        // Recarga con la lista ya visible (paginar, filtrar): barra fina arriba.
        if (_vm.cargando && lista.isNotEmpty)
          const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _vm.cargarInicial,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    _CuentaYRol(),
                    _pastillasDeTipo(),
                    ?_pastillasDeAutor(),
                    contenido,
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // .filtros "Qué ver": Todos, Gastos, Ingresos, Por revisar.
  Widget _pastillasDeTipo() {
    final sinEstado = _vm.estadoFiltro == null;
    final todos = _vm.esIngresoFiltro == null && sinEstado;
    return FilaFiltros(
      etiqueta: 'Qué ver',
      children: [
        FiltroPastilla(
          texto: 'Todos',
          activo: todos,
          alTocar: () => _filtrar(perfilId: _vm.perfilFiltroId),
        ),
        FiltroPastilla(
          texto: 'Gastos',
          activo: _vm.esIngresoFiltro == false && sinEstado,
          alTocar: () => _filtrar(esIngreso: false, perfilId: _vm.perfilFiltroId),
        ),
        FiltroPastilla(
          texto: 'Ingresos',
          activo: _vm.esIngresoFiltro == true && sinEstado,
          alTocar: () => _filtrar(esIngreso: true, perfilId: _vm.perfilFiltroId),
        ),
        FiltroPastilla(
          texto: 'Por revisar',
          activo: !sinEstado,
          ambar: true,
          alTocar: () => _filtrar(estado: 'PENDIENTE', perfilId: _vm.perfilFiltroId),
        ),
      ],
    );
  }

  // .filtros "De quién": solo en una cuenta compartida, con los integrantes que trae el backend.
  Widget? _pastillasDeAutor() {
    if (!_vm.enCuentaCompartida || _vm.perfilesDisponibles.isEmpty) return null;
    final miPerfil = cuentaActiva.value?['perfilId'];
    void elegir(int? perfilId) =>
        _filtrar(esIngreso: _vm.esIngresoFiltro, estado: _vm.estadoFiltro, perfilId: perfilId);
    return FilaFiltros(
      etiqueta: 'De quién',
      children: [
        FiltroPastilla(
          texto: 'De todos',
          activo: _vm.perfilFiltroId == null,
          alTocar: () => elegir(null),
        ),
        for (final p in _vm.perfilesDisponibles)
          FiltroPastilla(
            texto: p.id == miPerfil ? 'Solo míos' : 'De ${nombreCortoPerfil(p.nombre)}',
            activo: _vm.perfilFiltroId == p.id,
            alTocar: () => elegir(p.id),
          ),
      ],
    );
  }
}

// .ctas: el chip de la cuenta y, si es compartida, qué rol tiene el usuario en ella.
class _CuentaYRol extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: cuentaActiva,
      builder: (context, cuenta, _) {
        final admin = cuenta?['rol'] == 'ADMIN';
        return Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const ChipCuenta(),
            if (cuenta != null)
              ChipEstado(
                admin ? 'Sos administrador' : 'Sos miembro',
                admin ? TonoChip.menta : TonoChip.hundido,
              ),
          ],
        );
      },
    );
  }
}

// Un filtro (o la cuenta) sin movimientos: una línea, y para sacar los filtros si hay alguno puesto.
class _SinResultados extends StatelessWidget {
  const _SinResultados({
    required this.conFiltros,
    required this.alLimpiarFiltros,
  });

  final bool conFiltros;
  final VoidCallback alLimpiarFiltros;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        spacing: 4,
        children: [
          Text(
            conFiltros
                ? 'No hay movimientos con este filtro.'
                : 'No hay movimientos registrados en la cuenta.',
            textAlign: TextAlign.center,
            style: textos.bodyMedium?.copyWith(color: textos.bodySmall?.color),
          ),
          if (conFiltros)
            TextButton(
              onPressed: alLimpiarFiltros,
              child: const Text('Limpiar filtros'),
            ),
        ],
      ),
    );
  }
}

class _VistaError extends StatelessWidget {
  const _VistaError({required this.mensaje, required this.alReintentar});

  final String mensaje;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: textos.bodyMedium?.copyWith(color: textos.bodySmall?.color),
          ),
          OutlinedButton(
            onPressed: alReintentar,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
