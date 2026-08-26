import 'package:flutter/material.dart';

import '../state/global_state.dart';
import '../state/rozetler.dart';

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
                color: Theme.of(context).colorScheme.surface,
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
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
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
      bgRengi = Theme.of(context).colorScheme.surface;
      borderRengi = havuzIndex != null
          ? const Color(0xFF9FB4C7)
          : Colors.grey.shade300;
      yaziRengi = Theme.of(context).colorScheme.onSurface;
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
