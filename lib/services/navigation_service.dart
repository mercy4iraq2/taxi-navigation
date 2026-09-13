import 'package:taxi_navigation/models/trip.dart';
import 'package:url_launcher/url_launcher.dart';

typedef LaunchUrlFn = Future<bool> Function(Uri uri, {LaunchMode? mode});

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
  }) : _canLaunchUrl = canLaunchUrlFn ?? canLaunchUrl,
       _launchUrl = launchUrlFn ?? _defaultLaunchUrl;

  final Future<bool> Function(Uri uri) _canLaunchUrl;
  final LaunchUrlFn _launchUrl;

  Uri buildGoogleMapsAppUri(Trip trip) {
    return Uri.parse(
      'comgooglemaps://?saddr=${trip.startLatitude},${trip.startLongitude}'
      '&daddr=${trip.destinationLatitude},${trip.destinationLongitude}'
      '&directionsmode=driving',
    );
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
    await _launchFirstAvailable(<_LaunchTarget>[
      _LaunchTarget(
        uri: buildGoogleMapsAppUri(trip),
        mode: LaunchMode.externalApplication,
      ),
      _LaunchTarget(
        uri: buildGoogleMapsUri(trip),
        mode: LaunchMode.externalApplication,
      ),
    ], errorMessage: 'تعذر فتح خرائط Google. تأكد من توفر التطبيق أو المتصفح.');
  }

  Future<void> openWaze(Trip trip) async {
    await _launchFirstAvailable(
      buildWazeUris(trip)
          .map(
            (uri) =>
                _LaunchTarget(uri: uri, mode: LaunchMode.externalApplication),
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

      final launched = await _launchUrl(target.uri, mode: target.mode);
      if (launched) {
        return;
      }
    }

    throw NavigationException(errorMessage);
  }

  static Future<bool> _defaultLaunchUrl(Uri uri, {LaunchMode? mode}) {
    if (mode == null) {
      return launchUrl(uri);
    }

    return launchUrl(uri, mode: mode);
  }
}

class _LaunchTarget {
  const _LaunchTarget({required this.uri, this.mode});

  final Uri uri;
  final LaunchMode? mode;
}
