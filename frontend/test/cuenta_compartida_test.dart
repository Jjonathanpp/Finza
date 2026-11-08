import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/features/categorias/data/datasources/categoria_api.dart';
import 'package:frontend/features/categorias/data/models/categoria.dart';
import 'package:frontend/features/categorias/presentation/screens/categorias_screen.dart';
import 'package:frontend/features/cuentas_compartidas/data/datasources/cuenta_compartida_api.dart';
import 'package:frontend/features/cuentas_compartidas/presentation/widgets/selector_de_cuenta.dart';
import 'package:frontend/features/presupuestos/data/datasources/presupuesto_api.dart';
import 'package:frontend/features/presupuestos/data/models/presupuesto.dart';
import 'package:frontend/features/presupuestos/presentation/screens/presupuestos_screen.dart';
import 'package:frontend/features/presupuestos/presentation/viewmodels/presupuestos_view_model.dart';
import 'package:frontend/features/presupuestos/presentation/widgets/desglose_integrantes.dart';
import 'package:frontend/features/presupuestos/presentation/widgets/tarjetas_cargando.dart';
import 'package:provider/provider.dart';

// Selector de cuenta y lo que cambia en Casa según el rol (t-13.1.2), y cuánto gastó cada integrante
// en cada presupuesto (t-13.2.2).

const _casaAdmin = {'id': 5, 'nombre': 'Casa', 'rol': 'ADMIN', 'perfilId': 12};
const _casaMiembro = {'id': 5, 'nombre': 'Casa', 'rol': 'MIEMBRO', 'perfilId': 13};

class _CuentasDeMentira extends Fake implements CuentaCompartidaApi {
  _CuentasDeMentira({this.rechazo});

  final ApiException? rechazo;
  final creadas = <String>[];

  @override
  Future<List<Map<String, dynamic>>> listarMias() async => [_casaAdmin];

  // Como responde el backend al crearla: sin el rol (t-11.1.4).
  @override
  Future<Map<String, dynamic>> crear(String nombre) async {
    creadas.add(nombre);
    if (rechazo != null) throw rechazo!;
    return {'id': 8, 'nombre': nombre, 'perfilId': 21};
  }
}

class _PresupuestosDeMentira extends Fake implements PresupuestoApi {
  _PresupuestosDeMentira({this.rechazo});

  final ApiException? rechazo;
  final editados = <Map<String, Object>>[];
  final desactivados = <int>[];

  // Como los manda el backend estando en Casa: Ana es el perfil 12 (el admin) y Beto el 13 (el miembro).
  // Caro se fue, pero gastó en Comida. En Servicios nadie gastó.
  @override
  Future<List<Presupuesto>> listarPorMes(int mes, int anio) async => const [
    Presupuesto(
      presupuestoId: 7,
      categoriaId: 6,
      categoriaNombre: 'Comida',
      categoriaColor: '#EF4444',
      montoTope: 2000,
      montoGastado: 1500,
      porcentajeConsumo: 75,
      porPerfil: [
        GastoDePerfil(perfilId: 12, nombre: 'Ana', gastado: 1000, porcentaje: 50),
        GastoDePerfil(perfilId: 13, nombre: 'Beto', gastado: 300, porcentaje: 15),
        GastoDePerfil(perfilId: 14, nombre: 'Caro', gastado: 200, porcentaje: 10, activo: false),
      ],
    ),
    Presupuesto(
      presupuestoId: 8,
      categoriaId: 8,
      categoriaNombre: 'Servicios',
      categoriaColor: '#6366F1',
      montoTope: 500,
      montoGastado: 0,
      porcentajeConsumo: 0,
      porPerfil: [
        GastoDePerfil(perfilId: 12, nombre: 'Ana', gastado: 0, porcentaje: 0),
        GastoDePerfil(perfilId: 13, nombre: 'Beto', gastado: 0, porcentaje: 0),
      ],
    ),
  ];

  @override
  Future<void> editarPresupuesto({
    required int id,
    required int categoriaId,
    required double montoTope,
    required int mes,
    required int anio,
    required int intervaloAviso,
  }) async {
    if (rechazo != null) throw rechazo!;
    editados.add({'id': id, 'categoriaId': categoriaId, 'montoTope': montoTope, 'mes': mes, 'anio': anio});
  }

