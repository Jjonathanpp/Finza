import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/widgets/tocable.dart';
import 'package:frontend/features/movimientos/presentation/viewmodels/movimientos_view_model.dart';

// Anterior, los números de página y Siguiente, pegados abajo de la lista. Con una sola página no se muestran.
class ControlesPaginacion extends StatelessWidget {
  const ControlesPaginacion({super.key, required this.vm});

  final MovimientosViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (vm.totalPaginas <= 1) return const SizedBox.shrink();
    final c = context.colores;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.tarjeta,
        border: Border(top: BorderSide(color: c.linea)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: vm.hayAnterior && !vm.cargando ? vm.paginaAnterior : null,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Anterior',
            ),
            if (vm.cargando)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 4,
                    children: [
                      for (var i = 0; i < vm.totalPaginas; i++)
                        _Pagina(
                          numero: i + 1,
                          actual: i + 1 == vm.paginaActual,
                          alTocar: () => vm.irAPagina(i),
                        ),
                    ],
                  ),
                ),
              ),
            IconButton(
              onPressed: vm.hayMas && !vm.cargando ? vm.paginaSiguiente : null,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Siguiente',
            ),
          ],
        ),
      ),
    );
  }
}

class _Pagina extends StatelessWidget {
  const _Pagina({
    required this.numero,
    required this.actual,
    required this.alTocar,
  });

  final int numero;
  final bool actual;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Semantics(
      selected: actual,
      child: Tocable(
        alTocar: actual ? null : alTocar,
        etiqueta: 'Página $numero',
        child: Container(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Container(
            constraints: const BoxConstraints(minWidth: 36),
            height: 36,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: actual ? c.primario : Colors.transparent,
              borderRadius: BorderRadius.circular(Radios.pastilla),
            ),
            child: Text(
              '$numero',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: actual ? c.sobrePrimario : c.texto,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
