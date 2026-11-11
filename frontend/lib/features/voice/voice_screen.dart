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

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  static const _textoInicial = 'Tocá para grabar';

  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
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

  Future<void> _toggleRecording() async {
    // Si ya está grabando, frenamos y enviamos
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      _timer?.cancel();
      
      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _text = 'Procesando con la IA...';
        _esError = false;
      });

      if (path != null) {
        await _enviarAudioABackend(path);
      }
      return;
    }

    // Si no está grabando, pedimos permiso e iniciamos
    if (await _audioRecorder.hasPermission()) {
      if (kIsWeb) {
        // En Web se graba en memoria con Opus/WebM
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.opus), 
          path: ''
        );
      } else {
        // En Mobile (Android/iOS) se guarda archivo físico m4a
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/finza_movimiento.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc), 
          path: filePath
        );
      }
      
      setState(() {
        _isRecording = true;
        _recordDuration = 0;
        _esError = false;
      });

      // Cronómetro para feedback visual
      _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
        setState(() => _recordDuration++);
      });
    } else {
      setState(() {
        _text = 'Se necesita permiso de micrófono.';
        _esError = true;
      });
    }
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
        audioFile = MultipartFile.fromBytes(
          response.data!,
          filename: "movimiento.webm",
        );
      } else {
        // En Mobile enviamos directamente el archivo local
        audioFile = await MultipartFile.fromFile(
          path,
          filename: "movimiento.m4a",
        );
      }

      final formData = FormData.fromMap({
        "audio": audioFile,
      });

      // Enviamos al backend
      await ApiClient().postMultipart('/api/movimientos/procesar-audio', formData);

      if (mounted) {
        mostrarExito(context, 'Movimiento registrado correctamente');
        setState(() => _text = _textoInicial);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _text = 'Error al procesar: $e';
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

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    final textos = Theme.of(context).textTheme;
    return Scaffold(
      appBar: barraConVolver(context, 'Registro por voz', subtitulo: nombreDeCuentaActiva()),
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
                  'Contá qué gastaste o cobraste, como se lo dirías a alguien.',
                  textAlign: TextAlign.center,
                  style: textos.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                'Por ejemplo: «Gasté 2.500 en el kiosco»',
                textAlign: TextAlign.center,
                style: textos.bodyMedium?.copyWith(color: colores.suave),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 22, bottom: 10),
                child: SizedBox(
                  width: 136,
                  height: 136,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isRecording) const _Halo(),
                      Tocable(
                        alTocar: _isProcessing ? null : _toggleRecording,
                        etiqueta: _isRecording ? 'Terminar de grabar' : 'Empezar a grabar',
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
                            child: Icon(Icons.mic_none, size: 48, color: colores.sobrePrimario),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isProcessing)
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
              Semantics(
                liveRegion: true,
                child: Text(
                  _isRecording ? 'Te escucho… tocá para terminar' : _text,
                  textAlign: TextAlign.center,
                  style: textos.labelLarge?.copyWith(color: _esError ? colores.coralTexto : colores.texto),
                ),
              ),
              if (_isRecording) Text(_contador, style: textos.bodySmall?.copyWith(color: colores.suave)),
            ],
          ),
        ),
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
