import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/core/widgets/aviso_en_linea.dart';
import 'package:frontend/core/widgets/barra_con_volver.dart';
import 'package:frontend/core/widgets/campo.dart';
import 'package:frontend/core/widgets/circulo_categoria.dart';
import 'package:frontend/core/widgets/encabezado_pestana.dart';
import 'package:frontend/core/widgets/esqueleto.dart';
import 'package:frontend/features/categorias/data/models/categoria.dart';
import 'package:frontend/features/presupuestos/data/datasources/presupuesto_api.dart';
import 'package:frontend/features/presupuestos/data/models/presupuesto.dart';
import 'package:frontend/features/presupuestos/presentation/nombres_de_meses.dart';
import 'package:frontend/features/presupuestos/presentation/widgets/selector_intervalo_aviso.dart';
import 'package:frontend/l10n/idioma.dart';

class AltaPresupuestoScreen extends StatefulWidget {
  const AltaPresupuestoScreen({super.key});

  @override
  State<AltaPresupuestoScreen> createState() => _AltaPresupuestoScreenState();
}

class _AltaPresupuestoScreenState extends State<AltaPresupuestoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _api = PresupuestoApi(ApiClient());

  List<Map<String, dynamic>> _categorias = [];
  bool _cargandoCategorias = true;
  bool _guardando = false;
  String? _errorMensaje;

  int? _categoriaId;
  int _mes = DateTime.now().month;
  int _anio = DateTime.now().year;
  int _intervaloAviso = intervaloAvisoPorDefecto;
  final _montoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _cargarCategorias() async {
    try {
      final categorias = await _api.obtenerCategoriasEgreso();
      setState(() {
        _categorias = categorias;
        _cargandoCategorias = false;
      });
    } catch (e) {
      setState(() {
        _errorMensaje = tr('No se pudieron cargar las categorías.');
        _cargandoCategorias = false;
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('Por favor, seleccioná una categoría'))));
      return;
    }

    setState(() {
      _guardando = true;
      _errorMensaje = null;
    });

    try {
      final monto = double.parse(_montoController.text.replaceAll(',', '.'));
      await _api.crearPresupuesto(
        categoriaId: _categoriaId!,
        montoTope: monto,
        mes: _mes,
        anio: _anio,
        intervaloAviso: _intervaloAviso,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMensaje = e is ApiException ? e.message : context.tr('Error al guardar el presupuesto');
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    final aniosOpciones = [DateTime.now().year, DateTime.now().year + 1];
    final cuenta = cuentaActiva.value;

    return Scaffold(
      appBar: barraConVolver(context, context.tr('Nuevo presupuesto'), subtitulo: nombreDeCuentaActiva()),
      body: _cargandoCategorias
          ? Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              child: Semantics(
                container: true,
                liveRegion: true,
                label: context.tr('Cargando'),
                child: const ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 14,
                    children: [
                      Esqueleto(alto: 76, radio: Radios.control),
                      Esqueleto(alto: 76, radio: Radios.control),
                      Esqueleto(alto: 76, radio: Radios.control),
                    ],
                  ),
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMensaje != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: c.coralFondo,
                          borderRadius: BorderRadius.circular(Radios.aviso),
                        ),
                        child: Text(
                          _errorMensaje!,
                          style: textos.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: c.coralTexto),
                        ),
                      ),

                    Campo(
                      etiqueta: context.tr('Categoría'),
                      child: DropdownButtonFormField<int>(
                        initialValue: _categoriaId,
                        isExpanded: true,
                        hint: Text(context.tr('Seleccionar categoría...')),
                        items: _categorias.map((cat) {
                          return DropdownMenuItem<int>(
                            value: cat['id'] as int,
                            child: Row(
                              spacing: 10,
                              children: [
                                CirculoCategoria.de(Categoria.fromJson(cat), tamano: 30),
                                Expanded(
                                  child: Text(cat['nombre'] as String, maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _categoriaId = val),
                      ),
                    ),

                    Campo(
                      etiqueta: context.tr('Tope del mes'),
                      child: TextFormField(
                        controller: _montoController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(prefixText: r'$ ', hintText: '100.000'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return context.tr('El monto es obligatorio');
                          final numValue = double.tryParse(value.replaceAll(',', '.'));
                          if (numValue == null) return context.tr('Ingresá un número válido');
                          if (numValue <= 0) return context.tr('El monto debe ser mayor a 0');
                          return null;
                        },
                      ),
                    ),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12,
                      children: [
                        Expanded(
                          child: Campo(
                            etiqueta: context.tr('Mes'),
                            child: DropdownButtonFormField<int>(
                              initialValue: _mes,
                              isExpanded: true,
                              items: List.generate(12, (i) => i + 1).map((m) {
                                return DropdownMenuItem(
                                  value: m,
                                  child: Text(
                                    context.tr(nombresDeMeses[m]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _mes = val!),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Campo(
                            etiqueta: context.tr('Año'),
                            child: DropdownButtonFormField<int>(
                              initialValue: _anio,
                              isExpanded: true,
                              items: aniosOpciones.map((a) {
                                return DropdownMenuItem(value: a, child: Text(a.toString()));
                              }).toList(),
                              onChanged: (val) => setState(() => _anio = val!),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Cada cuánto avisar que el presupuesto se está llenando (popup).
                    Campo(
                      etiqueta: context.tr('Avisarme cada'),
                      child: SelectorIntervaloAviso(
                        valor: _intervaloAviso,
                        habilitado: !_guardando,
                        alCambiar: (valor) => setState(() => _intervaloAviso = valor),
                      ),
                    ),

                    if (cuenta != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: AvisoEnLinea(
                          context.tr('Lo ven todos en {cuenta}.', {'cuenta': '${cuenta['nombre']}'}),
                          icono: Icons.group_outlined,
                        ),
                      ),

                    FilledButton(
                      onPressed: _guardando ? null : _guardar,
                      child: _guardando
                          ? SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(color: c.sobrePrimario, strokeWidth: 2.5),
                            )
                          : Text(context.tr('Crear presupuesto')),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
