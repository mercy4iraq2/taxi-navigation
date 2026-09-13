import 'package:flutter/material.dart';
import 'package:taxi_navigation/screens/captain_navigation_screen.dart';

void main() {
  const tripPayload = <String, dynamic>{
    'startLatitude': 33.3152,
    'startLongitude': 44.3661,
    'destinationLatitude': 33.3128,
    'destinationLongitude': 44.3615,
  };

  runApp(TaxiNavigationApp(tripPayload: tripPayload));
}

class TaxiNavigationApp extends StatelessWidget {
  const TaxiNavigationApp({super.key, required this.tripPayload});

  final Map<String, dynamic> tripPayload;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Taxi Navigation',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: CaptainNavigationScreen.fromTripMap(tripPayload),
    );
  }
}
