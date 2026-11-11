import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/widgets/logo_finza.dart';
import '../widgets/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, restricciones) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: restricciones.maxHeight - 48,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: LogoFinza(tamano: 72)),
                  const SizedBox(height: 10),
                  const Center(child: NombreFinza()),
                  const SizedBox(height: 10),
                  Text(
                    'Tus finanzas claras, en un solo lugar.',
                    textAlign: TextAlign.center,
                    style: textos.bodyMedium?.copyWith(
                      fontSize: 15,
                      color: context.colores.suave,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const LoginForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
