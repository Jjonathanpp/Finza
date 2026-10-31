import 'package:flutter/material.dart';

class InvitacionScreen extends StatelessWidget {
  final String token;

  const InvitacionScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invitación')),
      body: Center(child: Text('Token recibido: $token')),
    );
  }
}
