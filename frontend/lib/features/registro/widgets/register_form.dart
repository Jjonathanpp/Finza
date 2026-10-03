import 'package:flutter/material.dart';
import '../../auth/service/auth_service.dart';
import '../models/registro_request.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();

  DateTime? _fechaNacimiento;
  String? _genero;
  bool _loading = false;
  bool _obscurePassword = true;
  final _authService = AuthService();

  static const _generos = ['Masculino', 'Femenino', 'Otro'];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _telefonoCtrl.dispose();
    _dniCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (fecha != null) {
      setState(() => _fechaNacimiento = fecha);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaNacimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccioná tu fecha de nacimiento')),
      );
      return;
    }
    if (_genero == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seleccioná tu género')));
      return;
    }

    setState(() => _loading = true);
    try {
      final fecha =
          '${_fechaNacimiento!.year.toString().padLeft(4, '0')}-'
          '${_fechaNacimiento!.month.toString().padLeft(2, '0')}-'
          '${_fechaNacimiento!.day.toString().padLeft(2, '0')}';

      await _authService.registrar(
        RegistroRequest(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          usuario: UsuarioData(
            nombre: _nombreCtrl.text.trim(),
            apellido: _apellidoCtrl.text.trim(),
            dni: int.parse(_dniCtrl.text.trim()),
            telefono: _telefonoCtrl.text.trim(),
            fechaNacimiento: fecha,
            genero: _genero!.toUpperCase(),
          ),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta creada correctamente')),
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
          TextFormField(
            controller: _nombreCtrl,
            decoration: const InputDecoration(labelText: 'Nombre'),
            textCapitalization: TextCapitalization.words,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Ingresá tu nombre' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _apellidoCtrl,
            decoration: const InputDecoration(labelText: 'Apellido'),
            textCapitalization: TextCapitalization.words,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Ingresá tu apellido' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailCtrl,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingresá tu email';
              final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
              if (!regex.hasMatch(v.trim())) return 'Email inválido';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordCtrl,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            obscureText: _obscurePassword,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresá una contraseña';
              if (v.length < 8) return 'Mínimo 8 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _telefonoCtrl,
            decoration: const InputDecoration(labelText: 'Teléfono'),
            keyboardType: TextInputType.phone,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Ingresá tu teléfono' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dniCtrl,
            decoration: const InputDecoration(labelText: 'DNI'),
            keyboardType: TextInputType.number,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Ingresá tu DNI' : null,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _seleccionarFecha,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Fecha de nacimiento',
              ),
              child: Text(
                _fechaNacimiento == null
                    ? 'Seleccionar fecha'
                    : '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _genero,
            decoration: const InputDecoration(labelText: 'Género'),
            items: _generos
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (v) => setState(() => _genero = v),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Registrarme'),
          ),
        ],
      ),
    );
  }
}
