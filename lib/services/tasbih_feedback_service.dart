import 'package:flutter/services.dart';

/// Uses Android's waveform API for a clearly perceptible completion feedback.
/// Other platforms retain Flutter's strongest available haptic fallback.
class TasbihFeedbackService {
  static const String channelName = 'com.techtouchai.islamic/tasbih_feedback';
  static const MethodChannel _channel = MethodChannel(channelName);

  static Future<void> stageCompleted() async {
    try {
      await _channel.invokeMethod<void>('vibrateStageCompletion');
    } on MissingPluginException {
      await HapticFeedback.heavyImpact();
    }
  }
}
