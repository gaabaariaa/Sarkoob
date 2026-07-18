import 'package:flutter/material.dart';
import '../models/role.dart';
import '../models/team.dart';
import '../theme/app_theme.dart';
import 'ornate_frame.dart';

/// کارت نمایش کامل یه نقش — همون حس‌وحالِ کارتی که طراحی شده:
/// نوار عنوانِ تیم بالا، عکس نقش وسط، نوار اسمِ نقش پایینش، توضیح زیرش.
class RoleInfoCard extends StatelessWidget {
  final GameRole role;
  final GameTeam team;

  const RoleInfoCard({super.key, required this.role, required this.team});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OrnateFrame(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              child: Text(
                team.name,
                style: TextStyle(
                  color: team.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (role.imageAsset != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                role.imageAsset!,
                fit: BoxFit.cover,
                height: 260,
                width: double.infinity,
              ),
            )
          else
            Container(
              height: 180,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: team.color.withOpacity(0.5)),
              ),
              child: Icon(Icons.badge, size: 64, color: team.color),
            ),
          const SizedBox(height: 14),
          OrnateFrame(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              child: Text(
                role.name,
                style: AppTheme.headingFont(size: 24),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            role.description,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, height: 1.6),
          ),
        ],
      ),
    );
  }
}
