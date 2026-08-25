import 'package:flutter/material.dart';

import '../state/global_state.dart';

// --- NOT DEFTERİ DETAY EKRANI ---
class NotDefteriDetayScreen extends StatefulWidget {
  final String defterId;
  const NotDefteriDetayScreen({super.key, required this.defterId});

  @override
  State<NotDefteriDetayScreen> createState() => _NotDefteriDetayScreenState();
}

class _NotDefteriDetayScreenState extends State<NotDefteriDetayScreen> {
  late final TextEditingController _icerikController;

  Map<String, String> get _defter =>
      notDefterleri.firstWhere((d) => d['id'] == widget.defterId);

  @override
  void initState() {
    super.initState();
    _icerikController = TextEditingController(text: _defter['icerik']);
  }

  @override
  void dispose() {
    _icerikController.dispose();
    super.dispose();
  }

  Future<void> _icerikDegisti(String text) async {
    _defter['icerik'] = text;
    await notDefterleriKaydet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _defter['isim'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFC4B495),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Hero(
          tag: widget.defterId,
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: TextField(
                controller: _icerikController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Buraya unutmamak istediğin ipuçlarını, kelime çağrışımlarını veya hedeflerini yazabilirsin...',
                ),
                onChanged: _icerikDegisti,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
