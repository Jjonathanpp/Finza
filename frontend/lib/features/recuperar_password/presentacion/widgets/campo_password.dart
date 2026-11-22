import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/widgets/campo.dart';
import 'package:frontend/l10n/idioma.dart';

class CampoPassword extends StatefulWidget {
  final TextEditingController controller;
  final String etiqueta;
  final String hint;
  final FormFieldValidator<String> validator;

  const CampoPassword({
    super.key,
    required this.controller,
    required this.etiqueta,
    required this.hint,
    required this.validator,
  });

  @override
  State<CampoPassword> createState() => _CampoPasswordState();
}

class _CampoPasswordState extends State<CampoPassword> {
  bool _ver = false;

  @override
  Widget build(BuildContext context) {
    return Campo(
      etiqueta: widget.etiqueta,
      child: TextFormField(
        controller: widget.controller,
        obscureText: !_ver,
        decoration: InputDecoration(
          hintText: widget.hint,
          suffixIcon: IconButton(
            tooltip: _ver ? context.tr('Ocultar contraseña') : context.tr('Mostrar contraseña'),
            icon: Icon(_ver ? Icons.visibility_off : Icons.visibility, color: context.colores.suave),
            onPressed: () => setState(() => _ver = !_ver),
          ),
        ),
        validator: widget.validator,
      ),
    );
  }
}
