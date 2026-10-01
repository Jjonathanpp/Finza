import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/widgets/campo.dart';
import 'package:frontend/core/widgets/selector_tipo.dart';
import 'package:frontend/features/categorias/data/datasources/categoria_api.dart';
import 'package:frontend/features/categorias/presentation/paleta_categorias.dart';
import 'package:frontend/features/categorias/presentation/viewmodels/nueva_categoria_view_model.dart';
import 'package:frontend/shared/utils/color_hex.dart';

// Nombre, tipo y color de una categoría nueva. Lo usan la pantalla "Nueva categoría"
// y el panel de "Nuevo movimiento". Al crearla, cierra y devuelve la categoría.
class FormularioCategoria extends StatefulWidget {
  const FormularioCategoria({super.key, this.esIngreso = false, this.tipoFijo = false});

  final bool esIngreso;
  final bool tipoFijo;

  @override
  State<FormularioCategoria> createState() => _FormularioCategoriaState();
}

class _FormularioCategoriaState extends State<FormularioCategoria> {
  late final _vm = NuevaCategoriaViewModel(CategoriaApi(ApiClient()), esIngreso: widget.esIngreso);
  final _nombre = TextEditingController();

  @override
  void dispose() {
    _vm.dispose();
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final creada = await _vm.guardar(_nombre.text);
    if (creada != null && mounted) Navigator.pop(context, creada);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final error = _vm.error;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.tipoFijo) ...[
              SelectorTipo(esIngreso: _vm.esIngreso, alCambiar: _vm.cambiarTipo),
              const SizedBox(height: 18),
            ],
            Campo(
              etiqueta: 'Nombre',
              error: _vm.errorNombre,
              child: TextField(
                controller: _nombre,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                // La columna del nombre es de 100 caracteres.
                inputFormatters: [LengthLimitingTextInputFormatter(100)],
                decoration: const InputDecoration(hintText: 'Por ejemplo, Mascotas'),
                onSubmitted: (_) => _guardar(),
              ),
            ),
            Campo(
              etiqueta: 'Color',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [for (final hex in paletaCategorias) _circulo(hex)],
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(error, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
              ),
            const SizedBox(height: 4),
            FilledButton.icon(
              onPressed: _vm.guardando ? null : _guardar,
              icon: _vm.guardando
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: const Text('Crear categoría'),
            ),
          ],
        );
      },
    );
  }

  // Un círculo de la paleta. El elegido lleva un tilde y un borde oscuro.
  Widget _circulo(String hex) {
    final elegido = hex == _vm.color;
    return InkWell(
      onTap: () => _vm.elegirColor(hex),
      customBorder: const CircleBorder(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: colorDesdeHex(hex),
          shape: BoxShape.circle,
          border: Border.all(color: elegido ? AppColors.text : Colors.transparent, width: 2),
        ),
        child: elegido ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
      ),
    );
  }
}
