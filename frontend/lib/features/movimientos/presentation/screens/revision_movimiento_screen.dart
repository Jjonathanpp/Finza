import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/widgets/barra_con_volver.dart';
import 'package:frontend/core/widgets/campo.dart';
import 'package:frontend/core/widgets/selector_tipo.dart';
import 'package:frontend/features/categorias/data/datasources/categoria_api.dart';
import 'package:frontend/features/movimientos/data/datasources/movimiento_api.dart';
import 'package:frontend/features/movimientos/data/models/movimiento.dart';
import 'package:frontend/features/movimientos/presentation/monto_formatter.dart';
import 'package:frontend/features/movimientos/presentation/viewmodels/revision_movimiento_view_model.dart';
import 'package:frontend/shared/utils/color_hex.dart';
import 'package:frontend/shared/utils/importe.dart';

class RevisionMovimientoScreen extends StatefulWidget {
  const RevisionMovimientoScreen({super.key, required this.movimiento});
  final Movimiento movimiento;

  @override
  State<RevisionMovimientoScreen> createState() => _RevisionMovimientoScreenState();
}

class _RevisionMovimientoScreenState extends State<RevisionMovimientoScreen> {
  late final RevisionMovimientoViewModel _vm;
  late final TextEditingController _monto;
  late final TextEditingController _descripcion;

  @override
  void initState() {
    super.initState();
    _vm = RevisionMovimientoViewModel(widget.movimiento, CategoriaApi(ApiClient()), MovimientoApi(ApiClient()));
    
    // Precargamos los datos inferidos por la IA[cite: 12]
    _monto = TextEditingController(text: widget.movimiento.monto.toStringAsFixed(2).replaceAll('.', ','));
    _descripcion = TextEditingController(text: widget.movimiento.descripcion ?? '');
    
    _vm.cargarCategorias();
  }

  @override
  void dispose() {
    _vm.dispose();
    _monto.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final exito = await _vm.confirmar(monto: _monto.text, descripcion: _descripcion.text);
    if (exito && mounted) {
      Navigator.pop(context, true); // Retorna true para refrescar la lista
    }
  }

  Future<void> _descartar() async {
    final exito = await _vm.descartar();
    if (exito && mounted) {
      Navigator.pop(context, true); // Retorna true para refrescar la lista
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barraConVolver(context, 'Revisar Inferencia'),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              _bannerInferencia(),
              const SizedBox(height: 20),
              SelectorTipo(esIngreso: _vm.esIngreso, alCambiar: _vm.cambiarTipo),
              _campoMonto(),
              _categorias(),
              Campo(
                etiqueta: 'Fecha',
                child: InkWell(
                  onTap: () async {
                    final elegida = await showDatePicker(
                      context: context,
                      initialDate: _vm.fecha,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (elegida != null) _vm.cambiarFecha(elegida);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.calendar_today, size: 18)),
                    child: Text('${_vm.fecha.day}/${_vm.fecha.month}/${_vm.fecha.year}'),
                  ),
                ),
              ),
              Campo(
                etiqueta: 'Descripción',
                child: TextField(
                  controller: _descripcion,
                  inputFormatters: [LengthLimitingTextInputFormatter(255)],
                ),
              ),
              if (_vm.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(_vm.error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                ),
              const SizedBox(height: 12),
              _botonesAccion(),
            ],
          );
        },
      ),
    );
  }

  Widget _bannerInferencia() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome, color: AppColors.accent),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Revisá y ajustá los datos inferidos por la IA antes de confirmar la transacción.',
              style: TextStyle(fontSize: 13, color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campoMonto() {
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
          if (_vm.errorMonto != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_vm.errorMonto!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            )
          // Con otra moneda elegida se aclara: lo que se carga son pesos (US-8.2).
          else if (convierte)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('En pesos', style: TextStyle(color: AppColors.faint, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _categorias() {
    return Campo(
      etiqueta: 'Categoría',
      error: _vm.errorCategoria,
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: _vm.categoriasDelTipo.map((c) {
          final seleccionado = c.nombre == _vm.categoria;
          return ChoiceChip(
            label: Text('${c.emoji ?? ''} ${c.nombre}'),
            selected: seleccionado,
            onSelected: (_) => _vm.elegirCategoria(c.nombre),
            backgroundColor: AppColors.surface2,
            selectedColor: AppColors.accent.withValues(alpha: 0.12),
            side: BorderSide(color: seleccionado ? AppColors.accent : AppColors.line),
          );
        }).toList(),
      ),
    );
  }

  Widget _botonesAccion() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _vm.cargando ? null : _descartar,
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            label: const Text('Descartar', style: TextStyle(color: AppColors.danger)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: _vm.cargando ? null : _confirmar,
            icon: _vm.cargando 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check),
            label: const Text('Confirmar'),
          ),
        ),
      ],
    );
  }
}