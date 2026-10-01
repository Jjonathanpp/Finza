import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/widgets/aviso_exito.dart';
import 'package:frontend/core/widgets/barra_con_volver.dart';
import 'package:frontend/core/widgets/campo.dart';
import 'package:frontend/core/widgets/selector_tipo.dart';
import 'package:frontend/features/categorias/data/datasources/categoria_api.dart';
import 'package:frontend/features/categorias/data/models/categoria.dart';
import 'package:frontend/features/categorias/presentation/widgets/formulario_categoria.dart';
import 'package:frontend/features/movimientos/data/datasources/movimiento_api.dart';
import 'package:frontend/features/movimientos/presentation/monto_formatter.dart';
import 'package:frontend/features/movimientos/presentation/viewmodels/alta_movimiento_view_model.dart';
import 'package:frontend/shared/utils/color_hex.dart';

class AltaMovimientoScreen extends StatefulWidget {
  const AltaMovimientoScreen({super.key});

  @override
  State<AltaMovimientoScreen> createState() => _AltaMovimientoScreenState();
}

class _AltaMovimientoScreenState extends State<AltaMovimientoScreen> {
  final _vm = AltaMovimientoViewModel(CategoriaApi(ApiClient()), MovimientoApi(ApiClient()));
  final _monto = TextEditingController();
  final _descripcion = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm.cargarCategorias();
  }

  @override
  void dispose() {
    _vm.dispose();
    _monto.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final creado = await _vm.guardar(monto: _monto.text, descripcion: _descripcion.text);
    if (creado == null || !mounted) return;
    mostrarExito(
      context,
      creado.esIngreso ? 'Ingreso registrado exitosamente' : 'Egreso registrado exitosamente',
    );
    _monto.clear();
    _descripcion.clear();
    _vm.limpiar();
  }

  // Un panel chico desde abajo, para no salir del movimiento. La categoría se crea en el momento,
  // con el tipo del movimiento, y queda elegida.
  Future<void> _nuevaCategoria() async {
    final creada = await showModalBottomSheet<Categoria>(
      context: context,
      isScrollControlled: true, // así el panel sube cuando aparece el teclado
      showDragHandle: true,
      builder: (context) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(18, 0, 18, 18 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nueva categoría de ${_vm.esIngreso ? 'ingreso' : 'egreso'}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            FormularioCategoria(esIngreso: _vm.esIngreso, tipoFijo: true),
          ],
        ),
      ),
    );
    if (creada != null) _vm.agregarCategoria(creada);
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _vm.fecha,
      firstDate: DateTime(hoy.year - 5),
      lastDate: hoy,
      // Escrita a mano, la app (todavía en inglés) la lee como mes/día/año: solo calendario.
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (elegida != null) _vm.cambiarFecha(elegida);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barraConVolver(context, 'Nuevo movimiento'),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final error = _vm.error;
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            children: [
              SelectorTipo(esIngreso: _vm.esIngreso, alCambiar: _vm.cambiarTipo),
              _campoMonto(),
              _categorias(),
              Campo(
                etiqueta: 'Fecha',
                child: InkWell(
                  onTap: _elegirFecha,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.calendar_today, size: 18)),
                    child: Text(_textoFecha(_vm.fecha)),
                  ),
                ),
              ),
              Campo(
                etiqueta: 'Descripción (opcional)',
                child: TextField(
                  controller: _descripcion,
                  inputFormatters: [LengthLimitingTextInputFormatter(255)],
                  decoration: const InputDecoration(hintText: 'Por ejemplo, el comercio'),
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(error, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
                ),
              FilledButton.icon(
                onPressed: _vm.guardando ? null : _guardar,
                icon: _vm.guardando
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: const Text('Registrar movimiento'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _campoMonto() {
    final error = _vm.errorMonto;
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('\$', style: TextStyle(fontSize: 24, color: AppColors.faint, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              SizedBox(
                width: 230,
                child: TextField(
                  controller: _monto,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [MontoArgentinoFormatter()],
                  style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration.collapsed(hintText: '0'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            error ?? (_vm.esIngreso ? 'Cuánto entró' : 'Cuánto gastaste'),
            style: TextStyle(fontSize: 12, color: error != null ? AppColors.danger : AppColors.faint),
          ),
        ],
      ),
    );
  }

  Widget _categorias() {
    return Campo(
      etiqueta: 'Categoría',
      error: _vm.errorCategoria,
      ayuda: 'Se muestran solo las categorías de ${_vm.esIngreso ? 'ingreso' : 'egreso'}.',
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          for (final c in _vm.categoriasDelTipo) _chip(c),
          ActionChip(
            avatar: const Icon(Icons.add, size: 16),
            label: const Text('Nueva'),
            onPressed: _nuevaCategoria,
            backgroundColor: AppColors.surface2,
            side: const BorderSide(color: AppColors.line),
            shape: const StadiumBorder(),
          ),
        ],
      ),
    );
  }

  // Las predefinidas llevan su emoji; las propias, un punto de su color.
  Widget _chip(Categoria categoria) {
    final seleccionado = categoria.nombre == _vm.categoria;
    return ChoiceChip(
      avatar: categoria.emoji != null
          ? Text(categoria.emoji!)
          : Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: colorDesdeHex(categoria.color), shape: BoxShape.circle),
            ),
      label: Text(categoria.nombre),
      selected: seleccionado,
      onSelected: (_) => _vm.elegirCategoria(categoria.nombre),
      showCheckmark: false,
      backgroundColor: AppColors.surface2,
      selectedColor: AppColors.accent.withValues(alpha: 0.12),
      side: BorderSide(color: seleccionado ? AppColors.accent : AppColors.line),
      labelStyle: TextStyle(
        color: seleccionado ? AppColors.accent : AppColors.muted,
        fontWeight: FontWeight.w600,
      ),
      shape: const StadiumBorder(),
    );
  }

  String _textoFecha(DateTime fecha) {
    final hoy = DateTime.now();
    if (fecha.year == hoy.year && fecha.month == hoy.month && fecha.day == hoy.day) return 'Hoy';
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year}';
  }
}
