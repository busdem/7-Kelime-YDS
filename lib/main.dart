import 'package:flutter/material.dart';

import 'kelimeler.dart';

import 'package:flutter_tts/flutter_tts.dart';

import 'package:shared_preferences/shared_preferences.dart'; // Eğer hata verirse bunu en üste import'lara ekle

import 'dart:convert'; // JSON çevirisi için gerekli

// --- KÜRESEL HAFIZA HAVUZLARI ---
List<Map<String, String>> ogrenilenKelimeler =
    []; // Genel Quiz buradaki kelimelerden sorulacak
List<Map<String, String>> tekrarEdilecekKelimeler =
    []; // Yanlış bilinenler buraya düşecek

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

// --- DİNAMİK SORU ÜRETİCİ (Yapay Zeka Gibi Çalışır) ---
List<Map<String, dynamic>> dinamikSoruUret(
  List<Map<String, String>> kaynakKelimeler,
) {
  List<Map<String, dynamic>> uretilenSorular = [];
  var tumKelimeler = List<Map<String, String>>.from(ydsKelimeleri);

  for (var kelime in kaynakKelimeler) {
    String dogruCevap = kelime['meaning'] ?? '';
    List<String> secenekler = [dogruCevap];

    tumKelimeler.shuffle();
    for (var rKelime in tumKelimeler) {
      if (secenekler.length >= 4) break;
      String anlam = rKelime['meaning'] ?? '';
      if (!secenekler.contains(anlam)) {
        secenekler.add(anlam);
      }
    }
    secenekler.shuffle(); // Şıkların yerini karıştır

    uretilenSorular.add({'kelime': kelime, 'secenekler': secenekler});
  }
  return uretilenSorular;
}

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

