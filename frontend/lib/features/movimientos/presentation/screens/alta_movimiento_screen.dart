import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/core/widgets/aviso_en_linea.dart';
import 'package:frontend/core/widgets/aviso_exito.dart';
import 'package:frontend/core/widgets/barra_con_volver.dart';
import 'package:frontend/core/widgets/campo.dart';
import 'package:frontend/core/widgets/encabezado_pestana.dart';
import 'package:frontend/core/widgets/hoja.dart';
import 'package:frontend/core/widgets/selector_tipo.dart';
import 'package:frontend/features/categorias/data/datasources/categoria_api.dart';
import 'package:frontend/features/categorias/data/models/categoria.dart';
import 'package:frontend/features/categorias/presentation/widgets/formulario_categoria.dart';
import 'package:frontend/features/movimientos/data/datasources/movimiento_api.dart';
import 'package:frontend/features/movimientos/presentation/monto_formatter.dart';
import 'package:frontend/features/movimientos/presentation/viewmodels/alta_movimiento_view_model.dart';
import 'package:frontend/features/movimientos/presentation/widgets/caja_fecha.dart';
import 'package:frontend/features/movimientos/presentation/widgets/chip_categoria.dart';
import 'package:frontend/features/voice/voice_screen.dart';
import 'package:frontend/shared/utils/importe.dart';

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

  // Una hoja chica desde abajo, para no salir del movimiento. La categoría se crea en el momento,
  // con el tipo del movimiento, y queda elegida.
  Future<void> _nuevaCategoria() async {
    final creada = await mostrarHoja<Categoria>(
      context,
      titulo: 'Nueva categoría de ${_vm.esIngreso ? 'ingreso' : 'egreso'}',
      contenido: FormularioCategoria(esIngreso: _vm.esIngreso, tipoFijo: true),
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
    final colores = context.colores;
    final cuenta = cuentaActiva.value;
    return Scaffold(
      appBar: barraConVolver(context, 'Nuevo movimiento', subtitulo: nombreDeCuentaActiva()),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final error = _vm.error;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              SelectorTipo(esIngreso: _vm.esIngreso, alCambiar: _vm.cambiarTipo),
              _campoMonto(),
              _categorias(),
              Campo(
                etiqueta: 'Fecha',
                child: CajaFecha(fecha: _vm.fecha, alTocar: _elegirFecha),
              ),
              Campo(
                etiqueta: 'Descripción (opcional)',
                child: TextField(
                  controller: _descripcion,
                  inputFormatters: [LengthLimitingTextInputFormatter(255)],
                  decoration: const InputDecoration(hintText: 'Por ejemplo, el comercio'),
                ),
              ),
              if (cuenta != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: AvisoEnLinea(
                    'Se guarda en ${cuenta['nombre']} y lo ven todos.',
                    icono: Icons.group_outlined,
                  ),
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    error,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colores.coralTexto,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              FilledButton(
                onPressed: _vm.guardando ? null : _guardar,
                child: _vm.guardando
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: colores.sobrePrimario),
                      )
                    : const Text('Guardar'),
              ),
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VoiceScreen()),
                  ),
                  icon: const Icon(Icons.mic_none, size: 18),
                  label: const Text('Prefiero dictarlo'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // .grande de la maqueta: la pregunta arriba (en suave) y el monto en 44/800, centrado.
  Widget _campoMonto() {
    final colores = context.colores;
    final textos = Theme.of(context).textTheme;
    final error = _vm.errorMonto;
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 14),
      child: Column(
        children: [
          Text(
            // Con otra moneda elegida se aclara: lo que se carga son pesos (US-8.2).
            '${_vm.esIngreso ? 'Cuánto entró' : 'Cuánto gastaste'}${convierte ? ', en pesos' : ''}',
            style: textos.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: TextField(
              controller: _monto,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [MontoArgentinoFormatter()],
              style: textos.displayMedium,
              decoration: InputDecoration.collapsed(
                hintText: '\$ 0',
                hintStyle: textos.displayMedium?.copyWith(color: colores.suave),
              ),
            ),
          ),
          if (error != null)
            Text(
              error,
              textAlign: TextAlign.center,
              style: textos.bodySmall?.copyWith(color: colores.coralTexto, fontWeight: FontWeight.w600),
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
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final c in _vm.categoriasDelTipo)
            ChipCategoria(
              categoria: c,
              elegida: c.nombre == _vm.categoria,
              alTocar: () => _vm.elegirCategoria(c.nombre),
            ),
          ChipNuevaCategoria(alTocar: _nuevaCategoria),
        ],
      ),
    );
  }
}
