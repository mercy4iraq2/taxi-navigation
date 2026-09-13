# taxi-navigation

نظام ملاحة لتطبيق التكسي - فتح الإحداثيات على Google Maps و Waze.

## ما الذي تم إضافته؟

- `Trip` model لاستقبال الإحداثيات من Firebase أو REST API عبر `Map<String, dynamic>`
- `NavigationService` لفتح Google Maps وWaze باستخدام `url_launcher`
- شاشة عربية `CaptainNavigationScreen` لعرض نقطة الانطلاق والوصول والمسافة والوقت التقديري
- إعدادات Android وiOS المطلوبة للتعامل مع روابط Waze والروابط الخارجية
- اختبارات مركزة للنموذج والخدمة والواجهة

## مثال ربط مع Firebase أو REST API

```dart
final tripPayload = {
  'startLatitude': 33.3152,
  'startLongitude': 44.3661,
  'destinationLatitude': 33.3128,
  'destinationLongitude': 44.3615,
};

final screen = CaptainNavigationScreen.fromTripMap(tripPayload);
```

يمكن تمرير نفس الخريطة سواء جاءت من Firebase document أو من استجابة REST API.
