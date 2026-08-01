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
  final Set<int> _independentMemberIndices = {};

  // کدوم بازیکن‌ها عضوِ تیمِ سرکوب‌ان (هم رهبر/نقش‌دارها هم سرکوبگرهای
  // ساده). خودِ برنامه موقعِ شروعِ بازی تصادفی تصمیم می‌گیره کدوم‌شون
  // کدوم نقشِ فعال رو می‌گیره.
  final Set<int> _sorkoobMemberIndices = {};

  // کدوم نقش‌های اختیاری تو این بازی فعالن؛ ولی‌فقیه همیشه اجباری و
  // فعاله. تخصیصِ این نقش‌ها به بازیکنِ خاص کاملاً خودکار و تصادفیه —
  // اینجا فقط انتخاب می‌شه که کدوم نقش‌ها اصلاً تو بازی باشن.
  bool _includeForeignMinister = false;
  bool _includeJudiciaryChief = false;
  bool _includeDoctor = false;
  bool _includeHacker = false;
  bool _includeRevolutionary = false;
  bool _includeLawyer = false;

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
      if (!mossad && !mek) _independentMemberIndices.clear();
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

  Set<int> _shiftSet(Set<int> set, int removedIndex) {
    return set.where((i) => i != removedIndex).map((i) => i > removedIndex ? i - 1 : i).toSet();
  }

  void _removePlayer(int index) {
    setState(() {
      _draftPlayers.removeAt(index);
      _independentMemberIndices
        ..clear()
        ..addAll(_shiftSet(_independentMemberIndices, index));
      _sorkoobMemberIndices
        ..clear()
        ..addAll(_shiftSet(_sorkoobMemberIndices, index));
    });
  }

  bool get _includeIndependent => _includeMossad || _includeMek;

  int get _citizenCount {
    final total = _draftPlayers.length;
    final result = total - _sorkoobMemberIndices.length - _independentMemberIndices.length;
    return result < 0 ? 0 : result;
  }

  int get _sorkoobRoleSlotsEnabled =>
      1 + (_includeForeignMinister ? 1 : 0) + (_includeJudiciaryChief ? 1 : 0);

  int get _citizenRoleSlotsEnabled =>
      (_includeDoctor ? 1 : 0) +
      (_includeHacker ? 1 : 0) +
      (_includeRevolutionary ? 1 : 0) +
      (_includeLawyer ? 1 : 0);

  /// یه بازیکن نمی‌تونه هم‌زمان عضوِ سرکوب و عضوِ تیمِ مستقل باشه.
  Set<int> get _assignedTeamIndices => {..._sorkoobMemberIndices, ..._independentMemberIndices};

  String _teamLabelFor(int index) {
    if (_sorkoobMemberIndices.contains(index)) return SarkoobTeams.suppression.name;
    if (_independentMemberIndices.contains(index)) {
      return _includeMossad ? SarkoobTeams.mossad.name : SarkoobTeams.mek.name;
    }
    return SarkoobTeams.citizen.name;
  }

  String? get _validationError {
    final total = _draftPlayers.length;
    if (total < _minPlayers) {
      return 'حداقل $_minPlayers بازیکن لازمه (الان $total نفر)';
    }
    if (_sorkoobMemberIndices.isEmpty) {
      return 'تیم سرکوب باید حداقل ۱ نفر داشته باشه (حداقل خودِ ولی‌فقیه)';
    }
    if (_sorkoobRoleSlotsEnabled > _sorkoobMemberIndices.length) {
      return 'با این تعداد عضوِ سرکوب، همه‌ی نقش‌های فعال‌شده‌ی این تیم جا نمی‌شن';
    }
    if (_citizenRoleSlotsEnabled > _citizenCount) {
      return 'با این تعداد شهروند، همه‌ی نقش‌های فعال‌شده‌ی این تیم جا نمی‌شن';
    }
    if (_includeIndependent && _independentMemberIndices.isEmpty) {
      return 'تیم مستقل انتخاب شده؛ باید حداقل ۱ نفر عضوش باشه';
    }
    if (_citizenCount < 1) {
      return 'با این انتخاب‌ها، کسی برای تیم شهروند نمی‌مونه؛ '
          'تعدادِ اعضای سرکوب/تیمِ مستقل رو کم کن';
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

    final sorkoobShuffled = _sorkoobMemberIndices.toList()..shuffle();
    final valiFaghihIndex = sorkoobShuffled.isNotEmpty ? sorkoobShuffled[0] : null;
    final foreignMinisterIndex =
        (_includeForeignMinister && sorkoobShuffled.length > 1) ? sorkoobShuffled[1] : null;
    final judiciaryChiefIndex =
        (_includeJudiciaryChief && sorkoobShuffled.length > 2) ? sorkoobShuffled[2] : null;

    final citizenShuffled = List<int>.generate(total, (i) => i)
        .where(
          (i) => !_sorkoobMemberIndices.contains(i) && !_independentMemberIndices.contains(i),
        )
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

    final slaughterCharges = (total / 6).floor().clamp(1, 999);
    final revolutionaryCharges = (_sorkoobMemberIndices.length - 1).clamp(0, 999);

    final players = <SessionPlayer>[];
    for (var i = 0; i < total; i++) {
      final String teamId;
      if (_sorkoobMemberIndices.contains(i)) {
        teamId = SarkoobTeams.suppression.id;
      } else if (_independentMemberIndices.contains(i)) {
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
      } else if (i == doctorIndex) {
        roleId = SarkoobRoles.doctor.id;
      } else if (i == hackerIndex) {
        roleId = SarkoobRoles.hacker.id;
      } else if (i == revolutionaryIndex) {
        roleId = SarkoobRoles.revolutionaryFighter.id;
      } else if (i == lawyerIndex) {
        roleId = SarkoobRoles.lawyer.id;
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
                subtitle: Text(
                  _teamLabelFor(index),
                  style: const TextStyle(color: AppColors.goldLight, fontSize: 12),
                ),
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
            _multiSelectChecklist(
              title:
                  'کدوم بازیکن‌ها عضوِ ${_includeMossad ? SarkoobTeams.mossad.name : SarkoobTeams.mek.name}ان؟',
              selected: _independentMemberIndices,
              onToggle: (i, checked) => setState(() {
                if (checked) {
                  _independentMemberIndices.add(i);
                } else {
                  _independentMemberIndices.remove(i);
                }
              }),
            ),

          const SizedBox(height: 24),
          Text('تیم سرکوب', style: AppTheme.headingFont(size: 20)),
          const SizedBox(height: 4),
          const Text(
            'کدوم بازیکن‌ها عضوِ این تیمن (چه نقش‌دار چه سرکوبگرِ ساده)؛ '
            'خودِ برنامه بینِ همین‌ها تصادفی تصمیم می‌گیره کی ولی‌فقیه/وزیر/'
            'رئیس‌قضاییه بشه.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 8),
          _multiSelectChecklist(
            title: 'اعضای تیم سرکوب:',
            selected: _sorkoobMemberIndices,
            onToggle: (i, checked) => setState(() {
              if (checked) {
                _sorkoobMemberIndices.add(i);
              } else {
                _sorkoobMemberIndices.remove(i);
              }
            }),
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

          const SizedBox(height: 24),
          Text('تیم شهروند', style: AppTheme.headingFont(size: 20)),
          const SizedBox(height: 4),
          Text(
            'بقیه‌ی بازیکنانی که بالا انتخاب نکردی، خودکار شهروند حساب '
            'می‌شن: $_citizenCount نفر از مجموع $total. این بازی کدوم '
            'نقش‌های شهروندی رو داشته باشه؟ تخصیصِ اینا هم کاملاً تصادفیه.',
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

  Widget _multiSelectChecklist({
    required String title,
    required Set<int> selected,
    required void Function(int index, bool checked) onToggle,
  }) {
    final assigned = _assignedTeamIndices;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ..._draftPlayers.asMap().entries.map((entry) {
          final i = entry.key;
          final takenElsewhere = assigned.contains(i) && !selected.contains(i);
          return CheckboxListTile(
            dense: true,
            value: selected.contains(i),
            onChanged: takenElsewhere ? null : (v) => onToggle(i, v ?? false),
            activeColor: AppColors.gold,
            title: Text(
              entry.value,
              style: TextStyle(color: takenElsewhere ? Colors.white24 : Colors.white),
            ),
          );
        }),
      ],
    );
  }
}

class StartGameScreen extends StatefulWidget {
  const StartGameScreen({super.key});

  @override
  State<StartGameScreen> createState() => _StartGameScreenState();
}
