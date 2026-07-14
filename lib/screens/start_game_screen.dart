import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../models/role.dart';
import '../models/team.dart';
import '../theme/app_theme.dart';
import 'game_flow_screen.dart';

class _DraftPlayer {
  String name;
  String teamId;
  bool isModiri;
  String? roleId;
  _DraftPlayer(this.name, {this.teamId = 'team_citizen', this.isModiri = false, this.roleId});
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

  // تیم سرکوب و شهروند همیشه اجباری‌ان؛ فقط یکی از دو تیم مستقل، اختیاریه.
  bool _includeMossad = false;
  bool _includeMek = false;

  static const int _minPlayers = 9;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List<GameTeam> get _activeTeams => [
        SarkoobTeams.suppression,
        SarkoobTeams.citizen,
        if (_includeMossad) SarkoobTeams.mossad,
        if (_includeMek) SarkoobTeams.mek,
      ];

  void _setIndependentTeam({required bool mossad, required bool mek}) {
    setState(() {
      _includeMossad = mossad;
      _includeMek = mek;
      final validIds = _activeTeams.map((t) => t.id).toSet();
      for (final p in _draftPlayers) {
        if (!validIds.contains(p.teamId)) {
          p.teamId = SarkoobTeams.citizen.id;
        }
      }
    });
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

  int _countInTeam(String teamId) =>
      _draftPlayers.where((p) => p.teamId == teamId).length;

  String? get _validationError {
    if (_draftPlayers.length < _minPlayers) {
      return 'حداقل $_minPlayers بازیکن لازمه (الان ${_draftPlayers.length} نفر)';
    }
    if (_countInTeam(SarkoobTeams.suppression.id) == 0) {
      return 'حداقل یک نفر باید عضو تیم سرکوب باشه';
    }
    if (_countInTeam(SarkoobTeams.citizen.id) == 0) {
      return 'حداقل یک نفر باید عضو تیم مقاومت (شهروند) باشه';
    }
    if (_includeMossad && _countInTeam(SarkoobTeams.mossad.id) == 0) {
      return 'تیم موساد رو انتخاب کردی ولی هیچ بازیکنی بهش اختصاص ندادی';
    }
    if (_includeMek && _countInTeam(SarkoobTeams.mek.id) == 0) {
      return 'تیم مجاهدین خلق رو انتخاب کردی ولی هیچ بازیکنی بهش اختصاص ندادی';
    }
    final hasValiFaghih =
        _draftPlayers.any((p) => p.roleId == SarkoobRoles.valiFaghih.id);
    if (!hasValiFaghih) {
      return 'باید یه نفر از تیم سرکوب رو به‌عنوان «ولی‌فقیه» مشخص کنی';
    }
    return null;
  }

  bool get _isPowerUnbalanced {
    final total = _draftPlayers.length;
    if (total == 0) return false;
    final citizenCount = _countInTeam(SarkoobTeams.citizen.id);
    return citizenCount < (total * 2 / 3);
  }

  Future<void> _onStartPressed() async {
    final error = _validationError;
    if (error != null) return;

    if (_isPowerUnbalanced) {
      final proceed = await _showBalanceWarning();
      if (proceed != true) return;
    }

    _startGame();
  }

  Future<bool?> _showBalanceWarning() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('قدرت بازی بالانس نیست', style: TextStyle(color: AppColors.goldLight)),
        content: const Text(
          'تعداد تیم مقاومت (شهروند) کمتر از دو‌سومِ کل نفراته؛ تیم مقاومت '
          'قدرت کمتری نسبت به بقیه‌ی تیم‌ها داره. می‌خوای همینطوری ادامه بدی؟',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('بازگشت و تغییر'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('همینطوری ادامه بده'),
          ),
        ],
      ),
    );
  }

  void _startGame() {
    final players = <SessionPlayer>[];
    final totalPlayers = _draftPlayers.length;
    final slaughterCharges = (totalPlayers / 6).floor().clamp(1, 999);

    for (var i = 0; i < _draftPlayers.length; i++) {
      final d = _draftPlayers[i];
      final isValiFaghih = d.roleId == SarkoobRoles.valiFaghih.id;
      players.add(
        SessionPlayer(
          id: i + 1,
          name: d.name,
          teamId: d.teamId,
          isModiri: d.isModiri,
          roleId: d.roleId,
          hasArmor: isValiFaghih,
          slaughterChargesRemaining: isValiFaghih ? slaughterCharges : null,
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
    final error = _validationError;

    return Scaffold(
      appBar: AppBar(title: const Text('شروع بازی')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('تیم‌های بازی', style: AppTheme.headingFont(size: 20)),
          const SizedBox(height: 4),
          const Text(
            'سرکوب و مقاومت (شهروند) همیشه تو بازی‌ان. حداکثر یکی از دو تیم '
            'مستقل رو هم می‌تونی اضافه کنی.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 10),
          _lockedTeamChip(SarkoobTeams.suppression),
          const SizedBox(height: 6),
          _lockedTeamChip(SarkoobTeams.citizen),
          const SizedBox(height: 10),
          RadioListTile<String>(
            value: 'none',
            groupValue: _includeMossad ? 'mossad' : (_includeMek ? 'mek' : 'none'),
            onChanged: (_) => _setIndependentTeam(mossad: false, mek: false),
            activeColor: AppColors.gold,
            title: const Text('بدون تیم مستقل', style: TextStyle(color: Colors.white)),
          ),
          RadioListTile<String>(
            value: 'mossad',
            groupValue: _includeMossad ? 'mossad' : (_includeMek ? 'mek' : 'none'),
            onChanged: (_) => _setIndependentTeam(mossad: true, mek: false),
            activeColor: SarkoobTeams.mossad.color,
            title: Text(SarkoobTeams.mossad.name, style: const TextStyle(color: Colors.white)),
          ),
          RadioListTile<String>(
            value: 'mek',
            groupValue: _includeMossad ? 'mossad' : (_includeMek ? 'mek' : 'none'),
            onChanged: (_) => _setIndependentTeam(mossad: false, mek: true),
            activeColor: SarkoobTeams.mek.color,
            title: Text(SarkoobTeams.mek.name, style: const TextStyle(color: Colors.white)),
          ),

          const SizedBox(height: 20),
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
            final isSorkoob = d.teamId == SarkoobTeams.suppression.id;
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
                    DropdownButton<String>(
                      value: d.teamId,
                      dropdownColor: AppColors.surfaceDark,
                      underline: const SizedBox.shrink(),
                      items: _activeTeams
                          .map(
                            (t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(t.name, style: TextStyle(color: t.color)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() {
                        d.teamId = value ?? d.teamId;
                        if (!isSorkoob) {
                          d.isModiri = false;
                          d.roleId = null;
                        }
                      }),
                    ),
                    const SizedBox(width: 6),
                    const Text('مدیری', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    Checkbox(
                      value: d.isModiri,
                      onChanged: isSorkoob
                          ? (v) => setState(() {
                                for (final other in _draftPlayers) {
                                  other.isModiri = false;
                                }
                                d.isModiri = v ?? false;
                              })
                          : null,
                    ),
                    const Text('ولی‌فقیه', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    Checkbox(
                      value: d.roleId == SarkoobRoles.valiFaghih.id,
                      onChanged: isSorkoob
                          ? (v) => setState(() {
                                for (final other in _draftPlayers) {
                                  if (other.roleId == SarkoobRoles.valiFaghih.id) {
                                    other.roleId = null;
                                  }
                                }
                                d.roleId = (v ?? false) ? SarkoobRoles.valiFaghih.id : null;
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
            'نکته‌ی موقت: چون بقیه‌ی نقش‌ها هنوز اضافه نشدن، فعلاً فقط ولی‌فقیه '
            'واقعیه (باید مشخص بشه) و «مدیری» صرفاً یه پرچم موقته تا نقش '
            'واقعی‌ش رو هم اضافه کنیم.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),

          const SizedBox(height: 28),
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

          const SizedBox(height: 24),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                error,
                style: const TextStyle(color: AppColors.bloodRedLight),
              ),
            ),
          ElevatedButton(
            onPressed: error == null ? _onStartPressed : null,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: const Text('شروع بازی (روز معارفه)'),
          ),
        ],
      ),
    );
  }

  Widget _lockedTeamChip(GameTeam team) {
    return Row(
      children: [
        CircleAvatar(radius: 10, backgroundColor: team.color),
        const SizedBox(width: 10),
        Text(team.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        const Text('(اجباری)', style: TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }
}
