import 'package:flutter/material.dart';

import '../state/global_state.dart';
import '../state/tekrar_takvimi.dart';
import '../services/quiz_generator.dart';
import '../services/tts_service.dart';
import 'quiz_screen.dart';

// --- DİNLEME ALIŞTIRMASI EKRANI ---
class ListeningQuizScreen extends StatefulWidget {
  final bool kolayMod;
  const ListeningQuizScreen({super.key, required this.kolayMod});

  @override
  State<ListeningQuizScreen> createState() => _ListeningQuizScreenState();
}

class _ListeningQuizScreenState extends State<ListeningQuizScreen> {
  List<Map<String, dynamic>> _aktifSorular = [];
  int _aktifSoruIndex = 0;
  int _dogruSayisi = 0;
  bool _cevapVerildi = false;
  String _secilenCevap = '';

  @override
  void initState() {
    super.initState();
    _sinaviBaslat();
    _mevcutKelimeyiSeslendir();
  }

  @override
  void dispose() {
    sesiDurdur(); // Ekrandan çıkıldığında sesi tamamen kapat
    super.dispose();
  }

  void _sinaviBaslat() {
    // Genel Tekrar ile aynı mantık: öğrenilenlerden rastgele en fazla 10 kelime
    var kopyaOgrenilen = List<Map<String, String>>.from(ogrenilenKelimeler)
      ..shuffle();
    int soruSayisi = kopyaOgrenilen.length >= 10 ? 10 : kopyaOgrenilen.length;
    _aktifSorular = dinamikDinlemeSorusuUret(
      kopyaOgrenilen.take(soruSayisi).toList(),
      kolayMod: widget.kolayMod,
    );
    _dogruSayisi = 0;
    _aktifSoruIndex = 0;
    _cevapVerildi = false;
    _secilenCevap = '';
  }

  void _mevcutKelimeyiSeslendir() {
    if (_aktifSorular.isEmpty) return;
    Map<String, String> kelime = _aktifSorular[_aktifSoruIndex]['kelime'];
    metniSeslendir(kelime['word'] ?? '');
  }

  void _cevapKontrol(
    String cevap,
    String dogruCevap,
    Map<String, String> kelime,
  ) {
    // İŞTE KORUMA KALKANIMIZ!
    // Eğer şık daha önce seçildiyse aşağıyı hiç okuma ve durdur:
    if (_cevapVerildi) return;

    setState(() {
      _cevapVerildi = true;
      _secilenCevap = cevap;
      if (cevap == dogruCevap) {
        _dogruSayisi++;
      }
      tekrarTakviminiGuncelle(kelime['word'] ?? '', cevap == dogruCevap);
    });
  }

  void _sonrakiSoru() {
    setState(() {
      if (_aktifSoruIndex < _aktifSorular.length - 1) {
        _aktifSoruIndex++;
        _cevapVerildi = false;
        _secilenCevap = '';
      }
    });
    _mevcutKelimeyiSeslendir();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.kolayMod ? 'Dinleme Testi (Kolay)' : 'Dinleme Testi (Zor)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF9FB4C7),
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
    String dogruCevap = widget.kolayMod
        ? (kelime['word'] ?? '')
        : (kelime['meaning'] ?? '');

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
              color: Color(0xFF9FB4C7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_aktifSoruIndex + 1) / _aktifSorular.length,
            backgroundColor: const Color(0xFF9FB4C7).withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9FB4C7)),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 40),
          // Kelimenin yazısı gösterilmez; onun yerine büyük bir "Dinle" butonu
          Center(
            child: GestureDetector(
              onTap: () => metniSeslendir(kelime['word'] ?? ''),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF9FB4C7),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9FB4C7).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.headphones,
                  color: Colors.white,
                  size: 56,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Dinlemek için dokun',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView.builder(
              itemCount: secenekler.length,
              itemBuilder: (context, index) {
                String secenek = secenekler[index];

                // Renk mantığı
                Color butonRengi = Theme.of(context).colorScheme.surface;
                Color yaziRengi = Theme.of(context).colorScheme.onSurface;
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
                backgroundColor: const Color(0xFF9FB4C7),
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
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizSonucScreen(
                      dogruSayisi: _dogruSayisi,
                      yanlisSayisi: _aktifSorular.length - _dogruSayisi,
                      toplamSoru: _aktifSorular.length,
                      baslik: 'Dinleme Testi',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9FB4C7),
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
