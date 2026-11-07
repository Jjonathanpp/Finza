import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/session/portero.dart';
import 'package:frontend/core/session/sesion.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/features/presupuestos/data/datasources/presupuesto_api.dart';
import 'package:frontend/features/presupuestos/data/models/presupuesto.dart';
import 'package:frontend/features/presupuestos/presentation/widgets/barra_progreso_presupuesto.dart';
import 'package:frontend/shared/utils/importe.dart';

// Aviso de presupuesto: "Che, estás llegando al límite". Cada presupuesto avisa cada X % de
// consumo (intervaloAviso, 33 por defecto): con 33, al 33 %, al 66 %, al 99 % y al pasarse del tope.
//
// Cada marca avisa UNA vez. Si un gasto salta varias de golpe (de 10 % a 90 %), sale un solo aviso
// con el consumo real, no uno por marca. Lo ya avisado queda guardado en el teléfono, por usuario.
//
// Se revisa: después de cargar, editar o aprobar un movimiento (MovimientoApi), al entrar con sesión
// (Portero), al cambiar de cuenta (irAlInicio) y al volver a la app (app.dart), para los gastos que
// llegan por voz o por Mercado Pago.

// ---------------- El cálculo ----------------

// Cuántas marcas pasó el consumo. Con intervalo 33: 0–32 % → 0, 33–65 % → 1, 66–98 % → 2,
// 99 % → 3, y pasarse del tope → 4. Si el intervalo cae justo en el 100 % (25, 50, 100), llegar al
// tope ya es la última marca. Pasado el tope no hay más avisos (no avisa de nuevo al 132 %).
int nivelDeAviso(double porcentaje, int intervalo) {
  if (intervalo < 1 || porcentaje.isNaN || porcentaje <= 0) return 0;
  final marcas = 100 ~/ intervalo; // las marcas hasta el tope: 33 → 3 (33, 66, 99); 25 → 4
  final tocaElTope = marcas * intervalo == 100;
  if (porcentaje >= 100) return tocaElTope ? marcas : marcas + 1;
  final nivel = (porcentaje / intervalo).floor();
  return nivel > marcas ? marcas : nivel;
}

// Qué avisos nuevos corresponden, comparando con lo ya avisado ({presupuestoId: {n: nivel, i: intervalo}}).
// Devuelve los presupuestos a avisar y lo que hay que guardar.
// - Primera vez que se ve un presupuesto: cuenta como nivel 0 (si ya viene pasado de una marca, avisa).
// - Si el usuario cambió el intervalo, se toma el nivel nuevo sin avisar (no salta un cartel por editar).
// - Si el consumo bajó (se borró un gasto), baja el nivel guardado: al volver a cruzar, avisa de nuevo.
({List<Presupuesto> avisar, Map<String, dynamic> guardar}) calcularAvisos(
  List<Presupuesto> presupuestos,
  Map<String, dynamic> yaAvisado,
) {
  final guardar = Map<String, dynamic>.of(yaAvisado);
  final avisar = <Presupuesto>[];

  for (final p in presupuestos) {
    final id = '${p.presupuestoId}';
    final nivel = nivelDeAviso(p.porcentajeConsumo, p.intervaloAviso);
    final anterior = yaAvisado[id] as Map<String, dynamic>?;

    if (anterior != null && anterior['i'] != p.intervaloAviso) {
      guardar[id] = {'n': nivel, 'i': p.intervaloAviso};
      continue;
    }

    final nivelAnterior = anterior?['n'] as int? ?? 0;
    if (nivel > nivelAnterior) avisar.add(p);
    if (anterior == null || nivel != nivelAnterior) {
      guardar[id] = {'n': nivel, 'i': p.intervaloAviso};
    }
  }
  return (avisar: avisar, guardar: guardar);
}

// ---------------- La revisión ----------------

const _almacen = FlutterSecureStorage();
bool _revisando = false;

