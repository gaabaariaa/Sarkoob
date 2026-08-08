import 'package:flutter/material.dart';
import '../models/history.dart';
import '../models/role.dart';
import '../models/team.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

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

  String _teamName(String teamId) => SarkoobTeams.byId(teamId)?.name ?? teamId;

  String _formatDate(DateTime dt) =>
      '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تاریخچه بازی‌ها')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(
                  child: Text(
                    'هنوز هیچ بازی‌ای ثبت نشده.\n(از دکمه‌ی «پایانِ بازی» تو صفحه‌ی خودِ بازی، بعدِ تمام‌شدنش ثبتش کن.)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final entry = _history[index];
                    return Card(
                      color: AppColors.surfaceCard,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: AppColors.gold.withOpacity(0.3)),
                      ),
                      child: ExpansionTile(
                        title: Text(
                          _formatDate(entry.playedAt),
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          entry.winningTeamId == 'unknown'
                              ? 'نتیجه: نامشخص'
                              : 'برنده: ${_teamName(entry.winningTeamId)}',
                          style: const TextStyle(color: AppColors.goldLight),
                        ),
                        iconColor: AppColors.gold,
                        collapsedIconColor: AppColors.gold,
                        children: entry.players.map((p) {
                          final role = p.roleId != null ? SarkoobRoles.byId(p.roleId!) : null;
                          return ListTile(
                            dense: true,
                            title: Text(p.name, style: const TextStyle(color: Colors.white)),
                            subtitle: Text(
                              '${_teamName(p.teamId)}${role != null ? ' — ${role.name}' : ''}',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                            trailing: Text(
                              p.wasOnWinningSide ? '🏆 برنده' : (p.survived ? 'زنده ماند' : 'حذف شد'),
                              style: TextStyle(
                                color: p.wasOnWinningSide ? AppColors.goldLight : Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
    );
  }
}
