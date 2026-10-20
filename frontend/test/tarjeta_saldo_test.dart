import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/panel/data/datasources/panel_api.dart';
import 'package:frontend/features/panel/presentation/widgets/tarjeta_saldo.dart';
import 'package:frontend/shared/utils/importe.dart';

// Contesta como /api/panel/resumen y anota qué se le pidió.
class _BackendDeMentira extends Fake implements ApiClient {
  _BackendDeMentira(this.respuesta);

  final Map<String, dynamic> respuesta;
  String? ruta;

  @override
  Future<dynamic> get(String path) async {
    ruta = path;
    return respuesta;
  }
}

Future<void> _mostrar(WidgetTester tester, ApiClient backend) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: TarjetaSaldo(api: PanelApi(backend)))));
  await tester.pumpAndSettle();
}

Finder _texto(String texto) => find.text(texto, findRichText: true);

void main() {
  tearDown(() => monedaVista.value = enPesos);

  testWidgets('el total es tipo billetera: no se reinicia con el mes', (tester) async {
    // Septiembre +100.000 y octubre −5.000 (lo que da el backend real con esos movimientos).
    final backend = _BackendDeMentira({'saldo': -5000.0, 'saldoTotal': 95000.0});
    await _mostrar(tester, backend);

    expect(backend.ruta, '/api/panel/resumen');
    expect(_texto('\$ 95.000,00'), findsOneWidget);
    expect(_texto('Período de informe: −\$ 5.000'), findsOneWidget);
  });

  testWidgets('con centavos, en negativo y con el mes en positivo', (tester) async {
    await _mostrar(tester, _BackendDeMentira({'saldo': 12000, 'saldoTotal': -1250000.5}));

    expect(_texto('−\$ 1.250.000,50'), findsOneWidget);
    expect(_texto('Período de informe: +\$ 12.000'), findsOneWidget);
  });

  testWidgets('el ojo esconde y vuelve a mostrar los montos', (tester) async {
    await _mostrar(tester, _BackendDeMentira({'saldo': -5000.0, 'saldoTotal': 95000.0}));

    await tester.tap(find.byTooltip('Ocultar montos'));
    await tester.pump();
    expect(_texto('\$ 95.000,00'), findsNothing);
    expect(_texto('\$ ••••••'), findsOneWidget);
    expect(_texto('Período de informe: ••••'), findsOneWidget);

    await tester.tap(find.byTooltip('Mostrar montos'));
    await tester.pump();
    expect(_texto('\$ 95.000,00'), findsOneWidget);
  });

  testWidgets('con dólares elegidos: el título, el total convertido y de dónde sale la cotización', (tester) async {
    monedaVista.value = (moneda: 'DOLAR', cotizacion: 1540.0, actualizada: DateTime(2026, 10, 20, 7));
    await _mostrar(tester, _BackendDeMentira({'saldo': -15400.0, 'saldoTotal': 80500.0}));

    expect(_texto('Dólares'), findsOneWidget);
    expect(_texto('US\$ 52,27'), findsOneWidget);
    expect(_texto('Período de informe: −US\$ 10,00'), findsOneWidget);
    expect(_texto('Dólar oficial: \$ 1.540 · 20/10'), findsOneWidget);
  });
}
