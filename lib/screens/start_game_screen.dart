import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../models/history.dart';
import '../models/role.dart';
import '../models/scenario.dart';
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

  // اولین قدمِ شروعِ بازی: انتخابِ سناریو. تا این انتخاب نشده، هیچ
  // بخشِ تیم/نقشی نشون داده نمی‌شه — چون نقش‌های قابل‌انتخاب کاملاً به
  // سناریو بستگی دارن.
  GameScenario? _selectedScenario;

  // ---- سناریوی «مافیا»: کاملاً موازیِ سرکوب — پدرخوانده اجباری،
  // بقیه‌ی نقش‌ها اختیاری، دو شمارشگر برای اعضای سادهٔ هر تیم. ----
  bool _includeZodiac = false;

  bool _includeNegotiator = false;
  bool _includeEnchanter = false;
  bool _includeSpy = false;
  bool _includeKidnapper = false;
  bool _includeTerrorist = false;

  bool _includeMafiaDoctor = false;
  bool _includeDetective = false;
  bool _includeProfessional = false;
  bool _includeKonstantin = false;
  bool _includeOcean = false;
  bool _includeGunman = false;
  bool _includeLeader = false;
  bool _includeSherlock = false;

  int _mafiaCount = 0; // مافیا ساده
  int _simpleCitizenCount = 0; // شهروندِ ساده

  bool _includeMossad = false;

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

  // به‌جای یه عددِ کلیِ «چند نفر عضوِ این تیم باشن» و کم‌کردنِ نقش‌های
  // فعال ازش، حالا مسیر برعکسه: جلوی نقش‌های بدونِ قابلیتِ خاص هم
  // (سرکوبگرِ ساده، شهروندِ خاکستری) یه شمارشگر هست، و مجموعِ تک‌تکِ
  // نقش‌های هر تیم خودش اندازه‌ی اون تیم رو تعیین می‌کنه.
  int _suppressorCount = 0;
  int _grayCitizenCount = 0;

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

  void _setMafiaIndependentTeam({required bool zodiac}) {
    setState(() {
      _includeZodiac = zodiac;
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

  /// از لیستِ دائمی، یا تک‌تک یا با «انتخابِ همه»، به این جلسه اضافه می‌کنه.
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
                )
              else
                CheckboxListTile(
                  value: selected.isEmpty
                      ? false
                      : (selected.length == available.length ? true : null),
                  tristate: true,
                  activeColor: AppColors.gold,
                  title: const Text(
                    'انتخابِ همه',
                    style: TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
                  ),
                  onChanged: (_) => setSheetState(() {
                    if (selected.length == available.length) {
                      selected.clear();
                    } else {
                      selected
                        ..clear()
                        ..addAll(available);
                    }
                  }),
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

  // مجموعِ نقش‌های هر تیم (نقش‌های ویژه + عضوِ سادهٔ بدونِ قابلیتِ خاص)
  // خودش اندازه‌ی اون تیم رو تعیین می‌کنه — نه برعکس.
  int get _sorkoobTotal => _sorkoobRoleSlotsEnabled + _suppressorCount;
  int get _independentTotal => _includeIndependent ? 1 : 0; // فعلاً فقط رهبرِ موساد
  int get _citizenTotal => _citizenRoleSlotsEnabled + _grayCitizenCount;
  int get _assignedTotal => _sorkoobTotal + _independentTotal + _citizenTotal;

  // ---- جمعِ نقش‌بندی‌شده‌ی سناریوی «مافیا» (کاملاً موازیِ بالا) ----
  int get _mafiaGangRoleSlotsEnabled =>
      1 + // پدرخوانده، همیشه اجباری
      (_includeNegotiator ? 1 : 0) +
      (_includeEnchanter ? 1 : 0) +
      (_includeSpy ? 1 : 0) +
      (_includeKidnapper ? 1 : 0) +
      (_includeTerrorist ? 1 : 0);

  int get _mafiaTownRoleSlotsEnabled =>
      (_includeMafiaDoctor ? 1 : 0) +
      (_includeDetective ? 1 : 0) +
      (_includeProfessional ? 1 : 0) +
      (_includeKonstantin ? 1 : 0) +
      (_includeOcean ? 1 : 0) +
      (_includeGunman ? 1 : 0) +
      (_includeLeader ? 1 : 0) +
      (_includeSherlock ? 1 : 0);

  int get _mafiaGangTotal => _mafiaGangRoleSlotsEnabled + _mafiaCount;
  int get _mafiaTownTotal => _mafiaTownRoleSlotsEnabled + _simpleCitizenCount;
  int get _zodiacTotal => _includeZodiac ? 1 : 0;
  int get _mafiaAssignedTotal => _mafiaGangTotal + _mafiaTownTotal + _zodiacTotal;

  bool get _isSorkoobScenario => _selectedScenario == SarkoobScenarios.sorkoob;
  bool get _isMafiaScenario => _selectedScenario == SarkoobScenarios.mafia;

  String? get _mafiaValidationError {
    final total = _draftPlayers.length;
    if (total < _minPlayers) {
      return 'حداقل $_minPlayers بازیکن لازمه (الان $total نفر)';
    }
    if (_mafiaTownTotal < 1) {
      return 'باید حداقل ۱ نفر تو تیم شهروند باشه — تعدادِ شهروندِ ساده رو زیاد کن';
    }
    final diff = total - _mafiaAssignedTotal;
    if (diff > 0) {
      return 'هنوز $diff نفر نقش نگرفتن — تعدادِ مافیا ساده یا شهروندِ ساده رو زیاد کن';
    }
    if (diff < 0) {
      return 'مجموعِ نقش‌ها ${-diff} نفر بیشتر از بازیکن‌هاست — تعدادِ مافیا ساده یا شهروندِ ساده رو کم کن';
    }
    return null;
  }

  /// راهنمای رایجِ بازیِ مافیا: تعدادِ تیمِ مافیا نباید بیشتر از یک‌سومِ کل باشه.
  bool get _isMafiaCountUnbalanced {
    final total = _draftPlayers.length;
    if (total == 0 || _mafiaGangTotal == 0) return false;
    return _mafiaGangTotal > (total / 3);
  }

  String? get _validationError {
    if (_isMafiaScenario) return _mafiaValidationError;
    final total = _draftPlayers.length;
    if (total < _minPlayers) {
      return 'حداقل $_minPlayers بازیکن لازمه (الان $total نفر)';
    }
    if (_citizenTotal < 1) {
      return 'باید حداقل ۱ نفر تو تیم شهروند باشه — تعدادِ شهروندِ خاکستری رو زیاد کن';
    }
    final diff = total - _assignedTotal;
    if (diff > 0) {
      return 'هنوز $diff نفر نقش نگرفتن — تعدادِ سرکوبگر یا شهروندِ خاکستری رو زیاد کن';
    }
    if (diff < 0) {
      return 'مجموعِ نقش‌ها ${-diff} نفر بیشتر از بازیکن‌هاست — تعدادِ سرکوبگر یا شهروندِ خاکستری رو کم کن';
    }
    return null;
  }

  bool get _isPowerUnbalanced {
    final total = _draftPlayers.length;
    if (total == 0) return false;
    return _citizenTotal < (total * 2 / 3);
  }

  Future<void> _onStartPressed() async {
    final error = _validationError;
    if (error != null) return;

    final unbalanced = _isMafiaScenario ? _isMafiaCountUnbalanced : _isPowerUnbalanced;
    if (unbalanced) {
      final proceed = await _showBalanceWarning(
        _isMafiaScenario
            ? 'تعدادِ مافیا بیشتر از یک‌سومِ کل نفراته؛ تیمِ مافیا قدرتِ '
                'زیادی نسبت به اهالیِ شهر داره. می‌خوای همینطوری ادامه بدی؟'
            : 'تعداد تیم مقاومت (شهروند) کمتر از دو‌سومِ کل نفراته؛ تیم مقاومت '
                'قدرت کمتری نسبت به بقیه‌ی تیم‌ها داره. می‌خوای همینطوری ادامه بدی؟',
      );
      if (proceed != true) return;
    }

    if (_isMafiaScenario) {
      _startMafiaGame();
    } else {
      _startGame();
    }
  }

  Future<bool?> _showBalanceWarning(String message) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('قدرت بازی بالانس نیست', style: TextStyle(color: AppColors.goldLight)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
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
    final sorkoobCount = _sorkoobTotal;
    final independentCount = _independentTotal;

    // تخصیصِ تیم: کاملاً تصادفی. کلِ بازیکن‌ها رو قاطی می‌کنیم، اولین
    // $sorkoobCount نفر سرکوب، بعدی‌ها (اگه تیمِ مستقل فعاله) مستقل، و
    // بقیه خودکار شهروند.
    final allShuffled = List<int>.generate(total, (i) => i)..shuffle();
    final sorkoobIndices = allShuffled.take(sorkoobCount).toSet();
    final independentIndices =
        allShuffled.skip(sorkoobCount).take(independentCount).toSet();

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
    final revolutionaryCharges = (sorkoobCount - 1).clamp(0, 999);
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

  /// نسخه‌ی سناریوی «مافیا»ی شروعِ بازی — کاملاً موازیِ _startGame، فقط
  /// با تیم‌ها/نقش‌های سناریوی مافیا.
  void _startMafiaGame() {
    final total = _draftPlayers.length;
    final independentTeamId = _includeZodiac ? SarkoobTeams.zodiac.id : null;
    final mafiaGangCount = _mafiaGangTotal;
    final independentCount = _zodiacTotal;

    final allShuffled = List<int>.generate(total, (i) => i)..shuffle();
    final mafiaGangIndices = allShuffled.take(mafiaGangCount).toSet();
    final independentIndices = allShuffled.skip(mafiaGangCount).take(independentCount).toSet();

    final mafiaGangShuffled = mafiaGangIndices.toList()..shuffle();
    final godfatherIndex = mafiaGangShuffled.isNotEmpty ? mafiaGangShuffled[0] : null;

    final independentShuffled = independentIndices.toList()..shuffle();
    final zodiacIndex = (_includeZodiac && independentShuffled.isNotEmpty) ? independentShuffled[0] : null;

    var mafiaGangCursor = 1; // اندیسِ ۰ همیشه پدرخوانده‌ست
    int? nextMafiaGangIndex(bool enabled) {
      if (!enabled || mafiaGangCursor >= mafiaGangShuffled.length) return null;
      return mafiaGangShuffled[mafiaGangCursor++];
    }

    final negotiatorIndex = nextMafiaGangIndex(_includeNegotiator);
    final enchanterIndex = nextMafiaGangIndex(_includeEnchanter);
    final spyIndex = nextMafiaGangIndex(_includeSpy);
    final kidnapperIndex = nextMafiaGangIndex(_includeKidnapper);
    final terroristIndex = nextMafiaGangIndex(_includeTerrorist);

    final townShuffled = List<int>.generate(total, (i) => i)
        .where((i) => !mafiaGangIndices.contains(i) && !independentIndices.contains(i))
        .toList()
      ..shuffle();

    var townCursor = 0;
    int? nextTownIndex(bool enabled) {
      if (!enabled || townCursor >= townShuffled.length) return null;
      return townShuffled[townCursor++];
    }

    final mafiaDoctorIndex = nextTownIndex(_includeMafiaDoctor);
    final detectiveIndex = nextTownIndex(_includeDetective);
    final professionalIndex = nextTownIndex(_includeProfessional);
    final konstantinIndex = nextTownIndex(_includeKonstantin);
    final oceanIndex = nextTownIndex(_includeOcean);
    final gunmanIndex = nextTownIndex(_includeGunman);
    final leaderIndex = nextTownIndex(_includeLeader);
    final sherlockIndex = nextTownIndex(_includeSherlock);

    final slaughterCharges = (total / 6).floor().clamp(1, 999);
    final professionalCharges = (mafiaGangCount - 1).clamp(0, 999);
    final warGunCharges = slaughterCharges;

    final players = <SessionPlayer>[];
    for (var i = 0; i < total; i++) {
      final String teamId;
      if (mafiaGangIndices.contains(i)) {
        teamId = SarkoobTeams.mafiaGang.id;
      } else if (independentIndices.contains(i)) {
        teamId = independentTeamId!;
      } else {
        teamId = SarkoobTeams.mafiaTown.id;
      }

      String? roleId;
      if (i == godfatherIndex) {
        roleId = SarkoobRoles.godfather.id;
      } else if (i == negotiatorIndex) {
        roleId = SarkoobRoles.negotiator.id;
      } else if (i == enchanterIndex) {
        roleId = SarkoobRoles.enchanter.id;
      } else if (i == spyIndex) {
        roleId = SarkoobRoles.spy.id;
      } else if (i == kidnapperIndex) {
        roleId = SarkoobRoles.kidnapper.id;
      } else if (i == terroristIndex) {
        roleId = SarkoobRoles.terrorist.id;
      } else if (i == mafiaDoctorIndex) {
        roleId = SarkoobRoles.mafiaDoctor.id;
      } else if (i == detectiveIndex) {
        roleId = SarkoobRoles.detective.id;
      } else if (i == professionalIndex) {
        roleId = SarkoobRoles.professional.id;
      } else if (i == konstantinIndex) {
        roleId = SarkoobRoles.konstantin.id;
      } else if (i == oceanIndex) {
        roleId = SarkoobRoles.ocean.id;
      } else if (i == gunmanIndex) {
        roleId = SarkoobRoles.gunman.id;
      } else if (i == leaderIndex) {
        roleId = SarkoobRoles.leader.id;
      } else if (i == sherlockIndex) {
        roleId = SarkoobRoles.sherlock.id;
      } else if (i == zodiacIndex) {
        roleId = SarkoobRoles.zodiacRole.id;
      }

      if (roleId == null) {
        if (teamId == SarkoobTeams.mafiaGang.id) {
          roleId = SarkoobRoles.simpleMafia.id;
        } else if (teamId == SarkoobTeams.mafiaTown.id) {
          roleId = SarkoobRoles.simpleCitizen.id;
        }
      }

      players.add(
        SessionPlayer(
          id: i + 1,
          name: _draftPlayers[i],
          rosterId: _draftRosterLinks[_draftPlayers[i]],
          teamId: teamId,
          roleId: roleId,
          hasArmor: i == godfatherIndex,
          slaughterChargesRemaining: i == godfatherIndex ? slaughterCharges : null,
          revolutionaryChargesRemaining: i == professionalIndex ? professionalCharges : null,
          warGunsRemaining: i == gunmanIndex ? warGunCharges : null,
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
    if (_selectedScenario == null) {
      return _buildScenarioPicker();
    }

    final introSeconds = (_speakSeconds / 2).round();
    final error = _validationError;
    final total = _draftPlayers.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('شروع بازی — ${_selectedScenario!.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'تغییرِ سناریو',
          onPressed: () => setState(() => _selectedScenario = null),
        ),
      ),
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

          if (_isSorkoobScenario) ...[
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
          if (_includeMossad) ...[
            const SizedBox(height: 4),
            const Text(
              'فعلاً تنها نقشِ این تیم رهبرِ موساده، پس این تیم همیشه دقیقاً ۱ نفره:',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 4),
            _mandatoryRoleRow(SarkoobRoles.mossadLeader),
          ],

          const SizedBox(height: 24),
          Text('تیم سرکوب', style: AppTheme.headingFont(size: 20)),
          const SizedBox(height: 4),
          const Text(
            'جلوی هر نقش، تعدادش رو مشخص کن؛ خودِ برنامه موقعِ شروعِ بازی '
            'کاملاً تصادفی مشخص می‌کنه کدوم بازیکن کدوم نقش رو می‌گیره.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 4),
          _roleCountStepper(
            role: SarkoobRoles.suppressor,
            value: _suppressorCount,
            onDecrement: () => setState(() {
              if (_suppressorCount > 0) _suppressorCount--;
            }),
            onIncrement: () => setState(() => _suppressorCount++),
          ),
          const SizedBox(height: 4),
          Text(
            'مجموعِ تیم سرکوب: $_sorkoobTotal نفر',
            style: const TextStyle(
              color: AppColors.goldLight,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),
          Text('تیم شهروند', style: AppTheme.headingFont(size: 20)),
          const SizedBox(height: 4),
          const Text(
            'همینطور جلوی هر نقشِ شهروندی، تعدادش رو مشخص کن؛ شهروندِ '
            'خاکستری همون عضوِ سادهٔ بدونِ قابلیتِ خاصه.',
            style: TextStyle(color: Colors.white60, fontSize: 12),
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
          const SizedBox(height: 4),
          _roleCountStepper(
            role: SarkoobRoles.grayCitizen,
            value: _grayCitizenCount,
            onDecrement: () => setState(() {
              if (_grayCitizenCount > 0) _grayCitizenCount--;
            }),
            onIncrement: () => setState(() => _grayCitizenCount++),
          ),
          const SizedBox(height: 4),
          Text(
            'مجموعِ تیم شهروند: $_citizenTotal نفر',
            style: const TextStyle(
              color: AppColors.goldLight,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: _assignedTotal == total ? AppColors.gold : AppColors.bloodRedLight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'نقش‌بندی‌شده: $_assignedTotal از $total نفر'
              '${_includeMossad ? ' (شاملِ ۱ نفرِ تیمِ مستقل)' : ''}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _assignedTotal == total ? AppColors.goldLight : AppColors.bloodRedLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ],

          if (_isMafiaScenario) ...[
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
              groupValue: _includeZodiac ? 'zodiac' : 'none',
              onChanged: (_) => _setMafiaIndependentTeam(zodiac: false),
              activeColor: AppColors.gold,
              title: const Text('بدون تیم مستقل', style: TextStyle(color: Colors.white)),
            ),
            RadioListTile<String>(
              value: 'zodiac',
              groupValue: _includeZodiac ? 'zodiac' : 'none',
              onChanged: (_) => _setMafiaIndependentTeam(zodiac: true),
              activeColor: SarkoobTeams.zodiac.color,
              title: Text(SarkoobTeams.zodiac.name, style: const TextStyle(color: Colors.white)),
            ),
            if (_includeZodiac) ...[
              const SizedBox(height: 4),
              const Text(
                'فعلاً تنها نقشِ این تیم زودیاکه، پس این تیم همیشه دقیقاً ۱ نفره:',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 4),
              _mandatoryRoleRow(SarkoobRoles.zodiacRole),
            ],

            const SizedBox(height: 24),
            Text('تیم مافیا', style: AppTheme.headingFont(size: 20)),
            const SizedBox(height: 4),
            const Text(
              'جلوی هر نقش، تعدادش رو مشخص کن؛ خودِ برنامه موقعِ شروعِ بازی '
              'کاملاً تصادفی مشخص می‌کنه کدوم بازیکن کدوم نقش رو می‌گیره.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 8),
            _mandatoryRoleRow(SarkoobRoles.godfather),
            _roleToggle(
              role: SarkoobRoles.negotiator,
              value: _includeNegotiator,
              onChanged: (v) => setState(() => _includeNegotiator = v),
            ),
            _roleToggle(
              role: SarkoobRoles.enchanter,
              value: _includeEnchanter,
              onChanged: (v) => setState(() => _includeEnchanter = v),
            ),
            _roleToggle(
              role: SarkoobRoles.spy,
              value: _includeSpy,
              onChanged: (v) => setState(() => _includeSpy = v),
            ),
            _roleToggle(
              role: SarkoobRoles.kidnapper,
              value: _includeKidnapper,
              onChanged: (v) => setState(() => _includeKidnapper = v),
            ),
            _roleToggle(
              role: SarkoobRoles.terrorist,
              value: _includeTerrorist,
              onChanged: (v) => setState(() => _includeTerrorist = v),
            ),
            const SizedBox(height: 4),
            _roleCountStepper(
              role: SarkoobRoles.simpleMafia,
              value: _mafiaCount,
              onDecrement: () => setState(() {
                if (_mafiaCount > 0) _mafiaCount--;
              }),
              onIncrement: () => setState(() => _mafiaCount++),
            ),
            const SizedBox(height: 4),
            Text(
              'مجموعِ تیم مافیا: $_mafiaGangTotal نفر',
              style: const TextStyle(
                color: AppColors.goldLight,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),
            Text('تیم شهروند', style: AppTheme.headingFont(size: 20)),
            const SizedBox(height: 4),
            const Text(
              'همینطور جلوی هر نقشِ شهروندی، تعدادش رو مشخص کن؛ شهروندِ '
              'ساده همون عضوِ سادهٔ بدونِ قابلیتِ خاصه.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 8),
            _roleToggle(
              role: SarkoobRoles.mafiaDoctor,
              value: _includeMafiaDoctor,
              onChanged: (v) => setState(() => _includeMafiaDoctor = v),
            ),
            _roleToggle(
              role: SarkoobRoles.detective,
              value: _includeDetective,
              onChanged: (v) => setState(() => _includeDetective = v),
            ),
            _roleToggle(
              role: SarkoobRoles.professional,
              value: _includeProfessional,
              onChanged: (v) => setState(() => _includeProfessional = v),
            ),
            _roleToggle(
              role: SarkoobRoles.konstantin,
              value: _includeKonstantin,
              onChanged: (v) => setState(() => _includeKonstantin = v),
            ),
            _roleToggle(
              role: SarkoobRoles.ocean,
              value: _includeOcean,
              onChanged: (v) => setState(() => _includeOcean = v),
            ),
            _roleToggle(
              role: SarkoobRoles.gunman,
              value: _includeGunman,
              onChanged: (v) => setState(() => _includeGunman = v),
            ),
            _roleToggle(
              role: SarkoobRoles.leader,
              value: _includeLeader,
              onChanged: (v) => setState(() => _includeLeader = v),
            ),
            _roleToggle(
              role: SarkoobRoles.sherlock,
              value: _includeSherlock,
              onChanged: (v) => setState(() => _includeSherlock = v),
            ),
            const SizedBox(height: 4),
            _roleCountStepper(
              role: SarkoobRoles.simpleCitizen,
              value: _simpleCitizenCount,
              onDecrement: () => setState(() {
                if (_simpleCitizenCount > 0) _simpleCitizenCount--;
              }),
              onIncrement: () => setState(() => _simpleCitizenCount++),
            ),
            const SizedBox(height: 4),
            Text(
              'مجموعِ تیم شهروند: $_mafiaTownTotal نفر',
              style: const TextStyle(
                color: AppColors.goldLight,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _mafiaAssignedTotal == total ? AppColors.gold : AppColors.bloodRedLight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'نقش‌بندی‌شده: $_mafiaAssignedTotal از $total نفر'
                '${_includeZodiac ? ' (شاملِ ۱ نفرِ تیمِ مستقل)' : ''}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      _mafiaAssignedTotal == total ? AppColors.goldLight : AppColors.bloodRedLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],

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

  Widget _buildScenarioPicker() {
    return Scaffold(
      appBar: AppBar(title: const Text('شروع بازی — انتخابِ سناریو')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'اول سناریوی بازی رو انتخاب کن — تیم‌ها و نقش‌های قابل‌انتخاب '
            'کاملاً به همین انتخاب بستگی دارن.',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ...SarkoobScenarios.all.map(
            (scenario) => Card(
              color: AppColors.surfaceCard,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: scenario.color.withOpacity(0.6), width: 1.5),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _selectedScenario = scenario),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(scenario.emoji, style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 10),
                          Text(
                            scenario.name,
                            style: AppTheme.headingFont(size: 22, color: scenario.color),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        scenario.description,
                        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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

  /// شمارشگرِ عددی جلوی یه نقشِ «بدونِ قابلیتِ خاص» (سرکوبگر، شهروندِ
  /// خاکستری) — برخلافِ نقش‌های ویژه که فقط ۰ یا ۱ تا ازشون معنی داره،
  /// از این‌ها می‌شه هر تعداد تو بازی داشت.
  Widget _roleCountStepper({
    required GameRole role,
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(role.name, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ),
          IconButton(
            icon: const Icon(Icons.remove, color: AppColors.gold),
            onPressed: onDecrement,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.goldLight, fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.gold),
            onPressed: onIncrement,
          ),
        ],
      ),
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
