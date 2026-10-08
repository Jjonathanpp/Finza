import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/features/mercadopago/presentation/screens/mercadopago_screen.dart';

void main() => runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: temaFinza(),
        home: const MercadoPagoScreen(),
      ),
    );