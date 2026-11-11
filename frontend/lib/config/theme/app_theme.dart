import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Paleta de la maqueta del rediseño. Cada campo es una variable del CSS (--fondo,
// --tarjeta, --linea...) y hay dos juegos de valores: .claro y .oscuro.
// En los widgets se usa con context.colores (ver ColoresDelTema, más abajo).
@immutable
class ColoresFinza extends ThemeExtension<ColoresFinza> {
  const ColoresFinza({
    required this.fondo,
    required this.tarjeta,
    required this.hundido,
    required this.pista,
    required this.brillo,
    required this.linea,
    required this.texto,
    required this.suave,
    required this.primario,
    required this.sobrePrimario,
    required this.menta,
    required this.barra,
    required this.ambar,
    required this.ambarTexto,
    required this.ambarFondo,
    required this.coral,
    required this.coralTexto,
    required this.coralFondo,
    required this.destacado,
    required this.destacadoTexto,
    required this.destacadoSuave,
    required this.destacadoVerde,
    required this.velo,
    required this.serie,
    required this.serieFondo,
    required this.sombra,
    required this.sombraBoton,
  });

  final Color fondo; // --fondo: fondo de las pantallas
  final Color tarjeta; // --tarjeta: tarjetas, hojas, diálogos, barra de navegación
  final Color hundido; // --hundido: campos, botón secundario, chips, segmentos
  final Color pista; // --pista: el riel de las barras de progreso
  final Color brillo; // --brillo: el destello del esqueleto de carga (sobre hundido)
  final Color linea; // --linea: separadores y bordes
  final Color texto; // --texto
  final Color suave; // --suave: texto secundario
  final Color primario; // --primario: verde de marca
  final Color sobrePrimario; // --sobre: texto e iconos sobre primario
  final Color menta; // --menta: fondo suave del verde (chips y avatares activos)
  final Color barra; // --barra: relleno de las barras de progreso
  final Color ambar; // --ambar: barra en alerta
  final Color ambarTexto; // --ambar-t
  final Color ambarFondo; // --ambar-f
  final Color coral; // --coral: barra pasada del tope
  final Color coralTexto; // --coral-t
  final Color coralFondo; // --coral-f
  final Color destacado; // --dest: tarjeta destacada (saldo del inicio), snackbar
  final Color destacadoTexto; // --dest-t
  final Color destacadoSuave; // --dest-s: texto secundario sobre destacado
  final Color destacadoVerde; // --dest-v: verde sobre destacado
  final Color velo; // --velo: la barrera detrás de hojas y diálogos
  final List<Color> serie; // --c0..--c4: colores de categorías y personas
  final List<Color> serieFondo; // --c0f..--c4f: fondo suave de cada color de serie
  final List<BoxShadow> sombra; // --sombra: sombra de tarjetas
  final List<BoxShadow> sombraBoton; // --sombra-boton: sombra del botón + de la barra

  // .claro de la maqueta (L15).
  static const claro = ColoresFinza(
    fondo: Color(0xFFF4F2EC),
    tarjeta: Color(0xFFFCFBF7),
    hundido: Color(0xFFECE9E1),
    pista: Color(0xFFECE9E1),
    brillo: Color(0xFFF8F7F2),
    linea: Color(0xFFDEDBD1),
    texto: Color(0xFF16211C),
    suave: Color(0xFF56625C),
    primario: Color(0xFF15784F),
    sobrePrimario: Color(0xFFFCFBF7),
    menta: Color(0xFFDCEFE3),
    barra: Color(0xFF15784F),
    ambar: Color(0xFFB87407),
    ambarTexto: Color(0xFF8F5600),
    ambarFondo: Color(0xFFF6EBD6),
    coral: Color(0xFFC9483A),
    coralTexto: Color(0xFFB23A2A),
    coralFondo: Color(0xFFF8E3DF),
    destacado: Color(0xFF16211C),
    destacadoTexto: Color(0xFFFCFBF7),
    destacadoSuave: Color(0xFFA9B5AE),
    destacadoVerde: Color(0xFF34C185),
    velo: Color.fromRGBO(14, 22, 18, .45),
    serie: [
      Color(0xFF56625C),
      Color(0xFF15784F),
      Color(0xFF2F5D9E),
      Color(0xFF8A3A66),
      Color(0xFF8F5600),
    ],
    serieFondo: [
      Color(0xFFECE9E1),
      Color(0xFFE1F0E7),
      Color(0xFFE3EAF5),
      Color(0xFFF2E5EC),
      Color(0xFFF5ECDA),
    ],
    sombra: [
      BoxShadow(color: Color.fromRGBO(22, 33, 28, .05), offset: Offset(0, 1), blurRadius: 2),
      BoxShadow(color: Color.fromRGBO(22, 33, 28, .06), offset: Offset(0, 8), blurRadius: 24),
    ],
    sombraBoton: [
      BoxShadow(color: Color.fromRGBO(21, 120, 79, .30), offset: Offset(0, 8), blurRadius: 20),
    ],
  );

  // .oscuro de la maqueta (L16).
  static const oscuro = ColoresFinza(
    fondo: Color(0xFF111915),
    tarjeta: Color(0xFF19231E),
    hundido: Color(0xFF212C26),
    pista: Color(0xFF2A3630),
    brillo: Color(0xFF2B3731),
    linea: Color(0xFF2C3832),
    texto: Color(0xFFEEECE5),
    suave: Color(0xFFA6B0AA),
    primario: Color(0xFF4CD69A),
    sobrePrimario: Color(0xFF0F1A14),
    menta: Color(0xFF1D3A2C),
    barra: Color(0xFF4CD69A),
    ambar: Color(0xFFF0B65A),
    ambarTexto: Color(0xFFF0B65A),
    ambarFondo: Color(0xFF3A2E17),
    coral: Color(0xFFF08A78),
    coralTexto: Color(0xFFF08A78),
    coralFondo: Color(0xFF3B211D),
    destacado: Color(0xFF173326),
    destacadoTexto: Color(0xFFEEECE5),
    destacadoSuave: Color(0xFFA8C2B5),
    destacadoVerde: Color(0xFF7BE7B5),
    velo: Color.fromRGBO(0, 0, 0, .55),
    serie: [
      Color(0xFFA6B0AA),
      Color(0xFF4CD69A),
      Color(0xFF8DB4F0),
      Color(0xFFE6A3C6),
      Color(0xFFF0B65A),
    ],
    serieFondo: [
      Color(0xFF26312B),
      Color(0xFF1D3A2C),
      Color(0xFF1E2B3D),
      Color(0xFF36222E),
      Color(0xFF3A2E17),
    ],
    // 0 0 0 1px #26322C: en oscuro la tarjeta no tiene sombra sino un borde fino.
    sombra: [BoxShadow(color: Color(0xFF26322C), spreadRadius: 1)],
    sombraBoton: [
      BoxShadow(color: Color.fromRGBO(0, 0, 0, .35), offset: Offset(0, 8), blurRadius: 20),
    ],
  );

  @override
  ColoresFinza copyWith({
    Color? fondo,
    Color? tarjeta,
    Color? hundido,
    Color? pista,
    Color? brillo,
    Color? linea,
    Color? texto,
    Color? suave,
    Color? primario,
    Color? sobrePrimario,
    Color? menta,
    Color? barra,
    Color? ambar,
    Color? ambarTexto,
    Color? ambarFondo,
    Color? coral,
    Color? coralTexto,
    Color? coralFondo,
    Color? destacado,
    Color? destacadoTexto,
    Color? destacadoSuave,
    Color? destacadoVerde,
    Color? velo,
    List<Color>? serie,
    List<Color>? serieFondo,
    List<BoxShadow>? sombra,
    List<BoxShadow>? sombraBoton,
  }) {
    return ColoresFinza(
      fondo: fondo ?? this.fondo,
      tarjeta: tarjeta ?? this.tarjeta,
      hundido: hundido ?? this.hundido,
      pista: pista ?? this.pista,
      brillo: brillo ?? this.brillo,
      linea: linea ?? this.linea,
      texto: texto ?? this.texto,
      suave: suave ?? this.suave,
      primario: primario ?? this.primario,
      sobrePrimario: sobrePrimario ?? this.sobrePrimario,
      menta: menta ?? this.menta,
      barra: barra ?? this.barra,
      ambar: ambar ?? this.ambar,
      ambarTexto: ambarTexto ?? this.ambarTexto,
      ambarFondo: ambarFondo ?? this.ambarFondo,
      coral: coral ?? this.coral,
      coralTexto: coralTexto ?? this.coralTexto,
      coralFondo: coralFondo ?? this.coralFondo,
      destacado: destacado ?? this.destacado,
      destacadoTexto: destacadoTexto ?? this.destacadoTexto,
      destacadoSuave: destacadoSuave ?? this.destacadoSuave,
      destacadoVerde: destacadoVerde ?? this.destacadoVerde,
      velo: velo ?? this.velo,
      serie: serie ?? this.serie,
      serieFondo: serieFondo ?? this.serieFondo,
      sombra: sombra ?? this.sombra,
      sombraBoton: sombraBoton ?? this.sombraBoton,
    );
  }

  @override
  ColoresFinza lerp(ThemeExtension<ColoresFinza>? other, double t) {
    if (other is! ColoresFinza) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    List<Color> lc(List<Color> a, List<Color> b) => [for (var i = 0; i < a.length; i++) c(a[i], b[i])];
    return ColoresFinza(
      fondo: c(fondo, other.fondo),
      tarjeta: c(tarjeta, other.tarjeta),
      hundido: c(hundido, other.hundido),
      pista: c(pista, other.pista),
      brillo: c(brillo, other.brillo),
      linea: c(linea, other.linea),
      texto: c(texto, other.texto),
      suave: c(suave, other.suave),
      primario: c(primario, other.primario),
      sobrePrimario: c(sobrePrimario, other.sobrePrimario),
      menta: c(menta, other.menta),
      barra: c(barra, other.barra),
      ambar: c(ambar, other.ambar),
      ambarTexto: c(ambarTexto, other.ambarTexto),
      ambarFondo: c(ambarFondo, other.ambarFondo),
      coral: c(coral, other.coral),
      coralTexto: c(coralTexto, other.coralTexto),
      coralFondo: c(coralFondo, other.coralFondo),
      destacado: c(destacado, other.destacado),
      destacadoTexto: c(destacadoTexto, other.destacadoTexto),
      destacadoSuave: c(destacadoSuave, other.destacadoSuave),
      destacadoVerde: c(destacadoVerde, other.destacadoVerde),
      velo: c(velo, other.velo),
      serie: lc(serie, other.serie),
      serieFondo: lc(serieFondo, other.serieFondo),
      sombra: BoxShadow.lerpList(sombra, other.sombra, t)!,
      sombraBoton: BoxShadow.lerpList(sombraBoton, other.sombraBoton, t)!,
    );
  }
}

extension ColoresDelTema on BuildContext {
  // Si el árbol no tiene el tema de Finza (algunos tests), se usa el claro.
  ColoresFinza get colores => Theme.of(this).extension<ColoresFinza>() ?? ColoresFinza.claro;
}

// Radios de las esquinas, tal como están en el CSS de la maqueta.
abstract final class Radios {
  static const double pastilla = 999; // chips, botones redondos, barras
  static const double tarjeta = 20; // .card
  static const double destacada = 28; // .dest
  static const double hoja = 28; // .hoja (arriba)
  static const double dialogo = 28; // .dialogo
  static const double menu = 28; // .menu (el lateral, del lado de afuera)
  static const double control = 14; // .btn, .entrada, .caja, .icb
  static const double segmento = 16; // .seg
  static const double botonSegmento = 12; // .seg button
  static const double aviso = 16; // .aviso, .opr
  static const double mini = 12; // .mini
}

// Duraciones de las animaciones de la maqueta.
abstract final class Duraciones {
  static const toque = Duration(milliseconds: 150); // .toque, .sw
  static const velo = Duration(milliseconds: 200);
  static const dialogo = Duration(milliseconds: 220);
  static const hoja = Duration(milliseconds: 250); // también .menu
  static const aparece = Duration(milliseconds: 300);
  static const dibuja = Duration(milliseconds: 400); // el tilde (.dibuja)
  static const dibujaRetraso = Duration(milliseconds: 150); // espera antes de dibujar el tilde
  static const llenar = Duration(milliseconds: 450); // barras de progreso
  static const brillo = Duration(milliseconds: 1400); // esqueleto de carga (.brillo) y .latido
}

abstract final class Curvas {
  static const toque = Cubic(.2, 0, 0, 1);
  static const salida = Cubic(.2, .8, .2, 1);
}

const _fuente = 'PlusJakartaSans';
const _tabulares = [FontFeature.tabularFigures()];

TextStyle? _tab(TextStyle? base, Color color) =>
    base?.copyWith(color: color, fontFeatures: _tabulares);

TextStyle _estilo(
  TextStyle? base,
  double tamano,
  FontWeight peso,
  Color color, {
  double espaciado = 0,
}) {
  return base!.copyWith(
    fontSize: tamano,
    fontWeight: peso,
    color: color,
    letterSpacing: espaciado,
    fontFeatures: _tabulares,
  );
}

TextTheme _textTheme(ColoresFinza c, Brightness brillo) {
  final base = ThemeData(brightness: brillo, useMaterial3: true, fontFamily: _fuente).textTheme;
  return TextTheme(
    displayLarge: _tab(base.displayLarge, c.texto),
    displayMedium: _estilo(base.displayMedium, 44, FontWeight.w800, c.texto), // monto grande del alta (.grande)
    displaySmall: _estilo(base.displaySmall, 40, FontWeight.w800, c.texto), // saldo grande del inicio
    headlineLarge: _tab(base.headlineLarge, c.texto),
    headlineMedium: _tab(base.headlineMedium, c.texto),
    headlineSmall: _estilo(base.headlineSmall, 24, FontWeight.w800, c.texto, espaciado: -.24), // .cab h1
    titleLarge: _estilo(base.titleLarge, 19, FontWeight.w800, c.texto), // título de hoja y de diálogo
    titleMedium: _estilo(base.titleMedium, 18, FontWeight.w800, c.texto), // .sec h2
    titleSmall: _estilo(base.titleSmall, 17, FontWeight.w800, c.texto), // .tit b
    bodyLarge: _estilo(base.bodyLarge, 16, FontWeight.w600, c.texto), // .entrada
    bodyMedium: _estilo(base.bodyMedium, 14, FontWeight.w400, c.texto),
    bodySmall: _estilo(base.bodySmall, 13, FontWeight.w400, c.suave), // .t2
    labelLarge: _estilo(base.labelLarge, 15, FontWeight.w700, c.texto), // .btn
    labelMedium: _estilo(base.labelMedium, 13, FontWeight.w700, c.texto), // .chip, .h2
    labelSmall: _estilo(base.labelSmall, 11, FontWeight.w700, c.texto, espaciado: -.11), // .ni
  );
}

ThemeData temaFinza({bool oscuro = false}) {
  final c = oscuro ? ColoresFinza.oscuro : ColoresFinza.claro;
  final brillo = oscuro ? Brightness.dark : Brightness.light;
  final textos = _textTheme(c, brillo);
  const sinColor = Colors.transparent;

  final esquema = ColorScheme(
    brightness: brillo,
    primary: c.primario,
    onPrimary: c.sobrePrimario,
    primaryContainer: c.menta,
    onPrimaryContainer: c.primario,
    secondary: c.primario,
    onSecondary: c.sobrePrimario,
    secondaryContainer: c.menta,
    onSecondaryContainer: c.primario,
    tertiary: c.ambar,
    onTertiary: c.sobrePrimario,
    tertiaryContainer: c.ambarFondo,
    onTertiaryContainer: c.ambarTexto,
    error: c.coral,
    onError: c.sobrePrimario,
    errorContainer: c.coralFondo,
    onErrorContainer: c.coralTexto,
    surface: c.tarjeta,
    onSurface: c.texto,
    onSurfaceVariant: c.suave,
    surfaceDim: c.hundido,
    surfaceBright: c.tarjeta,
    surfaceContainerLowest: c.tarjeta,
    surfaceContainerLow: c.tarjeta,
    surfaceContainer: c.tarjeta,
    surfaceContainerHigh: c.hundido,
    surfaceContainerHighest: c.hundido,
    outline: c.linea,
    outlineVariant: c.linea,
    shadow: Colors.black,
    scrim: c.velo,
    inverseSurface: c.destacado,
    onInverseSurface: c.destacadoTexto,
    inversePrimary: c.destacadoVerde,
    surfaceTint: sinColor,
  );

  final formaControl = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radios.control));

  OutlineInputBorder borde(BorderSide lado) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(Radios.control),
    borderSide: lado,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brillo,
    fontFamily: _fuente,
    colorScheme: esquema,
    textTheme: textos,
    scaffoldBackgroundColor: c.fondo,
    canvasColor: c.fondo,
    dividerColor: c.linea,
    extensions: [c],
    // .btn.bp: el botón principal.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        backgroundColor: c.primario,
        foregroundColor: c.sobrePrimario,
        disabledBackgroundColor: c.primario.withValues(alpha: .45),
        disabledForegroundColor: c.sobrePrimario,
        elevation: 0,
        shape: formaControl,
        textStyle: textos.labelLarge,
      ),
    ),
    // .btn.bs: el botón secundario (hundido, sin borde).
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        backgroundColor: c.hundido,
        foregroundColor: c.texto,
        disabledBackgroundColor: c.hundido.withValues(alpha: .45),
        disabledForegroundColor: c.suave,
        side: BorderSide.none,
        shape: formaControl,
        textStyle: textos.labelLarge,
      ),
    ),
    // .link
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        foregroundColor: c.primario,
        disabledForegroundColor: c.suave,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: formaControl,
        textStyle: textos.labelLarge?.copyWith(fontSize: 14),
      ),
    ),
    // .campo y .entrada: fondo hundido, sin borde, 2 px de primario al enfocar.
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: c.hundido,
      constraints: const BoxConstraints(minHeight: 48),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: textos.bodyLarge?.copyWith(fontWeight: FontWeight.w500, color: c.suave),
      labelStyle: textos.bodyLarge?.copyWith(fontWeight: FontWeight.w500, color: c.suave),
      floatingLabelStyle: textos.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      helperStyle: textos.bodySmall,
      errorStyle: textos.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: c.coralTexto),
      prefixIconColor: c.suave,
      suffixIconColor: c.suave,
      border: borde(BorderSide.none),
      enabledBorder: borde(BorderSide.none),
      disabledBorder: borde(BorderSide.none),
      focusedBorder: borde(BorderSide(color: c.primario, width: 2)),
      errorBorder: borde(BorderSide(color: c.coral, width: 2)),
      focusedErrorBorder: borde(BorderSide(color: c.coral, width: 2)),
    ),
    appBarTheme: AppBarThemeData(
      backgroundColor: c.fondo,
      foregroundColor: c.texto,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: sinColor,
      centerTitle: false,
      toolbarHeight: 66,
      titleTextStyle: textos.titleSmall,
      systemOverlayStyle: (oscuro ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: sinColor),
      actionsPadding: const EdgeInsets.only(right: 18),
    ),
    // .hoja
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.tarjeta,
      modalBackgroundColor: c.tarjeta,
      modalBarrierColor: c.velo,
      surfaceTintColor: sinColor,
      elevation: 0,
      modalElevation: 0,
      showDragHandle: true,
      dragHandleColor: c.linea,
      dragHandleSize: const Size(40, 4),
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radios.hoja)),
      ),
    ),
    // .dialogo
    dialogTheme: DialogThemeData(
      backgroundColor: c.tarjeta,
      surfaceTintColor: sinColor,
      barrierColor: c.velo,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      titleTextStyle: textos.titleLarge,
      contentTextStyle: textos.bodyMedium?.copyWith(color: c.suave),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radios.dialogo)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.destacado,
      contentTextStyle: textos.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: c.destacadoTexto),
      actionTextColor: c.destacadoVerde,
      disabledActionTextColor: c.destacadoSuave,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radios.aviso)),
    ),
    // .chip (sin .ch-m/.ch-a/.ch-c: esos colores se arman con context.colores). El alto de los Chip de
    // Flutter es 32 y no se puede bajar a 30 desde el tema.
    chipTheme: ChipThemeData(
      backgroundColor: c.hundido,
      selectedColor: c.menta,
      disabledColor: c.hundido,
      checkmarkColor: c.primario,
      labelStyle: textos.labelMedium,
      secondaryLabelStyle: textos.labelMedium?.copyWith(color: c.primario),
      side: BorderSide.none,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      iconTheme: IconThemeData(color: c.suave, size: 18),
      elevation: 0,
      pressElevation: 0,
    ),
    // .sw: Flutter fija el tamaño del switch en 52x32; acá van los colores y el círculo grande en ambos estados.
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(c.tarjeta),
      trackColor: WidgetStateProperty.resolveWith(
        (estados) => estados.contains(WidgetState.selected) ? c.primario : c.linea,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(sinColor),
      trackOutlineWidth: const WidgetStatePropertyAll(0),
      thumbIcon: const WidgetStatePropertyAll(Icon(null)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.barra,
      linearTrackColor: c.pista,
      circularTrackColor: sinColor,
      linearMinHeight: 8,
      borderRadius: BorderRadius.circular(Radios.pastilla),
      stopIndicatorColor: sinColor,
      stopIndicatorRadius: 0,
      trackGap: 0,
    ),
    dividerTheme: DividerThemeData(color: c.linea, thickness: 1, space: 1),
    listTileTheme: ListTileThemeData(
      iconColor: c.suave,
      textColor: c.texto,
      titleTextStyle: textos.bodyMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      subtitleTextStyle: textos.bodySmall,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minVerticalPadding: 12,
      horizontalTitleGap: 12,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: c.destacado,
        borderRadius: BorderRadius.circular(Radios.mini),
      ),
      textStyle: textos.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: c.destacadoTexto),
    ),
  );
}
