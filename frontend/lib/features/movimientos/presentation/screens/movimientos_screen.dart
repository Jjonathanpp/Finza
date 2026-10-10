import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/widgets/app_drawer.dart';
import 'package:frontend/features/categorias/data/datasources/categoria_api.dart';
import 'package:frontend/features/categorias/data/models/categoria.dart';
import 'package:frontend/features/movimientos/data/datasources/movimiento_api.dart';
import 'package:frontend/features/movimientos/data/models/movimiento.dart';
import 'package:frontend/features/movimientos/presentation/viewmodels/movimientos_view_model.dart';
import 'package:frontend/shared/utils/color_hex.dart';

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

  @override
  void initState() {
    super.initState();
    _vm.cargarInicial();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _abrirFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PanelFiltros(vm: _vm),
    );
  }

  Future<void> _confirmarEliminar(Movimiento m) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content: const Text('¿Estás seguro de eliminar este movimiento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    final error = await _vm.eliminar(m);
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Movimiento eliminado')));
    }
  }

  void _mostrarModalEdicion(BuildContext context, Movimiento movimiento) {
    final montoController = TextEditingController(
      text: movimiento.monto.toString(),
    );
    final descripcionController = TextEditingController(
      text: movimiento.descripcion ?? '',
    );
    final categoriaController = TextEditingController(
      text: movimiento.categoria.nombre,
    );

    bool esIngresoEdit = movimiento.esIngreso;
    DateTime fechaEdit = movimiento.fecha;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          return AlertDialog(
            title: const Text('Editar Movimiento'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tipo de movimiento',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(value: false, label: Text('Egreso')),
                      ButtonSegment<bool>(value: true, label: Text('Ingreso')),
                    ],
                    selected: {esIngresoEdit},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setStateModal(() {
                        esIngresoEdit = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: montoController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Monto'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: categoriaController,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Fecha: ${fechaEdit.day.toString().padLeft(2, '0')}/${fechaEdit.month.toString().padLeft(2, '0')}/${fechaEdit.year}',
                          style: const TextStyle(color: AppColors.text),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: fechaEdit,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setStateModal(() {
                              fechaEdit = picked;
                            });
                          }
                        },
                        child: const Text('Cambiar fecha'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descripcionController,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () async {
                  final error = await _vm.editar(
                    movimiento,
                    esIngreso: esIngresoEdit,
                    monto: montoController.text,
                    categoria: categoriaController.text,
                    descripcion: descripcionController.text,
                    fecha: fechaEdit,
                    origen: movimiento.origen,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    if (error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Movimiento actualizado con éxito'),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos'),
        actions: [
          ListenableBuilder(
            listenable: _vm,
            builder: (context, _) {
              return IconButton(
                icon: Icon(
                  _vm.tieneFiltrosActivos
                      ? Icons.filter_alt
                      : Icons.filter_alt_outlined,
                  color: _vm.tieneFiltrosActivos ? AppColors.accent : null,
                ),
                onPressed: _abrirFiltros,
                tooltip: 'Filtrar',
              );
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          if (_vm.cargando && _vm.movimientos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_vm.error != null && _vm.movimientos.isEmpty) {
            return _VistaError(
              mensaje: _vm.error!,
              alReintentar: _vm.cargarInicial,
            );
          }

          if (_vm.movimientos.isEmpty) {
            return const Center(
              child: Text(
                'No se encontraron movimientos',
                style: TextStyle(color: AppColors.muted),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _vm.cargarInicial,
                  color: AppColors.accent,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(18),
                    itemCount: _vm.movimientos.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: AppColors.line, height: 24),
                    itemBuilder: (context, i) {
                      final movimiento = _vm.movimientos[i];
                      return _FilaMovimiento(
                        movimiento,
                        onEditar: () =>
                            _mostrarModalEdicion(context, movimiento),
                        onEliminar: () => _confirmarEliminar(movimiento),
                      );
                    },
                  ),
                ),
              ),
              _ControlesPaginacion(vm: _vm),
            ],
          );
        },
      ),
    );
  }
}

// ======================= PANEL DE FILTROS =======================
class _PanelFiltros extends StatefulWidget {
  const _PanelFiltros({required this.vm});
  final MovimientosViewModel vm;

  @override
  State<_PanelFiltros> createState() => _PanelFiltrosState();
}

class _PanelFiltrosState extends State<_PanelFiltros> {
  DateTime? desde;
  DateTime? hasta;
  Categoria? categoriaSeleccionada;
  bool? esIngreso;

  @override
  void initState() {
    super.initState();
    desde = widget.vm.desde;
    hasta = widget.vm.hasta;
    categoriaSeleccionada = widget.vm.categoriaFiltro;
    esIngreso = widget.vm.esIngresoFiltro;
  }

