import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../kelimeler.dart';

// Her kelimenin metnine göre anahtarlanan aralıklı tekrar takvimi.
// Değer: {'asama': int (0-4), 'sonrakiTarih': 'yyyy-MM-dd'}
Map<String, Map<String, dynamic>> tekrarTakvimi = {};

// Aşama 1,2,3,4'e geçildiğinde kaç gün sonraya planlanacağı.
// Aşama 4'ten sonra da doğru bilinirse süresiz olarak son aralıkta
// (30 gün) döngüye devam eder, ayrı bir "ustalaşıldı" durumu yoktur.
const List<int> tekrarAraliklariGun = [1, 3, 7, 30];

String _bugununTarihi() {
  final s = DateTime.now();
  return '${s.year.toString().padLeft(4, '0')}-${s.month.toString().padLeft(2, '0')}-${s.day.toString().padLeft(2, '0')}';
}

String _tarihEkle(int gun) {
  final h = DateTime.now().add(Duration(days: gun));
  return '${h.year.toString().padLeft(4, '0')}-${h.month.toString().padLeft(2, '0')}-${h.day.toString().padLeft(2, '0')}';
}

Future<void> tekrarTakviminiKaydet() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('tekrarTakvimi', jsonEncode(tekrarTakvimi));
}

// Yükleme + eski sistemden geriye dönük göç: 'tekrarTakvimi' anahtarı
// hiç yoksa ama eski 'tekrarKelimeleri' (yanlış bilinenler) varsa, o
// kelimeleri bir kereliğine aşama 0 (hemen tekrar edilmeli) olarak yeni
// takvime taşı, sonra eski anahtarı sil.
Future<void> tekrarTakviminiYukle() async {
  final prefs = await SharedPreferences.getInstance();
  String? kayitli = prefs.getString('tekrarTakvimi');
  if (kayitli != null) {
    Map<String, dynamic> cozulmus = jsonDecode(kayitli);
    tekrarTakvimi = cozulmus.map(
      (anahtar, deger) => MapEntry(anahtar, Map<String, dynamic>.from(deger)),
    );
    return;
  }

  String? eskiTekrar = prefs.getString('tekrarKelimeleri');
  if (eskiTekrar != null) {
    List<dynamic> eskiListe = jsonDecode(eskiTekrar);
    for (var item in eskiListe) {
      String kelimeMetni = Map<String, String>.from(item)['word'] ?? '';
      if (kelimeMetni.isNotEmpty) {
        tekrarTakvimi[kelimeMetni] = {
          'asama': 0,
          'sonrakiTarih': _bugununTarihi(),
        };
      }
    }
    await tekrarTakviminiKaydet();
    await prefs.remove('tekrarKelimeleri');
  }
}

// Kelime ilk kez öğrenilenler listesine girdiğinde çağrılır.
void kelimeyiTekrarTakvimineEkle(String kelimeMetni) {
  if (kelimeMetni.isEmpty) return;
  if (!tekrarTakvimi.containsKey(kelimeMetni)) {
    tekrarTakvimi[kelimeMetni] = {'asama': 0, 'sonrakiTarih': _bugununTarihi()};
  }
}

// Doğru cevap: aşamayı bir artırır (üst sınır 4, 4'te süresiz döngü),
// sonraki tarihi ilgili aralık kadar ileri atar.
// Yanlış cevap: aşama 0'a döner, sonraki tarih bugün olur (hemen
// tekrar edilmeli listesine geri düşer).
void tekrarTakviminiGuncelle(String kelimeMetni, bool dogruBilindi) {
  if (kelimeMetni.isEmpty) return;
  var kayit = Map<String, dynamic>.from(
    tekrarTakvimi[kelimeMetni] ?? {'asama': 0, 'sonrakiTarih': _bugununTarihi()},
  );
  if (dogruBilindi) {
    int yeniAsama = ((kayit['asama'] as int) + 1).clamp(1, 4);
    kayit['asama'] = yeniAsama;
    kayit['sonrakiTarih'] = _tarihEkle(tekrarAraliklariGun[yeniAsama - 1]);
  } else {
    kayit['asama'] = 0;
    kayit['sonrakiTarih'] = _bugununTarihi();
  }
  tekrarTakvimi[kelimeMetni] = kayit;
  tekrarTakviminiKaydet();
}

// Sırası gelmiş (bugün veya daha eski tarihli) kelimelerin tam verisini
// ydsKelimeleri içinden bulup döner.
List<Map<String, String>> siraGelenKelimeleriGetir() {
  String bugun = _bugununTarihi();
  Set<String> siraGelenler = tekrarTakvimi.entries
      .where((e) => (e.value['sonrakiTarih'] as String).compareTo(bugun) <= 0)
      .map((e) => e.key)
      .toSet();
  return ydsKelimeleri.where((k) => siraGelenler.contains(k['word'])).toList();
}
