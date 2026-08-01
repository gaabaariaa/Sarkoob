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

  // نقش‌های تک‌نفره: roleId -> اندیسِ بازیکنِ انتخاب‌شده (یا null اگه هنوز
  // انتخاب نشده/غیرفعاله). ولی‌فقیه همیشه تویِ این مپه و اجباریه؛ بقیه
  // اختیاری‌ان و فقط وقتی تو _optionalRolesEnabled باشن نشون داده می‌شن.
  final Map<String, int?> _roleAssignment = {
    SarkoobRoles.valiFaghih.id: null,
    SarkoobRoles.foreignMinister.id: null,
    SarkoobRoles.judiciaryChief.id: null,
    SarkoobRoles.doctor.id: null,
    SarkoobRoles.hacker.id: null,
    SarkoobRoles.revolutionaryFighter.id: null,
    SarkoobRoles.lawyer.id: null,
  };
  final Set<String> _optionalRolesEnabled = {};

  // بازیکنانی که نقشِ خاصی ندارن ولی صراحتاً عضوِ تیمِ سرکوب (سرکوبگرِ
  // ساده) مشخص شدن. بقیه‌ی باقی‌مونده‌ها خودکار شهروندِ ساده حساب می‌شن.
  final Set<int> _plainSorkoobIndices = {};

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

  int? _shiftIndex(int? value, int removedIndex) {
    if (value == null) return null;
    if (value == removedIndex) return null;
    return value > removedIndex ? value - 1 : value;
  }

  Set<int> _shiftSet(Set<int> set, int removedIndex) {
    return set.where((i) => i != removedIndex).map((i) => i > removedIndex ? i - 1 : i).toSet();
  }

  void _removePlayer(int index) {
    setState(() {
      _draftPlayers.removeAt(index);
      _roleAssignment.updateAll((_, value) => _shiftIndex(value, index));
      _independentMemberIndices
        ..clear()
        ..addAll(_shiftSet(_independentMemberIndices, index));
      _plainSorkoobIndices
        ..clear()
        ..addAll(_shiftSet(_plainSorkoobIndices, index));
    });
  }

  bool get _includeIndependent => _includeMossad || _includeMek;

  // ---- گروه‌های نقشِ تک‌نفره، برای شمارش و ولیدیشن ----
  List<String> get _sorkoobRoleIdsList => [
        SarkoobRoles.foreignMinister.id,
        SarkoobRoles.judiciaryChief.id,
      ];

  Set<int> get _sorkoobRoleIndices {
    final result = <int>{};
    final vf = _roleAssignment[SarkoobRoles.valiFaghih.id];
    if (vf != null) result.add(vf);
    for (final id in _sorkoobRoleIdsList) {
      final v = _roleAssignment[id];
      if (v != null) result.add(v);
    }
    return result;
  }

  int get _sorkoobTotalCount => _sorkoobRoleIndices.length + _plainSorkoobIndices.length;

  int get _citizenCount {
    final total = _draftPlayers.length;
    final result = total - _sorkoobTotalCount - _independentMemberIndices.length;
    return result < 0 ? 0 : result;
  }

  /// همه‌ی اندیس‌هایی که همین الان یه جایگاهِ مشخص دارن (نقش، سرکوبگرِ
  /// ساده، یا عضوِ تیمِ مستقل) — برای فیلترکردنِ گزینه‌های قابل‌انتخاب.
  Set<int> get _assignedIndices {
    final result = <int>{..._independentMemberIndices, ..._plainSorkoobIndices};
    for (final v in _roleAssignment.values) {
      if (v != null) result.add(v);
    }
    return result;
  }

  List<int> _availableIndicesFor(String roleId) {
    final assigned = _assignedIndices;
    final current = _roleAssignment[roleId];
    return List<int>.generate(_draftPlayers.length, (i) => i)
        .where((i) => !assigned.contains(i) || i == current)
        .toList();
  }

  String? _labelFor(int index) {
    for (final entry in _roleAssignment.entries) {
      if (entry.value == index) {
        return SarkoobRoles.all.firstWhere((r) => r.id == entry.key).name;
      }
    }
    if (_independentMemberIndices.contains(index)) {
      return _includeMossad ? SarkoobTeams.mossad.name : SarkoobTeams.mek.name;
    }
    if (_plainSorkoobIndices.contains(index)) {
      return 'سرکوبگر (بدون نقش خاص)';
    }
    return 'شهروند (ساده)';
  }

  String? get _validationError {
    final total = _draftPlayers.length;
    if (total < _minPlayers) {
      return 'حداقل $_minPlayers بازیکن لازمه (الان $total نفر)';
    }
    if (_roleAssignment[SarkoobRoles.valiFaghih.id] == null) {
      return 'باید دقیقاً یه نفر رو به‌عنوانِ ولی‌فقیه انتخاب کنی';
    }
    for (final roleId in _optionalRolesEnabled) {
      if (_roleAssignment[roleId] == null) {
        final role = SarkoobRoles.all.firstWhere((r) => r.id == roleId);
        return 'نقشِ «${role.name}» فعاله ولی هنوز بازیکنی براش انتخاب نکردی';
      }
    }
    if (_includeIndependent && _independentMemberIndices.isEmpty) {
      return 'تیم مستقل انتخاب شده؛ باید حداقل ۱ نفر عضوش باشه';
    }
    if (_citizenCount < 1) {
      return 'با این انتخاب‌ها، کسی برای تیم شهروند نمی‌مونه؛ '
          'نقش/تیمِ بعضی بازیکن‌ها رو عوض کن';
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

    final valiFaghihIndex = _roleAssignment[SarkoobRoles.valiFaghih.id];
    final revolutionaryIndex = _roleAssignment[SarkoobRoles.revolutionaryFighter.id];

    final slaughterCharges = (total / 6).floor().clamp(1, 999);
    final revolutionaryCharges = (_sorkoobTotalCount - 1).clamp(0, 999);

    final sorkoobIndices = _sorkoobRoleIndices;

    final players = <SessionPlayer>[];
    for (var i = 0; i < total; i++) {
      final String teamId;
      if (sorkoobIndices.contains(i) || _plainSorkoobIndices.contains(i)) {
        teamId = SarkoobTeams.suppression.id;
      } else if (_independentMemberIndices.contains(i)) {
        teamId = independentTeamId!;
      } else {
        teamId = SarkoobTeams.citizen.id;
      }

      String? roleId;
      if (i == valiFaghihIndex) {
        roleId = SarkoobRoles.valiFaghih.id;
      } else if (i == _roleAssignment[SarkoobRoles.foreignMinister.id]) {
        roleId = SarkoobRoles.foreignMinister.id;
      } else if (i == _roleAssignment[SarkoobRoles.judiciaryChief.id]) {
        roleId = SarkoobRoles.judiciaryChief.id;
      } else if (i == _roleAssignment[SarkoobRoles.doctor.id]) {
        roleId = SarkoobRoles.doctor.id;
      } else if (i == _roleAssignment[SarkoobRoles.hacker.id]) {
        roleId = SarkoobRoles.hacker.id;
      } else if (i == revolutionaryIndex) {
        roleId = SarkoobRoles.revolutionaryFighter.id;
      } else if (i == _roleAssignment[SarkoobRoles.lawyer.id]) {
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
                  _labelFor(index) ?? '',
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
          Text('نقش‌های تیم سرکوب', style: AppTheme.headingFont(size: 20)),
          const SizedBox(height: 8),
          _roleRow(SarkoobRoles.valiFaghih, required: true),
          _roleRow(SarkoobRoles.foreignMinister, required: false),
          _roleRow(SarkoobRoles.judiciaryChief, required: false),
          const SizedBox(height: 8),
          _multiSelectChecklist(
            title: 'کدوم بازیکن‌های باقی‌مونده هم عضوِ تیم سرکوب‌ان (بدون نقشِ خاص)؟',
            selected: _plainSorkoobIndices,
            onToggle: (i, checked) => setState(() {
              if (checked) {
                _plainSorkoobIndices.add(i);
              } else {
                _plainSorkoobIndices.remove(i);
              }
            }),
          ),

          const SizedBox(height: 24),
          Text('نقش‌های تیم شهروند', style: AppTheme.headingFont(size: 20)),
          const SizedBox(height: 8),
          _roleRow(SarkoobRoles.doctor, required: false),
          _roleRow(SarkoobRoles.hacker, required: false),
          _roleRow(SarkoobRoles.revolutionaryFighter, required: false),
          _roleRow(SarkoobRoles.lawyer, required: false),
          const SizedBox(height: 8),
          Text(
            'بقیه‌ی بازیکنانِ باقی‌مونده خودکار شهروندِ ساده حساب می‌شن: '
            '$_citizenCount نفر از مجموع $total',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
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

  Widget _roleRow(GameRole role, {required bool required}) {
    final enabled = required || _optionalRolesEnabled.contains(role.id);
    final assignedIndex = _roleAssignment[role.id];
    final options = _availableIndicesFor(role.id);

    return Card(
      color: AppColors.surfaceCard,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.gold.withOpacity(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    required ? '${role.name} (اجباری)' : role.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                if (!required)
                  Switch(
                    value: enabled,
                    activeColor: AppColors.gold,
                    onChanged: (v) => setState(() {
                      if (v) {
                        _optionalRolesEnabled.add(role.id);
                      } else {
                        _optionalRolesEnabled.remove(role.id);
                        _roleAssignment[role.id] = null;
                      }
                    }),
                  ),
              ],
            ),
            if (enabled)
              DropdownButton<int>(
                isExpanded: true,
                dropdownColor: AppColors.surfaceDark,
                hint: const Text('انتخابِ بازیکن', style: TextStyle(color: Colors.white38)),
                value: assignedIndex,
                items: options
                    .map(
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Text(_draftPlayers[i], style: const TextStyle(color: Colors.white)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _roleAssignment[role.id] = v),
              ),
          ],
        ),
      ),
    );
  }

  Widget _multiSelectChecklist({
    required String title,
    required Set<int> selected,
    required void Function(int index, bool checked) onToggle,
  }) {
    final assigned = _assignedIndices;
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
