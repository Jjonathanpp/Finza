import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/widgets/aviso_exito.dart';
import 'package:frontend/features/recuperar_password/data/dataresources/recuperacion_api.dart';
import 'package:frontend/features/recuperar_password/presentacion/widgets/campo_codigo.dart';
import 'package:frontend/features/recuperar_password/presentacion/widgets/campo_password.dart';
import 'package:frontend/features/recuperar_password/presentacion/widgets/contador_expiracion.dart';

class RestablecerPasswordScreen extends StatefulWidget {
  final String email;

  const RestablecerPasswordScreen({super.key, required this.email});

  @override
  State<RestablecerPasswordScreen> createState() =>
      _RestablecerPasswordScreenState();
}

class _RestablecerPasswordScreenState extends State<RestablecerPasswordScreen> {
  static const _duracionSegundos =
      5 * 60; // igual que la expiración del backend
  static const _esperaReenvio = 60; // segundos antes de poder pedir otro código

  final _formKey = GlobalKey<FormState>();
  final _codigoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _api = RecuperacionApi(ApiClient());

  Timer? _timer;
  int _restantes = _duracionSegundos;

  bool _loading = false;
  bool _reenviando = false;
  String? _errorGeneral;

  @override
  void initState() {
    super.initState();
    _iniciarTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codigoCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _iniciarTimer() {
    _timer?.cancel();
    _restantes = _duracionSegundos;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_restantes <= 0) {
        t.cancel();
        return;
      }
      setState(() => _restantes--);
    });
  }

  bool get _expirado => _restantes <= 0;

  bool get _puedeReenviar => _restantes <= _duracionSegundos - _esperaReenvio;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorGeneral = null;
    });
    try {
      await _api.restablecer(
        email: widget.email,
        codigo: _codigoCtrl.text.trim(),
        nuevaContrasena: _passCtrl.text,
      );

      if (!mounted) return;
      mostrarExito(context, 'Contraseña actualizada. Ya podés iniciar sesión');
      // Asume que el login es la primera ruta del stack; ajustalo si no lo es
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (mounted) setState(() => _errorGeneral = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reenviar() async {
    setState(() {
      _reenviando = true;
      _errorGeneral = null;
    });
    try {
      await _api.solicitarCodigo(widget.email);

      if (!mounted) return;
      _codigoCtrl.clear();
      setState(_iniciarTimer);
      mostrarExito(context, 'Te enviamos un nuevo código');
    } catch (e) {
      if (mounted) setState(() => _errorGeneral = e.toString());
    } finally {
      if (mounted) setState(() => _reenviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restablecer contraseña')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ingresá el código de 6 dígitos que enviamos a '
                  '${widget.email} y elegí tu nueva contraseña.',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                ContadorExpiracion(segundosRestantes: _restantes),
                const SizedBox(height: 20),
                CampoCodigo(controller: _codigoCtrl),
                CampoPassword(
                  controller: _passCtrl,
                  etiqueta: 'Nueva contraseña',
                  hint: 'Mínimo 8 caracteres',
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Ingresá tu nueva contraseña';
                    }
                    if (v.length < 8) return 'Mínimo 8 caracteres';
                    return null;
                  },
                ),
                CampoPassword(
                  controller: _confirmCtrl,
                  etiqueta: 'Confirmar contraseña',
                  hint: 'Repetí la contraseña',
                  validator: (v) => v != _passCtrl.text
                      ? 'Las contraseñas no coinciden'
                      : null,
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
                  onPressed: (_loading || _expirado) ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accentInk,
                          ),
                        )
                      : const Text('Restablecer contraseña'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: (_puedeReenviar && !_reenviando)
                      ? _reenviar
                      : null,
                  child: _reenviando
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Reenviar código'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
