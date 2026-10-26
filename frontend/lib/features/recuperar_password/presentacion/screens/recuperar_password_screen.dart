import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/widgets/aviso_exito.dart';
import 'package:frontend/core/widgets/campo.dart';
import 'package:frontend/features/recuperar_password/data/dataresources/recuperacion_api.dart';
import 'package:frontend/features/recuperar_password/presentacion/screens/restablecer_password_screen.dart';

class RecuperarPasswordScreen extends StatefulWidget {
  const RecuperarPasswordScreen({super.key});

  @override
  State<RecuperarPasswordScreen> createState() =>
      _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState extends State<RecuperarPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _api = RecuperacionApi(ApiClient());

  bool _loading = false;
  String? _errorGeneral;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorGeneral = null;
    });
    try {
      final email = _emailCtrl.text.trim();
      await _api.solicitarCodigo(email);

      if (!mounted) return;
      mostrarExito(
        context,
        'Si el email está registrado, te enviamos un código',
      );
      // pushReplacement: al volver atrás se regresa al login, no a esta pantalla
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RestablecerPasswordScreen(email: email),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _errorGeneral = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Ingresá el email asociado a tu cuenta y te enviaremos '
                  'un código de 6 dígitos para restablecer tu contraseña.',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 24),
                Campo(
                  etiqueta: 'Email',
                  child: TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      hintText: 'maria@correo.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Ingresá tu email';
                      }
                      final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
                      if (!regex.hasMatch(v.trim())) return 'Email inválido';
                      return null;
                    },
                  ),
                ),
                if (_errorGeneral != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      _errorGeneral!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accentInk,
                          ),
                        )
                      : const Text('Enviar código'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
