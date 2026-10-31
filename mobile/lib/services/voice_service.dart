import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/scan_result.dart';
import 'api_service.dart';

class VoiceService {
  VoiceService({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;
  final FlutterTts _tts = FlutterTts();

  Future<void> speak(ScanResult result) async {
    final summary = await _api.voiceSummary(result);
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.48);
    await _tts.speak(summary);
  }

  void setCompletionHandler(VoidCallback handler) {
    _tts.setCompletionHandler(handler);
  }

  Future<void> stop() => _tts.stop();

  void dispose() {
    _api.close();
    _tts.stop();
  }
}
