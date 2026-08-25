import 'package:flutter/material.dart';

import 'state/global_state.dart';
import 'state/rozetler.dart';
import 'services/tts_service.dart';
import 'services/quiz_generator.dart';
import 'screens/dashboard_screen.dart';
import 'screens/flashcard_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/koleksiyonlar_screen.dart';
import 'screens/tekrar_et_screen.dart';
import 'screens/kelime_arsivi_screen.dart';
import 'screens/istatistikler_screen.dart';
import 'screens/spelling_screen.dart';
import 'screens/rehber_screen.dart';
import 'screens/not_defterleri_screen.dart';

void main() {
  runApp(const YdsApp());
}

class YdsApp extends StatelessWidget {
  const YdsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'YDS Kelime Rehberi',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF8BA88E),
        scaffoldBackgroundColor: const Color(0xFFF5F3E9),
        fontFamily: 'Roboto',
      ),
      home: const DashboardScreen(),
    );
  }
}
