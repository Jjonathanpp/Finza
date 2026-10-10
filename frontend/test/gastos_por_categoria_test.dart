import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/panel/data/datasources/panel_api.dart';
import 'package:frontend/features/panel/presentation/widgets/gastos_por_categoria.dart';

// Contesta como el backend (T-5.4.1), o falla, y anota qué se le pidió.
class _BackendDeMentira extends Fake implements ApiClient {
  _BackendDeMentira(this.respuesta, {this.falla});

  final Map<String, dynamic> respuesta;
  final ApiException? falla;
  String? ruta;

  @override
  Future<dynamic> get(String path) async {
    ruta = path;
    if (falla != null) throw falla!;
    return respuesta;
  }
}

// Como la manda el backend: los montos a veces con decimales y a veces sin, y un color que puede faltar.
const _octubre = {
  'total': 400000.00,
  'categorias': [
    {'id': 6, 'nombre': 'Comida', 'color': '#EF4444', 'total': 200000.00, 'porcentaje': 50.0},
    {'id': 23, 'nombre': 'Gimnasio', 'color': null, 'total': 120000, 'porcentaje': 30.0},
    {'id': 7, 'nombre': 'Transporte', 'color': '#8B5CF6', 'total': 80000.00, 'porcentaje': 20.0},
  ],
};

Future<void> _mostrar(WidgetTester tester, ApiClient backend) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: ListView(children: [GastosPorCategoria(api: PanelApi(backend))])),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra cada categoría con su monto y su porcentaje, en el orden del backend', (tester) async {
    await _mostrar(tester, _BackendDeMentira(_octubre));

    expect(find.text('Total \$ 400.000'), findsOneWidget);
    for (final texto in ['\$ 200.000', '50%', '\$ 120.000', '30%', '\$ 80.000', '20%']) {
      expect(find.text(texto), findsOneWidget, reason: texto);
    }
    final altura = [for (final nombre in ['Comida', 'Gimnasio', 'Transporte']) tester.getTopLeft(find.text(nombre)).dy];
    expect(altura[0] < altura[1] && altura[1] < altura[2], isTrue, reason: 'de mayor a menor gasto: $altura');
  });

  testWidgets('cada fila lleva el color de su categoría, y gris si no tiene', (tester) async {
    await _mostrar(tester, _BackendDeMentira(_octubre));

    final cuadraditos = tester
        .widgetList<Container>(find.byWidgetPredicate((w) => w is Container && w.constraints?.maxWidth == 9))
        .map((c) => (c.decoration as BoxDecoration).color)
        .toList();
    expect(cuadraditos, const [Color(0xFFEF4444), Color(0xFF94A3B8), Color(0xFF8B5CF6)]);
  });

  testWidgets('un porcentaje con decimales va con coma', (tester) async {
    await _mostrar(tester, _BackendDeMentira({
      'total': 1500,
      'categorias': [
        {'id': 6, 'nombre': 'Comida', 'color': '#EF4444', 'total': 1000, 'porcentaje': 66.7},
        {'id': 7, 'nombre': 'Transporte', 'color': '#8B5CF6', 'total': 500, 'porcentaje': 33.3},
      ],
    }));

    expect(find.text('66,7%'), findsOneWidget);
    expect(find.text('33,3%'), findsOneWidget);
  });

  testWidgets('sin gastos en el mes, lo avisa y no muestra el total', (tester) async {
    await _mostrar(tester, _BackendDeMentira({'total': 0, 'categorias': []}));

    expect(find.text('Todavía no hay gastos este mes.'), findsOneWidget);
    expect(find.textContaining('Total'), findsNothing);
  });

  testWidgets('si el backend falla, muestra su mensaje', (tester) async {
    await _mostrar(
      tester,
      _BackendDeMentira({}, falla: ApiException(null, 'No se pudo conectar con el servidor')),
    );

    expect(find.text('No se pudo conectar con el servidor'), findsOneWidget);
  });

  testWidgets('le pide el resumen al panel sin mandar cuenta ni perfil', (tester) async {
    final backend = _BackendDeMentira(_octubre);
    await _mostrar(tester, backend);

    expect(backend.ruta, '/api/panel/gastos-por-categoria');
  });
}
