import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/widgets/esqueleto.dart';
import 'package:frontend/core/widgets/tarjeta.dart';
import 'package:frontend/features/informes/data/datasources/informe_api.dart';
import 'package:frontend/features/panel/data/models/resumen_gastos.dart';
import 'package:frontend/shared/utils/color_hex.dart';
import 'package:frontend/shared/utils/importe.dart';

// "En qué gastás" (maqueta L499-505): una dona con los gastos por categoría y al lado la leyenda. Se dibuja
// con una animación al aparecer. Cada categoría va con el color que se guardó para ella.
class GraficoTortaCategorias extends StatefulWidget {
  const GraficoTortaCategorias({
    super.key,
    this.api,
    this.startDate,
    this.endDate,
  });

  final InformeApi? api;
  final DateTime? startDate;
  final DateTime? endDate;

  @override
  State<GraficoTortaCategorias> createState() => _GraficoTortaCategoriasState();
}

class _GraficoTortaCategoriasState extends State<GraficoTortaCategorias> {
  late Future<ResumenGastos> _futuro = _cargar();

  Future<ResumenGastos> _cargar() => (widget.api ?? InformeApi(ApiClient())).porCategoria(
        startDate: widget.startDate,
        endDate: widget.endDate,
      );

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final c = context.colores;
    return Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          Semantics(
            header: true,
            child: Text(
              'En qué gastás',
              style: textos.bodyMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
          FutureBuilder<ResumenGastos>(
            future: _futuro,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Esqueleto(alto: 128, radio: Radios.mini);
              }
              if (snapshot.hasError) {
                final e = snapshot.error;
                return _Reintentar(
                  mensaje: e is ApiException ? e.message : 'No se pudieron cargar los gastos.',
                  alTocar: () => setState(() => _futuro = _cargar()),
                );
              }
              final categorias = snapshot.data!.categorias;
              if (categorias.isEmpty) {
                return Text(
                  'Todavía no hay gastos en el período.',
                  style: textos.bodySmall?.copyWith(color: c.suave),
                );
              }
              // El color que se guardó para cada categoría, el mismo que en el Inicio (sin color, gris).
              final colores = [for (final categoria in categorias) colorDesdeHex(categoria.color)];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 18,
                children: [
                  Semantics(
                    label: 'Gráfico de gastos por categoría',
                    image: true,
                    excludeSemantics: true,
                    child: _Dona(categorias: categorias, colores: colores),
                  ),
                  Expanded(child: _Leyenda(categorias: categorias, colores: colores)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Dona extends StatelessWidget {
  const _Dona({required this.categorias, required this.colores});

  final List<GastoCategoria> categorias;
  final List<Color> colores;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final duracion = MediaQuery.disableAnimationsOf(context) ? Duration.zero : Duraciones.dibuja;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duracion,
      curve: Curvas.salida,
      builder: (context, progreso, _) => CustomPaint(
        size: const Size.square(128),
        painter: _DonaPainter(
          fracciones: [for (final cat in categorias) cat.porcentaje / 100.0],
          colores: colores,
          pista: c.pista,
          progreso: progreso,
        ),
      ),
    );
  }
}

class _DonaPainter extends CustomPainter {
  _DonaPainter({
    required this.fracciones,
    required this.colores,
    required this.pista,
    required this.progreso,
  });

  final List<double> fracciones;
  final List<Color> colores;
  final Color pista;
  final double progreso;

  @override
  void paint(Canvas canvas, Size size) {
    // La maqueta dibuja en un cuadro de 120: círculo de radio 40, trazo de 18 y 2 de hueco entre tramos.
    final escala = size.width / 120;
    final centro = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: centro, radius: 40 * escala);
    final trazo = 18 * escala;

    canvas.drawCircle(
      centro,
      40 * escala,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = trazo
        ..color = pista,
    );

    final hueco = 2 / (2 * math.pi * 40) * 2 * math.pi;
    final total = fracciones.fold<double>(0, (suma, f) => suma + math.max(0, f));
    final limite = progreso * total * 2 * math.pi;
    var desde = 0.0;
    for (var i = 0; i < fracciones.length; i++) {
      final largo = math.max(0, fracciones[i]) * 2 * math.pi;
      final visible = math.max(0.0, largo - hueco);
      final dibujado = (limite - desde).clamp(0.0, visible);
      if (dibujado > 0) {
        canvas.drawArc(
          rect,
          -math.pi / 2 + desde,
          dibujado,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = trazo
            ..color = colores[i],
        );
      }
      desde += largo;
    }
  }

  @override
  bool shouldRepaint(_DonaPainter anterior) =>
      anterior.progreso != progreso ||
      anterior.pista != pista ||
      anterior.fracciones != fracciones ||
      anterior.colores != colores;
}

class _Leyenda extends StatelessWidget {
  const _Leyenda({required this.categorias, required this.colores});

  final List<GastoCategoria> categorias;
  final List<Color> colores;

  String _porcentaje(double valor) {
    final texto = valor.toStringAsFixed(1).replaceAll('.', ',');
    return '${texto.endsWith(',0') ? texto.substring(0, texto.length - 2) : texto}%';
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final c = context.colores;
    return Column(
      spacing: 8,
      children: [
        for (var i = 0; i < categorias.length; i++)
          Row(
            spacing: 8,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: colores[i], shape: BoxShape.circle),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categorias[i].nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textos.bodyMedium?.copyWith(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      importe(categorias[i].total),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textos.bodySmall?.copyWith(fontSize: 12, color: c.suave),
                    ),
                  ],
                ),
              ),
              Text(
                _porcentaje(categorias[i].porcentaje),
                style: textos.bodyMedium?.copyWith(fontSize: 13.5, fontWeight: FontWeight.w800),
              ),
            ],
          ),
      ],
    );
  }
}

class _Reintentar extends StatelessWidget {
  const _Reintentar({required this.mensaje, required this.alTocar});

  final String mensaje;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(mensaje, style: textos.bodySmall?.copyWith(color: context.colores.suave)),
        TextButton(onPressed: alTocar, child: const Text('Reintentar')),
      ],
    );
  }
}
