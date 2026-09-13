import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_navigation/models/trip.dart';

void main() {
  group('Trip', () {
    test('parses coordinates from numeric and string values', () {
      final trip = Trip.fromMap(const <String, dynamic>{
        'startLatitude': '33.3152',
        'startLongitude': 44.3661,
        'destinationLatitude': 33.3128,
        'destinationLongitude': '44.3615',
      });

      expect(trip.startLatitude, 33.3152);
      expect(trip.destinationLongitude, 44.3615);
    });

    test('throws when a coordinate is missing or invalid', () {
      expect(
        () => Trip.fromMap(const <String, dynamic>{
          'startLatitude': 120,
          'startLongitude': 44.3661,
          'destinationLatitude': 33.3128,
          'destinationLongitude': 44.3615,
        }),
        throwsFormatException,
      );
    });

    test('calculates distance and estimated duration', () {
      final trip = Trip.fromMap(const <String, dynamic>{
        'startLatitude': 33.3152,
        'startLongitude': 44.3661,
        'destinationLatitude': 33.3128,
        'destinationLongitude': 44.3615,
      });

      expect(trip.straightLineDistanceKm, greaterThan(0));
      expect(trip.estimatedDriveDuration, isNot(Duration.zero));
    });
  });
}
