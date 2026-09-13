import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_navigation/models/trip.dart';
import 'package:taxi_navigation/services/navigation_service.dart';

void main() {
  final trip = Trip.fromMap(const <String, dynamic>{
    'startLatitude': 33.3152,
    'startLongitude': 44.3661,
    'destinationLatitude': 33.3128,
    'destinationLongitude': 44.3615,
  });

  group('NavigationService', () {
    test('builds a Google Maps directions URL with origin and destination', () {
      final service = NavigationService();
      final uri = service.buildGoogleMapsUri(trip);

      expect(uri.host, 'www.google.com');
      expect(uri.queryParameters['origin'], '33.3152,44.3661');
      expect(uri.queryParameters['destination'], '33.3128,44.3615');
      expect(uri.queryParameters['travelmode'], 'driving');
    });

    test('prefers Waze app URL before web fallback', () {
      final service = NavigationService();
      final uris = service.buildWazeUris(trip);

      expect(uris.first.toString(), 'waze://?ll=33.3128,44.3615&navigate=yes');
      expect(uris.last.toString(), contains('https://www.waze.com/ul'));
    });

    test(
      'throws Arabic error when all launch targets are unavailable',
      () async {
        final service = NavigationService(
          canLaunchUrlFn: (_) async => false,
          launchUrlFn: (_, {mode}) async => false,
        );

        expect(
          () => service.openGoogleMaps(trip),
          throwsA(
            isA<NavigationException>().having(
              (error) => error.message,
              'message',
              contains('تعذر فتح خرائط Google'),
            ),
          ),
        );
      },
    );
  });
}