  Future<void> _elegirFecha(bool esDesde) async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: (esDesde ? desde : hasta) ?? hoy,
      firstDate: DateTime(hoy.year - 5),
      lastDate: hoy,
    );
    if (elegida != null) {
      setState(() {
        if (esDesde)
          desde = elegida;
        else
          hasta = elegida;
      });
    }
  }

  String _textoFecha(DateTime? f) {
    if (f == null) return 'Seleccionar';
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(f.day)}/${dos(f.month)}/${f.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        18,
        0,
        18,
        18 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Filtrar movimientos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Desde',
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      onPressed: () => _elegirFecha(true),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(_textoFecha(desde)),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hasta',
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      onPressed: () => _elegirFecha(false),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(_textoFecha(hasta)),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Text(
            'Categoría',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<Categoria>(
            value: categoriaSeleccionada,
            hint: const Text('Todas las categorías'),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
            ),
            items: [
              const DropdownMenuItem<Categoria>(
                value: null,
                child: Text('Todas las categorías'),
              ),
              ...widget.vm.categorias.map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text('${c.emoji ?? ''} ${c.nombre}'),
                ),
              ),
            ],
            onChanged: (cat) => setState(() => categoriaSeleccionada = cat),
          ),
          const SizedBox(height: 20),

          const Text(
            'Tipo',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilterChip(
                label: const Text('Ingresos'),
                selected: esIngreso == true,
                onSelected: (val) =>
                    setState(() => esIngreso = val ? true : null),
              ),
              const SizedBox(width: 12),
              FilterChip(
                label: const Text('Egresos'),
                selected: esIngreso == false,
                onSelected: (val) =>
                    setState(() => esIngreso = val ? false : null),
              ),
            ],
          ),

          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    widget.vm.limpiarFiltros();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Limpiar',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () {
                    widget.vm.aplicarFiltros(
                      nuevoDesde: desde,
                      nuevoHasta: hasta,
                      nuevaCategoria: categoriaSeleccionada,
                      nuevoEsIngreso: esIngreso,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Aplicar filtros'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ======================= COMPONENTES DE VISTA =======================
class _ControlesPaginacion extends StatelessWidget {
  const _ControlesPaginacion({required this.vm});
  final MovimientosViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: vm.hayAnterior && !vm.cargando
                ? vm.paginaAnterior
                : null,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Anterior',
          ),
          if (vm.cargando)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(vm.totalPaginas, (index) {
                    final pagina = index + 1;
                    final esActual = pagina == vm.paginaActual;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: esActual ? null : () => vm.irAPagina(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: esActual
                                ? AppColors.accent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$pagina',
                            style: TextStyle(
                              color: esActual
                                  ? AppColors.surface
                                  : AppColors.text,
                              fontWeight: esActual
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          IconButton(
            onPressed: vm.hayMas && !vm.cargando ? vm.paginaSiguiente : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Siguiente',
          ),
        ],
      ),
    );
  }
}

class _FilaMovimiento extends StatelessWidget {
  const _FilaMovimiento(
    this.movimiento, {
    required this.onEditar,
    required this.onEliminar,
  });

  final Movimiento movimiento;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  String _formatearMonto(double monto) {
    final partes = monto.toStringAsFixed(2).split('.');
    final entero = partes[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => '.',
    );
    return '\$ $entero,${partes[1]}';
  }

  String _formatearFecha(DateTime fecha) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorCategoria = colorDesdeHex(movimiento.categoria.color);
    final colorMonto = movimiento.esIngreso ? AppColors.accent : AppColors.text;
    final signo = movimiento.esIngreso ? '+' : '-';

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorCategoria.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            movimiento.categoria.emoji ??
                movimiento.categoria.nombre.characters.first.toUpperCase(),
            style: TextStyle(
              fontSize: 20,
              color: colorCategoria,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                movimiento.categoria.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                movimiento.descripcion?.isNotEmpty == true
                    ? movimiento.descripcion!
                    : _formatearFecha(movimiento.fecha),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.faint),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$signo ${_formatearMonto(movimiento.monto)}',
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: colorMonto,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(
            Icons.edit_outlined,
            size: 20,
            color: AppColors.muted,
          ),
          onPressed: onEditar,
          tooltip: 'Editar movimiento',
        ),
        IconButton(
          icon: const Icon(
            Icons.delete_outline,
            size: 20,
            color: AppColors.danger,
          ),
          onPressed: onEliminar,
          tooltip: 'Eliminar movimiento',
        ),
      ],
    );
  }
}

class _VistaError extends StatelessWidget {
  const _VistaError({required this.mensaje, required this.alReintentar});
  final String mensaje;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
          const SizedBox(height: 16),
          Text(mensaje, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: alReintentar,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
