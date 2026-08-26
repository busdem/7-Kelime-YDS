import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

final FlutterLocalNotificationsPlugin bildirimEklentisi =
    FlutterLocalNotificationsPlugin();

const String _gunlukKanalId = 'gunluk_hatirlatma_kanali';
const String _gunlukKanalAdi = 'Günlük Kelime Hatırlatma';
const String _gunlukKanalAciklama =
    'Her gün saat 09:00\'da günün yeni kelimelerini hatırlatır.';

// Eklentiyi başlatır, saat dilimini ayarlar ve gerekiyorsa bildirim izni ister.
Future<void> bildirimleriBaslat() async {
  tz.initializeTimeZones();
  try {
    final tzBilgisi = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzBilgisi.identifier));
  } catch (_) {
    // Cihazın saat dilimi alınamazsa varsayılan (UTC) ile devam eder.
  }

  const androidAyarlari = AndroidInitializationSettings('@mipmap/launcher_icon');
  const iosAyarlari = DarwinInitializationSettings();
  const ayarlar = InitializationSettings(
    android: androidAyarlari,
    iOS: iosAyarlari,
  );

  await bildirimEklentisi.initialize(settings: ayarlar);

  // Android 13+ için bildirim izni iste (iOS izni DarwinInitializationSettings
  // ile initialize() sırasında zaten isteniyor).
  await bildirimEklentisi
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.requestNotificationsPermission();
}

// Her gün saat 09:00'da tekrarlayan günlük kelime hatırlatma bildirimini planlar.
Future<void> gunlukHatirlatmayiZamanla() async {
  tz.TZDateTime simdi = tz.TZDateTime.now(tz.local);
  tz.TZDateTime zamanlanan = tz.TZDateTime(
    tz.local,
    simdi.year,
    simdi.month,
    simdi.day,
    9, // saat 09:00
  );
  if (zamanlanan.isBefore(simdi)) {
    zamanlanan = zamanlanan.add(const Duration(days: 1));
  }

  await bildirimEklentisi.zonedSchedule(
    id: 0,
    title: 'YDS Kelime Rehberi',
    body: 'Günün 7 yeni kelimesi seni bekliyor!',
    scheduledDate: zamanlanan,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        _gunlukKanalId,
        _gunlukKanalAdi,
        channelDescription: _gunlukKanalAciklama,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}
