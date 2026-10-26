import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/campo.dart';

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
            icon: Icon(_ver ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _ver = !_ver),
          ),
        ),
        validator: widget.validator,
      ),
    );
  }
}
