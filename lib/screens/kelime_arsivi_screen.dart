import 'package:flutter/material.dart';

import '../state/global_state.dart';
import 'flashcard_screen.dart';

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
