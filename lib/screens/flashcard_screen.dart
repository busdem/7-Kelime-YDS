import 'package:flutter/material.dart';

import '../state/global_state.dart';
import '../services/tts_service.dart';

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
