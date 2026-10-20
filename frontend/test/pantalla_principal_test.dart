import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/categorias/presentation/screens/categorias_screen.dart';
import 'package:frontend/features/configuracion/presentation/screens/configuracion_screen.dart';
import 'package:frontend/features/home/presentation/screens/home_screen.dart';
import 'package:frontend/features/home/presentation/screens/pantalla_principal.dart';
import 'package:frontend/features/movimientos/presentation/screens/alta_movimiento_screen.dart';
import 'package:frontend/features/movimientos/presentation/screens/movimientos_screen.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  Future<void> abrir(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PantallaPrincipal()));
    await tester.pumpAndSettle();
  }

  testWidgets('la barra cambia de pestaña: Inicio, Historial y Categorías', (tester) async {
    await abrir(tester);
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Historial'));
    await tester.pumpAndSettle();
    expect(find.byType(MovimientosScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);

    await tester.tap(find.byTooltip('Categorías'));
    await tester.pumpAndSettle();
    expect(find.byType(CategoriasScreen), findsOneWidget);
  });

  testWidgets('el + despliega las opciones y tocando afuera se cierran', (tester) async {
    await abrir(tester);
    final manual = find.text('Movimiento manual').hitTestable();
    expect(manual, findsNothing);

    await tester.tap(find.byTooltip('Agregar'));
    await tester.pumpAndSettle();
    expect(manual, findsOneWidget);
    expect(find.text('Registrar por voz').hitTestable(), findsOneWidget);
    expect(find.text('Mercado Pago').hitTestable(), findsOneWidget);

    await tester.tapAt(const Offset(20, 200));
    await tester.pumpAndSettle();
    expect(manual, findsNothing);
  });

  testWidgets('"Movimiento manual" abre el alta', (tester) async {
    await abrir(tester);
    await tester.tap(find.byTooltip('Agregar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Movimiento manual'));
    await tester.pumpAndSettle();
    expect(find.byType(AltaMovimientoScreen), findsOneWidget);
  });

  testWidgets('abajo del menú está el mail del usuario, y tocándolo se abre Configuración', (tester) async {
    FlutterSecureStorage.setMockInitialValues({'auth_email': 'demo@finza.local'});
    await abrir(tester);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('Cerrar sesión'), findsOneWidget); // estaba repetido

    await tester.tap(find.text('demo@finza.local'));
    await tester.pumpAndSettle();
    expect(find.byType(ConfiguracionScreen), findsOneWidget);
    expect(find.text('Dólares'), findsOneWidget);
  });
}