// Se puede llamar de cualquier lado y las veces que sea: sin sesión no hace nada, y si ya hay una
// revisión en curso, no arranca otra (así no salen dos cuadros iguales).
Future<void> revisarAvisosDePresupuesto({PresupuestoApi? api}) async {
  if (_revisando) return;
  _revisando = true;
  try {
    final tokens = TokenStorage();
    // Sin sesión vigente no se pide nada: un 401 mandaría al login.
    if (!tokenVigente(await tokens.obtenerToken())) return;

    final hoy = DateTime.now();
    final List<Presupuesto> presupuestos;
    try {
      presupuestos = await (api ?? PresupuestoApi(ApiClient())).listarPorMes(hoy.month, hoy.year);
    } catch (_) {
      return; // sin internet o con el backend caído, no se avisa nada (y no se pierde nada)
    }

    final clave = 'avisos_presupuesto_${await tokens.obtenerEmail() ?? 'sin_email'}';
    final (:avisar, :guardar) = calcularAvisos(presupuestos, await _leer(clave));

    final contexto = navegador.currentContext;
    // Si no se puede mostrar, no se guarda: así avisa en la próxima revisión.
    if (avisar.isNotEmpty && (contexto == null || !contexto.mounted)) return;

    await _almacen.write(key: clave, value: jsonEncode(guardar));
    if (avisar.isEmpty || contexto == null || !contexto.mounted) return;

    await showDialog<void>(
      context: contexto,
      builder: (_) => _CuadroAviso(presupuestos: avisar),
    );
  } finally {
    _revisando = false;
  }
}

Future<Map<String, dynamic>> _leer(String clave) async {
  try {
    final texto = await _almacen.read(key: clave);
    return texto == null ? {} : (jsonDecode(texto) as Map).cast<String, dynamic>();
  } catch (_) {
    return {}; // si lo guardado se rompió, se arranca de cero
  }
}

// ---------------- El cuadro ----------------

class _CuadroAviso extends StatelessWidget {
  const _CuadroAviso({required this.presupuestos});

  final List<Presupuesto> presupuestos;

  @override
  Widget build(BuildContext context) {
    final excedido = presupuestos.any((p) => p.porcentajeConsumo >= 100);
    final peor = presupuestos.map((p) => p.porcentajeConsumo).reduce((a, b) => a > b ? a : b);

    return AlertDialog(
      icon: Icon(
        excedido ? Icons.error_outline : Icons.warning_amber_rounded,
        size: 40,
        color: colorTextoPorConsumo(peor),
      ),
      title: Text(excedido ? 'Che, te pasaste del presupuesto' : 'Che, estás llegando al límite'),
      // Ancho fijo: AlertDialog mide su contenido antes de dibujarlo, y así no depende de lo
      // que haya adentro (además, en la compu no se estira a toda la pantalla).
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, p) in presupuestos.indexed) ...[
                if (i > 0) const SizedBox(height: 18),
                _FilaAviso(presupuesto: p),
              ],
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendido'),
        ),
      ],
    );
  }
}

class _FilaAviso extends StatelessWidget {
  const _FilaAviso({required this.presupuesto});

  final Presupuesto presupuesto;

  @override
  Widget build(BuildContext context) {
    final p = presupuesto;
    final porcentaje = p.porcentajeConsumo;
    final diferencia = p.montoTope - p.montoGastado;
    final textoPorcentaje = porcentaje == porcentaje.roundToDouble()
        ? porcentaje.toStringAsFixed(0)
        : porcentaje.toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                p.categoriaNombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '$textoPorcentaje%',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colorTextoPorConsumo(porcentaje)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        BarraProgresoPresupuesto(porcentaje: porcentaje, altura: 8),
        const SizedBox(height: 8),
        Text(
          diferencia < 0
              ? 'Gastaste ${importe(p.montoGastado)} de ${importe(p.montoTope)}: te pasaste ${importe(-diferencia)}.'
              : 'Gastaste ${importe(p.montoGastado)} de ${importe(p.montoTope)}. Te quedan ${importe(diferencia)}.',
          style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
        ),
      ],
    );
  }
}