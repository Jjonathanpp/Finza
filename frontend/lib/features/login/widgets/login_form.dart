import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await _authService.login(
        LoginRequest(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        ),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VoiceScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
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
          const Text('Email', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextFormField(
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
          const SizedBox(height: 20),
          const Text(
            'Contraseña',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextFormField(
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
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
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
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '¿Primera vez? ',
                style: TextStyle(color: Colors.grey.shade700),
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
                    color: Color(0xFF2EC4A6),
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
