import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/widgets/campo.dart';
import 'package:frontend/core/widgets/selector_tipo.dart';
import 'package:frontend/core/widgets/tocable.dart';
import 'package:frontend/features/categorias/data/datasources/categoria_api.dart';
import 'package:frontend/features/categorias/data/models/categoria.dart';
import 'package:frontend/features/categorias/presentation/paleta_categorias.dart';
import 'package:frontend/features/categorias/presentation/viewmodels/formulario_categoria_view_model.dart';
import 'package:frontend/shared/utils/color_hex.dart';

// Nombre, tipo y color de una categoría. Lo usan las hojas "Nueva categoría" y
// "Editar categoría" (con editando), y el panel de "Nuevo movimiento".
// Al guardar, cierra y devuelve la categoría.
class FormularioCategoria extends StatefulWidget {
  const FormularioCategoria({super.key, this.esIngreso = false, this.tipoFijo = false, this.editando});

  final bool esIngreso;
  final bool tipoFijo;
  final Categoria? editando;

  @override
  State<FormularioCategoria> createState() => _FormularioCategoriaState();
}

class _FormularioCategoriaState extends State<FormularioCategoria> {
  late final _vm = FormularioCategoriaViewModel(
    CategoriaApi(ApiClient()),
    esIngreso: widget.esIngreso,
    editando: widget.editando,
  );
  late final _nombre = TextEditingController(text: widget.editando?.nombre);
  // Al editar, el tipo no se puede cambiar (el backend no lo deja).
  late final _mostrarTipo = !widget.tipoFijo && widget.editando == null;

  @override
  void dispose() {
    _vm.dispose();
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final guardada = await _vm.guardar(_nombre.text);
    if (guardada != null && mounted) Navigator.pop(context, guardada);
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
            if (_mostrarTipo) ...[
              SelectorTipo(esIngreso: _vm.esIngreso, alCambiar: _vm.cambiarTipo),
              const SizedBox(height: 18),
            ],
            Campo(
              etiqueta: 'Nombre',
              error: _vm.errorNombre,
              child: TextField(
                controller: _nombre,
                autofocus: widget.editando == null,
                textCapitalization: TextCapitalization.sentences,
                // La columna del nombre es de 100 caracteres.
                inputFormatters: [LengthLimitingTextInputFormatter(100)],
                decoration: const InputDecoration(hintText: 'Por ejemplo, Mascotas'),
                onSubmitted: (_) => _guardar(),
              ),
            ),
            Campo(
              etiqueta: 'Color',
              // El padding deja lugar al aro del color elegido, que se dibuja por fuera del círculo.
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [for (final hex in _colores) _circulo(hex)],
                ),
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  error,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colores.coralTexto,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            FilledButton(
              onPressed: _vm.guardando ? null : _guardar,
              child: _vm.guardando
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: context.colores.sobrePrimario),
                    )
                  : Text(widget.editando == null ? 'Crear categoría' : 'Guardar cambios'),
            ),
          ],
        );
      },
    );
  }

  // Los de la paleta. Si la categoría que se edita tiene un color que ya no está (las viejas usaban otros),
  // va primero, para que se vea elegido y se pueda conservar.
  List<String> get _colores {
    final actual = widget.editando?.color;
    if (actual == null || paletaCategorias.contains(actual)) return paletaCategorias;
    return [actual, ...paletaCategorias];
  }

  // Un círculo de la paleta (.colb): 40 px, con un aro por fuera si es el elegido. El área para tocar es de 44.
  Widget _circulo(String hex) {
    final colores = context.colores;
    final elegido = hex == _vm.color;
    final nombre = nombresColoresCategorias[hex] ?? 'Color actual';
    return Tocable(
      alTocar: () => _vm.elegirColor(hex),
      etiqueta: elegido ? '$nombre, elegido' : nombre,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorDesdeHex(hex),
              shape: BoxShape.circle,
              boxShadow: elegido
                  ? [
                      BoxShadow(color: colores.tarjeta, spreadRadius: 3),
                      BoxShadow(color: colores.texto, spreadRadius: 5),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
