import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../core/theme/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageId; // 'avatar_1' ~ 'avatar_8', 없으면 기본
  final double radius;
  const ProfileAvatar({super.key, this.imageId, this.radius = 20});

  // 프리셋 단일 소스 (나중에 실제 이미지로 교체 시 여기만 수정)
  static const presets = <({Color color, IconData icon})>[
    (color: Color(0xFFB39DDB), icon: CupertinoIcons.smiley),
    (color: Color(0xFF80CBC4), icon: CupertinoIcons.star_fill),
    (color: Color(0xFFFFCC80), icon: CupertinoIcons.heart_fill),
    (color: Color(0xFF90CAF9), icon: CupertinoIcons.moon_fill),
    (color: Color(0xFFEF9A9A), icon: CupertinoIcons.flame_fill),
    (color: Color(0xFFA5D6A7), icon: CupertinoIcons.leaf_arrow_circlepath),
    (color: Color(0xFFF48FB1), icon: CupertinoIcons.sparkles),
    (color: Color(0xFF9FA8DA), icon: CupertinoIcons.bolt_fill),
  ];

  static int? indexOf(String? id) {
    if (id == null || !id.startsWith('avatar_')) return null;
    final n = int.tryParse(id.substring(7));
    if (n == null || n < 1 || n > presets.length) return null;
    return n - 1;
  }

  @override
  Widget build(BuildContext context) {
    final idx = indexOf(imageId);
    if (idx == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: context.cs.surfaceContainerHighest,
        child: Icon(CupertinoIcons.person_fill,
            size: radius, color: context.cs.onSurfaceVariant),
      );
    }
    final p = presets[idx];
    return CircleAvatar(
      radius: radius,
      backgroundColor: p.color,
      child: Icon(p.icon, color: Colors.white, size: radius),
    );
  }
}