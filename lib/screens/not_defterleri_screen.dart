import 'package:flutter/material.dart';

import '../state/global_state.dart';
import 'not_defteri_detay_screen.dart';

// --- NOT DEFTERLERİM EKRANI ---
class NotDefterleriScreen extends StatefulWidget {
  const NotDefterleriScreen({super.key});

  @override
  State<NotDefterleriScreen> createState() => _NotDefterleriScreenState();
}

class _NotDefterleriScreenState extends State<NotDefterleriScreen> {
  Future<void> _yeniDefterEkle() async {
    final controller = TextEditingController();
    final isim = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Yeni Not Defteri',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Defter ismi'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text(
              'Oluştur',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFC4B495),
              ),
            ),
          ),
        ],
      ),
    );

    if (isim == null || isim.isEmpty) return;

    setState(() {
      notDefterleri.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'isim': isim,
        'icerik': '',
      });
    });
    await notDefterleriKaydet();
  }

  Future<void> _adiniDegistir(Map<String, String> defter) async {
    final controller = TextEditingController(text: defter['isim']);
    final yeniIsim = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Adını Değiştir',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text(
              'Kaydet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFC4B495),
              ),
            ),
          ),
        ],
      ),
    );

    if (yeniIsim == null || yeniIsim.isEmpty) return;

    setState(() {
      defter['isim'] = yeniIsim;
    });
    await notDefterleriKaydet();
  }

  Future<void> _defteriSil(Map<String, String> defter) async {
    setState(() {
      notDefterleri.removeWhere((d) => d['id'] == defter['id']);
    });
    await notDefterleriKaydet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Not Defterlerim',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFC4B495),
        foregroundColor: Colors.white,
      ),
      body: notDefterleri.isEmpty
          ? const Center(
              child: Text(
                'Henüz bir not defterin yok.\nAşağıdaki butonla ilk defterini oluştur.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Color(0xFF6B7B70)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notDefterleri.length,
              itemBuilder: (context, index) {
                final defter = notDefterleri[index];
                String onizleme = (defter['icerik'] ?? '').trim();
                if (onizleme.isEmpty) {
                  onizleme = 'Henüz içerik eklenmedi...';
                } else if (onizleme.length > 60) {
                  onizleme = '${onizleme.substring(0, 60)}...';
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: Colors.amber.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.amber.shade200),
                  ),
                  elevation: 0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotDefteriDetayScreen(
                            defterId: defter['id']!,
                          ),
                        ),
                      ).then((_) => setState(() {}));
                    },
                    title: Hero(
                      tag: defter['id']!,
                      child: Material(
                        type: MaterialType.transparency,
                        child: Text(
                          defter['isim'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Color(0xFF4A5750),
                          ),
                        ),
                      ),
                    ),
                    subtitle: Text(
                      onizleme,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF6B7B70)),
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.amber),
                      onSelected: (deger) {
                        if (deger == 'yenidenAdlandir') {
                          _adiniDegistir(defter);
                        } else if (deger == 'sil') {
                          _defteriSil(defter);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'yenidenAdlandir',
                          child: Text('Adını Değiştir'),
                        ),
                        const PopupMenuItem(
                          value: 'sil',
                          child: Text('Sil'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _yeniDefterEkle,
        backgroundColor: const Color(0xFFC4B495),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Yeni Not Defteri',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
