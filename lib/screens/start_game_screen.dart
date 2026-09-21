import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../models/history.dart';
import '../models/role.dart';
import '../models/scenario.dart';
import '../models/team.dart';
import '../services/storage_service.dart';
import '../services/scenario_role_assigner.dart';
import '../theme/app_theme.dart';
import '../widgets/game_3d_button.dart';
import 'role_reveal_screen.dart';

class _StartGameScreenState extends State<StartGameScreen> {
  final StorageService _storage = StorageService();
  final List<String> _draftPlayers = [];
  final Map<String, String> _draftRosterLinks = {}; // اسم -> آی‌دیِ لیستِ دائمی
  List<SavedPlayerProfile> _roster = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  int _speakSeconds = 60;
  int _doctorMaxSelfSaves = 2;

  // اولین قدمِ شروعِ بازی: انتخابِ سناریو. تا این انتخاب نشده، هیچ
  // بخشِ تیم/نقشی نشون داده نمی‌شه — چون نقش‌های قابل‌انتخاب کاملاً به
  // سناریو بستگی دارن.
  GameScenario? _selectedScenario;

  // ---- سناریوی «مافیا»: کاملاً موازیِ سرکوب — پدرخوانده اجباری،
  // بقیه‌ی نقش‌ها اختیاری، دو شمارشگر برای اعضای سادهٔ هر تیم. ----
  final Map<String, bool> _independentTeamEnabled = <String, bool>{};

  bool _includeGodfather = false;
  bool _includeNegotiator = false;
  bool _includeEnchanter = false;
  bool _includeSpy = false;
  bool _includeKidnapper = false;
  bool _includeTerrorist = false;
  bool _includeBomber = false;

  bool _includeMafiaDoctor = false;
  bool _includeDetective = false;
  bool _includeProfessional = false;
  bool _includeKonstantin = false;
  bool _includeOcean = false;
  bool _includeGunman = false;
  bool _includeLeader = false;
  bool _includeSherlock = false;
  bool _includeGuard = false;
  bool _includeMistress = false;
  bool _includeNatasha = false;
  bool _includeSaboteur = false;
  bool _includeDiscloser = false;
  bool _includeWhiteBeard = false;

  int _mafiaCount = 0; // مافیا ساده
  int _simpleCitizenCount = 0; // شهروندِ ساده


