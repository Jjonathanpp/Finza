import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final SpeechToText _speech = SpeechToText();
  bool _available = false;
  bool _listening = false;
  String _text = 'Tocá el micrófono y hablá...';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final ok = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _listening = false);
        }
      },
      onError: (error) => setState(() {
        _listening = false;
        _text = 'Error: ${error.errorMsg}';
      }),
    );
    setState(() => _available = ok);
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    setState(() {
      _listening = true;
      _text = '';
    });
    await _speech.listen(
      localeId: 'es_AR',
      onResult: (result) {
        setState(() => _text = result.recognizedWords);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro por voz')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 48),
            FloatingActionButton.large(
              onPressed: _available ? _toggleListening : null,
              backgroundColor: _listening ? Colors.red : null,
              child: Icon(_listening ? Icons.stop : Icons.mic),
            ),
            const SizedBox(height: 16),
            Text(_listening ? 'Escuchando...' : 'Tocá para grabar'),
          ],
        ),
      ),
    );
  }
}
