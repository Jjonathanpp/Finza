import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/widgets/boton_icono.dart';
import 'package:frontend/features/categorias/data/datasources/categoria_api.dart';
import 'package:frontend/features/categorias/data/models/categoria.dart';
import 'package:frontend/features/categorias/presentation/viewmodels/categorias_view_model.dart';
import 'package:frontend/shared/utils/color_hex.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  final _vm = CategoriasViewModel(CategoriaApi(ApiClient()));

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

  void _proximamente() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Próximamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        actions: [
          BotonIcono(icono: Icons.add, tamanio: 34, ayuda: 'Nueva categoría', alTocar: _proximamente),
        ],
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          if (_vm.cargando) {
            return const Center(child: CircularProgressIndicator());
          }
          final error = _vm.error;
          if (error != null) {
            return Center(child: Text(error, style: const TextStyle(color: AppColors.muted)));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            children: [
              _grupo('Egresos', _vm.deEgreso),
              _grupo('Ingresos', _vm.deIngreso),
            ],
          );
        },
      ),
    );
  }

  Widget _grupo(String titulo, List<Categoria> categorias) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 9),
          child: Text.rich(
            TextSpan(
              text: titulo,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              children: [
                TextSpan(
                  text: ' (${categorias.length})',
                  style: const TextStyle(color: AppColors.faint, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              for (var i = 0; i < categorias.length; i++) ...[
                if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.line),
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
                  categoria.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                _Etiqueta(predefinida: categoria.esPredefinida),
              ],
            ),
          ),
          if (!categoria.esPredefinida) ...[
            BotonIcono(icono: Icons.edit_outlined, tamanio: 28, ayuda: 'Editar', alTocar: _proximamente),
            const SizedBox(width: 4),
            BotonIcono(icono: Icons.delete_outline, tamanio: 28, ayuda: 'Eliminar', alTocar: _proximamente),
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
              categoria.nombre.isEmpty ? '?' : categoria.nombre[0].toUpperCase(),
              style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800),
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
        color: predefinida ? AppColors.surface3 : AppColors.blue.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        predefinida ? 'PREDEFINIDA' : 'PROPIA',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: predefinida ? AppColors.faint : AppColors.blue,
        ),
      ),
    );
  }
}
