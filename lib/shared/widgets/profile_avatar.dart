import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageId;
  final double radius;
  const ProfileAvatar({super.key, this.imageId, this.radius = 20});

  static const presets = <({Color color, IconData icon})>[
    (color: Color(0xFFF28A91), icon: Icons.sentiment_satisfied_alt_rounded),
    (color: Color(0xFF8CBFD5), icon: Icons.star_rounded),
    (color: Color(0xFFFFB7B2), icon: Icons.favorite_rounded),
    (color: Color(0xFFB2E2F2), icon: Icons.nightlight_round),
    (color: Color(0xFFFFD1DC), icon: Icons.local_fire_department_rounded),
    (color: Color(0xFFD4F1F4), icon: Icons.eco_rounded),
    (color: Color(0xFFF9C5D1), icon: Icons.auto_awesome_rounded),
    (color: Color(0xFFC5E1A5), icon: Icons.bolt_rounded),
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
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person_rounded,
          size: radius * 1.2,
          color: AppColors.textHint,
        ),
      );
    }
    final p = presets[idx];
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: p.color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: p.color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Icon(
        p.icon,
        color: Colors.white,
        size: radius * 1.1,
      ),
    );
  }
}
