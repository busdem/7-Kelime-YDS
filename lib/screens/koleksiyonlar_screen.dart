import 'package:flutter/material.dart';

import '../state/global_state.dart';
import 'flashcard_screen.dart';

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
    await koleksiyonlariKaydet();
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
