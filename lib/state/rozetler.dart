import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'global_state.dart';

// --- ROZETLER (BAŞARILAR) SİSTEMİ ---
class RozetBilgisi {
  final String baslik;
  final String aciklama;
  final IconData ikon;
  final Color renk;
  const RozetBilgisi({
    required this.baslik,
    required this.aciklama,
    required this.ikon,
    required this.renk,
  });
}

final Map<String, RozetBilgisi> rozetTanimlari = {
  'ilkAdim': const RozetBilgisi(
    baslik: 'İlk Adım',
    aciklama: '50 kelime öğrenildi.',
    ikon: Icons.emoji_events_rounded,
    renk: Color(0xFFE5C158),
  ),
  'istikrarAtesi': const RozetBilgisi(
    baslik: 'İstikrar Ateşi',
    aciklama: '7 gün üst üste çalışıldı.',
    ikon: Icons.local_fire_department_rounded,
    renk: Color(0xFFD98880),
  ),
  'kelimeAvcisi': const RozetBilgisi(
    baslik: 'Kelime Avcısı',
    aciklama: '100 kelime barajı aşıldı.',
    ikon: Icons.menu_book_rounded,
    renk: Color(0xFF8BA88E),
  ),
  'kusursuzOdak': const RozetBilgisi(
    baslik: 'Kusursuz Odak',
    aciklama: 'Günlük quiz %100 başarıyla tamamlandı.',
    ikon: Icons.psychology_rounded,
    renk: Color(0xFFBCAAD4),
  ),
  'koleksiyoner': const RozetBilgisi(
    baslik: 'Koleksiyoner',
    aciklama: 'Koleksiyonlara 25 kelime eklendi.',
    ikon: Icons.star_rounded,
    renk: Color(0xFFD69E9E),
  ),
  'ustaYazar': const RozetBilgisi(
    baslik: 'Usta Yazar',
    aciklama: 'Toplam 10 yazma alıştırması tamamlandı.',
    ikon: Icons.draw_rounded,
    renk: Color(0xFF9FB4C7),
  ),
  'kusursuzKalem': const RozetBilgisi(
    baslik: 'Kusursuz Kalem',
    aciklama: 'Genel yazma alıştırmasında (10 kelime) hiç hata yapılmadı.',
    ikon: Icons.spellcheck_rounded,
    renk: Color(0xFFF5CBA7),
  ),
};

// Rozetlerin kazanılma durumu (kalıcı hafızadan yüklenir)
Map<String, bool> kazanilanRozetler = {
  for (var anahtar in rozetTanimlari.keys) anahtar: false,
};

// İstikrar Ateşi rozeti için ardışık çalışma günü sayacı
int ardisikGunSayaci = 0;

// Usta Yazar rozeti için tamamlanan yazma alıştırması (oturum) sayacı
int yazmaAlistirmasiTamamlananSayisi = 0;

Future<void> _rozetleriKaydet() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('kazanilanRozetler', jsonEncode(kazanilanRozetler));
  await prefs.setInt('ardisikGunSayaci', ardisikGunSayaci);
}

Future<void> yazmaIlerlemesiniKaydet() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(
    'yazmaAlistirmasiTamamlananSayisi',
    yazmaAlistirmasiTamamlananSayisi,
  );
}

// Eşik değerine bağlı rozetleri (İlk Adım, Kelime Avcısı, İstikrar Ateşi,
// Koleksiyoner, Usta Yazar) mevcut ilerlemeye göre kontrol edip gerekirse açar.
Future<void> rozetleriKontrolEt() async {
  bool degisiklikOldu = false;

  if (!kazanilanRozetler['ilkAdim']! && ogrenilenKelimeler.length >= 50) {
    kazanilanRozetler['ilkAdim'] = true;
    degisiklikOldu = true;
  }
  if (!kazanilanRozetler['kelimeAvcisi']! && ogrenilenKelimeler.length >= 100) {
    kazanilanRozetler['kelimeAvcisi'] = true;
    degisiklikOldu = true;
  }
  if (!kazanilanRozetler['istikrarAtesi']! && ardisikGunSayaci >= 7) {
    kazanilanRozetler['istikrarAtesi'] = true;
    degisiklikOldu = true;
  }

  int koleksiyonToplamSayisi = koleksiyonlar.values
      .expand((liste) => liste)
      .map((k) => k['word'])
      .toSet()
      .length;
  if (!kazanilanRozetler['koleksiyoner']! && koleksiyonToplamSayisi >= 25) {
    kazanilanRozetler['koleksiyoner'] = true;
    degisiklikOldu = true;
  }

  if (!kazanilanRozetler['ustaYazar']! &&
      yazmaAlistirmasiTamamlananSayisi >= 10) {
    kazanilanRozetler['ustaYazar'] = true;
    degisiklikOldu = true;
  }

  if (degisiklikOldu) {
    await _rozetleriKaydet();
  }
}

// Kusursuz Odak rozeti olay tabanlı olduğu için (bir quiz'in bitişinde)
// eşik kontrolünden ayrı, doğrudan sonuca bakılarak tetiklenir.
Future<void> rozetKusursuzOdakKontrol(int dogruSayisi, int toplamSoru) async {
  if (!kazanilanRozetler['kusursuzOdak']! &&
      toplamSoru > 0 &&
      dogruSayisi == toplamSoru) {
    kazanilanRozetler['kusursuzOdak'] = true;
    await _rozetleriKaydet();
  }
}

// Kusursuz Kalem rozeti sadece Genel Yazma Alıştırmasında (10 kelime) hiç
// hata yapılmadan tamamlanınca açılır.
Future<void> rozetKusursuzKalemKontrol(int hataSayisi) async {
  if (!kazanilanRozetler['kusursuzKalem']! && hataSayisi == 0) {
    kazanilanRozetler['kusursuzKalem'] = true;
    await _rozetleriKaydet();
  }
}
