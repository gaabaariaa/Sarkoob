import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// این صفحه فعلاً فقط «طراحی ظاهری» آماره؛ داده‌هاش نمونه (mock) هستن.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('آمار')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('بهترین و بدترین بازیکنِ آخرین بازی', style: AppTheme.headingFont(size: 20)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _HighlightCard(
                  icon: Icons.emoji_events,
                  color: AppColors.gold,
                  title: 'بهترین بازیکن',
                  playerName: 'علی',
                  reason: 'برد + ۲ اقدام موفق شبانه',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HighlightCard(
                  icon: Icons.sentiment_dissatisfied,
                  color: AppColors.bloodRedLight,
                  title: 'بدترین بازیکن',
                  playerName: 'رضا',
                  reason: 'شب اول حذف شد',
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text('جدول رتبه‌بندی', style: AppTheme.headingFont(size: 20)),
          const SizedBox(height: 10),
          ..._mockLeaderboard.map((row) => _LeaderboardRow(row: row)),
          const SizedBox(height: 28),
          Text('تاریخچه‌ی کامل هر بازیکن', style: AppTheme.headingFont(size: 20)),
          const SizedBox(height: 4),
          const Text(
            'با زدن روی هر بازیکن، لیست همه‌ی بازی‌هاش، نقش هر بازی، '
            'و اقداماتی که انجام داده نشون داده می‌شه.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          ..._mockLeaderboard.map(
            (row) => Card(
              color: AppColors.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.gold.withOpacity(0.3)),
              ),
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                collapsedIconColor: AppColors.gold,
                iconColor: AppColors.gold,
                title: Text(
                  row.name,
                  style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${row.games} بازی — ${row.wins} برد',
                  style: const TextStyle(color: Colors.white60),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'نمونه — بازی ۱: نقش ولی‌فقیه، تیم سرکوب، برنده.\n'
                        'نمونه — بازی ۲: نقش دکتر، تیم شهروند، بازنده.',
                        style: TextStyle(color: Colors.white70, height: 1.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockPlayerRow {
  final String name;
  final int games;
  final int wins;
  const _MockPlayerRow(this.name, this.games, this.wins);
}

const _mockLeaderboard = [
  _MockPlayerRow('علی', 8, 5),
  _MockPlayerRow('سارا', 6, 3),
  _MockPlayerRow('رضا', 7, 2),
];

class _HighlightCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String playerName;
  final String reason;

  const _HighlightCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.playerName,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.7)),
        color: AppColors.surfaceCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            playerName,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            reason,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final _MockPlayerRow row;
  const _LeaderboardRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final rate = row.games == 0 ? 0 : ((row.wins / row.games) * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.gold.withOpacity(0.2),
            child: Text(
              row.name.isNotEmpty ? row.name.substring(0, 1) : '?',
              style: const TextStyle(color: AppColors.goldLight),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(row.name, style: const TextStyle(color: Colors.white)),
          ),
          Text('${row.games} بازی', style: const TextStyle(color: Colors.white60)),
          const SizedBox(width: 12),
          Text('$rate% برد', style: const TextStyle(color: AppColors.goldLight)),
        ],
      ),
    );
  }
}
