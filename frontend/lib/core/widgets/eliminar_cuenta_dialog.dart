import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import '../network/cuenta_service.dart';
import '../storage/token_storage.dart';
import 'package:frontend/core/session/portero.dart';

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
  String? _error;

  bool get _puedeEliminar => _passwordController.text.isNotEmpty && !_cargando;

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
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        'Eliminar cuenta',
        style: TextStyle(color: AppColors.text),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Esta acción es definitiva: se eliminarán tu cuenta, tus perfiles, '
              'movimientos, presupuestos y categorías. No se puede deshacer.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _ocultarPassword,
              enabled: !_cargando,
              autofocus: true,
              style: const TextStyle(color: AppColors.text),
              onChanged: (_) => setState(() => _error = null),
              decoration: InputDecoration(
                labelText: 'Contraseña actual',
                errorText: _error,
                suffixIcon: IconButton(
                  icon: Icon(
                    _ocultarPassword ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.muted,
                  ),
                  onPressed: () =>
                      setState(() => _ocultarPassword = !_ocultarPassword),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cargando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: _puedeEliminar ? _eliminar : null,
          child: _cargando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Eliminar definitivamente'),
        ),
      ],
    );
  }
}
