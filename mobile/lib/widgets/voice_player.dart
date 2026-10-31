import 'package:flutter/material.dart';

import '../models/scan_result.dart';
import '../services/voice_service.dart';

class VoicePlayer extends StatefulWidget {
  const VoicePlayer({required this.result, super.key});

  final ScanResult result;

  @override
  State<VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<VoicePlayer> {
  final _voice = VoiceService();
  bool _speaking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _voice.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
  }

  Future<void> _toggle() async {
    setState(() {
      _error = null;
      _speaking = !_speaking;
    });
    try {
      if (_speaking) {
        await _voice.speak(widget.result);
      } else {
        await _voice.stop();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _speaking = false;
        _error = error.toString();
      });
    }
  }

  @override
  void dispose() {
    _voice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: _toggle,
            icon: Icon(_speaking ? Icons.stop : Icons.volume_up_outlined),
            label: Text(_speaking ? 'Stop reading' : 'Read aloud'),
          ),
          if (_error != null)
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      );
}
