import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/core/widgets/aviso_exito.dart';
import 'package:frontend/core/widgets/barra_con_volver.dart';
import 'package:frontend/core/widgets/boton_icono.dart';
import 'package:frontend/features/categorias/data/datasources/categoria_api.dart';
import 'package:frontend/features/categorias/data/models/categoria.dart';
import 'package:frontend/features/categorias/presentation/viewmodels/categorias_view_model.dart';
import 'package:frontend/features/categorias/presentation/widgets/formulario_categoria.dart';
import 'package:frontend/l10n/idioma.dart';
import 'package:frontend/shared/utils/color_hex.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key, this.api});

  final CategoriaApi? api; // para los tests

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  late final _vm = CategoriasViewModel(widget.api ?? CategoriaApi(ApiClient()));

  int? get _cuentaCompartidaId {
    final id = cuentaActiva.value?['id'];
    return id is num ? id.toInt() : null;
  }

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

  // "Nueva categoría" o "Editar categoría": el mismo formulario en una pantalla entera.
  Future<void> _abrirFormulario({Categoria? editando}) async {
    final guardada = await Navigator.push<Categoria>(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: barraConVolver(
            context,
            editando == null
                ? context.tr('Nueva categoría')
                : context.tr('Editar categoría'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            children: [
              FormularioCategoria(
                editando: editando,
                cuentaCompartidaId: _cuentaCompartidaId,
              ),
            ],
          ),
        ),
      ),
    );
    if (guardada == null || !mounted) return;
    mostrarExito(
      context,
      editando == null
          ? context.tr('Categoría creada')
          : context.tr('Categoría actualizada'),
    );
    _vm.cargar();
  }

  Future<void> _eliminar(Categoria categoria) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.tr('¿Eliminar "{nombre}"?', {
            'nombre': context.tr(categoria.nombre),
          }),
        ),
        content: Text(context.tr('No se puede deshacer.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('Cancelar')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(context.tr('Eliminar')),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    final error = await _vm.eliminar(
      categoria,
      cuentaCompartidaId: _cuentaCompartidaId,
    );
    if (!mounted) return;
    if (error == null) {
      mostrarExito(context, context.tr('Categoría eliminada'));
      return;
    }
    // Por ejemplo, si tiene movimientos: el backend no la deja borrar y explica por qué.
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('No se pudo eliminar')),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('Entendido')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(conCuentaActiva(context.tr('Categorías'))),
        // También en una cuenta compartida, la crea cualquier integrante (t-12.1.6)
        actions: [
          BotonIcono(
            icono: Icons.add,
            tamanio: 34,
            ayuda: context.tr('Nueva categoría'),
            alTocar: _abrirFormulario,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          // La ruedita solo la primera vez: al recargar después de crear o editar, la lista
          // queda donde estaba y se actualiza sola (si no, se arma de nuevo y vuelve arriba).
          if (_vm.cargando && _vm.categorias.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final error = _vm.error;
          if (error != null) {
            return Center(
              child: Text(
                error,
                style: const TextStyle(color: AppColors.muted),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _vm.alternarPredefinidas,
                  style: TextButton.styleFrom(foregroundColor: AppColors.muted),
                  icon: Icon(
                    _vm.verPredefinidas
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                  ),
                  label: Text(
                    _vm.verPredefinidas
                        ? context.tr('Ocultar predefinidas')
                        : context.tr('Mostrar predefinidas'),
                  ),
                ),
              ),
              _grupo(
                context.tr('Egresos'),
                context.tr('No tenés categorías propias de egresos'),
                _vm.deEgreso,
              ),
              _grupo(
                context.tr('Ingresos'),
                context.tr('No tenés categorías propias de ingresos'),
                _vm.deIngreso,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _grupo(String titulo, String textoVacio, List<Categoria> categorias) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 9),
          child: Text.rich(
            TextSpan(
              text: titulo,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
              children: [
                TextSpan(
                  text: ' (${categorias.length})',
                  style: const TextStyle(
                    color: AppColors.faint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              // Vacío solo pasa con las predefinidas ocultas: el catálogo trae de los dos tipos.
              if (categorias.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Text(
                    textoVacio,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              for (var i = 0; i < categorias.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, thickness: 1, color: AppColors.line),
                _fila(categorias[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _fila(Categoria categoria) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          _Avatar(categoria),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(categoria.nombre),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                _Etiqueta(predefinida: categoria.esPredefinida),
              ],
            ),
          ),
          if (!categoria.esPredefinida && esAdminDeCuentaActiva) ...[
            BotonIcono(
              icono: Icons.edit_outlined,
              tamanio: 28,
              ayuda: context.tr('Editar'),
              alTocar: () => _abrirFormulario(editando: categoria),
            ),
            const SizedBox(width: 4),
            BotonIcono(
              icono: Icons.delete_outline,
              tamanio: 28,
              ayuda: context.tr('Eliminar'),
              alTocar: () => _eliminar(categoria),
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar(this.categoria);

  final Categoria categoria;

  @override
  Widget build(BuildContext context) {
    final color = colorDesdeHex(categoria.color);
    final emoji = categoria.emoji;
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: emoji != null
          ? Text(emoji, style: const TextStyle(fontSize: 18))
          : Text(
              // characters, no [0]: un emoji ocupa dos lugares del texto, y medio emoji no se puede dibujar.
              categoria.nombre.isEmpty
                  ? '?'
                  : categoria.nombre.characters.first.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.predefinida});

  final bool predefinida;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: predefinida
            ? AppColors.surface3
            : AppColors.blue.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        predefinida ? context.tr('PREDEFINIDA') : context.tr('PROPIA'),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: predefinida ? AppColors.faint : AppColors.blue,
        ),
      ),
    );
  }
}
