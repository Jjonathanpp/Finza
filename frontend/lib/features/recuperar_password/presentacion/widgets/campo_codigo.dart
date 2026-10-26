import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/widgets/campo.dart';

class CampoCodigo extends StatelessWidget {
  final TextEditingController controller;

  const CampoCodigo({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Campo(
      etiqueta: 'Código',
      child: TextFormField(
        controller: controller,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, letterSpacing: 8),
        decoration: const InputDecoration(hintText: '000000'),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        validator: (v) {
          if (v == null || v.trim().length != 6) {
            return 'Ingresá los 6 dígitos del código';
          }
          return null;
        },
      ),
    );
  }
}
