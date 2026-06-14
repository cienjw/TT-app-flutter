import 'package:flutter/material.dart';
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

  static const _fallback = NLatLng(37.5665, 126.9780); // 서울 시청 기준

  @override
  Widget build(BuildContext context) {
    final footprintsAsync = ref.watch(footprintsProvider);

    ref.listen(footprintsProvider, (_, next) {
      next.whenData(_syncMarkers);
    });

    final screenH = MediaQuery.of(context).size.height;
    final myLocBottom = screenH * _sheetExtent + 16;
    final compassBottom = myLocBottom + 60;

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
                options: const NaverMapViewOptions(
                  initialCameraPosition: NCameraPosition(target: _fallback, zoom: 12),
                  locationButtonEnable: false,
                ),
                onMapReady: _onMapReady,
                onCameraChange: (reason, animated) => _updateBearing(),
                onCameraIdle: () => _updateBearing(),
              ),
            ),

            // Top Guide Chip
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryPink, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '우리 동네 인기 만남 장소예요',
                        style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Compass
            if (_bearing.abs() > 0.5)
              Positioned(
                right: 20,
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
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                    ),
                    child: Transform.rotate(
                      angle: -_bearing * math.pi / 180,
                      child: const Icon(Icons.explore_rounded, color: AppColors.primaryBlue, size: 28),
                    ),
                  ),
                ),
              ),

            // My Location Button
            Positioned(
              right: 20,
              bottom: myLocBottom,
              child: GestureDetector(
                onTap: _goToMyLocation,
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                  ),
                  child: const Icon(Icons.my_location_rounded, color: AppColors.primaryPink, size: 24),
                ),
              ),
            ),

            _buildBottomSheet(footprintsAsync),
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
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;

      final lo = await controller.getLocationOverlay();
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
      final myLatLng = NLatLng(pos.latitude, pos.longitude);
      _moveCameraTo(controller, myLatLng);
      lo.setPosition(myLatLng);
      lo.setIsVisible(true);
    } catch (_) {}
  }

  void _moveCameraTo(NaverMapController controller, NLatLng target) {
    controller.updateCamera(
      NCameraUpdate.withParams(target: target)
        ..setAnimation(
            animation: NCameraAnimation.easing,
            duration: const Duration(milliseconds: 400)),
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
      )..setAnimation(
          animation: NCameraAnimation.fly,
          duration: const Duration(milliseconds: 600)),
    );
    _showDetail(f);
  }

  void _showDetail(Footprint f) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _FootprintDetailSheet(footprint: f),
    );
  }

  Widget _buildBottomSheet(AsyncValue<List<Footprint>> async) {
    return DraggableScrollableSheet(
      initialChildSize: 0.24,
      minChildSize: 0.12,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: async.when(
            data: (footprints) => ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('최근 만남 기록', style: AppTextStyles.title),
                const SizedBox(height: 16),
                if (footprints.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.map_outlined, size: 48, color: AppColors.textHint.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          const Text('아직 기록된 만남이 없어요', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  )
                else
                  ...footprints.map((f) => _FootprintCard(
                    footprint: f,
                    onTap: () => _moveTo(f),
                  )),
                const SizedBox(height: 32),
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
    final dateStr = DateFormat('M월 d일').format(footprint.metAt);
    final title = footprint.interests.isEmpty
        ? footprint.groupName
        : footprint.interests.join(' · ');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightGrey.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.location_on_rounded, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.title.copyWith(fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('$dateStr · ${footprint.attendeeCount}명이 만났어요', style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
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
    final dateStr = DateFormat('yyyy년 M월 d일').format(footprint.metAt);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.lightGrey, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: AppColors.backgroundBlue, borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.groups_rounded, color: AppColors.primaryBlue, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${footprint.attendeeCount}명이 모인 만남', style: AppTextStyles.headline2.copyWith(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(dateStr, style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('함께 나눈 관심사', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: footprint.interests.map((interest) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(interest, style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
