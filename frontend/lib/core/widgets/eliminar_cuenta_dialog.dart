import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import '../network/cuenta_service.dart';
import '../storage/token_storage.dart';
import 'package:frontend/core/session/portero.dart';
import 'package:frontend/core/widgets/campo.dart';

class EliminarCuentaDialog extends StatefulWidget {
  const EliminarCuentaDialog({super.key});

  static Future<void> mostrar(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const EliminarCuentaDialog(),
    );
  }

  @override
  State<EliminarCuentaDialog> createState() => _EliminarCuentaDialogState();
}

class _EliminarCuentaDialogState extends State<EliminarCuentaDialog> {
  final _passwordController = TextEditingController();
  final _cuentaService = CuentaService();

  bool _ocultarPassword = true;
  bool _cargando = false;
  bool _aceptoTerminos = false; // Estado para el checkbox
  String? _error;

  // Se habilita solo si hay contraseña, el checkbox está marcado y no está cargando
  bool get _puedeEliminar =>
      _passwordController.text.isNotEmpty && _aceptoTerminos && !_cargando;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _eliminar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    final resultado = await _cuentaService.eliminarCuenta(
      _passwordController.text,
    );
    if (!mounted) return;

    switch (resultado) {
      case EliminarCuentaResultado.exito:
        await TokenStorage().limpiar();
        if (!mounted) return;
        Navigator.of(context).pop(); // cierra el diálogo
        irAlLogin(); // deja solo el login, sin poder volver atrás
        break;
      case EliminarCuentaResultado.passwordIncorrecta:
        setState(() {
          _cargando = false;
          _error = 'La contraseña es incorrecta';
        });
        break;
      case EliminarCuentaResultado.sesionInvalida:
        // Sesión vencida: no hay nada que borrar con este token, se vuelve al login
        await TokenStorage().limpiar();
        if (!mounted) return;
        Navigator.of(context).pop();
        irAlLogin();
        break;
      case EliminarCuentaResultado.error:
        setState(() {
          _cargando = false;
          _error = 'No se pudo eliminar la cuenta. Intentá de nuevo.';
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final textos = Theme.of(context).textTheme;

    return Dialog(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // El círculo coral con el tacho (.cat.cc de 52)
            DecoratedBox(
              decoration: BoxDecoration(color: colores.coralFondo, shape: BoxShape.circle),
              child: SizedBox(
                width: 52,
                height: 52,
                child: Icon(Icons.delete_outline_rounded, size: 24, color: colores.coralTexto),
              ),
            ),
            const SizedBox(height: 14),
            Text('Eliminar tu cuenta', style: textos.titleLarge),
            const SizedBox(height: 14),
            Text(
              'Se borran tu cuenta, tus perfiles y todos tus datos. No se puede deshacer.',
              style: textos.bodyMedium?.copyWith(color: colores.suave),
            ),
            const SizedBox(height: 14),

            // Campo de contraseña
            Campo(
              etiqueta: 'Tu contraseña',
              child: TextField(
                controller: _passwordController,
                obscureText: _ocultarPassword,
                enabled: !_cargando,
                autofocus: true,
                style: textos.bodyLarge,
                onChanged: (_) => setState(() => _error = null),
                decoration: InputDecoration(
                  hintText: 'Para confirmar que sos vos',
                  errorText: _error,
                  suffixIcon: IconButton(
                    tooltip: _ocultarPassword ? 'Mostrar contraseña' : 'Ocultar contraseña',
                    icon: Icon(_ocultarPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _ocultarPassword = !_ocultarPassword),
                  ),
                ),
              ),
            ),

            // Casilla para aceptar el riesgo
            CheckboxListTile(
              value: _aceptoTerminos,
              onChanged: _cargando ? null : (valor) => setState(() => _aceptoTerminos = valor ?? false),
              title: Text(
                'Entiendo que pierdo todos mis datos y que no se pueden recuperar.',
                style: textos.bodyMedium,
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: colores.coral,
              checkColor: colores.sobrePrimario,
            ),
            const SizedBox(height: 14),

            // .acciones: dos botones iguales
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cargando ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  // .btn.bpel
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: colores.coralFondo,
                      foregroundColor: colores.coralTexto,
                      disabledBackgroundColor: colores.coralFondo.withValues(alpha: .45),
                      disabledForegroundColor: colores.coralTexto.withValues(alpha: .45),
                    ),
                    onPressed: _puedeEliminar ? _eliminar : null,
                    child: _cargando
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: colores.coralTexto),
                          )
                        : const Text('Eliminar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
