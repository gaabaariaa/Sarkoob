import 'package:flutter/material.dart';
import '../models/team.dart';
import '../theme/app_theme.dart';
import '../theme/app_strings.dart';

/// کارت تعاملی نمایش تیم برای پیش‌نمایش نقش.
class TeamRevealCard extends StatefulWidget {
  final GameTeam team;
  final String playerName;

  TeamRevealCard({
    super.key,
    required this.team,
    required this.playerName,
  });

  @override
  State<TeamRevealCard> createState() => _TeamRevealCardState();
}

class _TeamRevealCardState extends State<TeamRevealCard> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _revealed = !_revealed),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        width: 280,
        constraints: BoxConstraints(minHeight: 330),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.uiCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _revealed
                ? widget.team.color.withAlpha(191)
                : AppTheme.uiPrimary.withAlpha(115),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: (_revealed ? widget.team.color : AppTheme.uiPrimary).withAlpha(31),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 220),
          child: _revealed
              ? _buildRevealedContent()
              : _buildHiddenContent(),
        ),
      ),
    );
  }

  Widget _buildHiddenContent() {
    return SizedBox(
      key: ValueKey('hidden'),
      height: 290,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.uiPrimaryDark.withAlpha(46),
                border: Border.all(color: AppTheme.uiPrimary.withAlpha(128)),
              ),
              child: Icon(
                Icons.lock_rounded,
                size: 34,
                color: AppTheme.uiPrimaryLight,
              ),
            ),
            SizedBox(height: 18),
            Text(
              widget.playerName,
              textAlign: TextAlign.center,
              style: AppTheme.headingFont(size: 20, color: AppTheme.uiPrimaryLight),
            ),
            SizedBox(height: 8),
            Text(
              'برای دیدن تیم لمس کن',
              style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12),
            ),
            SizedBox(height: 14),
            Icon(
              Icons.touch_app_rounded,
              size: 18,
              color: AppTheme.uiSubtleText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevealedContent() {
    return SizedBox(
      key: ValueKey('revealed'),
      height: 290,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.team.color.withAlpha(41),
                border: Border.all(color: widget.team.color.withAlpha(153)),
              ),
              child: Icon(
                Icons.shield_rounded,
                size: 36,
                color: widget.team.color,
              ),
            ),
            SizedBox(height: 16),
            Text(
              widget.team.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: widget.team.color,
              ),
            ),
            SizedBox(height: 10),
            Text(
              widget.team.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                height: 1.6,
                fontSize: 13,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'برای مخفی کردن دوباره لمس کن',
              style: TextStyle(color: AppTheme.uiSubtleText, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
