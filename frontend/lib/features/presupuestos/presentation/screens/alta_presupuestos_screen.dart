import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/presupuestos/data/datasources/presupuesto_api.dart';
import 'package:frontend/shared/utils/color_hex.dart';

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
        _errorMensaje = 'No se pudieron cargar las categorías.';
        _cargandoCategorias = false;
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, seleccioná una categoría')),
      );
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
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMensaje = e is ApiException ? e.message : 'Error al guardar el presupuesto';
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final aniosOpciones = [DateTime.now().year, DateTime.now().year + 1];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Presupuesto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: _cargandoCategorias
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMensaje != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.danger),
                        ),
                        child: Text(_errorMensaje!, style: const TextStyle(color: AppColors.danger, fontSize: 13.5)),
                      ),
                      
                    const Text('Categoría', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _categoriaId,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      hint: const Text('Seleccionar categoría...'),
                      items: _categorias.map((cat) {
                        return DropdownMenuItem<int>(
                          value: cat['id'] as int,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: colorDesdeHex(cat['color']),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(cat['nombre'] as String),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _categoriaId = val),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    const Text('Monto Límite (\$)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _montoController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface,
                        prefixText: '\$ ',
                        prefixStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.text),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'El monto es obligatorio';
                        final numValue = double.tryParse(value.replaceAll(',', '.'));
                        if (numValue == null) return 'Ingresá un número válido';
                        if (numValue <= 0) return 'El monto debe ser mayor a 0';
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Mes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<int>(
                                value: _mes,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items: List.generate(12, (i) => i + 1).map((m) {
                                  return DropdownMenuItem(value: m, child: Text(m.toString().padLeft(2, '0')));
                                }).toList(),
                                onChanged: (val) => setState(() => _mes = val!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Año', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<int>(
                                value: _anio,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items: aniosOpciones.map((a) {
                                  return DropdownMenuItem(value: a, child: Text(a.toString()));
                                }).toList(),
                                onChanged: (val) => setState(() => _anio = val!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _guardando ? null : _guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _guardando
                            ? const SizedBox.square(
                                dimension: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text('Crear Presupuesto', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}