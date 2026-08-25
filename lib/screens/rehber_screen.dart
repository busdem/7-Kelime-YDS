import 'package:flutter/material.dart';

import '../data/rehber_ipuclari.dart';

// --- REHBER EKRANI (Statik İpucu Kartları) ---
class RehberScreen extends StatelessWidget {
  const RehberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rehber',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFC4B495),
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: rehberIpuclari.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final ipucu = rehberIpuclari[index];
          return _buildBilgiKart(
            context,
            ipucu['baslik'],
            ipucu['ikon'],
            ipucu['icerik'],
          );
        },
      ),
    );
  }

  Widget _buildBilgiKart(
    BuildContext context,
    String baslik,
    IconData icon,
    String icerik,
  ) {
    return InkWell(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(
            baslik,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Text(
              icerik,
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
                color: Color(0xFF4A5750),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Anladım',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFC4B495),
                ),
              ),
            ),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFC4B495).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFC4B495), size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                baslik,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFC4B495),
            ),
          ],
        ),
      ),
    );
  }
}
