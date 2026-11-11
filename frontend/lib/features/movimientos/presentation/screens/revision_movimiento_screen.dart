import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/widgets/aviso_en_linea.dart';
import 'package:frontend/core/widgets/barra_con_volver.dart';
import 'package:frontend/core/widgets/boton_peligro.dart';
import 'package:frontend/core/widgets/campo.dart';
import 'package:frontend/core/widgets/selector_tipo.dart';
import 'package:frontend/features/categorias/data/datasources/categoria_api.dart';
import 'package:frontend/features/movimientos/data/datasources/movimiento_api.dart';
import 'package:frontend/features/movimientos/data/models/movimiento.dart';
import 'package:frontend/features/movimientos/presentation/monto_formatter.dart';
import 'package:frontend/features/movimientos/presentation/viewmodels/revision_movimiento_view_model.dart';
import 'package:frontend/features/movimientos/presentation/widgets/caja_fecha.dart';
import 'package:frontend/features/movimientos/presentation/widgets/chip_categoria.dart';
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

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _vm.fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (elegida != null) _vm.cambiarFecha(elegida);
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Scaffold(
      appBar: barraConVolver(context, 'Revisá antes de guardar', subtitulo: 'Completado por la IA'),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              const AvisoEnLinea(
                'La IA completó estos datos. Cambiá lo que no esté bien y confirmá.',
                icono: Icons.check,
                verde: true,
              ),
              const SizedBox(height: 14),
              SelectorTipo(esIngreso: _vm.esIngreso, alCambiar: _vm.cambiarTipo),
              const SizedBox(height: 14),
              Campo(
                etiqueta: 'Monto',
                error: _vm.errorMonto,
                // Con otra moneda elegida se aclara: lo que se carga son pesos (US-8.2).
                ayuda: convierte ? 'En pesos' : null,
                child: TextField(
                  controller: _monto,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [MontoArgentinoFormatter()],
                  decoration: const InputDecoration(prefixText: '\$ ', hintText: '0'),
                ),
              ),
              _categorias(),
              Campo(
                etiqueta: 'Fecha',
                child: CajaFecha(fecha: _vm.fecha, alTocar: _elegirFecha),
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
                  child: Text(
                    _vm.error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colores.coralTexto,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              _botonesAccion(),
            ],
          );
        },
      ),
    );
  }

  Widget _categorias() {
    return Campo(
      etiqueta: 'Categoría',
      error: _vm.errorCategoria,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final c in _vm.categoriasDelTipo)
            ChipCategoria(
              categoria: c,
              elegida: c.nombre == _vm.categoria,
              alTocar: () => _vm.elegirCategoria(c.nombre),
            ),
        ],
      ),
    );
  }

  // .acciones de la maqueta: dos botones de igual ancho, 8 de separación.
  Widget _botonesAccion() {
    return Row(
      spacing: 8,
      children: [
        Expanded(
          child: FilledButton(
            onPressed: _vm.cargando ? null : _descartar,
            style: estiloBotonPeligro(context),
            child: const Text('Descartar'),
          ),
        ),
        Expanded(
          child: FilledButton(
            onPressed: _vm.cargando ? null : _confirmar,
            child: _vm.cargando
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: context.colores.sobrePrimario),
                  )
                : const Text('Confirmar'),
          ),
        ),
      ],
    );
  }
}
