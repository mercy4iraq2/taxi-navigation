import 'dart:math' as math;

class Trip {
  Trip({
    required this.startLatitude,
    required this.startLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
  }) {
    if (!hasValidCoordinates) {
      throw const FormatException('Trip coordinates are out of range.');
    }
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      startLatitude: _parseCoordinate(map, 'startLatitude'),
      startLongitude: _parseCoordinate(map, 'startLongitude'),
      destinationLatitude: _parseCoordinate(map, 'destinationLatitude'),
      destinationLongitude: _parseCoordinate(map, 'destinationLongitude'),
    );
  }

  factory Trip.fromJson(Map<String, dynamic> json) => Trip.fromMap(json);

  final double startLatitude;
  final double startLongitude;
  final double destinationLatitude;
  final double destinationLongitude;

  bool get hasValidCoordinates {
    return _isValidLatitude(startLatitude) &&
        _isValidLongitude(startLongitude) &&
        _isValidLatitude(destinationLatitude) &&
        _isValidLongitude(destinationLongitude);
  }

  String get formattedStartCoordinates =>
      '${startLatitude.toStringAsFixed(6)}, ${startLongitude.toStringAsFixed(6)}';

  String get formattedDestinationCoordinates =>
      '${destinationLatitude.toStringAsFixed(6)}, ${destinationLongitude.toStringAsFixed(6)}';

  double get straightLineDistanceKm {
    const earthRadiusKm = 6371.0;
    final startLatRad = _degreesToRadians(startLatitude);
    final endLatRad = _degreesToRadians(destinationLatitude);
    final deltaLat = _degreesToRadians(destinationLatitude - startLatitude);
    final deltaLng = _degreesToRadians(destinationLongitude - startLongitude);

    final a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(startLatRad) *
            math.cos(endLatRad) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  Duration get estimatedDriveDuration {
    if (straightLineDistanceKm == 0) {
      return Duration.zero;
    }

    const averageCitySpeedKmPerHour = 35.0;
    final estimatedMinutes =
        (straightLineDistanceKm / averageCitySpeedKmPerHour * 60).round();
    return Duration(minutes: math.max(1, estimatedMinutes));
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'startLatitude': startLatitude,
      'startLongitude': startLongitude,
      'destinationLatitude': destinationLatitude,
      'destinationLongitude': destinationLongitude,
    };
  }

  static double _parseCoordinate(Map<String, dynamic> map, String key) {
    final value = map[key];

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }

    throw FormatException('Missing or invalid coordinate: $key');
  }

  static bool _isValidLatitude(double value) => value >= -90 && value <= 90;

  static bool _isValidLongitude(double value) => value >= -180 && value <= 180;

  static double _degreesToRadians(double degrees) => degrees * math.pi / 180;
}
