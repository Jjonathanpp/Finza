import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/widgets/aviso_exito.dart';
import 'package:frontend/core/widgets/campo.dart';
import 'package:frontend/core/widgets/segmento.dart';
import 'package:frontend/core/widgets/titulo_seccion.dart';
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
  String? _errorGeneral;
  final _authService = AuthService();

  static const _generos = ['Femenino', 'Masculino', 'Otro'];

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
    setState(() => _errorGeneral = null);
    if (_fechaNacimiento == null) {
      setState(() => _errorGeneral = 'Seleccioná tu fecha de nacimiento');
      return;
    }
    if (_genero == null) {
      setState(() => _errorGeneral = 'Seleccioná tu género');
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
        mostrarExito(context, 'Cuenta creada correctamente');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorGeneral = e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _textoFecha {
    final f = _fechaNacimiento;
    if (f == null) return 'dd/mm/aaaa';
    return '${f.day.toString().padLeft(2, '0')}/'
        '${f.month.toString().padLeft(2, '0')}/${f.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final textos = Theme.of(context).textTheme;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TituloSeccion('Tus datos'),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Expanded(
                child: Campo(
                  etiqueta: 'Nombre',
                  child: TextFormField(
                    controller: _nombreCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'Tu nombre'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Ingresá tu nombre'
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: Campo(
                  etiqueta: 'Apellido',
                  child: TextFormField(
                    controller: _apellidoCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'Tu apellido'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Ingresá tu apellido'
                        : null,
                  ),
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Expanded(
                child: Campo(
                  etiqueta: 'DNI',
                  child: TextFormField(
                    controller: _dniCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Sin puntos'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Ingresá tu DNI'
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: Campo(
                  etiqueta: 'Nacimiento',
                  child: Material(
                    color: colores.hundido,
                    borderRadius: BorderRadius.circular(Radios.control),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _seleccionarFecha,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            spacing: 8,
                            children: [
                              Expanded(
                                child: Text(
                                  _textoFecha,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textos.bodyLarge?.copyWith(
                                    color: _fechaNacimiento == null
                                        ? colores.suave
                                        : colores.texto,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: colores.suave,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Campo(
            etiqueta: 'Género',
            child: Segmento<String?>(
              opciones: [for (final g in _generos) (g, g)],
              valor: _genero,
              alCambiar: (v) => setState(() => _genero = v),
            ),
          ),
          Campo(
            etiqueta: 'Teléfono',
            child: TextFormField(
              controller: _telefonoCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '11 2345 6789'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Ingresá tu teléfono'
                  : null,
            ),
          ),
          const TituloSeccion('Tu acceso'),
          const SizedBox(height: 12),
          Campo(
            etiqueta: 'Email',
            child: TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'tu@email.com'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingresá tu email';
                final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
                if (!regex.hasMatch(v.trim())) return 'Email inválido';
                return null;
              },
            ),
          ),
          Campo(
            etiqueta: 'Contraseña',
            child: TextFormField(
              controller: _passwordCtrl,
              decoration: InputDecoration(
                hintText: 'Mínimo 8 caracteres',
                suffixIcon: TextButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  child: Text(_obscurePassword ? 'Ver' : 'Ocultar'),
                ),
              ),
              obscureText: _obscurePassword,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ingresá una contraseña';
                if (v.length < 8) return 'Mínimo 8 caracteres';
                return null;
              },
            ),
          ),
          if (_errorGeneral != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                _errorGeneral!,
                style: textos.bodySmall?.copyWith(
                  color: colores.coralTexto,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 6),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colores.sobrePrimario,
                    ),
                  )
                : const Text('Crear cuenta'),
          ),
        ],
      ),
    );
  }
}
