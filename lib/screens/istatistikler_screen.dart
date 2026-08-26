import 'package:flutter/material.dart';

import '../kelimeler.dart';
import '../state/global_state.dart';
import '../state/rozetler.dart';
import '../state/tekrar_takvimi.dart';

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
    int tekrarSayisi = siraGelenKelimeleriGetir().length;

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
                color: Theme.of(context).colorScheme.surface,
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
                  Text(
                    'Genel Hedef İlerlemesi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
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
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$ogrenilenSayisi / $toplamKelime kelime görüntülendi',
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
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
                  context,
                  'Öğrenilen',
                  '$ogrenilenSayisi',
                  Icons.school,
                  const Color(0xFF8BA88E),
                ),
                _buildMetricCard(
                  context,
                  'Koleksiyonlarım',
                  '$koleksiyonSayisi',
                  Icons.collections_bookmark,
                  const Color(0xFFD69E9E),
                ),
                _buildMetricCard(
                  context,
                  'Tekrar Edilecek',
                  '$tekrarSayisi',
                  Icons.history,
                  const Color(0xFF9CB4A1),
                ),
                _buildMetricCard(
                  context,
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
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
        Text(
          'Rozetlerim',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
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
                    ? Theme.of(context).colorScheme.onSurface
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
          style: TextStyle(
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
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
