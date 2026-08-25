import 'package:flutter_tts/flutter_tts.dart';

// --- SES MOTORU (TTS) ---
final FlutterTts flutterTts = FlutterTts();

Future<void> metniSeslendir(String metin) async {
  await flutterTts
      .stop(); // Yeni bir sese başlamadan önce öncekini KESİN susturur
  await flutterTts.setLanguage("en-US");
  await flutterTts.setSpeechRate(
    0.45,
  ); // Hız hafif artırıldı (Normalden bir tık yavaş)
  await flutterTts.setVolume(1.0);
  await flutterTts.speak(metin);
}

Future<void> sesiDurdur() async {
  await flutterTts.stop();
}
