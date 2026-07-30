import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../models/role.dart';
import '../models/team.dart';
import '../theme/app_theme.dart';
import 'role_reveal_screen.dart';

class _StartGameScreenState extends State<StartGameScreen> {
  final List<String> _draftPlayers = [];
  final TextEditingController _nameController = TextEditingController();
  int _speakSeconds = 60;
  int _doctorMaxSelfSaves = 2;

  bool _includeMossad = false;
  bool _includeMek = false;

  int _sorkoobCount = 1;
  int _independentCount = 1;

  static const int _minPlayers = 9;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _setIndependentTeam({required bool mossad, required bool mek}) {
    setState(() {
      _includeMossad = mossad;
      _includeMek = mek;
    });
  }

  void _addPlayer() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _draftPlayers.add(name);
      _nameController.clear();
    });
  }

  void _removePlayer(int index) {
    setState(() => _draftPlayers.removeAt(index));
  }

  bool get _includeIndependent => _includeMossad || _includeMek;

  int get _independentTotal => _includeIndependent ? _independentCount : 0;

  int get _citizenCount => _draftPlayers.length - _sorkoobCount - _independentTotal;

  String? get _validationError {
    final total = _draftPlayers.length;
    if (total < _minPlayers) {
      return 'حداقل $_minPlayers بازیکن لازمه (الان $total نفر)';
    }
    if (_sorkoobCount < 1) {
      return 'تیم سرکوب باید حداقل ۱ نفر داشته باشه';
    }
    if (_includeIndependent && _independentCount < 1) {
      return 'تیم مستقل انتخاب شده؛ باید حداقل ۱ نفر داشته باشه';
    }
    if (_citizenCount < 1) {
      return 'با این تعداد، کسی برای تیم مقاومت (شهروند) نمی‌مونه؛ '
          'تعداد سرکوب/تیم مستقل رو کم کن';
    }
    return null;
  }

  bool get _isPowerUnbalanced {
    final total = _draftPlayers.length;
    if (total == 0) return false;
    return _citizenCount < (total * 2 / 3);
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
    final total = _draftPlayers.length;
    final order = List<int>.generate(total, (i) => i)..shuffle();

    final independentTeamId =
        _includeMossad ? SarkoobTeams.mossad.id : (_includeMek ? SarkoobTeams.mek.id : null);

    final sorkoobSet = order.take(_sorkoobCount).toSet();
    final independentSet = _includeIndependent
        ? order.skip(_sorkoobCount).take(_independentCount).toSet()
        : <int>{};

    final sorkoobShuffled = sorkoobSet.toList()..shuffle();
    final valiFaghihIndex = sorkoobShuffled.isNotEmpty ? sorkoobShuffled[0] : null;
    final foreignMinisterIndex = sorkoobShuffled.length > 1 ? sorkoobShuffled[1] : null;
    final judiciaryChiefIndex = sorkoobShuffled.length > 2 ? sorkoobShuffled[2] : null;

    final citizenShuffled = order
        .where((i) => !sorkoobSet.contains(i) && !independentSet.contains(i))
        .toList()
      ..shuffle();
    final doctorIndex = citizenShuffled.isNotEmpty ? citizenShuffled[0] : null;

    final slaughterCharges = (total / 6).floor().clamp(1, 999);

    final players = <SessionPlayer>[];
    for (var i = 0; i < total; i++) {
      final String teamId;
      if (sorkoobSet.contains(i)) {
        teamId = SarkoobTeams.suppression.id;
      } else if (independentSet.contains(i)) {
        teamId = independentTeamId!;
      } else {
        teamId = SarkoobTeams.citizen.id;
      }

      final isValiFaghih = i == valiFaghihIndex;
      final isForeignMinister = i == foreignMinisterIndex;
      final isJudiciaryChief = i == judiciaryChiefIndex;
      final isDoctor = i == doctorIndex;

      String? roleId;
      if (isValiFaghih) {
        roleId = SarkoobRoles.valiFaghih.id;
      } else if (isForeignMinister) {
        roleId = SarkoobRoles.foreignMinister.id;
      } else if (isJudiciaryChief) {
        roleId = SarkoobRoles.judiciaryChief.id;
      } else if (isDoctor) {
        roleId = SarkoobRoles.doctor.id;
      }

      players.add(
        SessionPlayer(
          id: i + 1,
          name: _draftPlayers[i],
          teamId: teamId,
          roleId: roleId,
          hasArmor: isValiFaghih,
          slaughterChargesRemaining: isValiFaghih ? slaughterCharges : null,
        ),
      );
    }

    final settings = GameSettings(
      speakSeconds: _speakSeconds,
      doctorMaxSelfSaves: _doctorMaxSelfSaves,
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RoleRevealScreen(players: players, settings: settings),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final introSeconds = (_speakSeconds / 2).round();
    final error = _validationError;
    final total = _draftPlayers.length;

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
            final name = entry.value;
            return Card(
              color: AppColors.surfaceCard,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: AppColors.gold.withOpacity(0.3)),
              ),
              child: ListTile(
                title: Text(name, style: const TextStyle(color: Colors.white)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.bloodRedLight),
                  onPressed: () => _removePlayer(index),
                ),
              ),
            );
          }),

          const SizedBox(height: 24),
          Text('تیم‌های بازی', style: AppTheme.headingFont(size: 20)),
          const SizedBox(height: 4),
          const Text(
            'فقط تعداد نفراتِ هر تیم رو مشخص کن؛ خودِ برنامه تصادفی '
            'می‌کنه کدوم بازیکن عضو کدوم تیمه.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 12),

          _teamCountRow(
            team: SarkoobTeams.suppression,
            count: _sorkoobCount,
            onDecrease: () => setState(() {
              if (_sorkoobCount > 1) _sorkoobCount--;
            }),
            onIncrease: () => setState(() => _sorkoobCount++),
          ),

          const SizedBox(height: 8),
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
          if (_includeIndependent)
            _teamCountRow(
              team: _includeMossad ? SarkoobTeams.mossad : SarkoobTeams.mek,
              count: _independentCount,
              onDecrease: () => setState(() {
                if (_independentCount > 1) _independentCount--;
              }),
              onIncrease: () => setState(() => _independentCount++),
            ),

          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(radius: 10, backgroundColor: SarkoobTeams.citizen.color),
              const SizedBox(width: 10),
              Text(
                '${SarkoobTeams.citizen.name} (خودکار): ${_citizenCount < 0 ? 0 : _citizenCount} نفر',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Text(
            'از مجموع $total بازیکن',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),

          const SizedBox(height: 12),
          const Text(
            'نقش‌ها (ولی‌فقیه، وزیر امور خارجه، رئیس قوه قضاییه، ...) بین '
            'اعضای هر تیم کاملاً تصادفی توسط خودِ برنامه تقسیم می‌شن.',
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
          Text('نجاتِ خودِ دکتر', style: AppTheme.headingFont(size: 20)),
          const SizedBox(height: 4),
          const Text(
            'دکتر در طولِ کلِ بازی حداکثر چندبار می‌تونه خودش رو نجات بده؟',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: AppColors.gold),
                onPressed: () => setState(() {
                  if (_doctorMaxSelfSaves > 0) _doctorMaxSelfSaves--;
                }),
              ),
              Text(
                '$_doctorMaxSelfSaves بار',
                style: const TextStyle(color: AppColors.goldLight, fontSize: 18),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.gold),
                onPressed: () => setState(() => _doctorMaxSelfSaves++),
              ),
            ],
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

  Widget _teamCountRow({
    required GameTeam team,
    required int count,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return Row(
      children: [
        CircleAvatar(radius: 10, backgroundColor: team.color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            team.name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(icon: const Icon(Icons.remove, color: AppColors.gold), onPressed: onDecrease),
        Text('$count', style: const TextStyle(color: AppColors.goldLight, fontSize: 16)),
        IconButton(icon: const Icon(Icons.add, color: AppColors.gold), onPressed: onIncrease),
      ],
    );
  }
}

class StartGameScreen extends StatefulWidget {
  const StartGameScreen({super.key});

  @override
  State<StartGameScreen> createState() => _StartGameScreenState();
}
