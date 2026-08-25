import '../kelimeler.dart';

// --- DİNAMİK SORU ÜRETİCİ (Yapay Zeka Gibi Çalışır) ---
List<Map<String, dynamic>> dinamikSoruUret(
  List<Map<String, String>> kaynakKelimeler,
) {
  List<Map<String, dynamic>> uretilenSorular = [];
  var tumKelimeler = List<Map<String, String>>.from(ydsKelimeleri);

  for (var kelime in kaynakKelimeler) {
    String dogruCevap = kelime['meaning'] ?? '';
    List<String> secenekler = [dogruCevap];

    tumKelimeler.shuffle();
    for (var rKelime in tumKelimeler) {
      if (secenekler.length >= 4) break;
      String anlam = rKelime['meaning'] ?? '';
      if (!secenekler.contains(anlam)) {
        secenekler.add(anlam);
      }
    }
    secenekler.shuffle(); // Şıkların yerini karıştır

    uretilenSorular.add({'kelime': kelime, 'secenekler': secenekler});
  }
  return uretilenSorular;
}

// --- DİNLEME SORUSU ÜRETİCİ ---
// kolayMod true: doğru cevap kelime['word'] (İngilizce yazılış şıkları).
// kolayMod false: mevcut dinamikSoruUret ile birebir aynı mantık.
List<Map<String, dynamic>> dinamikDinlemeSorusuUret(
  List<Map<String, String>> kaynakKelimeler, {
  required bool kolayMod,
}) {
  if (!kolayMod) {
    return dinamikSoruUret(kaynakKelimeler);
  }

  List<Map<String, dynamic>> uretilenSorular = [];
  var tumKelimeler = List<Map<String, String>>.from(ydsKelimeleri);

  for (var kelime in kaynakKelimeler) {
    String dogruCevap = kelime['word'] ?? '';
    List<String> secenekler = [dogruCevap];

    // Zorluğu artırmak için benzer uzunlukta / aynı harfle başlayan
    // kelimeleri önceliklendir; kalanı rastgele sırayla tamamlar.
    var adaylar = List<Map<String, String>>.from(tumKelimeler)..shuffle();
    adaylar.sort((a, b) {
      int puanHesapla(Map<String, String> k) {
        String yazilisi = k['word'] ?? '';
        int puan = 0;
        if (yazilisi.isNotEmpty &&
            dogruCevap.isNotEmpty &&
            yazilisi[0].toLowerCase() == dogruCevap[0].toLowerCase()) {
          puan += 2;
        }
        if ((yazilisi.length - dogruCevap.length).abs() <= 1) {
          puan += 1;
        }
        return puan;
      }

      return puanHesapla(b).compareTo(puanHesapla(a));
    });

    for (var rKelime in adaylar) {
      if (secenekler.length >= 4) break;
      String yazilisi = rKelime['word'] ?? '';
      if (yazilisi.isNotEmpty && !secenekler.contains(yazilisi)) {
        secenekler.add(yazilisi);
      }
    }
    secenekler.shuffle(); // Şıkların yerini karıştır

    uretilenSorular.add({'kelime': kelime, 'secenekler': secenekler});
  }
  return uretilenSorular;
}
