import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<ThemeMode> temaModuBildirici = ValueNotifier(
  ThemeMode.system,
);
final ValueNotifier<String> temaPaletiBildirici = ValueNotifier('varsayilan');

final Map<String, Color> temaPaletiRenkleri = {
  'varsayilan': const Color(0xFF8BA88E),
  'mavi': const Color(0xFF9FB4C7),
  'pembe': const Color(0xFFD98880),
};

final Map<String, int> temaPaletiKilitGunleri = {'mavi': 3, 'pembe': 7};

bool temaPaletiAcikMi(String anahtar, int ardisikGun) {
  int? gerekliGun = temaPaletiKilitGunleri[anahtar];
  if (gerekliGun == null) return true;
  return ardisikGun >= gerekliGun;
}

Future<void> temaTercihleriniKaydet() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('temaModu', temaModuBildirici.value.name);
  await prefs.setString('temaPaleti', temaPaletiBildirici.value);
}

Future<void> temaTercihleriniYukle() async {
  final prefs = await SharedPreferences.getInstance();
  String? kayitliMod = prefs.getString('temaModu');
  if (kayitliMod != null) {
    temaModuBildirici.value = ThemeMode.values.firstWhere(
      (m) => m.name == kayitliMod,
      orElse: () => ThemeMode.system,
    );
  }
  String? kayitliPalet = prefs.getString('temaPaleti');
  if (kayitliPalet != null && temaPaletiRenkleri.containsKey(kayitliPalet)) {
    temaPaletiBildirici.value = kayitliPalet;
  }
}
