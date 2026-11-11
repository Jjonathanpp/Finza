import 'package:flutter/material.dart';
import 'package:frontend/core/session/cuenta_activa.dart';
import 'package:frontend/core/widgets/chip_estado.dart';
import 'package:frontend/core/widgets/circulo_categoria.dart';
import 'package:frontend/core/widgets/fila_movimiento.dart';
import 'package:frontend/core/widgets/monto.dart';
import 'package:frontend/core/widgets/tarjeta.dart';
import 'package:frontend/core/widgets/titulo_seccion.dart';
import 'package:frontend/features/movimientos/data/models/movimiento.dart';

// Los integrantes invitados tienen como nombre de perfil su email (InvitacionService): se muestra solo la
// parte antes de la @.
String nombreCortoPerfil(String nombre) {
  final limpio = nombre.trim();
  final arroba = limpio.indexOf('@');
  return arroba > 0 ? limpio.substring(0, arroba) : limpio;
}

// Si el movimiento lo cargó otro integrante de la cuenta compartida (en la personal no hay ajenos).
bool esMovimientoAjeno(Movimiento movimiento) {
  final cuenta = cuentaActiva.value;
  return cuenta != null && movimiento.perfilId != cuenta['perfilId'];
}

// Los movimientos juntos por día, en el orden en que llegan: un título ("Hoy", "Ayer", "Lunes 2 de
// noviembre") y abajo una tarjeta con sus filas (L261-270 de la maqueta). alTocarDe da lo que pasa al tocar
// cada fila; si devuelve null, la fila no se toca.
class GruposDeMovimientos extends StatelessWidget {
  const GruposDeMovimientos({
    super.key,
    required this.movimientos,
    required this.mostrarAutor,
    required this.alTocarDe,
  });

  final List<Movimiento> movimientos;
  // true en una cuenta compartida viendo a todos los integrantes: muestra quién cargó cada uno.
  final bool mostrarAutor;
  final VoidCallback? Function(Movimiento) alTocarDe;

  static const _dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  static const _meses = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  static String _tituloDelDia(DateTime fecha) {
    final ahora = DateTime.now();
    final hoy = DateTime.utc(ahora.year, ahora.month, ahora.day);
    final dia = DateTime.utc(fecha.year, fecha.month, fecha.day);
    final diferencia = hoy.difference(dia).inDays;
    if (diferencia == 0) return 'Hoy';
    if (diferencia == 1) return 'Ayer';
    final anio = fecha.year == ahora.year ? '' : ' de ${fecha.year}';
    return '${_dias[fecha.weekday - 1]} ${fecha.day} de ${_meses[fecha.month - 1]}$anio';
  }

  @override
  Widget build(BuildContext context) {
    final porDia = <DateTime, List<Movimiento>>{};
    for (final m in movimientos) {
      porDia.putIfAbsent(DateTime(m.fecha.year, m.fecha.month, m.fecha.day), () => []).add(m);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        for (final grupo in porDia.entries)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 6,
            children: [
              TituloSeccion(_tituloDelDia(grupo.key)),
              TarjetaLista(
                children: [
                  for (final m in grupo.value)
                    _FilaDeMovimiento(m, mostrarAutor: mostrarAutor, alTocar: alTocarDe(m)),
                ],
              ),
            ],
          ),
      ],
    );
  }
}

class _FilaDeMovimiento extends StatelessWidget {
  const _FilaDeMovimiento(this.movimiento, {required this.mostrarAutor, required this.alTocar});

  final Movimiento movimiento;
  final bool mostrarAutor;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final m = movimiento;
    final pendiente = m.estado == 'PENDIENTE';
    final descripcion = m.descripcion;
    return FilaMovimiento(
      leading: CirculoCategoria.de(m.categoria),
      titulo: m.categoria.nombre,
      subtitulo: descripcion != null && descripcion.isNotEmpty ? descripcion : 'Sin descripción',
      monto: Monto.texto(m.monto, ingreso: m.esIngreso),
      colorMonto: Monto.color(context, m.esIngreso),
      chip: pendiente ? const ChipEstado('Por revisar', TonoChip.ambar, chico: true) : null,
      pie: mostrarAutor && m.perfilNombre != null ? _Autor(m.perfilNombre!, esPropio: !esMovimientoAjeno(m)) : null,
      alTocar: alTocar,
    );
  }
}

// Quién cargó el movimiento: "Vos" en menta o el nombre en gris. El nombre largo se corta.
class _Autor extends StatelessWidget {
  const _Autor(this.nombre, {required this.esPropio});

  final String nombre;
  final bool esPropio;

  @override
  Widget build(BuildContext context) {
    final corto = nombreCortoPerfil(nombre);
    final texto = esPropio ? 'Vos' : (corto.length > 12 ? '${corto.substring(0, 11)}…' : corto);
    return Tooltip(
      message: esPropio ? 'Cargado por vos' : 'Cargado por $nombre',
      child: ChipEstado(texto, esPropio ? TonoChip.menta : TonoChip.hundido, chico: true),
    );
  }
}