  @override
  Future<void> desactivarPresupuesto(int id) async => desactivados.add(id);
}

class _PresupuestosQueTardan extends _PresupuestosDeMentira {
  final espera = Completer<void>();

  @override
  Future<List<Presupuesto>> listarPorMes(int mes, int anio) async {
    await espera.future;
    return super.listarPorMes(mes, anio);
  }
}

class _CategoriasDeMentira extends Fake implements CategoriaApi {
  @override
  Future<List<Categoria>> listar() async => const [
    Categoria(id: 6, nombre: 'Comida', tipo: 'EGRESO', esPredefinida: true),
    Categoria(id: 21, nombre: 'Expensas', tipo: 'EGRESO', esPredefinida: false),
  ];
}

Future<void> _abrirPresupuestos(WidgetTester tester, PresupuestoApi api) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ChangeNotifierProvider(
        create: (_) => PresupuestosViewModel(api),
        child: const PresupuestosScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// En Casa, el admin edita desde la tarjeta abierta (t-13.2.2). Arriba está el resumen del mes, así que
// "Editar tope" puede quedar debajo del borde de la pantalla de la prueba: se scrollea hasta él.
Future<void> _abrirEditar(WidgetTester tester) async {
  await tester.tap(find.text('Comida'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Editar tope'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Editar tope'));
  await tester.pumpAndSettle();
}

Future<void> _abrirCategorias(WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(home: CategoriasScreen(api: _CategoriasDeMentira())));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  tearDown(() => cuentaActiva.value = null);

  testWidgets('el selector muestra la personal y las compartidas, y al elegir guarda la cuenta', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SelectorDeCuenta(api: _CuentasDeMentira()))));
    await tester.pumpAndSettle();

    expect(find.textContaining('Estás en tu cuenta personal'), findsOneWidget);
    expect(find.text('Solo vos'), findsOneWidget);
    expect(find.text('Compartida · Administrador'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget); // la personal, que es la elegida

    await tester.tap(find.text('Casa'));
    await tester.pumpAndSettle();

    expect(cuentaActiva.value, _casaAdmin);
  });

  group('crear una cuenta compartida (t-11.1.4)', () {
    Future<void> abrirCuadro(WidgetTester tester, _CuentasDeMentira api) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SelectorDeCuenta(api: api))));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crear cuenta compartida'));
      await tester.pumpAndSettle();
    }

    FilledButton botonCrear(WidgetTester tester) => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Crear'));

    testWidgets('con un nombre la crea y la app pasa a esa cuenta como administrador', (tester) async {
      final api = _CuentasDeMentira();
      await abrirCuadro(tester, api);

      expect(find.text('Nueva cuenta compartida'), findsOneWidget);
      expect(find.text('Vas a ser el administrador.'), findsOneWidget);
      expect(botonCrear(tester).onPressed, isNull); // sin nombre no se puede

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      expect(botonCrear(tester).onPressed, isNull); // solo espacios tampoco

      await tester.enterText(find.byType(TextField), '  Depto  ');
      await tester.pump();
      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();

      expect(api.creadas, ['Depto']);
      expect(find.text('Nueva cuenta compartida'), findsNothing);
      expect(cuentaActiva.value, {'id': 8, 'nombre': 'Depto', 'perfilId': 21, 'rol': 'ADMIN'});

      // Al pasar a la cuenta nueva, irAlInicio deja la revisión de avisos de presupuesto para
      // dentro de 700 ms: se deja correr para que el test no termine con ese timer pendiente.
      await tester.pump(const Duration(milliseconds: 700));
    });

    testWidgets('si el backend no la crea, muestra el mensaje y el cuadro sigue abierto', (tester) async {
      final api = _CuentasDeMentira(rechazo: ApiException(null, 'No se pudo conectar con el servidor'));
      await abrirCuadro(tester, api);

      await tester.enterText(find.byType(TextField), 'Depto');
      await tester.pump();
      await tester.tap(find.text('Crear'));
      await tester.pumpAndSettle();

      expect(find.text('No se pudo conectar con el servidor'), findsOneWidget);
      expect(find.text('Nueva cuenta compartida'), findsOneWidget);
      expect(botonCrear(tester).onPressed, isNotNull); // se puede volver a probar
      expect(cuentaActiva.value, isNull);
    });

    testWidgets('Cancelar lo cierra sin crear nada', (tester) async {
      final api = _CuentasDeMentira();
      await abrirCuadro(tester, api);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Nueva cuenta compartida'), findsNothing);
      expect(api.creadas, isEmpty);
      expect(cuentaActiva.value, isNull);
    });
  });

  group('presupuestos', () {
    testWidgets('en la personal: se puede agregar y las tarjetas no abren nada', (tester) async {
      await _abrirPresupuestos(tester, _PresupuestosDeMentira());

      expect(find.text('Presupuestos'), findsOneWidget);
      expect(find.text('Agregar presupuesto'), findsOneWidget);
      await tester.tap(find.text('Comida'));
      await tester.pumpAndSettle();
      expect(find.text('Desactivar presupuesto'), findsNothing);
      expect(find.text('Cuánto gastó cada uno'), findsNothing);
    });

    testWidgets('miembro de Casa: no puede agregar ni editar, y ve por qué', (tester) async {
      cuentaActiva.value = _casaMiembro;
      await _abrirPresupuestos(tester, _PresupuestosDeMentira());

      expect(find.text('Presupuestos · Casa'), findsOneWidget);
      expect(find.text('Agregar presupuesto'), findsNothing);
      expect(find.text('Solo los administradores de Casa pueden agregar o cambiar presupuestos.'), findsOneWidget);
      await tester.tap(find.text('Comida'));
      await tester.pumpAndSettle();
      expect(find.text('Desactivar presupuesto'), findsNothing);
    });

    testWidgets('admin de Casa: desde la tarjeta abierta cambia el tope', (tester) async {
      cuentaActiva.value = _casaAdmin;
      final api = _PresupuestosDeMentira();
      await _abrirPresupuestos(tester, api);
      expect(find.text('Agregar presupuesto'), findsOneWidget);

      await _abrirEditar(tester);
      await tester.enterText(find.byType(TextField), '2500');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      final hoy = DateTime.now();
      expect(api.editados, [
        {'id': 7, 'categoriaId': 6, 'montoTope': 2500.0, 'mes': hoy.month, 'anio': hoy.year},
      ]);
      expect(find.text('Desactivar presupuesto'), findsNothing, reason: 'el panel se cierra');
    });

    testWidgets('admin de Casa: desactivar pide confirmación', (tester) async {
      cuentaActiva.value = _casaAdmin;
      final api = _PresupuestosDeMentira();
      await _abrirPresupuestos(tester, api);

      await _abrirEditar(tester);
      await tester.tap(find.text('Desactivar presupuesto'));
      await tester.pumpAndSettle();
      expect(find.textContaining('para todos los de Casa'), findsOneWidget);
      await tester.tap(find.text('Desactivar'));
      await tester.pumpAndSettle();

      expect(api.desactivados, [7]);
    });

    testWidgets('si el backend no deja, el panel muestra su mensaje y queda abierto', (tester) async {
      cuentaActiva.value = _casaAdmin;
      await _abrirPresupuestos(
        tester,
        _PresupuestosDeMentira(rechazo: ApiException(403, 'Solo el administrador de la cuenta compartida puede hacer esto')),
      );

      await _abrirEditar(tester);
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Solo el administrador de la cuenta compartida puede hacer esto'), findsOneWidget);
      expect(find.text('Desactivar presupuesto'), findsOneWidget);
    });

    testWidgets('un tope vacío o en cero no se manda', (tester) async {
      cuentaActiva.value = _casaAdmin;
      final api = _PresupuestosDeMentira();
      await _abrirPresupuestos(tester, api);

      await _abrirEditar(tester);
      await tester.enterText(find.byType(TextField), '0');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresá un tope mayor a cero'), findsOneWidget);
      expect(api.editados, isEmpty);
    });

    testWidgets('miembro de Casa: al tocar una tarjeta ve cuánto gastó cada uno', (tester) async {
      cuentaActiva.value = _casaMiembro;
      await _abrirPresupuestos(tester, _PresupuestosDeMentira());
      expect(find.text('Cuánto gastó cada uno'), findsNothing, reason: 'cerrada hasta tocarla');
      expect(find.text('\$ 1.500'), findsOneWidget);
      // El porcentaje se tiene que leer sobre blanco: contraste de 4,5:1 o más (t-13.2.2).
      final colorPorcentaje = tester.widget<Text>(find.text('75%')).style!.color!;
      expect(1.05 / (colorPorcentaje.computeLuminance() + 0.05), greaterThanOrEqualTo(4.5));

      await tester.tap(find.text('Comida'));
      await tester.pumpAndSettle();

      expect(find.text('Cuánto gastó cada uno'), findsOneWidget);
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('\$ 1.000'), findsOneWidget);
      expect(find.text('50.0%'), findsOneWidget);
      expect(find.text('vos'), findsOneWidget, reason: 'Beto es el perfil 13, el del miembro');
      expect(find.text('ya no está'), findsOneWidget, reason: 'Caro se fue');
      expect(find.text('Editar tope'), findsNothing);

      await tester.tap(find.text('Comida'));
      await tester.pumpAndSettle();
      expect(find.text('Cuánto gastó cada uno'), findsNothing, reason: 'se cierra al tocarla de nuevo');
    });

    testWidgets('en Casa se abre una tarjeta por vez, y si nadie gastó lo dice', (tester) async {
      cuentaActiva.value = _casaAdmin;
      await _abrirPresupuestos(tester, _PresupuestosDeMentira());

      await tester.tap(find.text('Comida'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Servicios'), 100);
      await tester.tap(find.text('Servicios'));
      await tester.pumpAndSettle();

      expect(find.text('Cuánto gastó cada uno'), findsOneWidget, reason: 'Comida se cerró');
      expect(find.text('Todavía nadie gastó en Servicios este mes.'), findsOneWidget);
      // Los dos integrantes, en $ 0 (la tarjeta también muestra "Gastado $ 0", afuera del desglose).
      expect(find.descendant(of: find.byType(DesgloseIntegrantes), matching: find.text('\$ 0')), findsNWidgets(2));
      expect(find.text('vos'), findsOneWidget, reason: 'Ana es el perfil 12, el del admin');
    });

    testWidgets('mientras carga muestra tarjetas grises en vez de la ruedita', (tester) async {
      final api = _PresupuestosQueTardan();
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => PresupuestosViewModel(api),
            child: const PresupuestosScreen(),
          ),
        ),
      );
      await tester.pump(); // el pedido sale después del primer cuadro

      expect(find.byType(TarjetasCargando), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      api.espera.complete();
      await tester.pumpAndSettle();
      expect(find.byType(TarjetasCargando), findsNothing);
      expect(find.text('Comida'), findsOneWidget);
    });
  });

  group('categorías', () {
    testWidgets('en la personal: se crean, y las propias se editan y se borran', (tester) async {
      await _abrirCategorias(tester);

      expect(find.text('Categorías'), findsOneWidget);
      expect(find.byTooltip('Nueva categoría'), findsOneWidget);
      expect(find.byTooltip('Editar'), findsOneWidget);
      expect(find.byTooltip('Eliminar'), findsOneWidget);
    });

    testWidgets('miembro de Casa: crea, pero las de Casa no se editan ni se borran', (tester) async {
      cuentaActiva.value = _casaMiembro;
      await _abrirCategorias(tester);

      expect(find.text('Categorías · Casa'), findsOneWidget);
      expect(find.text('Expensas'), findsOneWidget);
      expect(find.byTooltip('Nueva categoría'), findsOneWidget);
      expect(find.byTooltip('Editar'), findsNothing);
      expect(find.byTooltip('Eliminar'), findsNothing);
    });

    testWidgets('admin de Casa: crea, pero las de Casa no se editan ni se borran', (tester) async {
      cuentaActiva.value = _casaAdmin;
      await _abrirCategorias(tester);

      expect(find.byTooltip('Nueva categoría'), findsOneWidget);
      expect(find.byTooltip('Editar'), findsNothing);
    });
  });
}