// --- ANA SAYFA (DASHBOARD) ---
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _verileriHafizadanYukle(); // Uygulama açıldığında ilk iş hafızayı okuyacağız!
  }

  Future<void> _verileriHafizadanYukle() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      // 1. KOLEKSİYONLARI GERİ GETİR
      String? kayitliKoleksiyonlar = prefs.getString('koleksiyonlarim');
      if (kayitliKoleksiyonlar != null) {
        Map<String, dynamic> cozulmusKoleksiyonlar = jsonDecode(
          kayitliKoleksiyonlar,
        );
        cozulmusKoleksiyonlar.forEach((koleksiyonAdi, liste) {
          if (koleksiyonlar.containsKey(koleksiyonAdi)) {
            koleksiyonlar[koleksiyonAdi] = (liste as List<dynamic>)
                .map((item) => Map<String, String>.from(item))
                .toList();
          }
        });
      } else {
        // Eski tekil favori listesi varsa 'Favorilerim' koleksiyonuna taşı
        String? kayitliFavoriler = prefs.getString('favorilerim');
        if (kayitliFavoriler != null) {
          List<dynamic> cozulmusListe = jsonDecode(kayitliFavoriler);
          koleksiyonlar['Favorilerim'] = cozulmusListe
              .map((item) => Map<String, String>.from(item))
              .toList();
          prefs.setString('koleksiyonlarim', jsonEncode(koleksiyonlar));
        }
      }

      // 2. TEKRAR EDİLECEK KELİMELERİ GERİ GETİR
      String? kayitliTekrar = prefs.getString('tekrarKelimeleri');
      if (kayitliTekrar != null) {
        List<dynamic> cozulmusTekrar = jsonDecode(kayitliTekrar);
        tekrarEdilecekKelimeler = cozulmusTekrar
            .map((item) => Map<String, String>.from(item))
            .toList();
      }

      // --- 3. ÖĞRENİLEN KELİMELERİ GERİ GETİR VE ÇİFTLERİ TEMİZLE ---
      String? kayitliOgrenilenler = prefs.getString('ogrenilenler');
      if (kayitliOgrenilenler != null) {
        List<dynamic> cozulmusOgrenilen = jsonDecode(kayitliOgrenilenler);
        List<Map<String, String>> geciciListe = cozulmusOgrenilen
            .map((item) => Map<String, String>.from(item))
            .toList();

        // TEMİZLİK FİLTRESİ: Aynı kelime zaten eklendiyse, kopyasını çöpe at!
        List<Map<String, String>> temizlenmisListe = [];
        for (var k in geciciListe) {
          if (!temizlenmisListe.any(
            (eklenen) => eklenen['word'] == k['word'],
          )) {
            temizlenmisListe.add(k);
          }
        }

        // Pırıl pırıl, tekil listemizi ana havuza aktarıyoruz
        ogrenilenKelimeler = temizlenmisListe;

        // Temizlenmiş kusursuz halini anında telefona kaydet ki bir daha eski hatalı veriyi okumasın!
        prefs.setString('ogrenilenler', jsonEncode(ogrenilenKelimeler));
      }

      // 4. GÜNLÜK KELİMELERİ KONTROL ET (Katlanma sorununu çözen kısım)
      DateTime simdi = DateTime.now();
      int bugun = simdi.year * 10000 + simdi.month * 100 + simdi.day;
      int kaydedilenGun = prefs.getInt('sonGirisGunu') ?? -1;

      if (kaydedilenGun != bugun) {
        var kopyaListe = List<Map<String, String>>.from(ydsKelimeleri)
          ..shuffle();
        gunlukKelimelerHafizasi = kopyaListe.take(7).toList();

        for (var kelime in gunlukKelimelerHafizasi) {
          // 'word' yani İngilizce kelimenin metnine bakarak kontrol ediyoruz!
          bool zatenVarMi = ogrenilenKelimeler.any(
            (k) => k['word'] == kelime['word'],
          );
          if (!zatenVarMi) {
            ogrenilenKelimeler.add(kelime);
          }
        }

        gunlukTestSorulari = dinamikSoruUret(gunlukKelimelerHafizasi);
        sonGirisGunu = bugun;

        prefs.setInt('sonGirisGunu', bugun);
        prefs.setString('gunlukKelimeler', jsonEncode(gunlukKelimelerHafizasi));
        prefs.setString('ogrenilenler', jsonEncode(ogrenilenKelimeler));
      } else {
        String? kayitliGunlukKelimeler = prefs.getString('gunlukKelimeler');
        if (kayitliGunlukKelimeler != null) {
          List<dynamic> cozulmusGunluk = jsonDecode(kayitliGunlukKelimeler);
          gunlukKelimelerHafizasi = cozulmusGunluk
              .map((item) => Map<String, String>.from(item))
              .toList();

          gunlukTestSorulari = dinamikSoruUret(gunlukKelimelerHafizasi);
          sonGirisGunu = bugun;

          bool yeniOgrenilenVarMi = false;
          for (var kelime in gunlukKelimelerHafizasi) {
            bool zatenVarMi = ogrenilenKelimeler.any(
              (k) => k['word'] == kelime['word'],
            );
            if (!zatenVarMi) {
              ogrenilenKelimeler.add(kelime);
              yeniOgrenilenVarMi = true;
            }
          }
          if (yeniOgrenilenVarMi) {
            prefs.setString('ogrenilenler', jsonEncode(ogrenilenKelimeler));
          }
        }
      }

      // 5. ROZETLERİ VE ARDIŞIK GÜN SERİSİNİ GERİ GETİR
      String? kayitliRozetler = prefs.getString('kazanilanRozetler');
      if (kayitliRozetler != null) {
        Map<String, dynamic> cozulmusRozetler = jsonDecode(kayitliRozetler);
        cozulmusRozetler.forEach((anahtar, deger) {
          if (kazanilanRozetler.containsKey(anahtar)) {
            kazanilanRozetler[anahtar] = deger as bool;
          }
        });
      }

      ardisikGunSayaci = prefs.getInt('ardisikGunSayaci') ?? 0;
      yazmaAlistirmasiTamamlananSayisi =
          prefs.getInt('yazmaAlistirmasiTamamlananSayisi') ?? 0;
      DateTime bugunTarih = DateTime(simdi.year, simdi.month, simdi.day);
      String? sonAktifTarihStr = prefs.getString('sonAktifTarih');
      if (sonAktifTarihStr == null) {
        ardisikGunSayaci = 1;
      } else {
        DateTime sonAktifTarih = DateTime.parse(sonAktifTarihStr);
        int farkGun = bugunTarih.difference(sonAktifTarih).inDays;
        if (farkGun == 1) {
          ardisikGunSayaci++;
        } else if (farkGun > 1) {
          ardisikGunSayaci = 1;
        }
        // farkGun == 0 ise (bugün zaten açılmışsa) sayaç aynı kalır
      }
      prefs.setInt('ardisikGunSayaci', ardisikGunSayaci);
      prefs.setString('sonAktifTarih', bugunTarih.toIso8601String());
    });

    await rozetleriKontrolEt();
  }

  void _quizMenusuAc(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Quiz Modunu Seçin',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A5750),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(
                  Icons.today,
                  color: Color(0xFF8BA88E),
                  size: 32,
                ),
                title: const Text(
                  'Günün Testi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF4A5750),
                  ),
                ),
                subtitle: const Text('Bugün öğrendiğin 7 kelimeyi test et.'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const QuizScreen(isDailyTest: true),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.public,
                  color: Color(0xFFC4B495),
                  size: 32,
                ),
                title: const Text(
                  'Genel Tekrar',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF4A5750),
                  ),
                ),
                subtitle: const Text(
                  'Şu ana kadar öğrendiklerinden 10 soruluk rastgele test.',
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (ogrenilenKelimeler.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Henüz kelime öğrenmedin! Önce günün kelimelerine çalış.',
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const QuizScreen(isDailyTest: false),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _yazmaMenusuAc(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Yazma Alıştırması Modunu Seçin',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A5750),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(
                  Icons.today,
                  color: Color(0xFF9FB4C7),
                  size: 32,
                ),
                title: const Text(
                  'Günün Yazma Alıştırması',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF4A5750),
                  ),
                ),
                subtitle: const Text('Bugün öğrendiğin 7 kelimeyi yaz.'),
                onTap: () {
                  Navigator.pop(context);
                  if (gunlukKelimelerHafizasi.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bugün için henüz kelime yüklenmedi.'),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SpellingScreen(isDailyMode: true),
                      ),
                    );
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.shuffle_rounded,
                  color: Color(0xFF9FB4C7),
                  size: 32,
                ),
                title: const Text(
                  'Genel Yazma Alıştırması',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF4A5750),
                  ),
                ),
                subtitle: const Text(
                  'Öğrendiklerinden rastgele 10 kelimeyi yaz.',
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (ogrenilenKelimeler.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Henüz kelime öğrenmedin! Önce günün kelimelerine çalış.',
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const SpellingScreen(isDailyMode: false),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'YDS Kelime Rehberi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A5750),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Hoş geldin!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A5750),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bugünün kelimeleri seni bekliyor.',
                style: TextStyle(fontSize: 16, color: Color(0xFF6B7B70)),
              ),
              const SizedBox(height: 32),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.62,
                children: [
                  _buildMenuCard(
                    title: 'Bugünün\nKelimeleri',
                    icon: Icons.style,
                    color: const Color(0xFF8BA88E),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FlashcardHomeScreen(),
                      ),
                    ),
                  ),
                  _buildMenuCard(
                    title: 'Tekrar Et',
                    icon: Icons.history,
                    color: const Color(0xFF9CB4A1),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TekrarEtScreen()),
                    ),
                  ),
                  _buildMenuCard(
                    title: 'Koleksiyonlarım',
                    icon: Icons.collections_bookmark,
                    color: const Color(0xFFD69E9E),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const KoleksiyonlarimScreen(),
                      ),
                    ),
                  ),
                  _buildMenuCard(
                    title: 'Quiz (Sınav)',
                    icon: Icons.quiz_outlined,
                    color: const Color(0xFFC4B495),
                    onTap: () => _quizMenusuAc(context),
                  ),
                  _buildMenuCard(
                    title: 'Yazma\nAlıştırması',
                    icon: Icons.draw_rounded,
                    color: const Color(0xFF9FB4C7),
                    onTap: () => _yazmaMenusuAc(context),
                  ),
                  _buildMenuCard(
                    title: 'Kelime Arşivim',
                    icon: Icons.library_books_rounded,
                    color: const Color(0xFF7D8C81),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const KelimeArsiviScreen(),
                      ),
                    ),
                  ),
                  _buildMenuCard(
                    title: 'İstatistikler',
                    icon: Icons.analytics_outlined,
                    color: const Color(0xFFB4A5A5),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const IstatistiklerScreen(),
                      ),
                    ),
                  ),
                  _buildMenuCard(
                    title: 'Rehber & Notlar',
                    icon: Icons.menu_book,
                    color: const Color(0xFFC4B495),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RehberVeNotlarScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5750),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- QUIZ (SINAV) EKRANI ---
