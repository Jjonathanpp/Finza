import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/metas_ahorro/data/models/meta_ahorro.dart';

void main() {
  final meta = MetaAhorro(
    id: 1,
    nombre: 'Viaje',
    montoObjetivo: 1000,
    montoActual: 200,
    montoRestante: 800,
    cuotaDiaria: 10,
    cuotaSemanal: 70,
    fechaLimite: DateTime(2026, 6, 17),
    fechaCreacion: DateTime(2026, 5, 1),
  );

  test('si el vencimiento es esta semana, muestra solo la cuota diaria', () {
    final cuotas = meta.cuotasRecomendadas(hoy: DateTime(2026, 6, 15));

    expect(cuotas, [(periodo: 'diaria', monto: 10.0)]);
  });

  test(
    'si vence en el mismo mes pero otra semana, muestra diaria y semanal',
    () {
      final cuotas = meta.cuotasRecomendadas(hoy: DateTime(2026, 6, 1));

      expect(cuotas, [
        (periodo: 'diaria', monto: 10.0),
        (periodo: 'semanal', monto: 70.0),
      ]);
    },
  );

  test('si vence en otro mes, muestra cuotas diaria, semanal y mensual', () {
    final metaConCuotaMensual = MetaAhorro(
      id: meta.id,
      nombre: meta.nombre,
      montoObjetivo: meta.montoObjetivo,
      montoActual: meta.montoActual,
      montoRestante: meta.montoRestante,
      cuotaDiaria: meta.cuotaDiaria,
      cuotaSemanal: meta.cuotaSemanal,
      cuotaMensual: 300,
      fechaLimite: meta.fechaLimite,
      fechaCreacion: meta.fechaCreacion,
    );
    final cuotas = metaConCuotaMensual.cuotasRecomendadas(
      hoy: DateTime(2026, 5, 1),
    );

    expect(cuotas, [
      (periodo: 'diaria', monto: 10.0),
      (periodo: 'semanal', monto: 70.0),
      (periodo: 'mensual', monto: 300.0),
    ]);
  });

  test('no muestra la cuota mensual si el backend la omite', () {
    final metaSinCuotaMensual = MetaAhorro(
      id: 2,
      nombre: 'Viaje',
      montoObjetivo: 1000,
      montoActual: 200,
      montoRestante: 800,
      cuotaDiaria: 10,
      cuotaSemanal: 70,
      fechaLimite: DateTime(2026, 6, 17),
    );

    final cuotas = metaSinCuotaMensual.cuotasRecomendadas(
      hoy: DateTime(2026, 5, 1),
    );

    expect(cuotas.map((cuota) => cuota.periodo), ['diaria', 'semanal']);
  });

  test(
    'no muestra la cuota mensual antes de cumplir un mes desde la creación',
    () {
      final metaRecienteConCuotaMensual = MetaAhorro(
        id: 2,
        nombre: 'Viaje',
        montoObjetivo: 1000,
        montoActual: 200,
        montoRestante: 800,
        cuotaDiaria: 10,
        cuotaSemanal: 70,
        cuotaMensual: 300,
        fechaLimite: DateTime(2026, 6, 17),
        fechaCreacion: DateTime(2026, 6, 1),
      );

      final cuotas = metaRecienteConCuotaMensual.cuotasRecomendadas(
        hoy: DateTime(2026, 6, 1),
      );

      expect(cuotas.map((cuota) => cuota.periodo), ['diaria', 'semanal']);
    },
  );

  test(
    'no muestra cuotas sin fecha límite ni cuando la meta está completa',
    () {
      const sinFecha = MetaAhorro(
        id: 2,
        nombre: 'Sin fecha',
        montoObjetivo: 100,
        montoActual: 0,
        montoRestante: 100,
      );
      final completa = MetaAhorro(
        id: 3,
        nombre: 'Completa',
        montoObjetivo: 100,
        montoActual: 100,
        montoRestante: 0,
        cuotaDiaria: 0,
        cuotaSemanal: 0,
        cuotaMensual: 0,
        fechaLimite: DateTime(2026, 6, 17),
      );

      expect(sinFecha.cuotasRecomendadas(hoy: DateTime(2026, 6, 15)), isEmpty);
      expect(completa.cuotasRecomendadas(hoy: DateTime(2026, 6, 15)), isEmpty);
    },
  );
}
