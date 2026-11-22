import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/widgets/aviso_exito.dart';
import 'package:frontend/core/widgets/barra_con_volver.dart';
import 'package:frontend/core/widgets/encabezado_pestana.dart';
import 'package:frontend/core/widgets/tocable.dart';
import 'package:frontend/l10n/idioma.dart';

// Grabar un movimiento por voz. Mientras graba se puede pausar y seguir, descartar o enviar (lo de
// Tomás en main, #152). El backend contesta al instante y la IA lo analiza en segundo plano.
class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  static const _textoInicial = 'Tocá para grabar';

  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isProcessing = false;
  String _text = _textoInicial;
  bool _esError = false;

  Timer? _timer;
  int _recordDuration = 0;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _arrancarCronometro() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _recordDuration++));
  }

  Future<void> _iniciarGrabacion() async {
    if (!await _audioRecorder.hasPermission()) {
      setState(() {
        _text = 'Se necesita permiso de micrófono.';
        _esError = true;
      });
      return;
    }
    if (kIsWeb) {
      // En Web se graba en memoria con Opus/WebM
      await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.opus), path: '');
    } else {
      // En Mobile (Android/iOS) se guarda archivo físico m4a
      final dir = await getApplicationDocumentsDirectory();
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: '${dir.path}/finza_movimiento.m4a',
      );
    }
    setState(() {
      _isRecording = true;
      _isPaused = false;
      _recordDuration = 0;
      _esError = false;
    });
    _arrancarCronometro();
  }

  Future<void> _pausarOSeguir() async {
    if (_isPaused) {
      await _audioRecorder.resume();
      _arrancarCronometro();
    } else {
      await _audioRecorder.pause();
      _timer?.cancel();
    }
    setState(() => _isPaused = !_isPaused);
  }

  Future<void> _descartar() async {
    await _audioRecorder.stop();
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _recordDuration = 0;
      _text = _textoInicial;
      _esError = false;
    });
  }

  Future<void> _enviar() async {
    final path = await _audioRecorder.stop();
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _isProcessing = true;
      _text = 'Enviando el audio...';
      _esError = false;
    });
    if (path == null) {
      setState(() {
        _isProcessing = false;
        _text = 'No se pudo guardar el audio. Probá grabarlo de nuevo.';
        _esError = true;
      });
      return;
    }
    await _enviarAudioABackend(path);
  }

  Future<void> _enviarAudioABackend(String path) async {
    try {
      final MultipartFile audioFile;

      if (kIsWeb) {
        // En Web descargamos los bytes del Blob generado en Chrome
        final response = await Dio().get<List<int>>(
          path,
          options: Options(responseType: ResponseType.bytes),
        );
        audioFile = MultipartFile.fromBytes(response.data!, filename: "movimiento.webm");
      } else {
        // En Mobile enviamos directamente el archivo local
        audioFile = await MultipartFile.fromFile(path, filename: "movimiento.m4a");
      }

      await ApiClient().postMultipart('/api/movimientos/procesar-audio', FormData.fromMap({"audio": audioFile}));

      if (mounted) {
        // El movimiento aparece en Movimientos como "Analizando" y después queda por revisar.
        mostrarExito(context, context.tr('Audio enviado. En unos segundos aparece en Movimientos para revisar.'));
        setState(() => _text = _textoInicial);
      }
    } catch (_) {
      // Sin el detalle técnico (antes salía el texto crudo del error): un mensaje que se entienda.
      if (mounted) {
        setState(() {
          _text = 'Error en el servidor de la IA';
          _esError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String get _contador {
    final segundos = (_recordDuration % 60).toString().padLeft(2, '0');
    return '${_recordDuration ~/ 60}:$segundos';
  }

  String get _estado {
    if (_isRecording) return _isPaused ? 'En pausa' : 'Te escucho…';
    return _text;
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final textos = Theme.of(context).textTheme;
    return Scaffold(
      appBar: barraConVolver(context, context.tr('Registro por voz'), subtitulo: nombreDeCuentaActiva()),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 14,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 290),
                child: Text(
                  context.tr('Contá qué gastaste o cobraste, como se lo dirías a alguien.'),
                  textAlign: TextAlign.center,
                  style: textos.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                context.tr('Por ejemplo: «Gasté 2.500 en el kiosco»'),
                textAlign: TextAlign.center,
                style: textos.bodyMedium?.copyWith(color: colores.suave),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 22, bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 20,
                  children: [
                    // Descartar y enviar aparecen solo mientras graba, a los costados del botón grande.
                    if (_isRecording)
                      _BotonChico(
                        icono: Icons.delete_outline,
                        etiqueta: context.tr('Descartar la grabación'),
                        fondo: colores.coralFondo,
                        color: colores.coralTexto,
                        alTocar: _descartar,
                      ),
                    SizedBox(
                      width: 136,
                      height: 136,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_isRecording && !_isPaused) const _Halo(),
                          Tocable(
                            alTocar: _isProcessing ? null : (_isRecording ? _pausarOSeguir : _iniciarGrabacion),
                            etiqueta: !_isRecording
                                ? context.tr('Empezar a grabar')
                                : _isPaused
                                    ? context.tr('Seguir grabando')
                                    : context.tr('Pausar la grabación'),
                            child: Opacity(
                              opacity: _isProcessing ? .45 : 1,
                              child: Container(
                                width: 120,
                                height: 120,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: colores.primario,
                                  shape: BoxShape.circle,
                                  boxShadow: colores.sombraBoton,
                                ),
                                child: Icon(
                                  _isRecording && !_isPaused ? Icons.pause : Icons.mic_none,
                                  size: 48,
                                  color: colores.sobrePrimario,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isRecording)
                      _BotonChico(
                        icono: Icons.send,
                        etiqueta: context.tr('Enviar la grabación'),
                        fondo: colores.primario,
                        color: colores.sobrePrimario,
                        alTocar: _enviar,
                      ),
                  ],
                ),
              ),
              if (_isProcessing)
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
              Semantics(
                liveRegion: true,
                child: Text(
                  context.tr(_estado),
                  textAlign: TextAlign.center,
                  style: textos.labelLarge?.copyWith(color: _esError ? colores.coralTexto : colores.texto),
                ),
              ),
              if (_isRecording) Text(_contador, style: textos.bodySmall?.copyWith(color: colores.suave)),
              if (_isRecording)
                Text(
                  context.tr('Tocá el botón grande para pausar y la flecha para enviar.'),
                  textAlign: TextAlign.center,
                  style: textos.bodySmall?.copyWith(color: colores.suave),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Los botones redondos de 56 a los costados del micrófono: descartar (coral) y enviar (verde).
class _BotonChico extends StatelessWidget {
  const _BotonChico({
    required this.icono,
    required this.etiqueta,
    required this.fondo,
    required this.color,
    required this.alTocar,
  });

  final IconData icono;
  final String etiqueta;
  final Color fondo;
  final Color color;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return Tocable(
      alTocar: alTocar,
      etiqueta: etiqueta,
      child: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: fondo, shape: BoxShape.circle),
        child: Icon(icono, size: 26, color: color),
      ),
    );
  }
}

// .latido de la maqueta: un círculo de 136 en verde que crece a 1,35 y se desvanece (de .45 a 0), en
// Duraciones.brillo, sin parar. Con "reducir animaciones" queda quieto y suave.
class _Halo extends StatefulWidget {
  const _Halo();

  @override
  State<_Halo> createState() => _HaloState();
}

class _HaloState extends State<_Halo> with SingleTickerProviderStateMixin {
  late final _controlador = AnimationController(vsync: this, duration: Duraciones.brillo);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controlador.stop();
    } else if (!_controlador.isAnimating) {
      _controlador.repeat();
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colores.primario;
    final circulo = DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: const SizedBox(width: 136, height: 136),
    );
    return ExcludeSemantics(
      child: IgnorePointer(
        child: MediaQuery.disableAnimationsOf(context)
            ? Opacity(opacity: .2, child: circulo)
            : AnimatedBuilder(
                animation: _controlador,
                builder: (context, hijo) {
                  final t = Curves.easeOut.transform(_controlador.value);
                  return Opacity(
                    opacity: .45 * (1 - t),
                    child: Transform.scale(scale: 1 + .35 * t, child: hijo),
                  );
                },
                child: circulo,
              ),
      ),
    );
  }
}
