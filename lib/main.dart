// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'state/global_state.dart';
import 'state/rozetler.dart';
import 'state/tema_state.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await temaTercihleriniYukle();
  await MobileAds.instance.initialize();
  runApp(const YdsApp());
}

class YdsApp extends StatelessWidget {
  const YdsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: temaPaletiBildirici,
      builder: (context, paletAnahtari, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: temaModuBildirici,
          builder: (context, mod, _) {
            Color paletRengi = temaPaletiRenkleri[paletAnahtari]!;
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'YDS Kelime Rehberi',
              themeMode: mod,
              theme: ThemeData(
                useMaterial3: true,
                colorSchemeSeed: paletRengi,
                scaffoldBackgroundColor: const Color(0xFFF5F3E9),
                fontFamily: 'Roboto',
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                colorSchemeSeed: paletRengi,
                brightness: Brightness.dark,
                fontFamily: 'Roboto',
              ),
              home: const DashboardScreen(),
            );
          },
        );
      },
    );
  }
}
