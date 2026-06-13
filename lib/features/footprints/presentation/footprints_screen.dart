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
  double _sheetExtent = 0.24; // 하단 시트의 현재 높이 비율 (initialChildSize와 동일)

  static const _fallback = NLatLng(36.9921, 127.1129);

  @override
  Widget build(BuildContext context) {
    final footprintsAsync = ref.watch(footprintsProvider);

    ref.listen(footprintsProvider, (_, next) {
      next.whenData(_syncMarkers);
    });

    final screenH = MediaQuery.of(context).size.height;
    final myLocBottom = screenH * _sheetExtent + 12; // 시트 바로 위
    final compassBottom = myLocBottom + 52; // 위치 버튼 바로 위

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
                  initialCameraPosition:
                  NCameraPosition(target: _fallback, zoom: 12),
                  mapType: NMapType.basic,
                  locationButtonEnable: false,
                ),
                onMapReady: _onMapReady,
                onCameraChange: (reason, animated) => _updateBearing(),
                onCameraIdle: () => _updateBearing(),
              ),
            ),

            // 상단 안내 칩
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8),
                    ],
                  ),
                  child: Text('같은 관심사를 가진 사람들이 다녀간 곳이에요',
                      style: AppTextStyles.caption),
                ),
              ),
            ),

            // 나침반: 회전 시에만 표시, 위치 버튼 바로 위
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                    child: Transform.rotate(
                      angle: -_bearing * math.pi / 180,
                      child: const Icon(CupertinoIcons.location_north_fill,
                          color: AppColors.secondary, size: 24),
                    ),
                  ),
                ),
              ),

            // 내 위치 버튼: 시트 바로 위에 붙어 따라다님
            // 내 위치 버튼: 나침반과 동일한 원형 디자인
            Positioned(
              right: 16,
              bottom: myLocBottom,
              child: GestureDetector(
                onTap: _goToMyLocation,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: const Icon(Icons.my_location,
                      color: AppColors.primary, size: 22),
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

      // ① 캐시된 위치로 즉시 이동 + 파란점 먼저 표시
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        final lastLatLng = NLatLng(last.latitude, last.longitude);
        _moveCameraTo(controller, lastLatLng);
        lo.setPosition(lastLatLng);
        lo.setIsVisible(true);
      }

      // ② 정확한 위치로 보정 (실패해도 위 파란점은 유지됨)
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 5),
        );
        final myLatLng = NLatLng(pos.latitude, pos.longitude);
        _moveCameraTo(controller, myLatLng);
        lo.setPosition(myLatLng);
        lo.setIsVisible(true);
      } catch (_) {/* 캐시 위치로 이미 파란점 표시됨 */}
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
    // _markersSynced 플래그 검사 제거, 대신 기존 마커 클리어 ✅
    controller.clearOverlays(type: NOverlayType.marker);

    for (final f in footprints) {
      final marker = NMarker(
        id: 'fp_${f.groupId}', // 키가 같으면 덮어씌워지긴 함
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
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)],
          ),
          child: async.when(
            data: (footprints) => ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text('최근 만남', style: AppTextStyles.title),
                ),
                if (footprints.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text('아직 기록된 만남이 없어요',
                          style: AppTextStyles.caption),
                    ),
                  )
                else
                  ...footprints.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _FootprintCard(
                      footprint: f,
                      onTap: () => _moveTo(f),
                    ),
                  )),
                const SizedBox(height: 20),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(20),
              child: Text('발자취를 불러오지 못했어요: $e',
                  style: AppTextStyles.caption),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                  color: AppColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(CupertinoIcons.placemark_fill, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('$dateStr · ${footprint.attendeeCount}명이 만났어요',
                      style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, color: AppColors.textHint),
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
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                      color: AppColors.primaryLight, shape: BoxShape.circle),
                  child: const Icon(CupertinoIcons.person_3_fill, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${footprint.attendeeCount}명이 모인 만남',
                          style: AppTextStyles.title),
                      Text(dateStr, style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('이런 관심사를 가진 사람들이에요', style: AppTextStyles.caption),
            const SizedBox(height: 10),
            if (footprint.interests.isEmpty)
              Text('관심사 정보가 없어요', style: AppTextStyles.body)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: footprint.interests.map((name) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(name,
                        style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}