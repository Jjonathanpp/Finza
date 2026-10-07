import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:frontend/config/theme/app_theme.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/widgets/aviso_exito.dart';
import '../../../core/widgets/app_drawer.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
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

  Future<void> _toggleRecording() async {
    // Si ya está grabando, frenamos y enviamos
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      _timer?.cancel();
      
      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _text = 'Procesando con la IA...';
      });

      if (path != null) {
        await _enviarAudioABackend(path);
      }
      return;
    }

    // Si no está grabando, pedimos permiso e iniciamos
    if (await _audioRecorder.hasPermission()) {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/finza_movimiento.m4a';

      // Iniciamos grabación en formato AAC (m4a)
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc), 
        path: filePath
      );
      
      setState(() {
        _isRecording = true;
        _recordDuration = 0;
        _text = 'Grabando... 00:00';
      });

      // Cronómetro para feedback visual
      _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
        setState(() {
          _recordDuration++;
          final minutes = _recordDuration ~/ 60;
          final seconds = _recordDuration % 60;
          _text = 'Grabando... ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        });
      });
    } else {
      setState(() => _text = 'Se necesita permiso de micrófono.');
    }
  }

  Future<void> _enviarAudioABackend(String path) async {
    try {
      final formData = FormData.fromMap({
        // Se manda el archivo físico tal cual lo espera el backend
        "audio": await MultipartFile.fromFile(path, filename: "movimiento.m4a")
      });

      // Pegamos al endpoint que ya probaste por cURL
      await ApiClient().postMultipart('/api/movimientos/procesar-audio/demo', formData);

      if (mounted) {
        mostrarExito(context, 'Movimiento registrado correctamente');
        setState(() => _text = 'Tocá el micrófono y hablá...');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _text = 'Error al procesar: $e');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro por voz')),
      drawer: const AppDrawer(),
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
                        color: _isRecording ? AppColors.danger : AppColors.muted
                      ),
                    ),
              ),
            ),
            FloatingActionButton.large(
              onPressed: _isProcessing ? null : _toggleRecording,
              backgroundColor: _isRecording ? AppColors.danger : AppColors.accent,
              foregroundColor: AppColors.accentInk,
              elevation: _isRecording ? 8 : 2,
              child: Icon(_isRecording ? Icons.stop : Icons.mic, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              _isRecording ? 'Tocá para detener y procesar' : 'Tocá para grabar',
              style: const TextStyle(color: AppColors.faint),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
