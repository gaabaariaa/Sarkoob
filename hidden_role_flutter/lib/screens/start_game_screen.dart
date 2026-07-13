import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../theme/app_theme.dart';
import 'game_flow_screen.dart';

class _DraftPlayer {
  String name;
  bool isSorkoob;
  bool isModiri;
  _DraftPlayer(this.name, {this.isSorkoob = false, this.isModiri = false});
}

class StartGameScreen extends StatefulWidget {
  const StartGameScreen({super.key});

  @override
  State<StartGameScreen> createState() => _StartGameScreenState();
}

class _StartGameScreenState extends State<StartGameScreen> {
  final List<_DraftPlayer> _draftPlayers = [];
  final TextEditingController _nameController = TextEditingController();
  int _speakSeconds = 60;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addPlayer() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _draftPlayers.add(_DraftPlayer(name));
      _nameController.clear();
    });
  }

  void _removePlayer(int index) {
    setState(() => _draftPlayers.removeAt(index));
  }

  void _startGame() {
    if (_draftPlayers.length < 3) return;
    final players = <SessionPlayer>[];
    for (var i = 0; i < _draftPlayers.length; i++) {
      final d = _draftPlayers[i];
      players.add(
        SessionPlayer(
          id: i + 1,
          name: d.name,
          isSorkoobTeam: d.isSorkoob,
          isModiri: d.isModiri,
        ),
      );
    }
    final settings = GameSettings(speakSeconds: _speakSeconds);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameFlowScreen(players: players, settings: settings),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final introSeconds = (_speakSeconds / 2).round();
    return Scaffold(
      appBar: AppBar(title: const Text('شروع بازی')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('بازیکن‌ها', style: AppTheme.headingFont(size: 20)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'اسم بازیکن',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addPlayer(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _addPlayer, child: const Text('افزودن')),
            ],
          ),
          const SizedBox(height: 12),
          ..._draftPlayers.asMap().entries.map((entry) {
            final index = entry.key;
            final d = entry.value;
            return Card(
              color: AppColors.surfaceCard,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: AppColors.gold.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(d.name, style: const TextStyle(color: Colors.white)),
                    ),
                    const Text('سرکوب', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    Checkbox(
                      value: d.isSorkoob,
                      onChanged: (v) => setState(() {
                        d.isSorkoob = v ?? false;
                        if (!d.isSorkoob) d.isModiri = false;
                      }),
                    ),
                    const Text('مدیری', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    Checkbox(
                      value: d.isModiri,
                      onChanged: d.isSorkoob
                          ? (v) => setState(() {
                                for (final other in _draftPlayers) {
                                  other.isModiri = false;
                                }
                                d.isModiri = v ?? false;
                              })
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.bloodRedLight),
                      onPressed: () => _removePlayer(index),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          const Text(
            'نکته‌ی موقت: چون هنوز موتور تقسیم نقش واقعی ساخته نشده، فعلاً خودت '
            'دستی مشخص کن چه کسانی عضو تیم سرکوب و کدومشون مدیری‌ان (برای شب معارفه لازمه).',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 24),
          Text('تنظیم زمان صحبت', style: AppTheme.headingFont(size: 20)),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: AppColors.gold),
                onPressed: () => setState(() {
                  if (_speakSeconds > 10) _speakSeconds -= 10;
                }),
              ),
              Text(
                '$_speakSeconds ثانیه',
                style: const TextStyle(color: AppColors.goldLight, fontSize: 18),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.gold),
                onPressed: () => setState(() => _speakSeconds += 10),
              ),
            ],
          ),
          Text(
            'زمان معارفه و زمان چالش خودکار میشه: $introSeconds ثانیه (نصف زمان صحبت)',
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _draftPlayers.length >= 3 ? _startGame : null,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: Text(
              _draftPlayers.length < 3
                  ? 'حداقل ۳ بازیکن لازمه'
                  : 'شروع بازی (روز معارفه)',
            ),
          ),
        ],
      ),
    );
  }
}
