import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_navigation/models/trip.dart';
import 'package:taxi_navigation/services/navigation_service.dart';
import 'package:url_launcher/url_launcher.dart';

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

    test('tries Google Maps app URL before the web fallback', () async {
      final checkedUris = <Uri>[];
      final launchedUris = <Uri>[];
      final launchModes = <LaunchMode?>[];
      final service = NavigationService(
        platform: TargetPlatform.android,
        canLaunchUrlFn: (uri) async {
          checkedUris.add(uri);
          return uri.scheme == 'https';
        },
        launchUrlFn: (uri, {mode}) async {
          launchedUris.add(uri);
          launchModes.add(mode);
          return true;
        },
      );

      await service.openGoogleMaps(trip);

      expect(checkedUris[0], service.buildGoogleMapsAppUri(trip));
      expect(checkedUris[1], service.buildGoogleMapsUri(trip));
      expect(launchedUris.single, service.buildGoogleMapsUri(trip));
      expect(launchModes.single, LaunchMode.externalApplication);
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
