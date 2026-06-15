import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/footprint_repository.dart';
import '../domain/footprint_provider.dart';
import 'dart:math' as math;

class FootprintsScreen extends ConsumerStatefulWidget {
  const FootprintsScreen({super.key});

  @override
  ConsumerState<FootprintsScreen> createState() => _FootprintsScreenState();
}

class _FootprintsScreenState extends ConsumerState<FootprintsScreen> {
  NaverMapController? _controller;
  double _bearing = 0;
  double _sheetExtent = 0.24;

  static const _fallback = NLatLng(36.9921, 127.1129);

  @override
  Widget build(BuildContext context) {
    final footprintsAsync = ref.watch(footprintsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ref.listen(footprintsProvider, (_, next) {
      next.whenData(_syncMarkers);
    });

    final screenH = MediaQuery.of(context).size.height;
    final myLocBottom = screenH * _sheetExtent + 12;
    final compassBottom = myLocBottom + 52;

    return Scaffold(
      body: NotificationListener<DraggableScrollableNotification>(
        onNotification: (n) {
          setState(() => _sheetExtent = n.extent);
          return false;
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: NaverMap(
                options: NaverMapViewOptions(
                  initialCameraPosition: const NCameraPosition(target: _fallback, zoom: 12),
                  mapType: isDark ? NMapType.navi : NMapType.basic,
                  nightModeEnable: isDark,
                  locationButtonEnable: false,
                ),
                onMapReady: _onMapReady,
                onCameraChange: (reason, animated) => _updateBearing(),
                onCameraIdle: () => _updateBearing(),
              ),
            ),

            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                  ),
                  child: Text(
                    '같은 관심사를 가진 사람들이 다녀간 곳이에요',
                    style: AppTextStyles.caption.copyWith(color: theme.textTheme.bodyLarge?.color),
                  ),
                ),
              ),
            ),

            if (_bearing.abs() > 0.5)
              Positioned(
                right: 16,
                bottom: compassBottom,
                child: GestureDetector(
                  onTap: () {
                    _controller?.updateCamera(
                      NCameraUpdate.withParams(bearing: 0)
                        ..setAnimation(
                            animation: NCameraAnimation.easing,
                            duration: const Duration(milliseconds: 400)),
                    );
                    setState(() => _bearing = 0);
                  },
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      shape: BoxShape.circle,
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    child: Transform.rotate(
                      angle: -_bearing * math.pi / 180,
                      child: Icon(CupertinoIcons.location_north_fill, color: theme.primaryColor, size: 24),
                    ),
                  ),
                ),
              ),

            Positioned(
              right: 16,
              bottom: myLocBottom,
              child: GestureDetector(
                onTap: _goToMyLocation,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: Icon(Icons.my_location, color: theme.primaryColor, size: 22),
                ),
              ),
            ),

            _buildBottomSheet(footprintsAsync, theme),
          ],
        ),
      ),
    );
  }

  Future<void> _onMapReady(NaverMapController controller) async {
    _controller = controller;
    controller.setLocationTrackingMode(NLocationTrackingMode.noFollow);
    ref.read(footprintsProvider).whenData(_syncMarkers);
    _goToMyLocation();
  }

  Future<void> _goToMyLocation() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;

      final lo = await controller.getLocationOverlay();

      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        final lastLatLng = NLatLng(last.latitude, last.longitude);
        _moveCameraTo(controller, lastLatLng);
        lo.setPosition(lastLatLng);
        lo.setIsVisible(true);
      }

      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 5),
        );
        final myLatLng = NLatLng(pos.latitude, pos.longitude);
        _moveCameraTo(controller, myLatLng);
        lo.setPosition(myLatLng);
        lo.setIsVisible(true);
      } catch (_) {}
    } catch (_) {}
  }

  void _moveCameraTo(NaverMapController controller, NLatLng target) {
    controller.updateCamera(
      NCameraUpdate.withParams(target: target)
        ..setAnimation(animation: NCameraAnimation.easing, duration: const Duration(milliseconds: 400)),
    );
  }

  Future<void> _updateBearing() async {
    final cam = await _controller?.getCameraPosition();
    if (cam == null || !mounted) return;
    if ((cam.bearing - _bearing).abs() > 0.1) {
      setState(() => _bearing = cam.bearing);
    }
  }

  Future<void> _syncMarkers(List<Footprint> footprints) async {
    final controller = _controller;
    if (controller == null) return;
    controller.clearOverlays(type: NOverlayType.marker);

    for (final f in footprints) {
      final marker = NMarker(
        id: 'fp_${f.groupId}',
        position: NLatLng(f.latitude, f.longitude),
        caption: NOverlayCaption(text: '${f.attendeeCount}명'),
      );
      marker.setOnTapListener((overlay) => _showDetail(f));
      await controller.addOverlay(marker);
    }
  }

  void _moveTo(Footprint f) {
    _controller?.updateCamera(
      NCameraUpdate.scrollAndZoomTo(
        target: NLatLng(f.latitude, f.longitude),
        zoom: 15,
      )..setAnimation(animation: NCameraAnimation.fly, duration: const Duration(milliseconds: 600)),
    );
    _showDetail(f);
  }

  void _showDetail(Footprint f) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FootprintDetailSheet(footprint: f),
    );
  }

  Widget _buildBottomSheet(AsyncValue<List<Footprint>> async, ThemeData theme) {
    return DraggableScrollableSheet(
      initialChildSize: 0.24,
      minChildSize: 0.12,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor, // 바닥 시트는 기본 배경색 사용
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
          ),
          child: async.when(
            data: (footprints) => ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text('최근 만남', style: AppTextStyles.title.copyWith(color: theme.textTheme.bodyLarge?.color)),
                ),
                if (footprints.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text('아직 기록된 만남이 없어요', style: AppTextStyles.caption),
                    ),
                  )
                else
                  ...footprints.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _FootprintCard(footprint: f, onTap: () => _moveTo(f)),
                  )),
                const SizedBox(height: 20),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(20),
              child: Text('발자취를 불러오지 못했어요: $e', style: AppTextStyles.caption),
            ),
          ),
        );
      },
    );
  }
}

