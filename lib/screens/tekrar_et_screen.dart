import 'package:flutter/material.dart';

import '../state/global_state.dart';
import 'quiz_screen.dart';
import 'flashcard_screen.dart';

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
