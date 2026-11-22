import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/theme/apariencia.dart';
import 'config/theme/app_theme.dart';
import 'core/actualizacion/aviso_de_version.dart';
import 'core/avisos/aviso_de_presupuestos.dart';
import 'core/session/deep_link_service.dart';
import 'core/session/portero.dart';
import 'core/widgets/sin_conexion.dart';
import 'l10n/idioma.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  final _deepLinks = DeepLinkService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    cargarApariencia();
    // Se espera al primer frame para que el Navigator ya exista
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deepLinks.iniciar();
      avisarSiHayVersionNueva();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deepLinks.dispose();
    super.dispose();
  }

  // Al volver a la app (estaba en segundo plano): pudo entrar un gasto por voz o por Mercado
  // Pago mientras tanto. Sin sesión, la revisión no hace nada.
  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed) revisarAvisosDePresupuesto();
  }

  @override
  Widget build(BuildContext context) {
    // Escucha la apariencia y el idioma elegidos en Configuración: al cambiar uno, toda la app se redibuja.
    return ListenableBuilder(
      listenable: Listenable.merge([apariencia, idioma]),
      builder: (context, _) => MaterialApp(
        navigatorKey: navegador,
        debugShowCheckedModeBanner: false,
        theme: temaFinza(),
        darkTheme: temaFinza(oscuro: true),
        themeMode: apariencia.value,
        locale: idioma.value,
        supportedLocales: idiomas.keys.map(Locale.new),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        // El aviso de "sin conexión" va arriba de todo, sobre cualquier pantalla.
        builder: (context, pantalla) => Stack(
          fit: StackFit.expand,
          children: [
            pantalla ?? const SizedBox.shrink(),
            const Positioned(top: 0, left: 0, right: 0, child: AvisoSinConexion()),
          ],
        ),
        home: const Portero(),
      ),
    );
  }
}
