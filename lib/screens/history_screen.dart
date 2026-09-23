import 'package:flutter/material.dart';
import '../models/history.dart';
import '../models/role.dart';
import '../models/team.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_strings.dart';
import '../utils/jalali_date.dart';

class HistoryScreen extends StatefulWidget {
  HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final StorageService _storage = StorageService();
  List<GameHistoryEntry> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = await _storage.loadHistory();
    setState(() {
      _history = history;
      _loading = false;
    });
  }

  String _teamName(String teamId) => GameTeams.byId(teamId)?.name ?? teamId;

  String _formatDate(DateTime dt) =>
      '${formatJalali(dt)} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تاریخچه بازی‌ها'.tr.tr.tr),
        actions: [
          Padding(
            padding: EdgeInsetsDirectional.only(end: 14),
            child: Center(
              child: Text(
                '${_history.length} بازی',
                style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 28),
                  itemCount: _history.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildHero();
                    }
                    final entry = _history[index - 1];
                    return _buildHistoryCard(entry);
                  },
                ),
    );
  }

  Widget _buildHero() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.uiCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.uiPrimary.withAlpha(61)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(61),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppTheme.uiPrimaryDark.withAlpha(56),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.uiPrimary.withAlpha(71)),
            ),
            child: Icon(Icons.history_rounded, color: AppTheme.uiPrimaryLight, size: 29),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('مرکز تاریخچه'.tr, style: AppTheme.headingFont(size: 21)),
                SizedBox(height: 5),
                Text(
                  'نتایج بازی‌ها و عملکرد بازیکنان را مرور کن.'.tr,
                  style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(GameHistoryEntry entry) {
    final isUnknown = entry.winningTeamId == 'unknown';
    final winner = isUnknown ? 'نتیجه نامشخص' : _teamName(entry.winningTeamId);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.uiCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.uiPrimary.withAlpha(51)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: AppTheme.uiPrimary.withAlpha(15),
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.fromLTRB(18, 8, 12, 8),
          childrenPadding: EdgeInsets.fromLTRB(10, 0, 10, 10),
          title: Text(
            _formatDate(entry.playedAt),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Icon(
                  isUnknown ? Icons.help_outline_rounded : Icons.emoji_events_rounded,
                  color: isUnknown ? AppTheme.uiMutedText : AppTheme.uiPrimaryLight,
                  size: 16,
                ),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    winner,
                    style: TextStyle(color: AppTheme.uiPrimaryLight, fontSize: 12),
                  ),
                ),
                if (entry.location.trim().isNotEmpty) ...[
                  SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      entry.location.trim(),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppTheme.uiMutedText, fontSize: 11),
                    ),
                  ),
                ],
              ],
            ),
          ),
          iconColor: AppTheme.uiPrimary,
          collapsedIconColor: AppTheme.uiPrimary,
          children: entry.players.map((p) {
            final role = p.roleId != null ? GameRoles.byId(p.roleId!) : null;
            final status = p.wasOnWinningSide
                ? 'برنده'
                : (p.survived ? 'زنده ماند' : 'حذف شد');
            final statusColor = p.wasOnWinningSide ? AppTheme.uiPrimaryLight : AppTheme.uiMutedText;

            return Container(
              margin: EdgeInsets.only(bottom: 7),
              decoration: BoxDecoration(
                color: AppTheme.uiSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.uiPrimaryDark.withAlpha(46),
                  child: Text(
                    p.name.isEmpty ? '?' : p.name.characters.first,
                    style: TextStyle(color: AppTheme.uiPrimaryLight, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  p.name,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${_teamName(p.teamId)}${role != null ? ' — ${role.localizedName}' : ''}',
                  style: TextStyle(color: AppTheme.uiMutedText, fontSize: 11),
                ),
                trailing: Container(
                  padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(28),
        child: Container(
          constraints: BoxConstraints(maxWidth: 440),
          padding: EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: AppTheme.uiCard,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppTheme.uiPrimary.withAlpha(56)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: AppTheme.uiPrimaryDark.withAlpha(46),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.history_toggle_off_rounded, color: AppTheme.uiPrimaryLight, size: 36),
              ),
              SizedBox(height: 18),
              Text('هنوز بازی‌ای ثبت نشده'.tr, style: AppTheme.headingFont(size: 22)),
              SizedBox(height: 8),
              Text(
                'بعد از پایان یک بازی، نتیجه را ثبت کن تا اینجا برای مرور و آمار نگه‌داری شود.'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