class QuizScreen extends StatefulWidget {
  final bool isDailyTest;
  final bool isTekrarTesti;
  const QuizScreen({
    super.key,
    required this.isDailyTest,
    this.isTekrarTesti = false,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Map<String, dynamic>> _aktifSorular = [];
  int _aktifSoruIndex = 0;
  int _dogruSayisi = 0;
  bool _cevapVerildi = false;
  String _secilenCevap = '';

  @override
  void initState() {
    super.initState();
    _sinaviBaslat();
  }

  void _sinaviBaslat() {
    if (widget.isTekrarTesti) {
      // Tekrar Testi: sadece 'Çalışmam Gerekenler' listesindeki kelimelerden sorulur
      var kopyaTekrar = List<Map<String, String>>.from(tekrarEdilecekKelimeler)
        ..shuffle();
      _aktifSorular = dinamikSoruUret(kopyaTekrar);
    } else if (widget.isDailyTest) {
      _aktifSorular = gunlukTestSorulari;
    } else {
      // Genel tekrar için öğrenilenlerden rastgele 10 soru üret
      var kopyaOgrenilen = List<Map<String, String>>.from(ogrenilenKelimeler)
        ..shuffle();
      int soruSayisi = kopyaOgrenilen.length >= 10 ? 10 : kopyaOgrenilen.length;
      _aktifSorular = dinamikSoruUret(kopyaOgrenilen.take(soruSayisi).toList());
    }
    _dogruSayisi = 0;
    _aktifSoruIndex = 0;
    _cevapVerildi = false;
    _secilenCevap = '';
  }

  void _cevapKontrol(
    String cevap,
    String dogruCevap,
    Map<String, String> kelime,
  ) async {
    // İŞTE KORUMA KALKANIMIZ!
    // Eğer şık daha önce seçildiyse aşağıyı hiç okuma ve durdur:
    if (_cevapVerildi) return;

    setState(() {
      _cevapVerildi = true;
      _secilenCevap = cevap;
      if (cevap == dogruCevap) {
        _dogruSayisi++;
        // Tekrar Testinde doğru bilinen kelime, çalışılacaklar listesinden çıkar
        if (widget.isTekrarTesti) {
          tekrarEdilecekKelimeler.removeWhere(
            (k) => k['word'] == kelime['word'],
          );
        }
      } else {
        // Yanlış bilindiyse otomatik olarak Tekrar Et havuzuna ekle
        if (!tekrarEdilecekKelimeler.any((k) => k['word'] == kelime['word'])) {
          tekrarEdilecekKelimeler.add(kelime);
        }
      }
    });

    // KAYDETME İŞLEMİ (setState'in dışında, sorunsuz çalışacak)
    if (cevap != dogruCevap || widget.isTekrarTesti) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'tekrarKelimeleri',
        jsonEncode(tekrarEdilecekKelimeler),
      );
    }
  }