  // کدوم نقش‌های اختیاری تو این بازی فعالن. این‌که کدوم نقش‌ها اصلاً تو
  // بازی باشن دستیه، ولی این‌که کدوم بازیکنِ خاص هرکدوم رو بگیره، کاملاً
  // تصادفیه.
  bool _includeValiFaghih = false;
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
    _selectedScenario = widget.initialScenario;
    _loadRoster();
  }

  Future<void> _loadRoster() async {
    final roster = await _storage.loadRoster();
    if (mounted) setState(() => _roster = roster);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  bool _isIndependentTeamEnabled(GameScenario scenario) =>
      _independentTeamEnabled[scenario.id] ?? false;

  void _setIndependentTeamEnabled(GameScenario scenario, bool enabled) {
    setState(() {
      _independentTeamEnabled[scenario.id] = enabled;
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
  bool get _includeIndependent {
    final scenario = _selectedScenario;
    return scenario != null && _isIndependentTeamEnabled(scenario);
  }

  int get _standardLeaderRoleSlotsEnabled =>
      (_includeValiFaghih ? 1 : 0) +
      (_includeForeignMinister ? 1 : 0) +
      (_includeJudiciaryChief ? 1 : 0) +
      (_includeCelebrity ? 1 : 0) +
      (_includeInterrogator ? 1 : 0) +
      (_includeIntelMinister ? 1 : 0) +
      (_includePoliceCommander ? 1 : 0) +
      (_includeMercenary ? 1 : 0);

  int get _standardTownRoleSlotsEnabled =>
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
  int get _standardLeaderTotal => _standardLeaderRoleSlotsEnabled + _suppressorCount;
  int get _independentTotal => _includeIndependent ? 1 : 0; // فعلاً فقط رهبرِ موساد
  int get _standardTownTotal => _standardTownRoleSlotsEnabled + _grayCitizenCount;
  int get _standardAssignedTotal => _standardLeaderTotal + _independentTotal + _standardTownTotal;

  // ---- جمعِ نقش‌بندی‌شده‌ی سناریوی «مافیا» (کاملاً موازیِ بالا) ----
  int get _mafiaGangRoleSlotsEnabled =>
      (_includeGodfather ? 1 : 0) +
      (_includeNegotiator ? 1 : 0) +
      (_includeEnchanter ? 1 : 0) +
      (_includeSpy ? 1 : 0) +
      (_includeKidnapper ? 1 : 0) +
      (_includeTerrorist ? 1 : 0) +
      (_includeBomber ? 1 : 0) +
      (_includeMistress ? 1 : 0) +
      (_includeNatasha ? 1 : 0) +
      (_includeSaboteur ? 1 : 0);

  int get _mafiaTownRoleSlotsEnabled =>
      (_includeMafiaDoctor ? 1 : 0) +
      (_includeDetective ? 1 : 0) +
      (_includeProfessional ? 1 : 0) +
      (_includeKonstantin ? 1 : 0) +
      (_includeOcean ? 1 : 0) +
      (_includeGunman ? 1 : 0) +
      (_includeLeader ? 1 : 0) +
      (_includeSherlock ? 1 : 0) +
      (_includeGuard ? 1 : 0) +
      (_includeDiscloser ? 1 : 0) +
      (_includeWhiteBeard ? 1 : 0);

  int get _mafiaGangTotal => _mafiaGangRoleSlotsEnabled + _mafiaCount;
  int get _mafiaTownTotal => _mafiaTownRoleSlotsEnabled + _simpleCitizenCount;
  int get _zodiacTotal => _selectedScenario == null
      ? 0
      : (_isIndependentTeamEnabled(_selectedScenario!) ? 1 : 0);
  int get _mafiaAssignedTotal => _mafiaGangTotal + _mafiaTownTotal + _zodiacTotal;


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

  String? get _standardValidationError {
    final total = _draftPlayers.length;
    if (total < _minPlayers) {
      return 'حداقل $_minPlayers بازیکن لازمه (الان $total نفر)';
    }
    if (_standardTownTotal < 1) {
      return 'باید حداقل ۱ نفر تو تیم شهروند باشه — تعدادِ شهروندِ خاکستری رو زیاد کن';
    }
    final diff = total - _standardAssignedTotal;
    if (diff > 0) {
      return 'هنوز $diff نفر نقش نگرفتن — تعدادِ سرکوبگر یا شهروندِ خاکستری رو زیاد کن';
    }
    if (diff < 0) {
      return 'مجموعِ نقش‌ها ${-diff} نفر بیشتر از بازیکن‌هاست — تعدادِ سرکوبگر یا شهروندِ خاکستری رو کم کن';
    }
    return null;
  }

  bool get _isPowerUnbalanced {
    final scenario = _selectedScenario;
    if (scenario == null || scenario.setupTemplate != GameScenarioSetupTemplate.standard) {
      return false;
    }
    final total = _draftPlayers.length;
    if (total == 0) return false;
    return _standardTownTotal < (total * 2 / 3);
  }

  String? get _validationError {
    final scenario = _selectedScenario;
    if (scenario == null) return 'سناریوی بازی انتخاب نشده';

    switch (scenario.setupTemplate) {
      case GameScenarioSetupTemplate.mafiaClassic:
        return _mafiaValidationError;
      case GameScenarioSetupTemplate.standard:
        return _standardValidationError;
    }
  }

  Future<void> _onStartPressed() async {
    final error = _validationError;
    if (error != null) return;

    final scenario = _selectedScenario;
    if (scenario == null) return;

    final unbalanced = scenario.setupTemplate == GameScenarioSetupTemplate.mafiaClassic
        ? _isMafiaCountUnbalanced
        : _isPowerUnbalanced;
    if (unbalanced) {
      final proceed = await _showBalanceWarning(
        scenario.setupTemplate == GameScenarioSetupTemplate.mafiaClassic
            ? 'تعدادِ مافیا بیشتر از یک‌سومِ کل نفراته؛ تیمِ مافیا قدرتِ '
                'زیادی نسبت به اهالیِ شهر داره. می‌خوای همینطوری ادامه بدی؟'
            : 'تعداد تیم مقاومت (شهروند) کمتر از دو‌سومِ کل نفراته؛ تیم مقاومت '
                'قدرت کمتری نسبت به بقیه‌ی تیم‌ها داره. می‌خوای همینطوری ادامه بدی؟',
      );
      if (proceed != true) return;
    }

    switch (scenario.setupTemplate) {
      case GameScenarioSetupTemplate.mafiaClassic:
        _startMafiaGame();
        break;
      case GameScenarioSetupTemplate.standard:
        _startGame();
        break;
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
    final scenario = _selectedScenario;
    if (scenario == null) return;

    _startScenarioWithRoles(
      scenario: scenario,
      leaderCount: _standardLeaderTotal,
      independentCount: _independentTotal,
      leaderRoleIds: [
        if (_includeValiFaghih) scenario.roleIdFor('leaderRole'),
        if (_includeForeignMinister) scenario.roleIdFor('negotiator'),
        if (_includeJudiciaryChief) scenario.roleIdFor('judiciary'),
        if (_includeCelebrity) scenario.roleIdFor('celebrity'),
        if (_includeInterrogator) scenario.roleIdFor('interrogator'),
        if (_includeIntelMinister) scenario.roleIdFor('intelligenceMinister'),
        if (_includePoliceCommander) scenario.roleIdFor('policeCommander'),
        if (_includeMercenary) scenario.roleIdFor('mercenary'),
      ],
      townRoleIds: [
        if (_includeDoctor) scenario.roleIdFor('doctor'),
        if (_includeHacker) scenario.roleIdFor('hacker'),
        if (_includeRevolutionary) scenario.roleIdFor('revolutionary'),
        if (_includeLawyer) scenario.roleIdFor('lawyer'),
        if (_includeZhina) scenario.roleIdFor('zhina'),
        if (_includeRapper) scenario.roleIdFor('rapper'),
        if (_includeRebel) scenario.roleIdFor('rebel'),
        if (_includeNationalHero) scenario.roleIdFor('nationalHero'),
        if (_includeCivicActivist) scenario.roleIdFor('civicActivist'),
        if (_includePoliticalAnalyst) scenario.roleIdFor('politicalAnalyst'),
      ],
      independentEnabled: _isIndependentTeamEnabled(scenario),
      slaughterRoleId: scenario.leaderRoleId,
      revolutionaryRoleId: scenario.roleIdFor('revolutionary'),
      warGunRoleId: scenario.roleIdFor('rebel'),
      intelRoleId: scenario.roleIdFor('intelligenceMinister'),
      guaranteeRoleId: scenario.roleIdFor('nationalHero'),
      armorRoleIds: {scenario.leaderRoleId},
    );
  }

  void _startMafiaGame() {
    final scenario = _selectedScenario;
    if (scenario == null) return;

    _startScenarioWithRoles(
      scenario: scenario,
      leaderCount: _mafiaGangTotal,
      independentCount: _zodiacTotal,
      leaderRoleIds: [
        if (_includeGodfather) scenario.roleIdFor('leaderRole'),
        if (_includeNegotiator) scenario.negotiatorRoleId,
        if (_includeEnchanter) scenario.roleIdFor('judiciary'),
        if (_includeSpy) scenario.roleIdFor('spy'),
        if (_includeKidnapper) scenario.roleIdFor('policeCommander'),
        if (_includeTerrorist) scenario.roleIdFor('terrorist'),
        if (_includeBomber) scenario.roleIdFor('bomber'),
        if (_includeMistress) scenario.roleIdFor('mistress'),
        if (_includeNatasha) scenario.roleIdFor('natasha'),
        if (_includeSaboteur) scenario.roleIdFor('saboteur'),
      ],
      townRoleIds: [
        if (_includeMafiaDoctor) scenario.roleIdFor('doctor'),
        if (_includeDetective) scenario.roleIdFor('hacker'),
        if (_includeProfessional) scenario.roleIdFor('revolutionary'),
        if (_includeKonstantin) scenario.roleIdFor('lawyer'),
        if (_includeOcean) scenario.roleIdFor('rapper'),
        if (_includeGunman) scenario.roleIdFor('warGun'),
        if (_includeLeader) scenario.roleIdFor('civicActivist'),
        if (_includeSherlock) scenario.roleIdFor('politicalAnalyst'),
        if (_includeGuard) scenario.roleIdFor('guard'),
        if (_includeDiscloser) scenario.roleIdFor('discloser'),
        if (_includeWhiteBeard) scenario.roleIdFor('guarantee'),
      ],
      independentEnabled: _isIndependentTeamEnabled(scenario),
      slaughterRoleId: scenario.leaderRoleId,
      revolutionaryRoleId: scenario.roleIdFor('revolutionary'),
      warGunRoleId: scenario.roleIdFor('warGun'),
      guaranteeRoleId: scenario.roleIdFor('guarantee'),
      armorRoleIds: {
        scenario.leaderRoleId,
        scenario.roleIdFor('revolutionary'),
      },
    );
  }

  void _startScenarioWithRoles({
    required GameScenario scenario,
    required int leaderCount,
    required int independentCount,
    required List<String> leaderRoleIds,
    required List<String> townRoleIds,
    required bool independentEnabled,
    required String slaughterRoleId,
    String? revolutionaryRoleId,
    String? warGunRoleId,
    String? intelRoleId,
    String? guaranteeRoleId,
    required Set<String> armorRoleIds,
  }) {
    final players = ScenarioRoleAssigner.assign(
      scenario: scenario,
      playerNames: _draftPlayers,
      rosterIds: _draftPlayers.map((name) => _draftRosterLinks[name]).toList(),
      leaderCount: leaderCount,
      independentCount: independentCount,
      leaderRoleIds: leaderRoleIds,
      townRoleIds: townRoleIds,
      independentEnabled: independentEnabled,
    );

    final total = players.length;
    final slaughterCharges = (total / 6).floor().clamp(1, 999);
    final revolutionaryCharges = (leaderCount - 1).clamp(0, 999);
    final warGunCharges = slaughterCharges;
    final intelQuestionCharges = slaughterCharges;
    final guaranteeCharges = slaughterCharges;

    for (final player in players) {
      final roleId = player.roleId;
      player.hasArmor = roleId != null && armorRoleIds.contains(roleId);
      player.slaughterChargesRemaining =
          roleId == slaughterRoleId ? slaughterCharges : null;
      player.revolutionaryChargesRemaining =
          roleId == revolutionaryRoleId ? revolutionaryCharges : null;
      player.warGunsRemaining =
          roleId == warGunRoleId ? warGunCharges : null;
      player.intelQuestionsRemaining =
          roleId == intelRoleId ? intelQuestionCharges : null;
      player.guaranteesRemaining =
          roleId == guaranteeRoleId ? guaranteeCharges : null;
    }

    final settings = GameSettings(
      scenarioId: scenario.id,
      speakSeconds: _speakSeconds,
      doctorMaxSelfSaves: _doctorMaxSelfSaves,
      location: _locationController.text.trim(),
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

    final scenario = _selectedScenario!;
    final introSeconds = (_speakSeconds / 2).round();
    final error = _validationError;
    final total = _draftPlayers.length;
    final assigned = _standardAssignedTotalFor(scenario);
    final leaderTeam = scenarioTeam(scenario, scenario.leaderTeamId);
    final townTeam = scenarioTeam(scenario, scenario.townTeamId);
    final teams = <(GameTeam, int, VoidCallback)>[
      if (leaderTeam.id.isNotEmpty)
        (
          leaderTeam,
          _teamMemberCountFor(scenario, leaderTeam.id),
          _teamSetupPageFor(scenario, leaderTeam.id) ?? (() {}),
        ),
      if (townTeam.id.isNotEmpty)
        (
          townTeam,
          _teamMemberCountFor(scenario, townTeam.id),
          _teamSetupPageFor(scenario, townTeam.id) ?? (() {}),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('شروع بازی — ${_selectedScenario!.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'تغییر سناریو',
          onPressed: () => setState(() => _selectedScenario = null),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 800;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 16, wide ? 28 : 16, 28),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _selectedScenario!.color.withAlpha(64)),
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(56), blurRadius: 24, offset: const Offset(0, 10))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: _selectedScenario!.color.withAlpha(36),
                              borderRadius: BorderRadius.circular(17),
                            ),
                            alignment: Alignment.center,
                            child: Text(_selectedScenario!.emoji, style: const TextStyle(fontSize: 29)),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selectedScenario!.name, style: AppTheme.headingFont(size: 22)),
                                const SizedBox(height: 3),
                                Text(
                                  _selectedScenario!.description,
                                  style: const TextStyle(color: AppColors.mutedText, fontSize: 12, height: 1.45),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('$total نفر', style: AppTheme.headingFont(size: 17, color: AppColors.goldLight)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSetupSection(
                      icon: Icons.groups_rounded,
                      title: 'بازیکن‌ها',
                      subtitle: total == 0 ? 'بازیکن‌ها را اضافه کن' : '$total بازیکن آماده است',
                      child: Game3DButton(
                        label: 'مدیریت بازیکن‌ها',
                        icon: Icons.manage_accounts_rounded,
                        onPressed: _showPlayersPage,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildSetupSection(
                      icon: Icons.hub_rounded,
                      title: 'تیم‌ها و نقش‌ها',
                      subtitle: '$assigned از $total نفر نقش‌بندی شده',
                      child: Column(
                        children: [
                          ...teams.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _teamNavButton(
                                label: entry.$1.name,
                                color: entry.$1.color,
                                count: entry.$2,
                                onTap: entry.$3,
                              ),
                            ),
                          ),
                          _teamNavButton(
                            label: 'تیمِ مستقل',
                            color: _isIndependentTeamEnabled(scenario)
                                ? scenarioTeam(scenario, scenario.independentTeamId).color
                                : AppColors.subtleText,
                            count: _isIndependentTeamEnabled(scenario) ? 1 : 0,
                            onTap: _showIndependentTeamPage,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: (assigned == total && total > 0)
                                  ? AppColors.gold.withAlpha(18)
                                  : AppColors.bloodRed.withAlpha(51),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: assigned == total && total > 0
                                    ? AppColors.gold.withAlpha(89)
                                    : AppColors.bloodRedLight.withAlpha(140),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  assigned == total && total > 0 ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                                  color: assigned == total && total > 0 ? AppColors.goldLight : AppColors.bloodRedLight,
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    'نقش‌بندی‌شده: $assigned از $total نفر',
                                    style: TextStyle(
                                      color: assigned == total && total > 0 ? AppColors.goldLight : AppColors.bloodRedLight,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildSetupSection(
                      icon: Icons.tune_rounded,
                      title: 'تنظیمات میز بازی',
                      subtitle: 'زمان صحبت، نجات دکتر و محل بازی',
                      child: Column(
                        children: [
                          _buildSettingRow(
                            icon: Icons.timer_outlined,
                            title: 'زمان صحبت',
                            value: '$_speakSeconds ثانیه',
                            onMinus: () => setState(() { if (_speakSeconds > 10) _speakSeconds -= 10; }),
                            onPlus: () => setState(() => _speakSeconds += 10),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              'معارفه و چالش: $introSeconds ثانیه',
                              style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSettingRow(
                            icon: Icons.health_and_safety_outlined,
                            title: 'نجات خودِ دکتر',
                            value: '$_doctorMaxSelfSaves بار',
                            onMinus: () => setState(() { if (_doctorMaxSelfSaves > 0) _doctorMaxSelfSaves--; }),
                            onPlus: () => setState(() => _doctorMaxSelfSaves++),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _locationController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'محل بازی (اختیاری)',
                              hintText: 'مثلاً خانه، کافه...',
                              prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.gold),
                              filled: true,
                              fillColor: AppColors.surfaceDark,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: AppColors.goldDark.withAlpha(89))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: AppColors.goldDark.withAlpha(89))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.gold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.bloodRed.withAlpha(56),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.bloodRedLight.withAlpha(153)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppColors.bloodRedLight),
                            const SizedBox(width: 10),
                            Expanded(child: Text(error, style: const TextStyle(color: AppColors.bloodRedLight, fontWeight: FontWeight.w700))),
                          ],
                        ),
                      ),
                    Game3DButton(
                      label: 'شروع بازی • روز معارفه',
                      icon: Icons.play_arrow_rounded,
                      onPressed: error == null ? _onStartPressed : null,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSetupSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withAlpha(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.goldDark.withAlpha(36),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.goldLight),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.headingFont(size: 17)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.goldLight, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
        IconButton(onPressed: onMinus, icon: const Icon(Icons.remove_circle_outline_rounded), color: AppColors.gold),
        Text(value, style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w900)),
        IconButton(onPressed: onPlus, icon: const Icon(Icons.add_circle_outline_rounded), color: AppColors.gold),
      ],
    );
  }

  /// دکمه‌ی رنگیِ هر تیم — رنگِ خودِ تیم، اسمِ تیم، تعدادِ اعضا روش.
  Widget _teamNavButton({
    required String label,
    required Color color,
    required int count,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: Game3DButton(
          label: '$label ($count نفر)',
          customColor: color,
          onPressed: onTap,
        ),
      ),
    );
  }

  /// ناوبریِ عمومی به یه «زیرصفحه» که محتواش با setSheetState محلی
  /// آپدیت می‌شه (چون خودِ صفحه یه روتِ جداست، setState معمولیِ این
  /// State بلافاصله روش اثر نمی‌ذاره). موقعِ برگشتن، هابِ اصلی هم با
  /// یه setState خالی رفرش می‌شه تا شمارشگرهای رویِ دکمه‌های تیمی
  /// درست باشن.
  void _pushSection(String title, Color appBarTint, WidgetBuilder builder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(title),
            backgroundColor: Color.alphaBlend(appBarTint.withAlpha(71), AppColors.surfaceDark),
          ),
          body: StatefulBuilder(
            builder: (context, setSheetState) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: builder(context),
            ),
          ),
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _showPlayersPage() {
    _pushSection('بازیکن‌ها', AppColors.gold, (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    onSubmitted: (_) {
                      _addPlayer();
                      setSheetState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _addPlayer();
                    setSheetState(() {});
                  },
                  child: const Text('افزودن'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.groups, color: AppColors.gold),
              label: Text('افزودن از لیستِ بازیکنان (${_roster.length} نفر)'),
              onPressed: _roster.isEmpty
                  ? null
                  : () async {
                      await _showAddFromRosterSheet();
                      setSheetState(() {});
                    },
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
              onReorder: (oldIndex, newIndex) {
                _reorderDraftPlayers(oldIndex, newIndex);
                setSheetState(() {});
              },
              children: _draftPlayers.asMap().entries.map((entry) {
                final index = entry.key;
                final name = entry.value;
                return Card(
                  key: ValueKey('draft-player-$index-$name'),
                  color: AppColors.surfaceCard,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: AppColors.gold.withAlpha(77)),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.drag_handle, color: Colors.white38),
                    title: Text(name, style: const TextStyle(color: Colors.white)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.bloodRedLight),
                      onPressed: () {
                        _removePlayer(index);
                        setSheetState(() {});
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    });
  }

  GameTeam scenarioTeam(GameScenario scenario, String teamId) {
    final team = SarkoobTeams.byId(teamId);
    if (team == null || team.scenarioId != scenario.id) {
      throw StateError('Unknown team ' + teamId + ' for scenario ' + scenario.id);
    }
    return team;
  }

  GameRole scenarioRole(GameScenario scenario, String key) {
    final roleId = key == 'leaderDefault'
        ? scenario.leaderDefaultRoleId
        : key == 'townDefault'
            ? scenario.townDefaultRoleId
            : scenario.roleIdFor(key);
    return scenarioRoleById(scenario, roleId);
  }

  GameRole scenarioRoleById(GameScenario scenario, String roleId) {
    for (final role in SarkoobRoles.forScenario(scenario.id)) {
      if (role.id == roleId) return role;
    }
    throw StateError('Unknown role ' + roleId + ' for scenario ' + scenario.id);
  }

  void _showIndependentTeamPage() {
    final scenario = _selectedScenario;
    if (scenario == null) return;
    final team = scenarioTeam(scenario, scenario.independentTeamId);
    final role = scenarioRoleById(scenario, scenario.independentLeaderRoleId);
    if (team == null || role == null) return;

    _pushSection('تیمِ مستقل', team.color, (context) {
      final enabled = _isIndependentTeamEnabled(scenario);
      return StatefulBuilder(
        builder: (context, setSheetState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('اختیاریه.', style: TextStyle(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 8),
            RadioListTile<String>(
              value: 'none',
              groupValue: enabled ? team.id : 'none',
              onChanged: (_) {
                _setIndependentTeamEnabled(scenario, false);
                setSheetState(() {});
              },
              activeColor: AppColors.gold,
              title: const Text('بدون تیم مستقل', style: TextStyle(color: Colors.white)),
            ),
            RadioListTile<String>(
              value: team.id,
              groupValue: enabled ? team.id : 'none',
              onChanged: (_) {
                _setIndependentTeamEnabled(scenario, true);
                setSheetState(() {});
              },
              activeColor: team.color,
              title: Text(team.name, style: const TextStyle(color: Colors.white)),
            ),
            if (enabled) ...[
              const SizedBox(height: 4),
              Text(
                'فعلاً تنها نقشِ این تیم «${role.name}» است، پس این تیم همیشه دقیقاً ۱ نفره:',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 4),
              _mandatoryRoleRow(role),
            ],
          ],
        ),
      );
    });
  }
  void _showStandardLeaderTeamPage() {
    _pushSection(scenarioTeam(scenario, scenario.leaderTeamId).name, scenarioTeam(scenario, scenario.leaderTeamId).color, (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'جلوی هر نقش، تعدادش رو مشخص کن؛ خودِ برنامه موقعِ شروعِ بازی '
              'کاملاً تصادفی مشخص می‌کنه کدوم بازیکن کدوم نقش رو می‌گیره.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 8),
            _roleToggle(
              role: scenarioRole(scenario, 'leaderRole'),
              value: _includeValiFaghih,
              onChanged: (v) => setSheetState(() => _includeValiFaghih = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'negotiator'),
              value: _includeForeignMinister,
              onChanged: (v) => setSheetState(() => _includeForeignMinister = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'judiciary'),
              value: _includeJudiciaryChief,
              onChanged: (v) => setSheetState(() => _includeJudiciaryChief = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'celebrity'),
              value: _includeCelebrity,
              onChanged: (v) => setSheetState(() => _includeCelebrity = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'interrogator'),
              value: _includeInterrogator,
              onChanged: (v) => setSheetState(() => _includeInterrogator = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'intelligenceMinister'),
              value: _includeIntelMinister,
              onChanged: (v) => setSheetState(() => _includeIntelMinister = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'policeCommander'),
              value: _includePoliceCommander,
              onChanged: (v) => setSheetState(() => _includePoliceCommander = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'mercenary'),
              value: _includeMercenary,
              onChanged: (v) => setSheetState(() => _includeMercenary = v),
            ),
            const SizedBox(height: 4),
            _roleCountStepper(
              role: scenarioRole(scenario, 'leaderDefault'),
              value: _suppressorCount,
              onDecrement: () => setSheetState(() {
                if (_suppressorCount > 0) _suppressorCount--;
              }),
              onIncrement: () => setSheetState(() => _suppressorCount++),
            ),
            const SizedBox(height: 4),
            Text(
              'مجموعِ تیم سرکوب: $_standardLeaderTotal نفر',
              style: const TextStyle(
                color: AppColors.goldLight,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showStandardTownTeamPage() {
    _pushSection(scenarioTeam(scenario, scenario.townTeamId).name, scenarioTeam(scenario, scenario.townTeamId).color, (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'همینطور جلوی هر نقشِ شهروندی، تعدادش رو مشخص کن؛ شهروندِ '
              'خاکستری همون عضوِ سادهٔ بدونِ قابلیتِ خاصه.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 8),
            _roleToggle(
              role: scenarioRole(scenario, 'doctor'),
              value: _includeDoctor,
              onChanged: (v) => setSheetState(() => _includeDoctor = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'hacker'),
              value: _includeHacker,
              onChanged: (v) => setSheetState(() => _includeHacker = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'revolutionary'),
              value: _includeRevolutionary,
              onChanged: (v) => setSheetState(() => _includeRevolutionary = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'lawyer'),
              value: _includeLawyer,
              onChanged: (v) => setSheetState(() => _includeLawyer = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'zhina'),
              value: _includeZhina,
              onChanged: (v) => setSheetState(() => _includeZhina = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'rapper'),
              value: _includeRapper,
              onChanged: (v) => setSheetState(() => _includeRapper = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'rebel'),
              value: _includeRebel,
              onChanged: (v) => setSheetState(() => _includeRebel = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'nationalHero'),
              value: _includeNationalHero,
              onChanged: (v) => setSheetState(() => _includeNationalHero = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'civicActivist'),
              value: _includeCivicActivist,
              onChanged: (v) => setSheetState(() => _includeCivicActivist = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'politicalAnalyst'),
              value: _includePoliticalAnalyst,
              onChanged: (v) => setSheetState(() => _includePoliticalAnalyst = v),
            ),
            const SizedBox(height: 4),
            _roleCountStepper(
              role: scenarioRole(scenario, 'townDefault'),
              value: _grayCitizenCount,
              onDecrement: () => setSheetState(() {
                if (_grayCitizenCount > 0) _grayCitizenCount--;
              }),
              onIncrement: () => setSheetState(() => _grayCitizenCount++),
            ),
            const SizedBox(height: 4),
            Text(
              'مجموعِ تیم شهروند: $_standardTownTotal نفر',
              style: const TextStyle(
                color: AppColors.goldLight,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showMafiaGangTeamPage() {
    _pushSection(scenarioTeam(scenario, scenario.leaderTeamId).name, scenarioTeam(scenario, scenario.leaderTeamId).color, (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'جلوی هر نقش، تعدادش رو مشخص کن؛ خودِ برنامه موقعِ شروعِ بازی '
              'کاملاً تصادفی مشخص می‌کنه کدوم بازیکن کدوم نقش رو می‌گیره.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 8),
            _roleToggle(
              role: scenarioRole(scenario, 'leaderRole'),
              value: _includeGodfather,
              onChanged: (v) => setSheetState(() => _includeGodfather = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'negotiator'),
              value: _includeNegotiator,
              onChanged: (v) => setSheetState(() => _includeNegotiator = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'judiciary'),
              value: _includeEnchanter,
              onChanged: (v) => setSheetState(() => _includeEnchanter = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'spy'),
              value: _includeSpy,
              onChanged: (v) => setSheetState(() => _includeSpy = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'policeCommander'),
              value: _includeKidnapper,
              onChanged: (v) => setSheetState(() => _includeKidnapper = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'terrorist'),
              value: _includeTerrorist,
              onChanged: (v) => setSheetState(() => _includeTerrorist = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'bomber'),
              value: _includeBomber,
              onChanged: (v) => setSheetState(() => _includeBomber = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'mistress'),
              value: _includeMistress,
              onChanged: (v) => setSheetState(() => _includeMistress = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'natasha'),
              value: _includeNatasha,
              onChanged: (v) => setSheetState(() => _includeNatasha = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'saboteur'),
              value: _includeSaboteur,
              onChanged: (v) => setSheetState(() => _includeSaboteur = v),
            ),
            const SizedBox(height: 4),
            _roleCountStepper(
              role: scenarioRole(scenario, 'leaderDefault'),
              value: _mafiaCount,
              onDecrement: () => setSheetState(() {
                if (_mafiaCount > 0) _mafiaCount--;
              }),
              onIncrement: () => setSheetState(() => _mafiaCount++),
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
          ],
        ),
      );
    });
  }

  void _showMafiaTownTeamPage() {
    _pushSection(scenarioTeam(scenario, scenario.townTeamId).name, scenarioTeam(scenario, scenario.townTeamId).color, (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'همینطور جلوی هر نقشِ شهروندی، تعدادش رو مشخص کن؛ شهروندِ '
              'ساده همون عضوِ سادهٔ بدونِ قابلیتِ خاصه.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 8),
            _roleToggle(
              role: scenarioRole(scenario, 'doctor'),
              value: _includeMafiaDoctor,
              onChanged: (v) => setSheetState(() => _includeMafiaDoctor = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'hacker'),
              value: _includeDetective,
              onChanged: (v) => setSheetState(() => _includeDetective = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'revolutionary'),
              value: _includeProfessional,
              onChanged: (v) => setSheetState(() => _includeProfessional = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'lawyer'),
              value: _includeKonstantin,
              onChanged: (v) => setSheetState(() => _includeKonstantin = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'rapper'),
              value: _includeOcean,
              onChanged: (v) => setSheetState(() => _includeOcean = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'warGun'),
              value: _includeGunman,
              onChanged: (v) => setSheetState(() => _includeGunman = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'civicActivist'),
              value: _includeLeader,
              onChanged: (v) => setSheetState(() => _includeLeader = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'politicalAnalyst'),
              value: _includeSherlock,
              onChanged: (v) => setSheetState(() => _includeSherlock = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'guard'),
              value: _includeGuard,
              onChanged: (v) => setSheetState(() => _includeGuard = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'discloser'),
              value: _includeDiscloser,
              onChanged: (v) => setSheetState(() => _includeDiscloser = v),
            ),
            _roleToggle(
              role: scenarioRole(scenario, 'guarantee'),
              value: _includeWhiteBeard,
              onChanged: (v) => setSheetState(() => _includeWhiteBeard = v),
            ),
            const SizedBox(height: 4),
            _roleCountStepper(
              role: scenarioRole(scenario, 'townDefault'),
              value: _simpleCitizenCount,
              onDecrement: () => setSheetState(() {
                if (_simpleCitizenCount > 0) _simpleCitizenCount--;
              }),
              onIncrement: () => setSheetState(() => _simpleCitizenCount++),
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
          ],
        ),
      );
    });
  }

  int _standardAssignedTotalFor(GameScenario scenario) {
    switch (scenario.setupTemplate) {
      case GameScenarioSetupTemplate.mafiaClassic:
        return _mafiaAssignedTotal;
      case GameScenarioSetupTemplate.standard:
        return _standardAssignedTotal;
    }
  }

  int _teamMemberCountFor(GameScenario scenario, String teamId) {
    switch (scenario.setupTemplate) {
      case GameScenarioSetupTemplate.mafiaClassic:
        if (teamId == scenario.leaderTeamId) return _mafiaGangTotal;
        if (teamId == scenario.townTeamId) return _mafiaTownTotal;
        return 0;
      case GameScenarioSetupTemplate.standard:
        if (teamId == scenario.leaderTeamId) return _standardLeaderTotal;
        if (teamId == scenario.townTeamId) return _standardTownTotal;
        return 0;
    }
  }

  VoidCallback? _teamSetupPageFor(GameScenario scenario, String teamId) {
    if (teamId == scenario.leaderTeamId) {
      switch (scenario.setupTemplate) {
        case GameScenarioSetupTemplate.mafiaClassic:
          return _showMafiaGangTeamPage;
        case GameScenarioSetupTemplate.standard:
          return _showStandardLeaderTeamPage;
      }
    }
    if (teamId == scenario.townTeamId) {
      switch (scenario.setupTemplate) {
        case GameScenarioSetupTemplate.mafiaClassic:
          return _showMafiaTownTeamPage;
        case GameScenarioSetupTemplate.standard:
          return _showStandardTownTeamPage;
      }
    }
    return null;
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
                side: BorderSide(color: scenario.color.withAlpha(153), width: 1.5),
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
  final GameScenario? initialScenario;

  const StartGameScreen({
    super.key,
    this.initialScenario,
  });

  @override
  State<StartGameScreen> createState() => _StartGameScreenState();
}