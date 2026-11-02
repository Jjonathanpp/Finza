import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/widgets/barra_con_volver.dart';
import 'package:frontend/features/configuracion/data/datasources/preferencias_api.dart';
import 'package:frontend/features/configuracion/presentation/viewmodels/cambiar_password_view_model.dart';

// Se abre desde Configuración. Pide la contraseña actual y la nueva (mínimo 8 caracteres, igual que en el registro).
class CambiarPasswordScreen extends StatefulWidget {
  const CambiarPasswordScreen({super.key, this.api});

  final PreferenciasApi? api;

  @override
  State<CambiarPasswordScreen> createState() => _CambiarPasswordScreenState();
}

class _CambiarPasswordScreenState extends State<CambiarPasswordScreen> {
  late final _vm = CambiarPasswordViewModel(
    widget.api ?? PreferenciasApi(ApiClient()),
  );

  final _formKey = GlobalKey<FormState>();
  final _actualCtrl = TextEditingController();
  final _nuevaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();
  bool _ocultar = true;

  @override
  void dispose() {
    _vm.dispose();
    _actualCtrl.dispose();
    _nuevaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await _vm.cambiarPassword(_actualCtrl.text, _nuevaCtrl.text);
    if (!ok || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contraseña cambiada exitosamente')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barraConVolver(context, 'Cambiar contraseña'),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final error = _vm.error;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _actualCtrl,
                    obscureText: _ocultar,
                    enabled: !_vm.guardando,
                    decoration: InputDecoration(
                      labelText: 'Contraseña actual',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _ocultar ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setState(() => _ocultar = !_ocultar),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Ingresá tu contraseña actual'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nuevaCtrl,
                    obscureText: _ocultar,
                    enabled: !_vm.guardando,
                    decoration: const InputDecoration(
                      labelText: 'Nueva contraseña',
                    ),
                    validator: (v) {
                      if (v == null || v.length < 8) {
                        return 'La contraseña debe tener al menos 8 caracteres';
                      }
                      if (v == _actualCtrl.text) {
                        return 'La nueva contraseña debe ser distinta a la actual';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmarCtrl,
                    obscureText: _ocultar,
                    enabled: !_vm.guardando,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar nueva contraseña',
                    ),
                    validator: (v) => v != _nuevaCtrl.text
                        ? 'Las contraseñas no coinciden'
                        : null,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      error,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _vm.guardando ? null : _guardar,
                      child: _vm.guardando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Cambiar contraseña'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
