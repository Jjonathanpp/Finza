import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/core/widgets/app_drawer.dart';
import 'package:frontend/core/widgets/cuenta_usuario.dart';
import 'package:frontend/features/cuentas_compartidas/presentation/widgets/selector_de_cuenta.dart';

// El nombre de la cuenta en la que está la app: "Personal" o el de la compartida.
String nombreDeCuentaActiva() => (cuentaActiva.value?['nombre'] as String?) ?? 'Personal';

// .cab de la maqueta (L27-35): el avatar que abre el menú J, el título de la pestaña y, a la derecha,
// los botones de la pantalla (.bi). `acciones` son widgets ya armados, de 44 px.
// El menú se abre con abrirMenu, por encima de toda la pantalla (la barra de abajo incluida).
class EncabezadoPestana extends StatelessWidget {
  const EncabezadoPestana({super.key, required this.titulo, this.acciones = const []});

  final String titulo;
  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) {
    return _Cabecera(
      acciones: acciones,
      centro: Semantics(
        header: true,
        child: Text(
          titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}

// La variante del Inicio (maqueta L203-210): "Hola, {nombre}" y abajo la cuenta, que abre el selector.
class EncabezadoInicio extends StatelessWidget {
  const EncabezadoInicio({super.key, this.acciones = const []});

  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    return _Cabecera(
      acciones: acciones,
      centro: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          UsuarioActual(
            builder: (context, email) {
              final nombre = nombreDeUsuario(email);
              return Text(
                nombre.isEmpty ? 'Hola' : 'Hola, $nombre',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textos.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              );
            },
          ),
          ValueListenableBuilder<Map<String, dynamic>?>(
            valueListenable: cuentaActiva,
            builder: (context, _, _) {
              final nombre = nombreDeCuentaActiva();
              return Semantics(
                button: true,
                label: 'Estás en $nombre. Cambiar de cuenta',
                excludeSemantics: true,
                child: _Toque(
                  alTocar: () => SelectorDeCuenta.mostrar(context),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 2,
                      children: [
                        Flexible(
                          child: Text(
                            nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textos.titleMedium,
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down, size: 20, color: c.texto),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// .cuenta de la maqueta (L59): la cuenta en la que está la app, en una pastilla menta; al tocarla se
// abre el selector de cuenta.
class ChipCuenta extends StatelessWidget {
  const ChipCuenta({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: cuentaActiva,
      builder: (context, _, _) {
        final nombre = nombreDeCuentaActiva();
        return Semantics(
          button: true,
          label: 'Estás en $nombre. Cambiar de cuenta',
          excludeSemantics: true,
          child: _Toque(
            alTocar: () => SelectorDeCuenta.mostrar(context),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Center(
                widthFactor: 1,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.only(left: 14, right: 10),
                  decoration: BoxDecoration(color: c.menta, borderRadius: BorderRadius.circular(Radios.pastilla)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 2,
                    children: [
                      Flexible(
                        child: Text(
                          nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: c.primario, fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down, size: 18, color: c.primario),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// La fila de .cab: padding 16 20 6, alto mínimo 66, 12 de espacio entre cosas. Respeta la barra de arriba.
class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.centro, required this.acciones});

  final Widget centro;
  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 66),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
          child: Row(
            spacing: 12,
            children: [
              AvatarUsuario(alTocar: () => abrirMenu(context), ayuda: 'Abrir el menú'),
              Expanded(child: Align(alignment: Alignment.centerLeft, child: centro)),
              ...acciones,
            ],
          ),
        ),
      ),
    );
  }
}

// .toque: al apretar, se achica un poquito.
class _Toque extends StatefulWidget {
  const _Toque({required this.alTocar, required this.child});

  final VoidCallback alTocar;
  final Widget child;

  @override
  State<_Toque> createState() => _ToqueState();
}

class _ToqueState extends State<_Toque> {
  bool _apretado = false;

  void _apretar(bool apretado) => setState(() => _apretado = apretado);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.alTocar,
      onTapDown: (_) => _apretar(true),
      onTapUp: (_) => _apretar(false),
      onTapCancel: () => _apretar(false),
      child: AnimatedScale(
        scale: _apretado ? .96 : 1,
        duration: Duraciones.toque,
        curve: Curvas.toque,
        child: widget.child,
      ),
    );
  }
}
