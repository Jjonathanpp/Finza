import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/widgets/aviso_exito.dart';
import 'package:frontend/core/widgets/campo.dart';
import '../../auth/service/auth_service.dart';
import '../../registro/screens/register_screen.dart';
import '../../voice/voice_screen.dart';
import '../models/login_request.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorGeneral;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorGeneral = null;
    });
    try {
      await _authService.login(
        LoginRequest(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        ),
      );

      if (mounted) {
        mostrarExito(context, 'Sesión iniciada');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VoiceScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorGeneral = e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Campo(
            etiqueta: 'Email',
            child: TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(hintText: 'maria@correo.com'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingresá tu email';
                final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
                if (!regex.hasMatch(v.trim())) return 'Email inválido';
                return null;
              },
            ),
          ),
          Campo(
            etiqueta: 'Contraseña',
            child: TextFormField(
              controller: _passwordCtrl,
              decoration: InputDecoration(
                hintText: '••••••••',
                suffixIcon: TextButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  child: Text(_obscurePassword ? 'Ver' : 'Ocultar'),
                ),
              ),
              obscureText: _obscurePassword,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Ingresá tu contraseña' : null,
            ),
          ),
          if (_errorGeneral != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                _errorGeneral!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12.5),
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
                : const Text('Ingresar'),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                // TODO: implementar recuperación de contraseña
              },
              child: const Text('Olvidé mi contraseña'),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.line),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '¿Primera vez? ',
                style: TextStyle(color: AppColors.muted),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: const Text(
                  'Creá tu cuenta',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
