import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/config/theme/app_theme.dart';

// El código de 6 dígitos como 6 cajas (.caja). Abajo de las cajas va el pie (el contador de expiración).
// Las cajas solo muestran lo escrito: el que recibe el teclado es un campo transparente encima, que usa
// el mismo controller.
class CampoCodigo extends StatefulWidget {
  final TextEditingController controller;
  final Widget? pie;

  const CampoCodigo({super.key, required this.controller, this.pie});

  @override
  State<CampoCodigo> createState() => _CampoCodigoState();
}

class _CampoCodigoState extends State<CampoCodigo> {
  static const _largo = 6;

  final _foco = FocusNode();

  @override
  void initState() {
    super.initState();
    _foco.addListener(_redibujar);
  }

  @override
  void dispose() {
    _foco.removeListener(_redibujar);
    _foco.dispose();
    super.dispose();
  }

  void _redibujar() => setState(() {});

  // Lo que hay en el portapapeles, solo con los dígitos y hasta 6, completa las cajas.
  Future<void> _pegar(FormFieldState<String> estado) async {
    final datos = await Clipboard.getData(Clipboard.kTextPlain);
    final digitos = (datos?.text ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digitos.isEmpty) return;
    final codigo = digitos.length > _largo ? digitos.substring(0, _largo) : digitos;
    widget.controller.value = TextEditingValue(
      text: codigo,
      selection: TextSelection.collapsed(offset: codigo.length),
    );
    estado.didChange(codigo);
    if (estado.hasError) estado.validate();
  }

  String? _validar() {
    if (widget.controller.text.trim().length != _largo) {
      return 'Ingresá los 6 dígitos del código';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final textos = Theme.of(context).textTheme;
    final chico = textos.bodySmall;
    return FormField<String>(
      validator: (_) => _validar(),
      builder: (estado) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Código',
                style: chico?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colores.suave,
                ),
              ),
              const SizedBox(height: 6),
              Semantics(
                label: 'Código de 6 dígitos',
                textField: true,
                child: Stack(
                  children: [
                    ExcludeSemantics(
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: widget.controller,
                        builder: (_, valor, _) =>
                            _cajas(context, valor.text),
                      ),
                    ),
                    Positioned.fill(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _foco,
                        expands: true,
                        maxLines: null,
                        showCursor: false,
                        enableInteractiveSelection: false,
                        style: const TextStyle(color: Colors.transparent),
                        decoration: const InputDecoration.collapsed(
                          hintText: null,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(_largo),
                        ],
                        onChanged: (v) {
                          estado.didChange(v);
                          if (estado.hasError) estado.validate();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (estado.errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    estado.errorText!,
                    style: chico?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colores.coralTexto,
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => _pegar(estado),
                  child: const Text('Pegar código'),
                ),
              ),
              if (widget.pie != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: widget.pie,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _cajas(BuildContext context, String texto) {
    final colores = context.colores;
    final estilo = Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontSize: 22, color: colores.texto);
    final activa = _foco.hasFocus && texto.length < _largo ? texto.length : -1;
    return Row(
      spacing: 8,
      children: [
        for (var i = 0; i < _largo; i++)
          Expanded(
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colores.hundido,
                borderRadius: BorderRadius.circular(Radios.control),
                border: Border.all(
                  color: i == activa ? colores.primario : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Text(i < texto.length ? texto[i] : '', style: estilo),
            ),
          ),
      ],
    );
  }
}