class _FootprintCard extends StatelessWidget {
  final Footprint footprint;
  final VoidCallback onTap;
  const _FootprintCard({required this.footprint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('M월 d일').format(footprint.metAt);
    final title = footprint.interests.isEmpty ? footprint.groupName : footprint.interests.join(' · ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border.all(color: theme.dividerColor, width: 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle
              ),
              child: Icon(CupertinoIcons.placemark_fill, color: theme.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      title,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color),
                      maxLines: 1, overflow: TextOverflow.ellipsis
                  ),
                  const SizedBox(height: 2),
                  Text('$dateStr · ${footprint.attendeeCount}명이 만났어요', style: AppTextStyles.caption.copyWith(color: theme.textTheme.bodyMedium?.color)),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, color: theme.textTheme.bodyMedium?.color),
          ],
        ),
      ),
    );
  }
}

class _FootprintDetailSheet extends StatelessWidget {
  final Footprint footprint;
  const _FootprintDetailSheet({required this.footprint});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('yyyy년 M월 d일').format(footprint.metAt);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: theme.dividerColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(CupertinoIcons.person_3_fill, color: theme.primaryColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${footprint.attendeeCount}명이 모인 만남', style: AppTextStyles.title.copyWith(color: theme.textTheme.bodyLarge?.color)),
                      Text(dateStr, style: AppTextStyles.caption.copyWith(color: theme.textTheme.bodyMedium?.color)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('이런 관심사를 가진 사람들이에요', style: AppTextStyles.caption.copyWith(color: theme.textTheme.bodyMedium?.color)),
            const SizedBox(height: 10),
            if (footprint.interests.isEmpty)
              Text('관심사 정보가 없어요', style: AppTextStyles.body.copyWith(color: theme.textTheme.bodyLarge?.color))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: footprint.interests.map((name) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(name,
                        style: AppTextStyles.body.copyWith(
                            color: theme.primaryColor, fontWeight: FontWeight.w600)),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}