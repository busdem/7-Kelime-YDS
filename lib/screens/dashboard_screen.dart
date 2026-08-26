import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';

import '../kelimeler.dart';
import '../state/global_state.dart';
import '../state/rozetler.dart';
import '../state/tekrar_takvimi.dart';
import '../state/tema_state.dart';
import '../services/quiz_generator.dart';
import '../services/bildirim_servisi.dart';
import 'quiz_screen.dart';
import 'flashcard_screen.dart';
import 'tekrar_et_screen.dart';
import 'koleksiyonlar_screen.dart';
import 'kelime_arsivi_screen.dart';
import 'istatistikler_screen.dart';
import 'rehber_screen.dart';
import 'not_defterleri_screen.dart';
import 'spelling_screen.dart';
import 'listening_screen.dart';

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
    _bildirimleriKur();
  }

  // initState senkron olduğu için bildirim kurulumu ayrı bir async
  // fonksiyonda yapılır. İzin reddedilirse veya platform desteklemezse
  // uygulama çökmesin diye hatalar burada yutulur.
  Future<void> _bildirimleriKur() async {
    try {
      await bildirimleriBaslat();
      await gunlukHatirlatmayiZamanla();
    } catch (_) {
      // Bildirim izni verilmediyse veya kurulum başarısız olduysa
      // uygulamanın geri kalanını etkilemeden sessizce devam et.
    }
  }

  Future<void> _verileriHafizadanYukle() async {
    final prefs = await SharedPreferences.getInstance();
    await tekrarTakviminiYukle();

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
        var ogrenilmemisHavuz = ydsKelimeleri
            .where(
              (k) => !ogrenilenKelimeler.any((o) => o['word'] == k['word']),
            )
            .toList();
        var kopyaListe =
            (ogrenilmemisHavuz.length >= 7 ? ogrenilmemisHavuz : ydsKelimeleri)
                .toList()
              ..shuffle();
        gunlukKelimelerHafizasi = kopyaListe.take(7).toList();

        bool yeniTekrarVarMi = false;
        for (var kelime in gunlukKelimelerHafizasi) {
          // 'word' yani İngilizce kelimenin metnine bakarak kontrol ediyoruz!
          bool zatenVarMi = ogrenilenKelimeler.any(
            (k) => k['word'] == kelime['word'],
          );
          if (!zatenVarMi) {
            ogrenilenKelimeler.add(kelime);
            kelimeyiTekrarTakvimineEkle(kelime['word'] ?? '');
            yeniTekrarVarMi = true;
          }
        }
        if (yeniTekrarVarMi) {
          tekrarTakviminiKaydet();
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
              kelimeyiTekrarTakvimineEkle(kelime['word'] ?? '');
              yeniOgrenilenVarMi = true;
            }
          }
          if (yeniOgrenilenVarMi) {
            prefs.setString('ogrenilenler', jsonEncode(ogrenilenKelimeler));
            tekrarTakviminiKaydet();
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
    await notDefterleriYukle();
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
              Text(
                'Quiz Modunu Seçin',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(
                  Icons.today,
                  color: Color(0xFF8BA88E),
                  size: 32,
                ),
                title: Text(
                  'Günün Testi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface,
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
                title: Text(
                  'Genel Tekrar',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface,
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
              Text(
                'Yazma Alıştırması Modunu Seçin',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(
                  Icons.today,
                  color: Color(0xFF9FB4C7),
                  size: 32,
                ),
                title: Text(
                  'Günün Yazma Alıştırması',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface,
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
                title: Text(
                  'Genel Yazma Alıştırması',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface,
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

  void _dinlemeMenusuAc(BuildContext context) {
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
              Text(
                'Dinleme Alıştırması Zorluğunu Seçin',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(
                  Icons.sentiment_satisfied_alt,
                  color: Color(0xFF9FB4C7),
                  size: 32,
                ),
                title: Text(
                  'Kolay (İngilizce şıklar)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: const Text(
                  'Kelimeyi dinle, doğru İngilizce yazılışını seç.',
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
                            const ListeningQuizScreen(kolayMod: true),
                      ),
                    );
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.local_fire_department,
                  color: Color(0xFF9FB4C7),
                  size: 32,
                ),
                title: Text(
                  'Zor (Türkçe şıklar)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: const Text(
                  'Kelimeyi dinle, doğru Türkçe anlamını seç.',
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
                            const ListeningQuizScreen(kolayMod: false),
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
    return ValueListenableBuilder<String>(
      valueListenable: temaPaletiBildirici,
      builder: (context, paletAnahtari, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'YDS Kelime Rehberi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5750),
              ),
            ),
            backgroundColor: temaPaletiRenkleri[paletAnahtari]!,
            elevation: 0,
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.palette, color: Color(0xFF4A5750)),
                tooltip: 'Tema Seç',
                onPressed: () => _temaSeciciAc(context),
              ),
            ],
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
                          MaterialPageRoute(
                            builder: (_) => const TekrarEtScreen(),
                          ),
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
                        title: 'Dinleme\nAlıştırması',
                        icon: Icons.headphones,
                        color: const Color(0xFFF5CBA7),
                        onTap: () => _dinlemeMenusuAc(context),
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
                        title: 'Rehber',
                        icon: Icons.menu_book,
                        color: const Color(0xFFC4B495),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RehberScreen(),
                          ),
                        ),
                      ),
                      _buildMenuCard(
                        title: 'Not Defterlerim',
                        icon: Icons.edit_note,
                        color: const Color(0xFFE5C158),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotDefterleriScreen(),
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
      },
    );
  }

  void _temaSeciciAc(BuildContext context) {
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
              Text(
                'Tema Seç',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: temaModuBildirici,
                builder: (context, mod, _) {
                  return SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Açık'),
                        icon: Icon(Icons.light_mode),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Koyu'),
                        icon: Icon(Icons.dark_mode),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('Sistem'),
                        icon: Icon(Icons.brightness_auto),
                      ),
                    ],
                    selected: {mod},
                    onSelectionChanged: (secilenler) {
                      temaModuBildirici.value = secilenler.first;
                      temaTercihleriniKaydet();
                    },
                  );
                },
              ),
              const SizedBox(height: 28),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Renk Paleti',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<String>(
                valueListenable: temaPaletiBildirici,
                builder: (context, seciliPalet, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: temaPaletiRenkleri.keys
                        .map(
                          (anahtar) =>
                              _buildPaletSecenegi(anahtar, seciliPalet),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaletSecenegi(String anahtar, String seciliPalet) {
    Color renk = temaPaletiRenkleri[anahtar]!;
    bool acikMi = temaPaletiAcikMi(anahtar, ardisikGunSayaci);
    bool seciliMi = anahtar == seciliPalet;

    return GestureDetector(
      onTap: acikMi
          ? () {
              temaPaletiBildirici.value = anahtar;
              temaTercihleriniKaydet();
            }
          : null,
      child: Opacity(
        opacity: acikMi ? 1.0 : 0.5,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: renk,
                    shape: BoxShape.circle,
                    border: seciliMi
                        ? Border.all(color: const Color(0xFF4A5750), width: 3)
                        : null,
                  ),
                ),
                if (!acikMi)
                  const Icon(Icons.lock, color: Colors.white, size: 22),
                if (seciliMi && acikMi)
                  const Icon(Icons.check, color: Colors.white, size: 22),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _paletIsmi(anahtar),
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (!acikMi)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${temaPaletiKilitGunleri[anahtar]} gün üst üste çalış',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _paletIsmi(String anahtar) {
    switch (anahtar) {
      case 'mavi':
        return 'Mavi';
      case 'pembe':
        return 'Pembe';
      default:
        return 'Varsayılan';
    }
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
          color: Theme.of(context).colorScheme.surface,
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
