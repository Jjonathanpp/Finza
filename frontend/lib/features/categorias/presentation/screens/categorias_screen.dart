import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/core/widgets/aviso_en_linea.dart';
import 'package:frontend/core/widgets/aviso_exito.dart';
import 'package:frontend/core/widgets/barra_con_volver.dart';
import 'package:frontend/core/widgets/boton_icono.dart';
import 'package:frontend/core/widgets/chip_estado.dart';
import 'package:frontend/core/widgets/circulo_categoria.dart';
import 'package:frontend/core/widgets/confirmar.dart';
import 'package:frontend/core/widgets/esqueleto.dart';
import 'package:frontend/core/widgets/fila_opcion.dart';
import 'package:frontend/core/widgets/hoja.dart';
import 'package:frontend/core/widgets/segmento.dart';
import 'package:frontend/core/widgets/tarjeta.dart';
import 'package:frontend/core/widgets/titulo_seccion.dart';
import 'package:frontend/features/categorias/data/datasources/categoria_api.dart';
import 'package:frontend/features/categorias/data/models/categoria.dart';
import 'package:frontend/features/categorias/presentation/viewmodels/categorias_view_model.dart';
import 'package:frontend/features/categorias/presentation/widgets/formulario_categoria.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key, this.api});

  final CategoriaApi? api; // para los tests

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  late final _vm = CategoriasViewModel(widget.api ?? CategoriaApi(ApiClient()));
  // Qué lista se ve: la de gastos o la de ingresos.
  bool _verIngresos = false;

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

  // "Nueva categoría" o "Editar categoría": el mismo formulario en una hoja.
  Future<void> _abrirFormulario({Categoria? editando}) async {
    final compartida = cuentaActiva.value?['nombre'] as String?;
    final guardada = await mostrarHoja<Categoria>(
      context,
      titulo: editando == null ? 'Nueva categoría' : 'Editar categoría',
      texto: editando == null && compartida != null
          ? 'La van a ver y usar todos en $compartida.'
          : null,
      // El tipo es el de la lista que se está viendo; al editar, no se puede cambiar.
      contenido: FormularioCategoria(
        esIngreso: _verIngresos,
        tipoFijo: true,
        editando: editando,
      ),
    );
    if (guardada == null || !mounted) return;
    mostrarExito(
      context,
      editando == null ? 'Categoría creada' : 'Categoría actualizada',
    );
    _vm.cargar();
  }

  Future<void> _eliminar(Categoria categoria) async {
    final confirmado = await confirmar(
      context,
      titulo: '¿Eliminar "${categoria.nombre}"?',
      texto: 'No se puede deshacer.',
      textoAccion: 'Eliminar',
      peligro: true,
    );
    if (!confirmado || !mounted) return;
    final error = await _vm.eliminar(categoria);
    if (!mounted) return;
    if (error == null) {
      mostrarExito(context, 'Categoría eliminada');
      return;
    }
    // Por ejemplo, si tiene movimientos: el backend no la deja borrar y explica por qué.
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No se pudo eliminar'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cuenta = cuentaActiva.value?['nombre'] as String?;
    return Scaffold(
      appBar: barraConVolver(
        context,
        'Categorías',
        subtitulo: cuenta ?? 'Personal',
        // También en una cuenta compartida, la crea cualquier integrante (t-12.1.6)
        acciones: [
          BotonIcono(
            icono: Icons.add,
            principal: true,
            ayuda: 'Nueva categoría',
            alTocar: _abrirFormulario,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          // El esqueleto solo la primera vez: al recargar después de crear o editar, la lista
          // queda donde estaba y se actualiza sola (si no, se arma de nuevo y vuelve arriba).
          if (_vm.cargando && _vm.categorias.isEmpty) {
            return const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 32),
              child: EsqueletoLista(),
            );
          }
          final error = _vm.error;
          if (error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 12,
                  children: [
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.colores.suave,
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _vm.cargar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          final todas = _verIngresos ? _vm.deIngreso : _vm.deEgreso;
          final propias = todas.where((c) => !c.esPredefinida).toList();
          final predefinidas = todas.where((c) => c.esPredefinida).toList();
          final cuenta = cuentaActiva.value?['nombre'] as String?;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  Segmento<bool>(
                    opciones: const [(false, 'Gastos'), (true, 'Ingresos')],
                    valor: _verIngresos,
                    alCambiar: (valor) => setState(() => _verIngresos = valor),
                  ),
                  if (cuenta != null)
                    AvisoEnLinea(
                      'Las categorías de $cuenta las ven y usan todos. Cualquiera puede crear una.',
                      icono: Icons.group_outlined,
                    ),
                  if (propias.isNotEmpty)
                    _seccion(
                      cuenta == null ? 'Tuyas' : 'De $cuenta',
                      [for (final c in propias) _fila(c, cuenta)],
                    ),
                  Tarjeta(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: FilaOpcion.interruptor(
                      titulo: 'Mostrar predefinidas',
                      subtitulo: 'Las que trae Finza para empezar',
                      activo: _vm.verPredefinidas,
                      alCambiar: (_) => _vm.alternarPredefinidas(),
                    ),
                  ),
                  if (predefinidas.isNotEmpty)
                    _seccion(
                      'Predefinidas',
                      [for (final c in predefinidas) _fila(c, cuenta)],
                    ),
                  // Vacío solo pasa con las predefinidas ocultas: el catálogo trae de los dos tipos.
                  if (propias.isEmpty && !_vm.verPredefinidas)
                    Text(
                      'No tenés categorías propias de ${_verIngresos ? 'ingresos' : 'gastos'}.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _seccion(String titulo, List<Widget> filas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        TituloSeccion(titulo),
        TarjetaLista(children: filas),
      ],
    );
  }

  Widget _fila(Categoria categoria, String? cuenta) {
    return FilaOpcion(
      leading: CirculoCategoria.de(categoria),
      titulo: categoria.nombre,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          if (categoria.esPredefinida)
            const ChipEstado('Predefinida', TonoChip.hundido, chico: true)
          else
            Flexible(
              child: ChipEstado(
                cuenta == null ? 'Propia' : 'De $cuenta',
                TonoChip.menta,
                chico: true,
              ),
            ),
          // Las de una cuenta compartida todavía no se editan ni se borran (el backend no lo deja)
          if (!categoria.esPredefinida && cuentaActiva.value == null) ...[
            BotonIcono(
              icono: Icons.edit_outlined,
              ayuda: 'Editar',
              alTocar: () => _abrirFormulario(editando: categoria),
            ),
            BotonIcono(
              icono: Icons.delete_outline,
              ayuda: 'Eliminar',
              alTocar: () => _eliminar(categoria),
            ),
          ],
        ],
      ),
    );
  }
}
