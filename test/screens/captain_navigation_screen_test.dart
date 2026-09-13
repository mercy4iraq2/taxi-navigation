import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_navigation/models/trip.dart';
import 'package:taxi_navigation/screens/captain_navigation_screen.dart';
import 'package:taxi_navigation/services/navigation_service.dart';

void main() {
  final trip = Trip.fromMap(const <String, dynamic>{
    'startLatitude': 33.3152,
    'startLongitude': 44.3661,
    'destinationLatitude': 33.3128,
    'destinationLongitude': 44.3615,
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    NavigationService navigationService,
  ) {
    return tester.pumpWidget(
      MaterialApp(
        home: CaptainNavigationScreen(
          trip: trip,
          navigationService: navigationService,
        ),
      ),
    );
  }

  testWidgets('shows trip coordinates and navigation actions in Arabic', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, FakeNavigationService());

    expect(find.text('ملاحة الرحلة'), findsOneWidget);
    expect(find.text('نقطة الانطلاق'), findsOneWidget);
    expect(find.text('نقطة الوصول'), findsOneWidget);
    expect(find.text('فتح في Google Maps'), findsOneWidget);
    expect(find.text('فتح في Waze'), findsOneWidget);
  });

  testWidgets('fromTripMap builds the screen from external payload data', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CaptainNavigationScreen.fromTripMap(const <String, dynamic>{
          'startLatitude': 33.3152,
          'startLongitude': 44.3661,
          'destinationLatitude': 33.3128,
          'destinationLongitude': 44.3615,
        }, navigationService: FakeNavigationService()),
      ),
    );

    expect(find.text('33.315200, 44.366100'), findsOneWidget);
    expect(find.text('33.312800, 44.361500'), findsOneWidget);
  });

  test('fromTripMap throws when payload coordinates are invalid', () {
    expect(
      () => CaptainNavigationScreen.fromTripMap(const <String, dynamic>{
        'startLatitude': 'invalid',
        'startLongitude': 44.3661,
        'destinationLatitude': 33.3128,
        'destinationLongitude': 44.3615,
      }),
      throwsFormatException,
    );
  });

  testWidgets('tapping Google Maps shows loading state and disables actions', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final completer = Completer<void>();
    final service = FakeNavigationService(
      onOpenGoogleMaps: (_) => completer.future,
    );

    await pumpScreen(tester, service);

    await tester.tap(find.text('فتح في Google Maps'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('جاري فتح خرائط Google'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );

    completer.complete();
    await tester.pumpAndSettle();

    expect(service.googleMapsOpenCount, 1);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    semantics.dispose();
  });

  testWidgets('tapping Waze forwards the trip to the navigation service', (
    WidgetTester tester,
  ) async {
    final service = FakeNavigationService();

    await pumpScreen(tester, service);
    await tester.tap(find.text('فتح في Waze'));
    await tester.pumpAndSettle();

    expect(service.wazeOpenCount, 1);
  });

  testWidgets('tapping Waze shows loading state and disables actions', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final completer = Completer<void>();
    final service = FakeNavigationService(onOpenWaze: (_) => completer.future);

    await pumpScreen(tester, service);

    await tester.tap(find.text('فتح في Waze'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('جاري فتح Waze'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );

    completer.complete();
    await tester.pumpAndSettle();

    expect(service.wazeOpenCount, 1);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    semantics.dispose();
  });

  testWidgets('shows Arabic snackbar for navigation errors', (
    WidgetTester tester,
  ) async {
    final service = FakeNavigationService(
      onOpenWaze: (_) async =>
          throw const NavigationException('تعذر فتح Waze الآن.'),
    );

    await pumpScreen(tester, service);
    await tester.tap(find.text('فتح في Waze'));
    await tester.pumpAndSettle();

    expect(find.text('تعذر فتح Waze الآن.'), findsOneWidget);
  });

  testWidgets('shows Arabic snackbar for invalid coordinates', (
    WidgetTester tester,
  ) async {
    final service = FakeNavigationService(
      onOpenGoogleMaps: (_) async => throw const FormatException('invalid'),
    );

    await pumpScreen(tester, service);
    await tester.tap(find.text('فتح في Google Maps'));
    await tester.pumpAndSettle();

    expect(find.text('الإحداثيات المستلمة غير صالحة.'), findsOneWidget);
  });

  testWidgets('shows invalid-coordinate snackbar for Waze as well', (
    WidgetTester tester,
  ) async {
    final service = FakeNavigationService(
      onOpenWaze: (_) async => throw const FormatException('invalid'),
    );

    await pumpScreen(tester, service);
    await tester.tap(find.text('فتح في Waze'));
    await tester.pumpAndSettle();

    expect(find.text('الإحداثيات المستلمة غير صالحة.'), findsOneWidget);
  });

  testWidgets('shows zero-duration text for identical coordinates', (
    WidgetTester tester,
  ) async {
    final zeroTrip = Trip.fromMap(const <String, dynamic>{
      'startLatitude': 33.3152,
      'startLongitude': 44.3661,
      'destinationLatitude': 33.3152,
      'destinationLongitude': 44.3661,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: CaptainNavigationScreen(
          trip: zeroTrip,
          navigationService: FakeNavigationService(),
        ),
      ),
    );

    expect(find.text('الوقت المتوقع: أقل من دقيقة'), findsOneWidget);
  });

  testWidgets('shows multi-hour Arabic duration text', (
    WidgetTester tester,
  ) async {
    final longTrip = Trip.fromMap(const <String, dynamic>{
      'startLatitude': 0.0,
      'startLongitude': 0.0,
      'destinationLatitude': 0.0,
      'destinationLongitude': 0.63,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: CaptainNavigationScreen(
          trip: longTrip,
          navigationService: FakeNavigationService(),
        ),
      ),
    );

    expect(find.text('الوقت المتوقع: ساعتان'), findsOneWidget);
  });

  testWidgets('shows generic snackbar for unexpected failures', (
    WidgetTester tester,
  ) async {
    final service = FakeNavigationService(
      onOpenGoogleMaps: (_) async => throw Exception('boom'),
    );

    await pumpScreen(tester, service);
    await tester.tap(find.text('فتح في Google Maps'));
    await tester.pumpAndSettle();

    expect(
      find.text('حدث خطأ غير متوقع أثناء فتح تطبيق الملاحة.'),
      findsOneWidget,
    );
  });
}

class FakeNavigationService extends NavigationService {
  FakeNavigationService({this.onOpenGoogleMaps, this.onOpenWaze});

  final Future<void> Function(Trip trip)? onOpenGoogleMaps;
  final Future<void> Function(Trip trip)? onOpenWaze;
  int googleMapsOpenCount = 0;
  int wazeOpenCount = 0;

  @override
  Future<void> openGoogleMaps(Trip trip) async {
    googleMapsOpenCount++;
    await onOpenGoogleMaps?.call(trip);
  }

  @override
  Future<void> openWaze(Trip trip) async {
    wazeOpenCount++;
    await onOpenWaze?.call(trip);
  }
}
