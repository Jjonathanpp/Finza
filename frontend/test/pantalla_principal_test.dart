import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/categorias/presentation/screens/categorias_screen.dart';
import 'package:frontend/features/configuracion/presentation/screens/configuracion_screen.dart';
import 'package:frontend/features/home/presentation/screens/home_screen.dart';
import 'package:frontend/features/home/presentation/screens/pantalla_principal.dart';
import 'package:frontend/features/movimientos/presentation/screens/alta_movimiento_screen.dart';
import 'package:frontend/features/movimientos/presentation/screens/movimientos_screen.dart';
import 'package:frontend/features/presupuestos/presentation/screens/presupuestos_screen.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  Future<void> abrir(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PantallaPrincipal()));
    await tester.pumpAndSettle();
  }

  testWidgets('la barra cambia de pestaña: Inicio, Movimientos y Presupuestos', (tester) async {
    await abrir(tester);
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Movimientos'));
    await tester.pumpAndSettle();
    expect(find.byType(MovimientosScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);

    await tester.tap(find.bySemanticsLabel('Presupuestos'));
    await tester.pumpAndSettle();
    expect(find.byType(PresupuestosScreen), findsOneWidget);
    expect(find.byType(MovimientosScreen), findsNothing);
  });

  testWidgets('Categorías ya no es una pestaña: se abre desde el menú', (tester) async {
    await abrir(tester);
    expect(find.bySemanticsLabel('Categorías'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Abrir el menú'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Categorías'));
    await tester.pumpAndSettle();
    expect(find.byType(CategoriasScreen), findsOneWidget);
  });

  testWidgets('el + abre la hoja con las formas de cargar, y Cancelar la cierra', (tester) async {
    await abrir(tester);
    final manual = find.text('Gasto o ingreso').hitTestable();
    expect(manual, findsNothing);

    await tester.tap(find.byTooltip('Cargar algo'));
    await tester.pumpAndSettle();
    expect(manual, findsOneWidget);
    expect(find.text('Por voz').hitTestable(), findsOneWidget);
    expect(find.text('Desde Mercado Pago').hitTestable(), findsOneWidget);
    expect(find.text('Cancelar').hitTestable(), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(manual, findsNothing);
  });

  testWidgets('tocando afuera de la hoja del + se cierra', (tester) async {
    await abrir(tester);
    await tester.tap(find.byTooltip('Cargar algo'));
    await tester.pumpAndSettle();
    expect(find.text('Gasto o ingreso').hitTestable(), findsOneWidget);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.text('Gasto o ingreso').hitTestable(), findsNothing);
  });

  testWidgets('"Gasto o ingreso" abre el alta', (tester) async {
    await abrir(tester);
    await tester.tap(find.byTooltip('Cargar algo'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gasto o ingreso'));
    await tester.pumpAndSettle();
    expect(find.byType(AltaMovimientoScreen), findsOneWidget);
  });

  testWidgets('el avatar abre el menú con el mail del usuario, y Configuración se abre desde ahí', (tester) async {
    FlutterSecureStorage.setMockInitialValues({'auth_email': 'demo@finza.local'});
    await abrir(tester);

    await tester.tap(find.bySemanticsLabel('Abrir el menú'));
    await tester.pumpAndSettle();
    expect(find.text('demo@finza.local'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget); // estaba repetido

    await tester.tap(find.text('Configuración'));
    await tester.pumpAndSettle();
    expect(find.byType(ConfiguracionScreen), findsOneWidget);
    expect(find.text('Dólares'), findsOneWidget);
  });
}
