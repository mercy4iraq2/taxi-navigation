import 'package:flutter/material.dart';
import 'package:taxi_navigation/models/trip.dart';
import 'package:taxi_navigation/screens/captain_navigation_screen.dart';

void main() {
  const tripPayload = <String, dynamic>{
    'startLatitude': 33.3152,
    'startLongitude': 44.3661,
    'destinationLatitude': 33.3128,
    'destinationLongitude': 44.3615,
  };

  Trip? initialTrip;
  String? initialError;

  try {
    initialTrip = Trip.fromMap(tripPayload);
  } on FormatException {
    initialError = 'تعذر تحميل بيانات الرحلة. الإحداثيات المستلمة غير صالحة.';
  } catch (_) {
    initialError = 'حدث خطأ أثناء تحميل بيانات الرحلة.';
  }

  runApp(
    TaxiNavigationApp(initialTrip: initialTrip, initialError: initialError),
  );
}

class TaxiNavigationApp extends StatelessWidget {
  const TaxiNavigationApp({
    super.key,
    required this.initialTrip,
    this.initialError,
  });

  final Trip? initialTrip;
  final String? initialError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Taxi Navigation',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: initialTrip != null
          ? CaptainNavigationScreen(trip: initialTrip!)
          : _TripLoadErrorScreen(message: initialError ?? 'تعذر تحميل الرحلة.'),
    );
  }
}

class _TripLoadErrorScreen extends StatelessWidget {
  const _TripLoadErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ملاحة الرحلة')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ),
    );
  }
}
