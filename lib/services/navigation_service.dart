import 'package:taxi_navigation/models/trip.dart';
import 'package:url_launcher/url_launcher.dart';

class NavigationException implements Exception {
  const NavigationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NavigationService {
  NavigationService({
    Future<bool> Function(Uri uri)? canLaunchUrlFn,
    Future<bool> Function(Uri uri)? launchExternalUrlFn,
  }) : _canLaunchUrl = canLaunchUrlFn ?? canLaunchUrl,
       _launchExternalUrl = launchExternalUrlFn ?? _defaultLaunchExternalUrl;

  final Future<bool> Function(Uri uri) _canLaunchUrl;
  final Future<bool> Function(Uri uri) _launchExternalUrl;

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
    await _launchFirstAvailable(<Uri>[
      buildGoogleMapsUri(trip),
    ], errorMessage: 'تعذر فتح خرائط Google. تأكد من توفر التطبيق أو المتصفح.');
  }

  Future<void> openWaze(Trip trip) async {
    await _launchFirstAvailable(
      buildWazeUris(trip),
      errorMessage: 'تعذر فتح Waze. تأكد من تثبيت التطبيق أو توفر المتصفح.',
    );
  }

  Future<void> _launchFirstAvailable(
    List<Uri> uris, {
    required String errorMessage,
  }) async {
    for (final uri in uris) {
      final canLaunch = await _canLaunchUrl(uri);
      if (!canLaunch) {
        continue;
      }

      final launched = await _launchExternalUrl(uri);
      if (launched) {
        return;
      }
    }

    throw NavigationException(errorMessage);
  }

  static Future<bool> _defaultLaunchExternalUrl(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