  void _sonrakiSoru() {
    setState(() {
      if (_aktifSoruIndex < _aktifSorular.length - 1) {
        _aktifSoruIndex++;
        _cevapVerildi = false;
        _secilenCevap = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isTekrarTesti
              ? 'Tekrar Testi'
              : (widget.isDailyTest ? 'Günün Testi' : 'Genel Tekrar'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFC4B495),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _buildSoruEkrani(),
    );
  }

  Widget _buildSoruEkrani() {
    if (_aktifSorular.isEmpty)
      return const Center(child: Text("Soru bulunamadı."));

    var soruData = _aktifSorular[_aktifSoruIndex];
    Map<String, String> kelime = soruData['kelime'];
    List<String> secenekler = soruData['secenekler'];
    String dogruCevap = kelime['meaning'] ?? '';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Soru ${_aktifSoruIndex + 1} / ${_aktifSorular.length}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC4B495),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_aktifSoruIndex + 1) / _aktifSorular.length,
            backgroundColor: const Color(0xFFC4B495).withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC4B495)),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFC4B495).withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC4B495).withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  kelime['word'] ?? '',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A5750),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView.builder(
              itemCount: secenekler.length,
              itemBuilder: (context, index) {
                String secenek = secenekler[index];

                // Renk mantığı
                Color butonRengi = Colors.white;
                Color yaziRengi = const Color(0xFF4A5750);
                Color borderRengi = Colors.grey.shade300;
                bool secildiMi = false;

                if (_cevapVerildi) {
                  if (secenek == _secilenCevap)
                    secildiMi = true; // Tıklanan şıkkı büyütmek için işaretle
                  if (secenek == dogruCevap) {
                    butonRengi = const Color(0xFF8BA88E); // Doğru Yeşil
                    yaziRengi = Colors.white;
                    borderRengi = const Color(0xFF8BA88E);
                  } else if (secenek == _secilenCevap &&
                      secenek != dogruCevap) {
                    butonRengi = const Color(0xFFD69E9E); // Yanlış Kırmızı
                    yaziRengi = Colors.white;
                    borderRengi = const Color(0xFFD69E9E);
                  }
                }

                // Animasyonlu Şık Butonu
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: AnimatedScale(
                    scale: secildiMi
                        ? 1.05
                        : 1.0, // Seçilen şık öne doğru hafif büyür
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: InkWell(
                      onTap: () => _cevapKontrol(secenek, dogruCevap, kelime),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: butonRengi,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderRengi, width: 2),
                        ),
                        child: Text(
                          secenek,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: yaziRengi,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_cevapVerildi && _aktifSoruIndex < _aktifSorular.length - 1)
            ElevatedButton(
              onPressed: _sonrakiSoru,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC4B495),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Sonraki Soru',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          if (_cevapVerildi && _aktifSoruIndex == _aktifSorular.length - 1)
            ElevatedButton(
              onPressed: () async {
                // Kusursuz Odak rozeti sadece günlük testte %100 başarı ile açılır
                if (widget.isDailyTest) {
                  await rozetKusursuzOdakKontrol(
                    _dogruSayisi,
                    _aktifSorular.length,
                  );
                }
                if (!mounted) return;
                // YENİ EKRANA GEÇİŞ KISMI
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizSonucScreen(
                      dogruSayisi: _dogruSayisi,
                      yanlisSayisi: _aktifSorular.length - _dogruSayisi, // Toplamdan doğruyu çıkarınca yanlış kalır :)
                      toplamSoru: _aktifSorular.length,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC4B495),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Sonuçları Gör',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}

// --- FAVORİLER VE DÖNEN KART (Eski kodlarının aynısı, dokunmadım) ---
// Not: Hata almamak için bir önceki mesajda çalışan Favoriler ve FlashcardHomeScreen kodları da burada var say.
// Tamamı kopyalanabilir olsun diye aşağıya onları da ekliyorum.

// --- KOLEKSİYONLARIM EKRANI (Klasör Merkezi) ---

class KoleksiyonlarimScreen extends StatefulWidget {
  const KoleksiyonlarimScreen({super.key});

  @override
  State<KoleksiyonlarimScreen> createState() => _KoleksiyonlarimScreenState();
}

class _KoleksiyonlarimScreenState extends State<KoleksiyonlarimScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Koleksiyonlarım',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFD69E9E),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(20),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.95,
        children: koleksiyonlar.keys.map((koleksiyonAdi) {
          Color renk = koleksiyonStilleri[koleksiyonAdi]!.renk;
          int adet = koleksiyonlar[koleksiyonAdi]!.length;
          return InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => KoleksiyonDetayScreen(koleksiyonAdi: koleksiyonAdi),
              ),
            ),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: renk.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: renk.withOpacity(0.25), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  koleksiyonIkonDairesi(koleksiyonAdi, boyut: 48),
                  const SizedBox(height: 12),
                  Text(
                    koleksiyonAdi,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A5750),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$adet kelime',
                    style: TextStyle(fontSize: 13, color: renk),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// --- KOLEKSİYON DETAY EKRANI (Arama Özellikli) ---

class KoleksiyonDetayScreen extends StatefulWidget {
  final String koleksiyonAdi;
  const KoleksiyonDetayScreen({super.key, required this.koleksiyonAdi});

  @override
  State<KoleksiyonDetayScreen> createState() => _KoleksiyonDetayScreenState();
}

class _KoleksiyonDetayScreenState extends State<KoleksiyonDetayScreen> {
  String _aramaMetni = '';

  Future<void> _kelimeyiKaldir(Map<String, String> kelime) async {
    setState(() {
      koleksiyonlar[widget.koleksiyonAdi]!.removeWhere(
        (k) => k['word'] == kelime['word'],
      );
    });
    await _koleksiyonlariKaydet();
  }

  @override
  Widget build(BuildContext context) {
    Color renk = koleksiyonStilleri[widget.koleksiyonAdi]!.renk;
    List<Map<String, String>> kelimeler = koleksiyonlar[widget.koleksiyonAdi]!;

    List<Map<String, String>> gosterilecekKelimeler = kelimeler.where((
      kelime,
    ) {
      return (kelime['word'] ?? '').toLowerCase().startsWith(
        _aramaMetni.toLowerCase(),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            koleksiyonIkonDairesi(widget.koleksiyonAdi, boyut: 32),
            const SizedBox(width: 10),
            Text(
              widget.koleksiyonAdi,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: renk,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (kelimeler.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Bu koleksiyonda ara...',
                  prefixIcon: Icon(Icons.search, color: renk),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (deger) => setState(() => _aramaMetni = deger),
              ),
            ),
          Expanded(
            child: kelimeler.isEmpty
                ? Center(
                    child: Text(
                      'Bu koleksiyona henüz\nbir kelime eklenmedi.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF6B7B70),
                      ),
                    ),
                  )
                : gosterilecekKelimeler.isEmpty
                ? const Center(
                    child: Text(
                      'Aradığınız kelime bu koleksiyonda bulunamadı.',
                      style: TextStyle(color: Color(0xFF6B7B70)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: gosterilecekKelimeler.length,
                    itemBuilder: (context, index) {
                      final kelime = gosterilecekKelimeler[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          title: Text(
                            kelime['word'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF4A5750),
                            ),
                          ),
                          subtitle: Text(
                            kelime['meaning'] ?? '',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF6B7B70),
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.close, color: renk),
                            tooltip: 'Koleksiyondan çıkar',
                            onPressed: () => _kelimeyiKaldir(kelime),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SingleFlashcardScreen(kelime: kelime),
                            ),
                          ).then((_) => setState(() {})),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class FlashcardHomeScreen extends StatefulWidget {
  const FlashcardHomeScreen({super.key});
  @override
  State<FlashcardHomeScreen> createState() => _FlashcardHomeScreenState();
}

class _FlashcardHomeScreenState extends State<FlashcardHomeScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isFlipped = false;

  @override
  void dispose() {
    sesiDurdur(); // Ekrandan çıkıldığında sesi tamamen kapat
    _pageController.dispose();
    super.dispose();
  }

  void _sayfaDegisti(int index) {
    sesiDurdur(); // Diğer karta geçerken sesi kes
    setState(() {
      _currentIndex = index;
      _isFlipped = false;
    });
  }

  Widget _koleksiyonRozetleri(List<String> uyeOlduguKoleksiyonlar) {
    if (uyeOlduguKoleksiyonlar.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 4,
      alignment: WrapAlignment.end,
      children: uyeOlduguKoleksiyonlar
          .map((ad) => koleksiyonIkonDairesi(ad, boyut: 18))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Günün Kelimeleri',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF8BA88E),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            '${_currentIndex + 1} / ${gunlukKelimelerHafizasi.length}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8BA88E),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _sayfaDegisti,
              itemCount: gunlukKelimelerHafizasi.length,
              itemBuilder: (context, index) {
                final kelime = gunlukKelimelerHafizasi[index];
                return GestureDetector(
                  onTap: () => setState(() => _isFlipped = !_isFlipped),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (
                      Widget child,
                      Animation<double> animation,
                    ) => FadeTransition(opacity: animation, child: child),
                    child: _isFlipped
                        ? _buildBackCard(kelime)
                        : _buildFrontCard(kelime),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrontCard(Map<String, String> kelime) {
    List<String> uyeOlduguKoleksiyonlar = kelimeninKoleksiyonlari(kelime);
    return Card(
      key: const ValueKey(true),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      color: const Color(0xFF8BA88E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 6,
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // YENİ: Kelime ve yanına hoparlör butonu
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, // Merkeze sıkıca topla
                  children: [
                    // İŞTE SİHİR BURADA: Uzun kelimeleri taşırmak yerine alt satıra atar
                    Flexible(
                      child: Text(
                        kelime['word'] ?? '',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign:
                            TextAlign.center, // Alt satıra inerse ortalı dursun
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.volume_up,
                        color: Colors.white,
                        size: 36,
                      ),
                      onPressed: () {
                        // Tıklanınca yukarıda yazdığımız motor çalışır
                        metniSeslendir(kelime['word'] ?? '');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Icon(Icons.touch_app, color: Colors.white70, size: 36),
                const SizedBox(height: 12),
                const Text(
                  'Anlamı görmek için dokun',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    uyeOlduguKoleksiyonlar.isNotEmpty
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: () => kelimeKoleksiyonSecimiAc(
                    context,
                    kelime,
                    () => setState(() {}),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _koleksiyonRozetleri(uyeOlduguKoleksiyonlar),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard(Map<String, String> kelime) {
    List<String> uyeOlduguKoleksiyonlar = kelimeninKoleksiyonlari(kelime);
    return Card(
      key: const ValueKey(false),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF8BA88E), width: 2),
      ),
      elevation: 6,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      kelime['meaning'] ?? '',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A5750),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8BA88E).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${kelime['type']}  •  ${kelime['ipa']}',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF4A5750),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(color: Color(0xFFE0E5E2)),
                    ),
                    const Text(
                      'Örnek Cümle:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8BA88E),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // --- SESLİ OKUMA İKONU ALT SIRA ALINDI ---
                    Column(
                      children: [
                        Text(
                          kelime['sentence'] ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF4A5750),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(
                          height: 8,
                        ), // Cümle ile ikon arası hafif boşluk
                        IconButton(
                          icon: const Icon(
                            Icons.volume_up,
                            color: Color(0xFF8BA88E),
                            size: 32, // Alt satırda daha dengeli dursun diye hafif büyüttüm
                          ),
                          onPressed: () {
                            metniSeslendir(kelime['sentence'] ?? '');
                          },
                        ),
                      ],
                    ),
                    // ----------------------------------------

                    const SizedBox(height: 12),
                    Text(
                      kelime['translation'] ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6B7B70),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    uyeOlduguKoleksiyonlar.isNotEmpty
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: const Color(0xFF8BA88E),
                    size: 32,
                  ),
                  onPressed: () => kelimeKoleksiyonSecimiAc(
                    context,
                    kelime,
                    () => setState(() {}),
                  ),
                ),
                _koleksiyonRozetleri(uyeOlduguKoleksiyonlar),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SingleFlashcardScreen extends StatefulWidget {
  final Map<String, String> kelime;
  const SingleFlashcardScreen({super.key, required this.kelime});
  @override
  State<SingleFlashcardScreen> createState() => _SingleFlashcardScreenState();
}

class _SingleFlashcardScreenState extends State<SingleFlashcardScreen> {
  bool _isFlipped = false;
  @override
  void dispose() {
    sesiDurdur(); // Ekrandan çıkınca sesi anında kes
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.kelime['word'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFD69E9E),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: GestureDetector(
          onTap: () => setState(() => _isFlipped = !_isFlipped),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (Widget child, Animation<double> animation) =>
                FadeTransition(opacity: animation, child: child),
            child: _isFlipped ? _buildBackCard() : _buildFrontCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildFrontCard() {
    return Card(
      key: const ValueKey(true),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      color: const Color(0xFFD69E9E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 6,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        width: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, // YENİ: Ortada sıkıca tut
                children: [
                  // YENİ: Uzun metni esnetip alt satıra geçiren Flexible!
                  Flexible(
                    child: Text(
                      widget.kelime['word'] ?? '',
                      textAlign:
                          TextAlign.center, // Alt satıra inerse ortalansın
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.volume_up,
                      color: Colors.white,
                      size: 36,
                    ),
                    onPressed: () =>
                        metniSeslendir(widget.kelime['word'] ?? ''),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Icon(Icons.touch_app, color: Colors.white70, size: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackCard() {
    return Card(
      key: const ValueKey(false),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFD69E9E), width: 2),
      ),
      elevation: 6,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.kelime['meaning'] ?? '',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A5750),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  '${widget.kelime['type']}  •  ${widget.kelime['ipa']}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF4A5750),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Divider(color: Color(0xFFE0E5E2)),
                ),
                const Text(
                  'Örnek Cümle:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD69E9E),
                  ),
                ),
                const SizedBox(height: 12),

                // --- SESLİ OKUMA İKONU ALT SIRA ALINDI ---
                Column(
                  children: [
                    Text(
                      widget.kelime['sentence'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF4A5750),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 8,
                    ), // Cümle ile hoparlör arası boşluk
                    IconButton(
                      icon: const Icon(
                        Icons.volume_up,
                        color: Color(0xFFD69E9E),
                        size: 32, // Estetik dursun diye biraz büyüttüm
                      ),
                      onPressed: () =>
                          metniSeslendir(widget.kelime['sentence'] ?? ''),
                    ),
                  ],
                ),
                // ----------------------------------------

                const SizedBox(height: 12),
                Text(
                  widget.kelime['translation'] ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6B7B70),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// --- TEKRAR ET (ÇALIŞMAM GEREKENLER) EKRANI ---

class TekrarEtScreen extends StatefulWidget {
  const TekrarEtScreen({super.key});

  @override
  State<TekrarEtScreen> createState() => _TekrarEtScreenState();
}

class _TekrarEtScreenState extends State<TekrarEtScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Çalışmam Gerekenler',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(
          0xFF9CB4A1,
        ), // Ana sayfadaki butonla aynı renk
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (tekrarEdilecekKelimeler.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const QuizScreen(
                          isDailyTest: false,
                          isTekrarTesti: true,
                        ),
                      ),
                    );
                    // Testten dönüşte doğru bilinen kelimeler listeden
                    // düşmüş olabilir, ekranı tazele.
                    setState(() {});
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text(
                    'Tekrar Testine Başla',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9CB4A1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
            ),
          Expanded(
            child: tekrarEdilecekKelimeler.isEmpty
                ? const Center(
                    child: Text(
                      'Harika gidiyorsun!\nŞu an tekrar etmen gereken\nbir kelime yok. ',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Color(0xFF6B7B70)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tekrarEdilecekKelimeler.length,
                    itemBuilder: (context, index) {
                      final kelime = tekrarEdilecekKelimeler[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          title: Text(
                            kelime['word'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: Color(0xFF4A5750),
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SingleFlashcardScreen(kelime: kelime),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// --- KELİME ARŞİVİM EKRANI ---
class KelimeArsiviScreen extends StatefulWidget {
  const KelimeArsiviScreen({super.key});

  @override
  State<KelimeArsiviScreen> createState() => _KelimeArsiviScreenState();
}

class _KelimeArsiviScreenState extends State<KelimeArsiviScreen> {
  String _aramaMetni = '';

  @override
  Widget build(BuildContext context) {
    // 1. Öğrenilen kelimeleri kopyala ve alfabetik olarak sırala
    List<Map<String, String>> siraliKelimeler = List.from(ogrenilenKelimeler);
    siraliKelimeler.sort(
      (a, b) => (a['word'] ?? '').toLowerCase().compareTo(
        (b['word'] ?? '').toLowerCase(),
      ),
    );

    // 2. Arama çubuğuna yazılan metne göre filtrele
    List<Map<String, String>> gosterilecekKelimeler = siraliKelimeler.where((
      kelime,
    ) {
      return (kelime['word'] ?? '').toLowerCase().startsWith(
        _aramaMetni.toLowerCase(),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kelime Arşivim',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF7D8C81), // Farklı, şık bir pastel ton
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Hoşgeldin Mesajı
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: const Color(0xFF7D8C81).withOpacity(0.1),
            child: const Text(
              'Şu ana kadar öğrendiğin tüm kelimeleri burada bulabilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF4A5750),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          // Arama Çubuğu
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Kelime ara...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF7D8C81)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (deger) {
                setState(() {
                  _aramaMetni = deger; // Metin değiştikçe ekranı günceller
                });
              },
            ),
          ),
          // Kelime Listesi
          Expanded(
            child: gosterilecekKelimeler.isEmpty
                ? const Center(
                    child: Text(
                      'Aradığınız kelime bulunamadı veya\nhenüz kelime öğrenmediniz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF6B7B70), fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: gosterilecekKelimeler.length,
                    itemBuilder: (context, index) {
                      final kelime = gosterilecekKelimeler[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 1,
                        child: ListTile(
                          title: Text(
                            kelime['word'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF4A5750),
                            ),
                          ),
                          subtitle: Text(
                            kelime['meaning'] ?? '',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF6B7B70),
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Color(0xFF7D8C81),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SingleFlashcardScreen(kelime: kelime),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// --- İSTATİSTİKLER VE İLERLEME EKRANI ---
class IstatistiklerScreen extends StatelessWidget {
  const IstatistiklerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    int toplamKelime = ydsKelimeleri.isNotEmpty ? ydsKelimeleri.length : 3000;
    int ogrenilenSayisi = ogrenilenKelimeler.length;
    int koleksiyonSayisi = koleksiyonlar.values
        .expand((liste) => liste)
        .map((k) => k['word'])
        .toSet()
        .length;
    int tekrarSayisi = tekrarEdilecekKelimeler.length;

    // Yüzde hesaplama (0.0 ile 1.0 arası)
    double ilerlemeOrani = toplamKelime > 0
        ? (ogrenilenSayisi / toplamKelime)
        : 0.0;
    if (ilerlemeOrani > 1.0) ilerlemeOrani = 1.0;
    int yuzde = (ilerlemeOrani * 100).toInt();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'İstatistiklerim',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFB4A5A5),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ana İlerleme Kartı
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB4A5A5).withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFFB4A5A5).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Genel Hedef İlerlemesi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A5750),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 120,
                        width: 120,
                        child: CircularProgressIndicator(
                          value: ilerlemeOrani,
                          backgroundColor: const Color(0xFFF5F3E9),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF8BA88E),
                          ),
                          strokeWidth: 12,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Text(
                        '%$yuzde',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A5750),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$ogrenilenSayisi / $toplamKelime kelime görüntülendi',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6B7B70),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Detaylı Metrik Kutuları
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
              children: [
                _buildMetricCard(
                  'Öğrenilen',
                  '$ogrenilenSayisi',
                  Icons.school,
                  const Color(0xFF8BA88E),
                ),
                _buildMetricCard(
                  'Koleksiyonlarım',
                  '$koleksiyonSayisi',
                  Icons.collections_bookmark,
                  const Color(0xFFD69E9E),
                ),
                _buildMetricCard(
                  'Tekrar Edilecek',
                  '$tekrarSayisi',
                  Icons.history,
                  const Color(0xFF9CB4A1),
                ),
                _buildMetricCard(
                  'Toplam Havuz',
                  '$toplamKelime',
                  Icons.library_books,
                  const Color(0xFFC4B495),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _buildRozetlerBolumu(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5750),
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7B70),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRozetlerBolumu(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rozetlerim',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A5750),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Rozetlere dokunarak nasıl kazanıldığını görebilirsin.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 128,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: rozetTanimlari.length,
            itemBuilder: (context, index) {
              String anahtar = rozetTanimlari.keys.elementAt(index);
              return _buildRozetKarti(context, anahtar);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRozetKarti(BuildContext context, String anahtar) {
    final tanim = rozetTanimlari[anahtar]!;
    bool kazanildi = kazanilanRozetler[anahtar] ?? false;

    return GestureDetector(
      onTap: () => _rozetAciklamasiniGoster(context, tanim, kazanildi),
      onLongPress: () => _rozetAciklamasiniGoster(context, tanim, kazanildi),
      child: Container(
        width: 104,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: kazanildi ? tanim.renk : Colors.grey.shade200,
                shape: BoxShape.circle,
                boxShadow: kazanildi
                    ? [
                        BoxShadow(
                          color: tanim.renk.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                tanim.ikon,
                color: kazanildi ? Colors.white : Colors.grey.shade500,
                size: 34,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tanim.baslik,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kazanildi
                    ? const Color(0xFF4A5750)
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _rozetAciklamasiniGoster(
    BuildContext context,
    RozetBilgisi tanim,
    bool kazanildi,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kazanildi ? tanim.renk : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                tanim.ikon,
                color: kazanildi ? Colors.white : Colors.grey.shade500,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tanim.baslik,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          kazanildi
              ? tanim.aciklama
              : '${tanim.aciklama}\n\nBu rozeti henüz kazanmadın.',
          style: const TextStyle(fontSize: 15, color: Color(0xFF6B7B70)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tamam',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: kazanildi ? tanim.renk : const Color(0xFFB4A5A5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- QUİZ SONUC EKRANI ---
class QuizSonucScreen extends StatelessWidget {
  final int dogruSayisi;
  final int yanlisSayisi;
  final int toplamSoru;

  const QuizSonucScreen({
    super.key,
    required this.dogruSayisi,
    required this.yanlisSayisi,
    required this.toplamSoru,
  });

  @override
  Widget build(BuildContext context) {
    double basariOrani = toplamSoru > 0 ? (dogruSayisi / toplamSoru) : 0.0;
    int yuzde = (basariOrani * 100).toInt();

    String mesaj = 'Tebrikler!';
    if (yuzde < 50)
      mesaj = 'Biraz daha pratik yapmalısın!';
    else if (yuzde < 80)
      mesaj = 'İyi iş çıkardın!';
    else
      mesaj = 'Harikasın, mükemmel sonuç! ';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sınav Sonucu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFC4B495), // Şık bir kahve/bej tonu
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading:
            false, // Geri butonunu gizleriz ki zorla çıkmasınlar
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Dairesel Skor Göstergesi
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 160,
                    width: 160,
                    child: CircularProgressIndicator(
                      value: basariOrani,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        yuzde >= 50
                            ? const Color(0xFF8BA88E)
                            : const Color(0xFFD69E9E),
                      ),
                      strokeWidth: 16,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    '%$yuzde',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A5750),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                mesaj,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A5750),
                ),
              ),
              const SizedBox(height: 32),

              // Doğru / Yanlış Kutuları
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSonucKutusu(
                    'Doğru',
                    dogruSayisi,
                    const Color(0xFF8BA88E),
                  ),
                  _buildSonucKutusu(
                    'Yanlış',
                    yanlisSayisi,
                    const Color(0xFFD69E9E),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Ana Sayfaya Dön Butonu
              ElevatedButton.icon(
                onPressed: () {
                  // Tüm quiz ekranlarını kapatıp ana sayfaya güvenli dönüş yapar
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.home, color: Colors.white),
                label: const Text(
                  'Ana Sayfaya Dön',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7D8C81),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSonucKutusu(String baslik, int sayi, Color renk) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: renk.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: renk.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Text(
            sayi.toString(),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: renk,
            ),
          ),
          Text(
            baslik,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: renk,
            ),
          ),
        ],
      ),
    );
  }
}

// --- YAZMA ALIŞTIRMASI EKRANI (Harf Sürükle-Bırak Oyunu) ---
class SpellingScreen extends StatefulWidget {
  final bool isDailyMode;
  const SpellingScreen({super.key, required this.isDailyMode});

  @override
  State<SpellingScreen> createState() => _SpellingScreenState();
}

class _SpellingScreenState extends State<SpellingScreen> {
  late List<Map<String, String>> _kelimeler;
  int _aktifIndex = 0;
  int _hataSayisi = 0;
  final Set<int> _hataliKelimeIndeksleri = {};

  late List<String> _harfHavuzu;
  late List<bool> _havuzKullanildiMi;
  late List<int?> _slotHavuzIndeksi;
  bool? _dogruMu; // null: henüz kontrol edilmedi, true/false: son kontrol sonucu

  @override
  void initState() {
    super.initState();
    _kelimeleriHazirla();
    if (_kelimeler.isNotEmpty) {
      _kelimeyiYukle();
    }
  }

  void _kelimeleriHazirla() {
    if (widget.isDailyMode) {
      _kelimeler = List<Map<String, String>>.from(gunlukKelimelerHafizasi);
    } else {
      var kopyaOgrenilen = List<Map<String, String>>.from(ogrenilenKelimeler)
        ..shuffle();
      int kelimeSayisi = kopyaOgrenilen.length >= 10
          ? 10
          : kopyaOgrenilen.length;
      _kelimeler = kopyaOgrenilen.take(kelimeSayisi).toList();
    }
  }

  void _kelimeyiYukle() {
    List<String> harfler = (_kelimeler[_aktifIndex]['word'] ?? '').split('');
    _harfHavuzu = List<String>.from(harfler)..shuffle();
    _havuzKullanildiMi = List<bool>.filled(_harfHavuzu.length, false);
    _slotHavuzIndeksi = List<int?>.filled(harfler.length, null);
    _dogruMu = null;
  }

  void _harfeTikla(int havuzIndex) {
    if (_dogruMu == true) return;
    if (_havuzKullanildiMi[havuzIndex]) return;
    int bosSlot = _slotHavuzIndeksi.indexWhere((slot) => slot == null);
    if (bosSlot == -1) return;
    setState(() {
      _slotHavuzIndeksi[bosSlot] = havuzIndex;
      _havuzKullanildiMi[havuzIndex] = true;
      _dogruMu = null; // önceki yanlış vurgusunu temizle, düzenlemeye izin ver
    });
  }

  void _slotaTikla(int slotIndex) {
    if (_dogruMu == true) return;
    int? havuzIndex = _slotHavuzIndeksi[slotIndex];
    if (havuzIndex == null) return;
    setState(() {
      _havuzKullanildiMi[havuzIndex] = false;
      _slotHavuzIndeksi[slotIndex] = null;
      _dogruMu = null;
    });
  }

  void _kontrolEt() {
    if (_slotHavuzIndeksi.contains(null)) return;
    String kullaniciCevabi = _slotHavuzIndeksi
        .map((havuzIndex) => _harfHavuzu[havuzIndex!])
        .join();
    String dogruKelime = (_kelimeler[_aktifIndex]['word'] ?? '').toLowerCase();
    bool dogruMu = kullaniciCevabi.toLowerCase() == dogruKelime;

    setState(() {
      _dogruMu = dogruMu;
      if (!dogruMu) {
        _hataSayisi++;
        _hataliKelimeIndeksleri.add(_aktifIndex);
      }
    });
  }

  Future<void> _sonrakiKelime() async {
    if (_aktifIndex < _kelimeler.length - 1) {
      setState(() {
        _aktifIndex++;
        _kelimeyiYukle();
      });
      return;
    }

    // Oturum tamamlandı: ilerlemeyi kaydet ve rozetleri kontrol et
    yazmaAlistirmasiTamamlananSayisi++;
    await yazmaIlerlemesiniKaydet();
    await rozetleriKontrolEt();
    if (!widget.isDailyMode) {
      await rozetKusursuzKalemKontrol(_hataSayisi);
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => YazmaSonucScreen(
          toplamKelime: _kelimeler.length,
          hatasizKelimeSayisi:
              _kelimeler.length - _hataliKelimeIndeksleri.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_kelimeler.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Yazma Alıştırması',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF9FB4C7),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: const Center(child: Text('Alıştırma için kelime bulunamadı.')),
      );
    }

    Map<String, String> kelime = _kelimeler[_aktifIndex];
    bool tumSlotlarDolu = !_slotHavuzIndeksi.contains(null);
    bool sonKelimeMi = _aktifIndex == _kelimeler.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Yazma Alıştırması',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF9FB4C7),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Kelime ${_aktifIndex + 1} / ${_kelimeler.length}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9FB4C7),
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (_aktifIndex + 1) / _kelimeler.length,
              backgroundColor: const Color(0xFF9FB4C7).withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF9FB4C7),
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 32),
            // Hedef kelimenin Türkçe anlamı
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 24,
                horizontal: 20,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF9FB4C7).withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9FB4C7).withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                kelime['meaning'] ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A5750),
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Harf slotları
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                _slotHavuzIndeksi.length,
                (index) => _buildSlot(index),
              ),
            ),
            if (_dogruMu == false) ...[
              const SizedBox(height: 16),
              AnimatedOpacity(
                opacity: 1,
                duration: const Duration(milliseconds: 400),
                child: Text(
                  'Doğru yazılışı: ${(kelime['word'] ?? '').toUpperCase()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD98880),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),
            // Karışık harf havuzu
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: List.generate(
                _harfHavuzu.length,
                (index) => _buildHarfButonu(index),
              ),
            ),
            const SizedBox(height: 32),
            if (_dogruMu == true)
              ElevatedButton.icon(
                onPressed: _sonrakiKelime,
                icon: Icon(
                  sonKelimeMi ? Icons.flag_rounded : Icons.arrow_forward_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  sonKelimeMi ? 'Bitir' : 'Sonraki Kelime',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8BA88E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              )
            else ...[
              ElevatedButton(
                onPressed: tumSlotlarDolu ? _kontrolEt : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9FB4C7),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Kontrol Et',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (_dogruMu == false)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton(
                    onPressed: _sonrakiKelime,
                    child: Text(
                      sonKelimeMi ? 'Bu kelimeyi geç ve bitir' : 'Bu kelimeyi geç',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSlot(int index) {
    int? havuzIndex = _slotHavuzIndeksi[index];
    String harf = havuzIndex != null ? _harfHavuzu[havuzIndex] : '';

    Color bgRengi;
    Color borderRengi;
    Color yaziRengi;
    if (_dogruMu == true) {
      bgRengi = const Color(0xFF8BA88E);
      borderRengi = const Color(0xFF8BA88E);
      yaziRengi = Colors.white;
    } else if (_dogruMu == false) {
      bgRengi = const Color(0xFFD98880);
      borderRengi = const Color(0xFFD98880);
      yaziRengi = Colors.white;
    } else {
      bgRengi = Colors.white;
      borderRengi = havuzIndex != null
          ? const Color(0xFF9FB4C7)
          : Colors.grey.shade300;
      yaziRengi = const Color(0xFF4A5750);
    }

    return GestureDetector(
      onTap: () => _slotaTikla(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 52,
        decoration: BoxDecoration(
          color: bgRengi,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderRengi, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          harf.toUpperCase(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: yaziRengi,
          ),
        ),
      ),
    );
  }

  Widget _buildHarfButonu(int index) {
    bool kullanildiMi = _havuzKullanildiMi[index];
    return Visibility(
      visible: !kullanildiMi,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: GestureDetector(
        onTap: () => _harfeTikla(index),
        child: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Color(0xFF9FB4C7),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            _harfHavuzu[index].toUpperCase(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// --- YAZMA ALIŞTIRMASI SONUÇ EKRANI ---
class YazmaSonucScreen extends StatelessWidget {
  final int toplamKelime;
  final int hatasizKelimeSayisi;

  const YazmaSonucScreen({
    super.key,
    required this.toplamKelime,
    required this.hatasizKelimeSayisi,
  });

  @override
  Widget build(BuildContext context) {
    double basariOrani = toplamKelime > 0
        ? (hatasizKelimeSayisi / toplamKelime)
        : 0.0;
    int yuzde = (basariOrani * 100).toInt();
    int hataliKelimeSayisi = toplamKelime - hatasizKelimeSayisi;

    String mesaj = 'Tebrikler!';
    if (yuzde < 50) {
      mesaj = 'Biraz daha pratik yapmalısın!';
    } else if (yuzde < 80) {
      mesaj = 'İyi iş çıkardın!';
    } else {
      mesaj = 'Harikasın, mükemmel sonuç!';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Yazma Sonucu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF9FB4C7),
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 160,
                    width: 160,
                    child: CircularProgressIndicator(
                      value: basariOrani,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        yuzde >= 50
                            ? const Color(0xFF8BA88E)
                            : const Color(0xFFD98880),
                      ),
                      strokeWidth: 16,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    '%$yuzde',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A5750),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                mesaj,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A5750),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSonucKutusu(
                    'Hatasız',
                    hatasizKelimeSayisi,
                    const Color(0xFF8BA88E),
                  ),
                  _buildSonucKutusu(
                    'Hatalı',
                    hataliKelimeSayisi,
                    const Color(0xFFD98880),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.home, color: Colors.white),
                label: const Text(
                  'Ana Sayfaya Dön',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7D8C81),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSonucKutusu(String baslik, int sayi, Color renk) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: renk.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: renk.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Text(
            sayi.toString(),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: renk,
            ),
          ),
          Text(
            baslik,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: renk,
            ),
          ),
        ],
      ),
    );
  }
}

// --- REHBER VE NOTLAR EKRANI ---
class RehberVeNotlarScreen extends StatefulWidget {
  const RehberVeNotlarScreen({super.key});

  @override
  State<RehberVeNotlarScreen> createState() => _RehberVeNotlarScreenState();
}

class _RehberVeNotlarScreenState extends State<RehberVeNotlarScreen> {
  final TextEditingController _notController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notlariYukle();
  }

  void _notlariYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notController.text = prefs.getString('kullanici_notu') ?? '';
    });
  }

  void _notKaydet(String text) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('kullanici_notu', text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rehber & Notlarım',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFC4B495),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Bilgi Kartları
            Row(
              children: [
                Expanded(
                  child: _buildBilgiKart(
                    context,
                    'Neden 7 Kelime?',
                    Icons.psychology,
                    'Beynimiz bir günde yüzlerce kelimeye maruz kalabilir ama onları gerçekten "öğrenmek" için odaklanmaya ihtiyacı vardır. Bilimsel araştırmalar, kısa süreli hafızamızın bir seferde en verimli şekilde ortalama 7 yeni bilgiyi işleyebildiğini gösteriyor. Amacımız seni kelime yığınlarına boğup tüketmek değil; az, öz ve kalıcı adımlarla hedefine ulaştırmak.',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBilgiKart(
                    context,
                    'IPA Nedir?',
                    Icons.mic,
                    'Kelime kartlarındaki /kənˈstrʌkt/ gibi garip semboller gözünü korkutmasın! Bunlar Uluslararası Fonetik Alfabe (IPA) sembolleridir ve kelimenin tam olarak nasıl telaffuz edileceğini gösterir. Bu sembolleri ezberlemene gerek yok; sadece vurgunun nerede olduğunu (kesme işareti olan yer) anlaman için bir ipucudur. Telaffuzdan emin olamadığın an, kelimenin yanındaki ses ikonuna tıklayarak doğru okunuşu duyabilirsin.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Not Defteri Alanı
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Kişisel Notların',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TextField(
                        controller: _notController,
                        maxLines: null,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Buraya unutmamak istediğin ipuçlarını, kelime çağrışımlarını veya hedeflerini yazabilirsin...',
                        ),
                        onChanged: _notKaydet,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBilgiKart(
    BuildContext context,
    String baslik,
    IconData icon,
    String icerik,
  ) {
    return InkWell(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(
            baslik,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Text(
              icerik,
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
                color: Color(0xFF4A5750),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Anladım',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFC4B495),
                ),
              ),
            ),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFC4B495).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFC4B495), size: 32),
            const SizedBox(height: 8),
            Text(
              baslik,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
