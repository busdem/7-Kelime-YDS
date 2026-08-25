import 'package:flutter/material.dart';

final List<Map<String, dynamic>> rehberIpuclari = [
  {
    'baslik': 'Neden 7 Kelime?',
    'ikon': Icons.psychology,
    'icerik': 'Beynimiz bir günde yüzlerce kelimeye maruz kalabilir ama onları gerçekten "öğrenmek" için odaklanmaya ihtiyacı vardır. Bilimsel araştırmalar, kısa süreli hafızamızın bir seferde en verimli şekilde ortalama 7 yeni bilgiyi işleyebildiğini gösteriyor. Amacımız seni kelime yığınlarına boğup tüketmek değil; az, öz ve kalıcı adımlarla hedefine ulaştırmak.',
  },
  {
    'baslik': 'IPA Nedir?',
    'ikon': Icons.mic,
    'icerik': 'Kelime kartlarındaki /kənˈstrʌkt/ gibi garip semboller gözünü korkutmasın! Bunlar Uluslararası Fonetik Alfabe (IPA) sembolleridir ve kelimenin tam olarak nasıl telaffuz edileceğini gösterir. Bu sembolleri ezberlemene gerek yok; sadece vurgunun nerede olduğunu (kesme işareti olan yer) anlaman için bir ipucudur. Telaffuzdan emin olamadığın an, kelimenin yanındaki ses ikonuna tıklayarak doğru okunuşu duyabilirsin.',
  },
  {
    'baslik': 'Sık Karıştırılan Kelime Çiftleri',
    'ikon': Icons.compare_arrows,
    'icerik': 'YDS\'de doğru cevabı bulmanı engelleyen genelde bilmediğin kelimeler değil, birbirine çok benzeyen kelimelerdir! \'However\' ile \'Nevertheless\' ikisi de "ancak" anlamına gelir ama biri cümle başında virgülle, diğeri genelde bağımsız cümleler arasında kullanılır. \'Few\' ("neredeyse hiç yok", olumsuz anlam) ile \'A few\' ("birkaç tane var", olumlu anlam) arasındaki tek fark bir harf ama anlam tamamen değişir. \'Economic\' (ekonomiyle ilgili) ile \'Economical\' (tutumlu, az harcayan) da sınavın klasik tuzaklarındandır. Bu tür çiftleri tek tek değil, ikili gruplar halinde ezberlemek, sınavda hangi durumda hangisinin kullanılacağını çok daha net görmeni sağlar.',
  },
  {
    'baslik': 'Bağlaçlar ve Geçiş İfadeleri',
    'ikon': Icons.link,
    'icerik': 'YDS\'nin boşluk doldurma ve paragraf tamamlama sorularının büyük bir kısmı, aslında kelime bilgisinden çok bağlaç bilgisini test eder. \'However\', \'Nevertheless\', \'Moreover\', \'Furthermore\' gibi ifadeler cümleler arasındaki mantıksal ilişkiyi kurar: zıtlık mı (whereas, although, despite), ekleme mi (in addition, besides), sonuç mu (therefore, thus, consequently) anlatılıyor? Bir cümlenin öncesini ve sonrasını okuyup hangi ilişkinin kurulduğunu anlayabilirsen, kelimeyi bilmesen bile doğru bağlacı seçebilirsin. Her yeni bağlaç öğrendiğinde, hangi "aile"ye ait olduğunu (zıtlık/sonuç/ekleme) not almaya çalış.',
  },
  {
    'baslik': 'Kelime + Doğru Edat Kalıpları',
    'ikon': Icons.anchor,
    'icerik': '\'Depend\', \'responsible\', \'aware\', \'capable\' gibi kelimeleri çoğu öğrenci bilir ama hangi edatla kullanıldığını karıştırır: depend ON, responsible FOR, aware OF, capable OF, interested IN, similar TO. YDS\'de bu kalıplar hem doğrudan boşluk doldurma sorusu olarak hem de cümle içinde "yanlış" bir edatla seni yanıltmak için kullanılır. Yeni bir kelime öğrenirken sadece anlamını değil, yanına hangi edatın geldiğini de bir bütün olarak ezberlemek, tek tek edat kurallarını ezberlemekten çok daha kalıcı ve pratik bir yöntemdir.',
  },
  {
    'baslik': 'Eklerle Kelime Türetme',
    'ikon': Icons.construction,
    'icerik': 'Bilmediğin bir kelimeyle karşılaştığında bile, ekleri tanıyarak kelimenin türünü ve hatta anlamını tahmin edebilirsin. Olumsuzluk önekleri: un-, in-, dis-, im- (unaware, incomplete, disagree, impossible). İsim yapan sonekler: -tion, -ness, -ment, -ity (creation, kindness, development, activity). Sıfat yapan sonekler: -ive, -ful, -less, -able (creative, useful, careless, comfortable). YDS\'de bazı sorular doğrudan "boşluğa hangi tür kelime gelmeli" diye sorar; cümledeki boşluğun önünde/sonunda ne olduğuna bakarak doğru ekli formu seçebilirsin.',
  },
  {
    'baslik': 'Bağlamdan Anlam Çıkarma',
    'ikon': Icons.psychology_alt,
    'icerik': 'Sınavda mutlaka bilmediğin bir kelimeyle karşılaşacaksın. Bu normal, hatta beklenen bir şey. Böyle bir anda panikleyip soruyu boş bırakmak yerine, cümledeki ipuçlarına bak: kelimeden hemen önce/sonra bir \'but\', \'however\', \'although\' varsa, kelime muhtemelen cümlenin geri kalanıyla ZIT bir anlam taşıyor. Bir örnek veya tanım cümlesi varsa (", which means...", ", such as..."), kelimenin anlamı genelde orada saklıdır. Cümlenin genel havası olumlu mu olumsuz mu, kelime muhtemelen o havayı taşıyor. Bu strateji, kelime dağarcığın ne kadar geniş olursa olsun her zaman işine yarayacak bir sınav refleksi.',
  },
  {
    'baslik': 'Akademik Kelime Aileleri',
    'ikon': Icons.school,
    'icerik': 'YDS metinleri genelde bilim, ekonomi, sağlık, çevre gibi akademik konulardan seçilir. Bu yüzden tek bir kelimeyi değil, aynı kökten türeyen tüm aileyi öğrenmek büyük avantaj sağlar: significant (sıfat) → significantly (zarf) → significance (isim); analyze (fiil) → analysis (isim) → analytical (sıfat); differ (fiil) → different (sıfat) → difference (isim) → differently (zarf). Bir kelimeyi öğrendiğinde "bunun fiili, ismi, sıfatı, zarfı ne?" diye kendine sormak, tek seferde 3-4 kelimeyi birden kazanmanı sağlar.',
  },
];
