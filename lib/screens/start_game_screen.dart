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
  int _independentCount = 1;

  // چندتا از کلِ بازیکن‌ها عضوِ تیمِ سرکوبن. خودِ برنامه موقعِ شروعِ بازی
  // به همین تعداد، کاملاً تصادفی، از بینِ همه‌ی بازیکن‌ها انتخاب می‌کنه —
  // نه گرداننده انتخاب می‌کنه کیا، نه کسی پیش‌فرض جایی می‌ره.
  int _sorkoobCount = 1;

  // کدوم نقش‌های اختیاری تو این بازی فعالن؛ ولی‌فقیه همیشه اجباری و
  // فعاله. این‌که کدوم نقش‌ها اصلاً تو بازی باشن دستیه، ولی این‌که کدوم
  // بازیکنِ خاص هرکدوم رو بگیره، کاملاً تصادفیه.
  bool _includeForeignMinister = false;
  bool _includeJudiciaryChief = false;
  bool _includeCelebrity = false;
  bool _includeDoctor = false;
  bool _includeHacker = false;
  bool _includeRevolutionary = false;
  bool _includeLawyer = false;
  bool _includeZhina = false;
  bool _includeRapper = false;

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

  int get _sorkoobRoleSlotsEnabled =>
      1 +
      (_includeForeignMinister ? 1 : 0) +
      (_includeJudiciaryChief ? 1 : 0) +
      (_includeCelebrity ? 1 : 0);

  int get _citizenRoleSlotsEnabled =>
      (_includeDoctor ? 1 : 0) +
      (_includeHacker ? 1 : 0) +
      (_includeRevolutionary ? 1 : 0) +
      (_includeLawyer ? 1 : 0) +
      (_includeZhina ? 1 : 0) +
      (_includeRapper ? 1 : 0);

  int get _citizenCount {
    final total = _draftPlayers.length;
    final independent = _includeIndependent ? _independentCount : 0;
    final result = total - _sorkoobCount - independent;
    return result < 0 ? 0 : result;
  }

  String? get _validationError {
    final total = _draftPlayers.length;
    if (total < _minPlayers) {
      return 'حداقل $_minPlayers بازیکن لازمه (الان $total نفر)';
    }
    if (_sorkoobCount < 1) {
      return 'تیم سرکوب باید حداقل ۱ نفر داشته باشه (خودِ ولی‌فقیه)';
    }
    if (_sorkoobCount < _sorkoobRoleSlotsEnabled) {
      return 'با این تعداد عضوِ سرکوب، همه‌ی نقش‌های فعال‌شده‌ی این تیم جا نمی‌شن';
    }
    if (_includeIndependent && _independentCount < 1) {
      return 'تیم مستقل انتخاب شده؛ باید حداقل ۱ نفر داشته باشه';
    }
    final independent = _includeIndependent ? _independentCount : 0;
    if (_sorkoobCount + independent >= total) {
      return 'با این اعداد، کسی برای تیم شهروند نمی‌مونه؛ تعدادِ سرکوب/مستقل رو کم کن';
    }
    if (_citizenRoleSlotsEnabled > _citizenCount) {
      return 'با این تعداد شهروند، همه‌ی نقش‌های فعال‌شده‌ی این تیم جا نمی‌شن';
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
    final independentTeamId =
        _includeMossad ? SarkoobTeams.mossad.id : (_includeMek ? SarkoobTeams.mek.id : null);
    final independentCount = _includeIndependent ? _independentCount : 0;

    // تخصیصِ تیم: کاملاً تصادفی. کلِ بازیکن‌ها رو قاطی می‌کنیم، اولین
    // $_sorkoobCount نفر سرکوب، بعدی‌ها (اگه تیمِ مستقل فعاله) مستقل، و
    // بقیه خودکار شهروند.
    final allShuffled = List<int>.generate(total, (i) => i)..shuffle();
    final sorkoobIndices = allShuffled.take(_sorkoobCount).toSet();
    final independentIndices =
        allShuffled.skip(_sorkoobCount).take(independentCount).toSet();

    final sorkoobShuffled = sorkoobIndices.toList()..shuffle();
    final valiFaghihIndex = sorkoobShuffled.isNotEmpty ? sorkoobShuffled[0] : null;

    var sorkoobCursor = 1; // اندیسِ ۰ همیشه ولی‌فقیه‌ست
    int? nextSorkoobIndex(bool enabled) {
      if (!enabled || sorkoobCursor >= sorkoobShuffled.length) return null;
      return sorkoobShuffled[sorkoobCursor++];
    }

    final foreignMinisterIndex = nextSorkoobIndex(_includeForeignMinister);
    final judiciaryChiefIndex = nextSorkoobIndex(_includeJudiciaryChief);
    final celebrityIndex = nextSorkoobIndex(_includeCelebrity);

    final citizenShuffled = List<int>.generate(total, (i) => i)
        .where((i) => !sorkoobIndices.contains(i) && !independentIndices.contains(i))
        .toList()
      ..shuffle();

    var citizenCursor = 0;
    int? nextCitizenIndex(bool enabled) {
      if (!enabled || citizenCursor >= citizenShuffled.length) return null;
      return citizenShuffled[citizenCursor++];
    }

    final doctorIndex = nextCitizenIndex(_includeDoctor);
    final hackerIndex = nextCitizenIndex(_includeHacker);
    final revolutionaryIndex = nextCitizenIndex(_includeRevolutionary);
    final lawyerIndex = nextCitizenIndex(_includeLawyer);
    final zhinaIndex = nextCitizenIndex(_includeZhina);
    final rapperIndex = nextCitizenIndex(_includeRapper);

    final slaughterCharges = (total / 6).floor().clamp(1, 999);
    final revolutionaryCharges = (_sorkoobCount - 1).clamp(0, 999);

    final players = <SessionPlayer>[];
    for (var i = 0; i < total; i++) {
      final String teamId;
      if (sorkoobIndices.contains(i)) {
        teamId = SarkoobTeams.suppression.id;
      } else if (independentIndices.contains(i)) {
        teamId = independentTeamId!;
      } else {
        teamId = SarkoobTeams.citizen.id;
      }

      String? roleId;
      if (i == valiFaghihIndex) {
        roleId = SarkoobRoles.valiFaghih.id;
      } else if (i == foreignMinisterIndex) {
        roleId = SarkoobRoles.foreignMinister.id;
      } else if (i == judiciaryChiefIndex) {
        roleId = SarkoobRoles.judiciaryChief.id;
      } else if (i == celebrityIndex) {
        roleId = SarkoobRoles.governmentCelebrity.id;
      } else if (i == doctorIndex) {
        roleId = SarkoobRoles.doctor.id;
      } else if (i == hackerIndex) {
        roleId = SarkoobRoles.hacker.id;
      } else if (i == revolutionaryIndex) {
        roleId = SarkoobRoles.revolutionaryFighter.id;
      } else if (i == lawyerIndex) {
        roleId = SarkoobRoles.lawyer.id;
      } else if (i == zhinaIndex) {
        roleId = SarkoobRoles.zhina.id;
      } else if (i == rapperIndex) {
        roleId = SarkoobRoles.rapper.id;
      }

      players.add(
        SessionPlayer(
          id: i + 1,
          name: _draftPlayers[i],
          teamId: teamId,
          roleId: roleId,
          hasArmor: i == valiFaghihIndex,
          slaughterChargesRemaining: i == valiFaghihIndex ? slaughterCharges : null,
          revolutionaryChargesRemaining: i == revolutionaryIndex ? revolutionaryCharges : null,
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
          Text('تیم مستقل', style: AppTheme.headingFont(size: 20)),
          const SizedBox(height: 4),
          const Text(
            'اختیاریه؛ حداکثر یکی از این دو تیم قابل‌اضافه‌شدنه.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
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
            _countStepper(
              label: 'چند نفر عضوِ ${_includeMossad ? SarkoobTeams.mossad.name : SarkoobTeams.mek.name} باشن؟',
              value: _independentCount,
              onDecrement: () => setState(() {
                if (_independentCount > 1) _independentCount--;
              }),
              onIncrement: () => setState(() => _independentCount++),
            ),

          const SizedBox(height: 24),
          Text('تیم سرکوب', style: AppTheme.headingFont(size: 20)),
          const SizedBox(height: 4),
          const Text(
            'چند نفر عضوِ این تیم باشن؛ خودِ برنامه موقعِ شروعِ بازی کاملاً '
            'تصادفی مشخص می‌کنه کیا، و بینِ همون‌ها هم تصادفی تصمیم می‌گیره '
            'کی ولی‌فقیه/وزیر/رئیس‌قضاییه بشه.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 8),
          _countStepper(
            label: 'تعدادِ اعضای تیم سرکوب',
            value: _sorkoobCount,
            onDecrement: () => setState(() {
              if (_sorkoobCount > 1) _sorkoobCount--;
            }),
            onIncrement: () => setState(() => _sorkoobCount++),
          ),
          const SizedBox(height: 12),
          const Text(
            'این بازی کدوم نقش‌های سرکوب رو داشته باشه؟ (ولی‌فقیه همیشه هست)',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          _roleToggle(
            role: SarkoobRoles.foreignMinister,
            value: _includeForeignMinister,
            onChanged: (v) => setState(() => _includeForeignMinister = v),
          ),
          _roleToggle(
            role: SarkoobRoles.judiciaryChief,
            value: _includeJudiciaryChief,
            onChanged: (v) => setState(() => _includeJudiciaryChief = v),
          ),
          _roleToggle(
            role: SarkoobRoles.governmentCelebrity,
            value: _includeCelebrity,
            onChanged: (v) => setState(() => _includeCelebrity = v),
          ),

          const SizedBox(height: 24),
          Text('تیم شهروند', style: AppTheme.headingFont(size: 20)),
          const SizedBox(height: 4),
          Text(
            'بقیه‌ی بازیکنانی که تو تیم سرکوب/مستقل نیفتادن، خودکار و '
            'تصادفی شهروند حساب می‌شن: تقریباً $_citizenCount نفر از مجموع '
            '$total. این بازی کدوم نقش‌های شهروندی رو داشته باشه؟',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 8),
          _roleToggle(
            role: SarkoobRoles.doctor,
            value: _includeDoctor,
            onChanged: (v) => setState(() => _includeDoctor = v),
          ),
          _roleToggle(
            role: SarkoobRoles.hacker,
            value: _includeHacker,
            onChanged: (v) => setState(() => _includeHacker = v),
          ),
          _roleToggle(
            role: SarkoobRoles.revolutionaryFighter,
            value: _includeRevolutionary,
            onChanged: (v) => setState(() => _includeRevolutionary = v),
          ),
          _roleToggle(
            role: SarkoobRoles.lawyer,
            value: _includeLawyer,
            onChanged: (v) => setState(() => _includeLawyer = v),
          ),
          _roleToggle(
            role: SarkoobRoles.zhina,
            value: _includeZhina,
            onChanged: (v) => setState(() => _includeZhina = v),
          ),
          _roleToggle(
            role: SarkoobRoles.rapper,
            value: _includeRapper,
            onChanged: (v) => setState(() => _includeRapper = v),
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

  Widget _countStepper({
    required String label,
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove, color: AppColors.gold),
              onPressed: onDecrement,
            ),
            Text('$value نفر', style: const TextStyle(color: AppColors.goldLight, fontSize: 18)),
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.gold),
              onPressed: onIncrement,
            ),
          ],
        ),
      ],
    );
  }

  Widget _roleToggle({
    required GameRole role,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: (v) => onChanged(v),
      activeColor: AppColors.gold,
      title: Text(role.name, style: const TextStyle(color: Colors.white)),
      dense: true,
    );
  }
}

class StartGameScreen extends StatefulWidget {
  const StartGameScreen({super.key});

  @override
  State<StartGameScreen> createState() => _StartGameScreenState();
}
