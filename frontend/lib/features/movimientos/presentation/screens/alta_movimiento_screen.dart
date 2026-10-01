import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/widgets/aviso_exito.dart';
import 'package:frontend/core/widgets/boton_icono.dart';
import 'package:frontend/features/categorias/data/datasources/categoria_api.dart';
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
    _vm.cargarCategorias(); // por si se creó una categoría nueva
  }

  Future<void> _nuevaCategoria() async {
    var escrito = '';
    final nombre = (await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva categoría'),
        content: TextField(
          autofocus: true,
          inputFormatters: [LengthLimitingTextInputFormatter(100)],
          decoration: const InputDecoration(
            hintText: 'Por ejemplo, Gimnasio',
            helperText: 'Se crea con el tipo del movimiento cuando lo registres.',
            helperMaxLines: 2,
          ),
          onChanged: (texto) => escrito = texto,
          onSubmitted: (texto) => Navigator.pop(context, texto),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, escrito), child: const Text('Usar')),
        ],
      ),
    ))
        ?.trim();
    if (nombre == null || nombre.isEmpty) return;
    // Si ya existe con otro uso de mayúsculas, se elige la que existe.
    final existente = _vm.categoriasDelTipo.where((c) => c.nombre.toLowerCase() == nombre.toLowerCase());
    _vm.elegirCategoria(existente.isEmpty ? nombre : existente.first.nombre);
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 18,
        title: Row(
          children: [
            BotonIcono(
              icono: Icons.arrow_back,
              tamanio: 34,
              ayuda: 'Volver',
              alTocar: () => Navigator.maybePop(context),
            ),
            const SizedBox(width: 12),
            const Text('Nuevo movimiento'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final error = _vm.error;
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            children: [
              _selectorTipo(),
              _campoMonto(),
              _categorias(),
              _Campo(
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
              _Campo(
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
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _selectorTipo() {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(value: true, label: Text('Ingreso')),
        ButtonSegment(value: false, label: Text('Egreso')),
      ],
      selected: {_vm.esIngreso},
      onSelectionChanged: (seleccion) => _vm.cambiarTipo(seleccion.first),
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      style: SegmentedButton.styleFrom(
        backgroundColor: AppColors.surface2,
        foregroundColor: AppColors.muted,
        selectedBackgroundColor: AppColors.surface,
        selectedForegroundColor: _vm.esIngreso ? AppColors.accent : AppColors.danger,
        side: const BorderSide(color: AppColors.line),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
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
    final elegida = _vm.categoria;
    final lista = _vm.categoriasDelTipo;
    final esNueva = elegida != null && !lista.any((c) => c.nombre == elegida);
    return _Campo(
      etiqueta: 'Categoría',
      error: _vm.errorCategoria,
      ayuda: esNueva
          ? '"$elegida" se crea cuando registres el movimiento.'
          : 'Se muestran solo las categorías de ${_vm.esIngreso ? 'ingreso' : 'egreso'}.',
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          for (final c in lista)
            _chip(
              c.nombre,
              seleccionado: c.nombre == elegida,
              icono: c.emoji != null ? Text(c.emoji!) : _punto(colorDesdeHex(c.color)),
            ),
          if (esNueva) _chip(elegida, seleccionado: true, icono: _punto(AppColors.faint)),
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

  Widget _chip(String nombre, {required bool seleccionado, required Widget icono}) {
    return ChoiceChip(
      avatar: icono,
      label: Text(nombre),
      selected: seleccionado,
      onSelected: (_) => _vm.elegirCategoria(nombre),
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

  Widget _punto(Color color) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  String _textoFecha(DateTime fecha) {
    final hoy = DateTime.now();
    if (fecha.year == hoy.year && fecha.month == hoy.month && fecha.day == hoy.day) return 'Hoy';
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year}';
  }
}

// Una etiqueta arriba, el campo, y abajo el error o una ayuda.
class _Campo extends StatelessWidget {
  const _Campo({required this.etiqueta, required this.child, this.error, this.ayuda});

  final String etiqueta;
  final Widget child;
  final String? error;
  final String? ayuda;

  @override
  Widget build(BuildContext context) {
    final abajo = error ?? ayuda;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
          const SizedBox(height: 6),
          child,
          if (abajo != null)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                abajo,
                style: TextStyle(fontSize: 11.5, color: error != null ? AppColors.danger : AppColors.faint),
              ),
            ),
        ],
      ),
    );
  }
}
