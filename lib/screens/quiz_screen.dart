import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../state/global_state.dart';
import '../state/rozetler.dart';
import '../services/quiz_generator.dart';

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

// --- QUİZ SONUC EKRANI ---
class QuizSonucScreen extends StatelessWidget {
  final int dogruSayisi;
  final int yanlisSayisi;
  final int toplamSoru;
  final String baslik;

  const QuizSonucScreen({
    super.key,
    required this.dogruSayisi,
    required this.yanlisSayisi,
    required this.toplamSoru,
    this.baslik = 'Sınav Sonucu',
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
        title: Text(
          baslik,
          style: const TextStyle(fontWeight: FontWeight.bold),
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
