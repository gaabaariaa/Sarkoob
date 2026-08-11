import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../models/history.dart';
import '../models/role.dart';
import '../models/team.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'role_reveal_screen.dart';

class _StartGameScreenState extends State<StartGameScreen> {
  final StorageService _storage = StorageService();
  final List<String> _draftPlayers = [];
  final Map<String, String> _draftRosterLinks = {}; // اسم -> آی‌دیِ لیستِ دائمی
  List<SavedPlayerProfile> _roster = [];
  final TextEditingController _nameController = TextEditingController();
  int _speakSeconds = 60;
  int _doctorMaxSelfSaves = 2;

  bool _includeMossad = false;
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
  bool _includeRebel = false;
  bool _includeNationalHero = false;
  bool _includeInterrogator = false;
  bool _includeIntelMinister = false;
  bool _includePoliceCommander = false;
  bool _includeMercenary = false;
  bool _includeCivicActivist = false;
  bool _includePoliticalAnalyst = false;

  static const int _minPlayers = 9;

  @override
  void initState() {
    super.initState();
    _loadRoster();
  }

  Future<void> _loadRoster() async {
    final roster = await _storage.loadRoster();
    if (mounted) setState(() => _roster = roster);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _setIndependentTeam({required bool mossad}) {
    setState(() {
      _includeMossad = mossad;
    });
  }

  /// اسمی که دستی تایپ شده رو هم به لیستِ بازی و هم (اگه از قبل نبوده)
  /// به لیستِ دائمی اضافه می‌کنه، تا لیستِ دائمی خودش‌به‌خود کامل بشه.
  Future<void> _addPlayer() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _draftPlayers.contains(name)) return;
    setState(() {
      _draftPlayers.add(name);
      _nameController.clear();
    });
    final rosterId = await _storage.ensurePlayerInRoster(name);
    _draftRosterLinks[name] = rosterId;
    _loadRoster();
  }

  Future<void> _showAddFromRosterSheet() async {
    final available = _roster.where((p) => !_draftPlayers.contains(p.name)).toList();
    final selected = <SavedPlayerProfile>{};
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          builder: (context, scrollController) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('افزودن از لیستِ بازیکنان', style: AppTheme.headingFont(size: 18)),
              ),
              if (available.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'همه‌ی بازیکنانِ لیستِ دائمی از قبل تو این بازی هستن.',
                    style: TextStyle(color: Colors.white38),
                  ),
                ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: available
                      .map(
                        (p) => CheckboxListTile(
                          value: selected.contains(p),
                          activeColor: AppColors.gold,
                          title: Text(p.name, style: const TextStyle(color: Colors.white)),
                          onChanged: (v) => setSheetState(() {
                            if (v ?? false) {
                              selected.add(p);
                            } else {
                              selected.remove(p);
                            }
                          }),
                        ),
                      )
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () {
                          setState(() {
                            for (final p in selected) {
                              _draftPlayers.add(p.name);
                              _draftRosterLinks[p.name] = p.id;
                            }
                          });
                          Navigator.of(context).pop();
                        },
                  child: Text('افزودنِ ${selected.length} نفر'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removePlayer(int index) {
    setState(() => _draftPlayers.removeAt(index));
  }

  void _reorderDraftPlayers(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final name = _draftPlayers.removeAt(oldIndex);
      _draftPlayers.insert(newIndex, name);
    });
  }

  // فعلاً تنها تیمِ مستقلِ قابل‌انتخاب موسادِه؛ اگه بعداً یه تیمِ دیگه
  // اضافه شد، اینجا `|| _includeXxx` هم اضافه می‌شه.
  bool get _includeIndependent => _includeMossad;

  int get _sorkoobRoleSlotsEnabled =>
      1 +
      (_includeForeignMinister ? 1 : 0) +
      (_includeJudiciaryChief ? 1 : 0) +
      (_includeCelebrity ? 1 : 0) +
      (_includeInterrogator ? 1 : 0) +
      (_includeIntelMinister ? 1 : 0) +
      (_includePoliceCommander ? 1 : 0) +
      (_includeMercenary ? 1 : 0);

  int get _citizenRoleSlotsEnabled =>
      (_includeDoctor ? 1 : 0) +
      (_includeHacker ? 1 : 0) +
      (_includeRevolutionary ? 1 : 0) +
      (_includeLawyer ? 1 : 0) +
      (_includeZhina ? 1 : 0) +
      (_includeRapper ? 1 : 0) +
      (_includeRebel ? 1 : 0) +
      (_includeNationalHero ? 1 : 0) +
      (_includeCivicActivist ? 1 : 0) +
      (_includePoliticalAnalyst ? 1 : 0);

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
    final independentTeamId = _includeMossad ? SarkoobTeams.mossad.id : null;
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

    // یکی از اعضای تیمِ مستقل (اگه موساد فعال باشه) رهبرِ موساد می‌شه —
    // درست مثلِ ولی‌فقیهِ سرکوب.
    final independentShuffled = independentIndices.toList()..shuffle();
    final mossadLeaderIndex =
        (_includeMossad && independentShuffled.isNotEmpty) ? independentShuffled[0] : null;

    var sorkoobCursor = 1; // اندیسِ ۰ همیشه ولی‌فقیه‌ست
    int? nextSorkoobIndex(bool enabled) {
      if (!enabled || sorkoobCursor >= sorkoobShuffled.length) return null;
      return sorkoobShuffled[sorkoobCursor++];
    }

    final foreignMinisterIndex = nextSorkoobIndex(_includeForeignMinister);
    final judiciaryChiefIndex = nextSorkoobIndex(_includeJudiciaryChief);
    final celebrityIndex = nextSorkoobIndex(_includeCelebrity);
    final interrogatorIndex = nextSorkoobIndex(_includeInterrogator);
    final intelMinisterIndex = nextSorkoobIndex(_includeIntelMinister);
    final policeCommanderIndex = nextSorkoobIndex(_includePoliceCommander);
    final mercenaryIndex = nextSorkoobIndex(_includeMercenary);

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
    final rebelIndex = nextCitizenIndex(_includeRebel);
    final nationalHeroIndex = nextCitizenIndex(_includeNationalHero);
    final civicActivistIndex = nextCitizenIndex(_includeCivicActivist);
    final politicalAnalystIndex = nextCitizenIndex(_includePoliticalAnalyst);

    final slaughterCharges = (total / 6).floor().clamp(1, 999);
    final revolutionaryCharges = (_sorkoobCount - 1).clamp(0, 999);
    final warGunCharges = slaughterCharges; // همون فرمولِ «هر ۶ نفر یکی»، رو کلِ بازیکن‌ها
    final intelQuestionCharges = slaughterCharges; // همون فرمول
    final guaranteeCharges = slaughterCharges; // همون فرمول

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
      } else if (i == interrogatorIndex) {
        roleId = SarkoobRoles.interrogator.id;
      } else if (i == intelMinisterIndex) {
        roleId = SarkoobRoles.intelligenceMinister.id;
      } else if (i == policeCommanderIndex) {
        roleId = SarkoobRoles.policeCommander.id;
      } else if (i == mercenaryIndex) {
        roleId = SarkoobRoles.mercenary.id;
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
      } else if (i == rebelIndex) {
        roleId = SarkoobRoles.rebel.id;
      } else if (i == nationalHeroIndex) {
        roleId = SarkoobRoles.nationalHero.id;
      } else if (i == civicActivistIndex) {
        roleId = SarkoobRoles.civicActivist.id;
      } else if (i == politicalAnalystIndex) {
        roleId = SarkoobRoles.politicalAnalyst.id;
      } else if (i == mossadLeaderIndex) {
        roleId = SarkoobRoles.mossadLeader.id;
      }

      // بازیکنی که هیچ نقشِ خاصی نگرفته: اگه عضوِ سرکوبه، «سرکوبگر»
      // حساب می‌شه؛ اگه عضوِ شهرونده، «شهروندِ خاکستری». عضوِ سادهٔ
      // تیمِ مستقل (غیر از رهبرِ موساد) دست‌نخورده می‌مونه چون هنوز
      // نقشِ اختصاصیِ دومی براش تعریف نشده.
      if (roleId == null) {
        if (teamId == SarkoobTeams.suppression.id) {
          roleId = SarkoobRoles.suppressor.id;
        } else if (teamId == SarkoobTeams.citizen.id) {
          roleId = SarkoobRoles.grayCitizen.id;
        }
      }

      players.add(
        SessionPlayer(
          id: i + 1,
          name: _draftPlayers[i],
          rosterId: _draftRosterLinks[_draftPlayers[i]],
          teamId: teamId,
          roleId: roleId,
          hasArmor: i == valiFaghihIndex,
          slaughterChargesRemaining: i == valiFaghihIndex ? slaughterCharges : null,
          revolutionaryChargesRemaining: i == revolutionaryIndex ? revolutionaryCharges : null,
          warGunsRemaining: i == rebelIndex ? warGunCharges : null,
          intelQuestionsRemaining: i == intelMinisterIndex ? intelQuestionCharges : null,
          guaranteesRemaining: i == nationalHeroIndex ? guaranteeCharges : null,
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
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.groups, color: AppColors.gold),
            label: Text('افزودن از لیستِ بازیکنان (${_roster.length} نفر)'),
            onPressed: _roster.isEmpty ? null : _showAddFromRosterSheet,
          ),
          const SizedBox(height: 12),
          const Text(
            'با نگه‌داشتن و کشیدن، می‌تونی ترتیبِ بازیکن‌ها رو عوض کنی.',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 4),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: _reorderDraftPlayers,
            children: _draftPlayers.asMap().entries.map((entry) {
              final index = entry.key;
              final name = entry.value;
              return Card(
                key: ValueKey('draft-player-$index-$name'),
                color: AppColors.surfaceCard,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: AppColors.gold.withOpacity(0.3)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.drag_handle, color: Colors.white38),
                  title: Text(name, style: const TextStyle(color: Colors.white)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.bloodRedLight),
                    onPressed: () => _removePlayer(index),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),
          Text('تیم مستقل', style: AppTheme.headingFont(size: 20)),
          const SizedBox(height: 4),
          const Text(
            'اختیاریه.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 8),
          RadioListTile<String>(
            value: 'none',
            groupValue: _includeMossad ? 'mossad' : 'none',
            onChanged: (_) => _setIndependentTeam(mossad: false),
            activeColor: AppColors.gold,
            title: const Text('بدون تیم مستقل', style: TextStyle(color: Colors.white)),
          ),
          RadioListTile<String>(
            value: 'mossad',
            groupValue: _includeMossad ? 'mossad' : 'none',
            onChanged: (_) => _setIndependentTeam(mossad: true),
            activeColor: SarkoobTeams.mossad.color,
            title: Text(SarkoobTeams.mossad.name, style: const TextStyle(color: Colors.white)),
          ),
          if (_includeIndependent)
            _countStepper(
              label: 'چند نفر عضوِ ${SarkoobTeams.mossad.name} باشن؟',
              value: _independentCount,
              onDecrement: () => setState(() {
                if (_independentCount > 1) _independentCount--;
              }),
              onIncrement: () => setState(() => _independentCount++),
            ),
          if (_includeMossad) ...[
            const SizedBox(height: 4),
            const Text(
              'یکی از اعضای موساد، تصادفاً، رهبرِ موساد می‌شه:',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 4),
            _mandatoryRoleRow(SarkoobRoles.mossadLeader),
          ],

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
            'این بازی کدوم نقش‌های سرکوب رو داشته باشه؟',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          _mandatoryRoleRow(SarkoobRoles.valiFaghih),
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
          _roleToggle(
            role: SarkoobRoles.interrogator,
            value: _includeInterrogator,
            onChanged: (v) => setState(() => _includeInterrogator = v),
          ),
          _roleToggle(
            role: SarkoobRoles.intelligenceMinister,
            value: _includeIntelMinister,
            onChanged: (v) => setState(() => _includeIntelMinister = v),
          ),
          _roleToggle(
            role: SarkoobRoles.policeCommander,
            value: _includePoliceCommander,
            onChanged: (v) => setState(() => _includePoliceCommander = v),
          ),
          _roleToggle(
            role: SarkoobRoles.mercenary,
            value: _includeMercenary,
            onChanged: (v) => setState(() => _includeMercenary = v),
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
          _roleToggle(
            role: SarkoobRoles.rebel,
            value: _includeRebel,
            onChanged: (v) => setState(() => _includeRebel = v),
          ),
          _roleToggle(
            role: SarkoobRoles.nationalHero,
            value: _includeNationalHero,
            onChanged: (v) => setState(() => _includeNationalHero = v),
          ),
          _roleToggle(
            role: SarkoobRoles.civicActivist,
            value: _includeCivicActivist,
            onChanged: (v) => setState(() => _includeCivicActivist = v),
          ),
          _roleToggle(
            role: SarkoobRoles.politicalAnalyst,
            value: _includePoliticalAnalyst,
            onChanged: (v) => setState(() => _includePoliticalAnalyst = v),
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

  Widget _mandatoryRoleRow(GameRole role) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.check_circle, color: AppColors.gold),
      title: Text(role.name, style: const TextStyle(color: Colors.white)),
      trailing: const Text('همیشه فعال', style: TextStyle(color: Colors.white38, fontSize: 12)),
    );
  }
}

class StartGameScreen extends StatefulWidget {
  const StartGameScreen({super.key});

  @override
  State<StartGameScreen> createState() => _StartGameScreenState();
}
