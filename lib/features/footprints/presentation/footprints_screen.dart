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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(footprintsProvider, (_, next) {
      next.whenData(_syncMarkers);
    });

    final screenH = MediaQuery.of(context).size.height;
    final myLocBottom = screenH * _sheetExtent + 16;
    final compassBottom = myLocBottom + 56;

    return Scaffold(
      body: NotificationListener<DraggableScrollableNotification>(
        onNotification: (n) {
          setState(() => _sheetExtent = n.extent);
          return false;
        },
        child: Stack(
          children: [
            // 지도
            Positioned.fill(
              child: NaverMap(
                options: NaverMapViewOptions(
                  initialCameraPosition:
                  const NCameraPosition(target: _fallback, zoom: 12),
                  mapType: isDark ? NMapType.navi : NMapType.basic,
                  nightModeEnable: isDark,
                  locationButtonEnable: false,
                ),
                onMapReady: _onMapReady,
                onCameraChange: (reason, animated) => _updateBearing(),
                onCameraIdle: () => _updateBearing(),
              ),
            ),

            // 상단 안내 칩 (블러 글래스모피즘)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 12, left: 20, right: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1C1C1E).withOpacity(0.88)
                        : Colors.white.withOpacity(0.88),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.07)
                          : Colors.black.withOpacity(0.06),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.sparkles,
                        size: 14,
                        color: AppColors.meetorySkyBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '같은 관심사를 가진 사람들이 다녀간 곳이에요',
                        style: AppTextStyles.caption.copyWith(
                          color: isDark
                              ? Colors.white.withOpacity(0.85)
                              : Colors.black.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 나침반
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
                  child: _MapButton(
                    isDark: isDark,
                    child: Transform.rotate(
                      angle: -_bearing * math.pi / 180,
                      child: Icon(CupertinoIcons.location_north_fill,
                          color: AppColors.meetoryPink, size: 20),
                    ),
                  ),
                ),
              ),

            // 내 위치 버튼
            Positioned(
              right: 16,
              bottom: myLocBottom,
              child: GestureDetector(
                onTap: _goToMyLocation,
                child: _MapButton(
                  isDark: isDark,
                  child: Icon(CupertinoIcons.location_fill,
                      color: AppColors.meetorySkyBlue, size: 20),
                ),
              ),
            ),

            _buildBottomSheet(footprintsAsync, isDark),
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
        id: 'fp_${f.groupId}_${f.metAt.millisecondsSinceEpoch}',
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
      backgroundColor: context.cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _FootprintDetailSheet(footprint: f),
    );
  }

  Widget _buildBottomSheet(AsyncValue<List<Footprint>> async, bool isDark) {
    return DraggableScrollableSheet(
      initialChildSize: 0.24,
      minChildSize: 0.12,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF111111)
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: async.when(
            data: (footprints) => ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // 드래그 핸들
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.cs.onSurface.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // 헤더
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.meetorySkyBlue,
                            AppColors.meetoryPink,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('최근 만남', style: AppTextStyles.title),
                    const Spacer(),
                    if (footprints.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.meetorySkyBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${footprints.length}건',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.meetorySkyBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (footprints.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(CupertinoIcons.map_fill,
                            size: 40,
                            color:
                            context.cs.onSurface.withOpacity(0.2)),
                        const SizedBox(height: 12),
                        Text('아직 기록된 만남이 없어요',
                            style: AppTextStyles.caption),
                      ],
                    ),
                  )
                else
                  ...footprints.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _FootprintCard(
                      footprint: f,
                      isDark: isDark,
                      onTap: () => _moveTo(f),
                    ),
                  )),
                const SizedBox(height: 20),
              ],
            ),
            loading: () =>
            const Center(child: CircularProgressIndicator()),
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

// 지도 위 둥근 버튼 공통 위젯
class _MapButton extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _MapButton({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C1C1E).withOpacity(0.92)
            : Colors.white.withOpacity(0.95),
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}

class _FootprintCard extends StatelessWidget {
  final Footprint footprint;
  final bool isDark;
  final VoidCallback onTap;
  const _FootprintCard(
      {required this.footprint, required this.isDark, required this.onTap});

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
          color: isDark
              ? const Color(0xFF1C1C1E)
              : const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // 아이콘 원
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.meetorySkyBlue,
                    AppColors.meetoryPink,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.placemark_fill,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(
                    '$dateStr · ${footprint.attendeeCount}명이 만났어요',
                    style: AppTextStyles.caption.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: context.cs.onSurface.withOpacity(0.3),
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.cs.onSurface.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 헤더
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.meetorySkyBlue.withOpacity(isDark ? 0.15 : 0.1),
                    AppColors.meetoryPink.withOpacity(isDark ? 0.1 : 0.07),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.meetorySkyBlue.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.meetorySkyBlue,
                          AppColors.meetoryPink,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.person_3_fill,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${footprint.attendeeCount}명이 모인 만남',
                            style: AppTextStyles.title),
                        const SizedBox(height: 2),
                        Text(dateStr, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Text('공통 관심사',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.cs.onSurface.withOpacity(0.5),
                )),
            const SizedBox(height: 10),
            if (footprint.interests.isEmpty)
              Text('관심사 정보가 없어요', style: AppTextStyles.caption)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: footprint.interests.map((name) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.meetorySkyBlue.withOpacity(
                          isDark ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.meetorySkyBlue.withOpacity(0.3),
                      ),
                    ),
                    child: Text(name,
                        style: AppTextStyles.body.copyWith(
                          color: isDark
                              ? AppColors.meetorySkyBlue
                              : AppColors.meetoryNavy,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        )),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}