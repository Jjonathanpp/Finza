import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/barra_con_volver.dart';
import '../widgets/register_form.dart';
import 'package:frontend/l10n/idioma.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barraConVolver(context, context.tr('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: RegisterForm(),
        ),
      ),
    );
  }
}
