import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'rozetler.dart';

// --- KÜRESEL HAFIZA HAVUZLARI ---
List<Map<String, String>> ogrenilenKelimeler =
    []; // Genel Quiz buradaki kelimelerden sorulacak

List<Map<String, String>> gunlukKelimelerHafizasi = [];
List<Map<String, dynamic>> gunlukTestSorulari =
    []; // Günlük test için sabit sorular ve şıklar
int sonGirisGunu = -1;

// --- KOLEKSİYONLARIM (ESKİ FAVORİLER YERİNE) ---
Map<String, List<Map<String, String>>> koleksiyonlar = {
  'Favorilerim': [],
  'Kritik Kelimeler': [],
  'Zorlandıklarım': [],
  'Özel Liste': [],
};

class KoleksiyonStili {
  final IconData ikon;
  final Color renk;
  const KoleksiyonStili({required this.ikon, required this.renk});
}

final Map<String, KoleksiyonStili> koleksiyonStilleri = {
  'Favorilerim': const KoleksiyonStili(
    ikon: Icons.star_rounded,
    renk: Color(0xFFE5C158),
  ),
  'Kritik Kelimeler': const KoleksiyonStili(
    ikon: Icons.push_pin_rounded,
    renk: Color(0xFFD98880),
  ),
  'Zorlandıklarım': const KoleksiyonStili(
    ikon: Icons.energy_savings_leaf,
    renk: Color(0xFF8BA88E),
  ),
  'Özel Liste': const KoleksiyonStili(
    ikon: Icons.auto_awesome_rounded,
    renk: Color(0xFFBCAAD4),
  ),
};

// Pastel dairesel arka plan içinde beyaz ikon gösteren koleksiyon rozeti
Widget koleksiyonIkonDairesi(String koleksiyonAdi, {double boyut = 40}) {
  final stil = koleksiyonStilleri[koleksiyonAdi]!;
  return Container(
    width: boyut,
    height: boyut,
    decoration: BoxDecoration(color: stil.renk, shape: BoxShape.circle),
    child: Icon(stil.ikon, color: Colors.white, size: boyut * 0.55),
  );
}

// Bir kelimenin hangi koleksiyonlarda olduğunu bulur (kelime metnine göre karşılaştırır)
List<String> kelimeninKoleksiyonlari(Map<String, String> kelime) {
  return koleksiyonlar.entries
      .where((girdi) => girdi.value.any((k) => k['word'] == kelime['word']))
      .map((girdi) => girdi.key)
      .toList();
}

bool kelimeKoleksiyondaMi(Map<String, String> kelime, String koleksiyonAdi) {
  return koleksiyonlar[koleksiyonAdi]!.any((k) => k['word'] == kelime['word']);
}

Future<void> _koleksiyonlariKaydet() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('koleksiyonlarim', jsonEncode(koleksiyonlar));
}

// _koleksiyonlariKaydet private olduğu için (dosya taşıma sırasında ortaya
// çıkan bir ihtiyaç) diğer dosyalardan (örn. KoleksiyonDetayScreen) kalıcı
// kayıt tetiklemek için bu genel (public) sarmalayıcı eklendi. Davranışı
// _koleksiyonlariKaydet ile birebir aynıdır.
Future<void> koleksiyonlariKaydet() async {
  await _koleksiyonlariKaydet();
}

Future<void> koleksiyondaDegistir(String koleksiyonAdi, Map<String, String> kelime) async {
  if (kelimeKoleksiyondaMi(kelime, koleksiyonAdi)) {
    koleksiyonlar[koleksiyonAdi]!.removeWhere((k) => k['word'] == kelime['word']);
  } else {
    koleksiyonlar[koleksiyonAdi]!.add(kelime);
  }
  await _koleksiyonlariKaydet();
  await rozetleriKontrolEt();
}

// Bir kelime kartında hangi koleksiyonlara ekleneceğini seçtiren alt menü
void kelimeKoleksiyonSecimiAc(
  BuildContext context,
  Map<String, String> kelime,
  VoidCallback yenile,
) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Koleksiyonlara Ekle',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A5750),
                  ),
                ),
                const SizedBox(height: 16),
                ...koleksiyonlar.keys.map((koleksiyonAdi) {
                  bool eklendiMi = kelimeKoleksiyondaMi(kelime, koleksiyonAdi);
                  Color renk = koleksiyonStilleri[koleksiyonAdi]!.renk;
                  return CheckboxListTile(
                    value: eklendiMi,
                    activeColor: renk,
                    controlAffinity: ListTileControlAffinity.trailing,
                    secondary: koleksiyonIkonDairesi(koleksiyonAdi, boyut: 36),
                    title: Text(
                      koleksiyonAdi,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onChanged: (_) async {
                      await koleksiyondaDegistir(koleksiyonAdi, kelime);
                      setModalState(() {});
                      yenile();
                    },
                  );
                }),
              ],
            ),
          );
        },
      );
    },
  );
}

// --- NOT DEFTERLERİ (ÇOKLU NOT DEFTERİ SİSTEMİ) ---
// Her eleman {'id': ..., 'isim': ..., 'icerik': ...} şeklindedir.
List<Map<String, String>> notDefterleri = [];

Future<void> notDefterleriKaydet() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('notDefterleri', jsonEncode(notDefterleri));
}

Future<void> notDefterleriYukle() async {
  final prefs = await SharedPreferences.getInstance();
  String? kayitliDefterler = prefs.getString('notDefterleri');
  if (kayitliDefterler != null) {
    List<dynamic> cozulmus = jsonDecode(kayitliDefterler);
    notDefterleri = cozulmus
        .map((item) => Map<String, String>.from(item))
        .toList();
    return;
  }

  // GERİYE DÖNÜK UYUMLULUK: eski tekil not varsa "Notlarım" adıyla
  // ilk defter olarak bir kereliğine taşı.
  String? eskiNot = prefs.getString('kullanici_notu');
  if (eskiNot != null && eskiNot.isNotEmpty) {
    notDefterleri = [
      {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'isim': 'Notlarım',
        'icerik': eskiNot,
      },
    ];
    await notDefterleriKaydet();
  }
}
