import 'package:flutter/foundation.dart';
import 'package:taxi_navigation/models/trip.dart';
import 'package:url_launcher/url_launcher.dart';

typedef LaunchUrlFn = Future<bool> Function(
  Uri uri, {
  required LaunchMode mode,
});

class NavigationException implements Exception {
  const NavigationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NavigationService {
  NavigationService({
    Future<bool> Function(Uri uri)? canLaunchUrlFn,
    LaunchUrlFn? launchUrlFn,
    TargetPlatform? platform,
  }) : _canLaunchUrl = canLaunchUrlFn ?? canLaunchUrl,
       _launchUrl = launchUrlFn ?? _defaultLaunchUrl,
       _platform = platform ?? defaultTargetPlatform;

  final Future<bool> Function(Uri uri) _canLaunchUrl;
  final LaunchUrlFn _launchUrl;
  final TargetPlatform _platform;

  Uri? buildGoogleMapsAppUri(Trip trip) {
    switch (_platform) {
      case TargetPlatform.android:
        return Uri.parse(
          'google.navigation:q=${trip.destinationLatitude},${trip.destinationLongitude}&mode=d',
        );
      case TargetPlatform.iOS:
        return Uri.parse(
          'comgooglemaps://?saddr=${trip.startLatitude},${trip.startLongitude}'
          '&daddr=${trip.destinationLatitude},${trip.destinationLongitude}'
          '&directionsmode=driving',
        );
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return null;
    }
  }

  Uri buildGoogleMapsUri(Trip trip) {
    return Uri.https('www.google.com', '/maps/dir/', <String, String>{
      'api': '1',
      'origin': '${trip.startLatitude},${trip.startLongitude}',
      'destination': '${trip.destinationLatitude},${trip.destinationLongitude}',
      'travelmode': 'driving',
    });
  }

  List<Uri> buildWazeUris(Trip trip) {
    return <Uri>[
      Uri.parse(
        'waze://?ll=${trip.destinationLatitude},${trip.destinationLongitude}&navigate=yes',
      ),
      Uri.https('www.waze.com', '/ul', <String, String>{
        'll': '${trip.destinationLatitude},${trip.destinationLongitude}',
        'navigate': 'yes',
      }),
    ];
  }

  Future<void> openGoogleMaps(Trip trip) async {
    final targets = <_LaunchTarget>[
      if (buildGoogleMapsAppUri(trip) case final appUri?)
        _LaunchTarget(uri: appUri, mode: LaunchMode.externalApplication),
      _LaunchTarget(
        uri: buildGoogleMapsUri(trip),
        mode: LaunchMode.externalApplication,
      ),
    ];

    await _launchFirstAvailable(
      targets,
      errorMessage: 'تعذر فتح خرائط Google. تأكد من توفر التطبيق أو المتصفح.',
    );
  }

  Future<void> openWaze(Trip trip) async {
    await _launchFirstAvailable(
      buildWazeUris(trip)
          .map(
            (uri) => _LaunchTarget(
              uri: uri,
              mode: uri.scheme == 'https'
                  ? LaunchMode.platformDefault
                  : LaunchMode.externalApplication,
            ),
          )
          .toList(),
      errorMessage: 'تعذر فتح Waze. تأكد من تثبيت التطبيق أو توفر المتصفح.',
    );
  }

  Future<void> _launchFirstAvailable(
    List<_LaunchTarget> targets, {
    required String errorMessage,
  }) async {
    for (final target in targets) {
      final canLaunch = await _canLaunchUrl(target.uri);
      if (!canLaunch) {
        continue;
      }

      try {
        final launched = await _launchUrl(target.uri, mode: target.mode);
        if (launched) {
          return;
        }
      } catch (_) {
        continue;
      }
    }

    throw NavigationException(errorMessage);
  }

  static Future<bool> _defaultLaunchUrl(Uri uri, {required LaunchMode mode}) {
    return launchUrl(uri, mode: mode);
  }
}

class _LaunchTarget {
  const _LaunchTarget({required this.uri, this.mode});

  final Uri uri;
  final LaunchMode mode;
}
