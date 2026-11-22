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
import 'package:frontend/l10n/idioma.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  late final AudioRecorder _audioRecorder;

  bool _isRecording = false;
  bool _isPaused = false;
  bool _isProcessing = false;
  String _text = 'Tocá el micrófono y hablá...';

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

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {
        _recordDuration++;
        _actualizarTextoTiempo();
      });
    });
  }

  void _actualizarTextoTiempo() {
    final minutes = _recordDuration ~/ 60;
    final seconds = _recordDuration % 60;
    final tiempoFormateado = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    if (_isPaused) {
      _text = 'Pausado... $tiempoFormateado';
    } else {
      _text = 'Grabando... $tiempoFormateado';
    }
  }

  Future<void> _iniciarGrabacion() async {
    if (await _audioRecorder.hasPermission()) {
      if (kIsWeb) {
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.opus),
          path: '',
        );
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/finza_movimiento.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: filePath,
        );
      }

      setState(() {
        _isRecording = true;
        _isPaused = false;
        _recordDuration = 0;
        _actualizarTextoTiempo();
      });

      _startTimer();
    } else {
      setState(() => _text = tr('Se necesita permiso de micrófono.'));
    }
  }

  Future<void> _pausarGrabacion() async {
    await _audioRecorder.pause();
    _timer?.cancel();
    setState(() {
      _isPaused = true;
      _actualizarTextoTiempo();
    });
  }

  Future<void> _reanudarGrabacion() async {
    await _audioRecorder.resume();
    setState(() {
      _isPaused = false;
      _actualizarTextoTiempo();
    });
    _startTimer();
  }

  Future<void> _cancelarYBorrarGrabacion() async {
    await _audioRecorder.stop();
    _timer?.cancel();

    setState(() {
      _isRecording = false;
      _isPaused = false;
      _recordDuration = 0;
      _text = 'Tocá el micrófono y hablá...';
    });
  }

  Future<void> _finalizarYEnviarAudio() async {
    final path = await _audioRecorder.stop();
    _timer?.cancel();

    setState(() {
      _isRecording = false;
      _isPaused = false;
      _isProcessing = true;
      _text = 'Procesando con la IA...';
    });

    if (path != null) {
      await _enviarAudioABackend(path);
    } else {
      setState(() {
        _isProcessing = false;
        _text = 'Error: No se pudo guardar el audio localmente.';
      });
    }
  }

  Future<void> _enviarAudioABackend(String path) async {
    try {
      final MultipartFile audioFile;

      if (kIsWeb) {
        final response = await Dio().get<List<int>>(
          path,
          options: Options(responseType: ResponseType.bytes),
        );
        audioFile = MultipartFile.fromBytes(
          response.data!,
          filename: "movimiento.webm",
        );
      } else {
        audioFile = await MultipartFile.fromFile(
          path,
          filename: "movimiento.m4a",
        );
      }

      final formData = FormData.fromMap({
        "audio": audioFile,
      });

      await ApiClient().postMultipart('/api/movimientos/procesar-audio', formData);

      if (mounted) {
        mostrarExito(context, 'Audio enviado. Procesando en segundo plano.');
        setState(() => _text = 'Tocá el micrófono y hablá...');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _text = 'Error en el servidor de la IA');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: barraConVolver(context, context.tr('Registro por voz')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _isProcessing
                    ? const CircularProgressIndicator(color: AppColors.accent)
                    : Text(
                        _text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: _isRecording ? FontWeight.bold : FontWeight.normal,
                          color: (_isRecording && !_isPaused) ? AppColors.danger : AppColors.text,
                        ),
                      ),
              ),
            ),
            if (!_isRecording && !_isProcessing)
              FloatingActionButton.large(
                onPressed: _iniciarGrabacion,
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 4,
                child: const Icon(Icons.mic, size: 36),
              )
            else if (_isRecording)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    heroTag: 'btn_cancelar',
                    onPressed: _cancelarYBorrarGrabacion,
                    backgroundColor: AppColors.surface2,
                    foregroundColor: AppColors.danger,
                    elevation: 1,
                    child: const Icon(Icons.delete_outline, size: 28),
                  ),
                  const SizedBox(width: 24),
                  FloatingActionButton.large(
                    heroTag: 'btn_pausa',
                    onPressed: _isPaused ? _reanudarGrabacion : _pausarGrabacion,
                    backgroundColor: _isPaused ? AppColors.accent : AppColors.surface3,
                    foregroundColor: _isPaused ? Colors.white : AppColors.text,
                    elevation: _isPaused ? 4 : 2,
                    child: Icon(_isPaused ? Icons.mic : Icons.pause, size: 36),
                  ),
                  const SizedBox(width: 24),
                  FloatingActionButton(
                    heroTag: 'btn_enviar',
                    onPressed: _finalizarYEnviarAudio,
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    child: const Icon(Icons.send, size: 24),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Text(
              _isProcessing
                  ? 'Aguardá un momento...'
                  : _isRecording
                      ? (_isPaused ? 'Grabación pausada' : 'Grabando ahora...')
                      : 'Tocá para grabar',
              style: const TextStyle(color: AppColors.faint),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}