import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_navigation/models/trip.dart';
import 'package:taxi_navigation/screens/captain_navigation_screen.dart';
import 'package:taxi_navigation/services/navigation_service.dart';

void main() {
  testWidgets('shows trip coordinates and navigation actions in Arabic', (
    WidgetTester tester,
  ) async {
    final trip = Trip.fromMap(const <String, dynamic>{
      'startLatitude': 33.3152,
      'startLongitude': 44.3661,
      'destinationLatitude': 33.3128,
      'destinationLongitude': 44.3615,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: CaptainNavigationScreen(
          trip: trip,
          navigationService: NavigationService(
            canLaunchUrlFn: (_) async => true,
            launchExternalUrlFn: (_) async => true,
          ),
        ),
      ),
    );

    expect(find.text('ملاحة الرحلة'), findsOneWidget);
    expect(find.text('نقطة الانطلاق'), findsOneWidget);
    expect(find.text('نقطة الوصول'), findsOneWidget);
    expect(find.text('فتح في Google Maps'), findsOneWidget);
    expect(find.text('فتح في Waze'), findsOneWidget);
  });
}
