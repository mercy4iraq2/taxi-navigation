import 'package:flutter/material.dart';
import 'package:taxi_navigation/models/trip.dart';
import 'package:taxi_navigation/services/navigation_service.dart';

class CaptainNavigationScreen extends StatefulWidget {
  const CaptainNavigationScreen({
    super.key,
    required this.trip,
    this.navigationService,
  });

  factory CaptainNavigationScreen.fromTripMap(
    Map<String, dynamic> tripMap, {
    Key? key,
    NavigationService? navigationService,
  }) {
    return CaptainNavigationScreen(
      key: key,
      trip: Trip.fromMap(tripMap),
      navigationService: navigationService,
    );
  }

  final Trip trip;
  final NavigationService? navigationService;

  @override
  State<CaptainNavigationScreen> createState() =>
      _CaptainNavigationScreenState();
}

class _CaptainNavigationScreenState extends State<CaptainNavigationScreen> {
  late final NavigationService _navigationService =
      widget.navigationService ?? NavigationService();
  bool _isLaunchingGoogleMaps = false;
  bool _isLaunchingWaze = false;

  Future<void> _openGoogleMaps() async {
    if (_isLaunchingGoogleMaps || _isLaunchingWaze) {
      return;
    }

    setState(() => _isLaunchingGoogleMaps = true);
    try {
      await _handleNavigation(
        action: () => _navigationService.openGoogleMaps(widget.trip),
      );
    } finally {
      if (mounted) {
        setState(() => _isLaunchingGoogleMaps = false);
      }
    }
  }

  Future<void> _openWaze() async {
    if (_isLaunchingGoogleMaps || _isLaunchingWaze) {
      return;
    }

    setState(() => _isLaunchingWaze = true);
    try {
      await _handleNavigation(
        action: () => _navigationService.openWaze(widget.trip),
      );
    } finally {
      if (mounted) {
        setState(() => _isLaunchingWaze = false);
      }
    }
  }

  Future<void> _handleNavigation({
    required Future<void> Function() action,
  }) async {
    try {
      await action();
    } on FormatException {
      _showMessage('الإحداثيات المستلمة غير صالحة.');
    } on NavigationException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('حدث خطأ غير متوقع أثناء فتح تطبيق الملاحة.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textDirection: TextDirection.rtl)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estimatedDuration = widget.trip.estimatedDriveDuration;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ملاحة الرحلة'), centerTitle: true),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _InfoCard(
              title: 'نقطة الانطلاق',
              icon: Icons.my_location,
              coordinates: widget.trip.formattedStartCoordinates,
            ),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'نقطة الوصول',
              icon: Icons.location_on,
              coordinates: widget.trip.formattedDestinationCoordinates,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ملخص الرحلة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'المسافة التقديرية: ${widget.trip.straightLineDistanceKm.toStringAsFixed(1)} كم',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'الوقت المتوقع: ${_formatDuration(estimatedDuration)}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isLaunchingGoogleMaps)
              const Semantics(
                liveRegion: true,
                label: 'جاري فتح خرائط Google',
                child: SizedBox.shrink(),
              ),
            FilledButton.icon(
              onPressed: _isLaunchingGoogleMaps || _isLaunchingWaze
                  ? null
                  : _openGoogleMaps,
              icon: _isLaunchingGoogleMaps
                  ? const ExcludeSemantics(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.map_outlined),
              label: Text(
                _isLaunchingGoogleMaps
                    ? 'جاري فتح خرائط Google'
                    : 'فتح في Google Maps',
              ),
            ),
            const SizedBox(height: 12),
            if (_isLaunchingWaze)
              const Semantics(
                liveRegion: true,
                label: 'جاري فتح Waze',
                child: SizedBox.shrink(),
              ),
            OutlinedButton.icon(
              onPressed: _isLaunchingGoogleMaps || _isLaunchingWaze
                  ? null
                  : _openWaze,
              icon: _isLaunchingWaze
                  ? const ExcludeSemantics(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.alt_route),
              label: Text(_isLaunchingWaze ? 'جاري فتح Waze' : 'فتح في Waze'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) {
      return 'أقل من دقيقة';
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours == 0) {
      return '$minutes دقيقة';
    }

    if (minutes == 0) {
      return '$hours ساعة';
    }

    return '$hours ساعة و $minutes دقيقة';
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.coordinates,
  });

  final String title;
  final IconData icon;
  final String coordinates;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(coordinates),
      ),
    );
  }
}
