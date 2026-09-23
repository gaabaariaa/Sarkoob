import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../models/history.dart';
import '../models/role.dart';
import '../models/scenario.dart';
import '../models/team.dart';
import '../services/storage_service.dart';
import '../services/scenario_role_assigner.dart';
import '../theme/app_theme.dart';
import '../theme/app_strings.dart';
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

  final Map<String, bool> _independentTeamEnabled = <String, bool>{};

  /// وضعیتِ نقش‌های اختیاری کاملاً بر اساس کلید قراردادی سناریو نگه‌داری می‌شود.
  /// بنابراین اضافه‌شدن سناریوی جدید نیازمند افزودن فیلدِ _includeXxx نیست.
  final Map<String, bool> _includedRoles = <String, bool>{};

  /// تعدادِ نقش‌های ساده هم مثل نقش‌های اختیاری متعلق به سناریو است؛
  /// کلید شامل scenario.id است تا تغییر سناریو state را قاطی نکند.
  final Map<String, int> _simpleRoleCounts = <String, int>{};

  static int _minPlayers = 6;

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
      backgroundColor: AppTheme.uiSurface,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          builder: (context, scrollController) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text('افزودن از لیستِ بازیکنان'.tr.tr, style: AppTheme.headingFont(size: 18)),
              ),
              if (available.isEmpty)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'همه‌ی بازیکنانِ لیستِ دائمی از قبل تو این بازی هستن.'.tr.tr,
                    style: TextStyle(color: Colors.white38),
                  ),
                )
              else
                CheckboxListTile(
                  value: selected.isEmpty
                      ? false
                      : (selected.length == available.length ? true : null),
                  tristate: true,
                  activeColor: AppTheme.uiPrimary,
                  title: Text(
                    'انتخابِ همه'.tr.tr.tr,
                    style: TextStyle(color: AppTheme.uiPrimaryLight, fontWeight: FontWeight.bold),
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
                          activeColor: AppTheme.uiPrimary,
                          title: Text(p.name, style: TextStyle(color: Colors.white)),
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
                padding: EdgeInsets.all(16),
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

  String _roleStateKey(GameScenario scenario, String key) =>
      '${scenario.id}::$key';

  bool _isRoleIncluded(GameScenario scenario, String key) =>
      _includedRoles[_roleStateKey(scenario, key)] ?? false;

  int _enabledRoleCount(GameScenario scenario, String teamId) =>
      scenario.setupRoleKeysForTeam(teamId)
          .where((key) => _isRoleIncluded(scenario, key))
          .length;

  String _simpleCountKey(GameScenario scenario, String roleId) =>
      '\${scenario.id}::\${roleId}';

  int _simpleRoleCount(GameScenario scenario, String roleId) =>
      _simpleRoleCounts[_simpleCountKey(scenario, roleId)] ?? 0;

  void _setSimpleRoleCount(GameScenario scenario, String roleId, int value) {
    _simpleRoleCounts[_simpleCountKey(scenario, roleId)] = value.clamp(0, 999).toInt();
  }

  int _teamMemberCountFor(GameScenario scenario, String teamId) {
    if (teamId == scenario.leaderTeamId) {
      return _enabledRoleCount(scenario, teamId) + _simpleRoleCount(scenario, scenario.setupRules.simpleLeaderRoleId);
    }
    if (teamId == scenario.townTeamId) {
      return _enabledRoleCount(scenario, teamId) + _simpleRoleCount(scenario, scenario.setupRules.simpleTownRoleId);
    }
    if (teamId == scenario.independentTeamId && _isIndependentTeamEnabled(scenario)) {
      return scenario.setupRules.independentPlayerCount;
    }
    return 0;
  }

  int _assignedTotalFor(GameScenario scenario) =>
      _teamMemberCountFor(scenario, scenario.leaderTeamId) +
      _teamMemberCountFor(scenario, scenario.townTeamId) +
      _teamMemberCountFor(scenario, scenario.independentTeamId);

  int _leaderTeamTotal(GameScenario scenario) => _teamMemberCountFor(scenario, scenario.leaderTeamId);
  int _townTeamTotal(GameScenario scenario) => _teamMemberCountFor(scenario, scenario.townTeamId);
  int _independentTotal(GameScenario scenario) => _isIndependentTeamEnabled(scenario) ? scenario.setupRules.independentPlayerCount : 0;


  String? get _validationError {
    final scenario = _selectedScenario;
    if (scenario == null) return 'سناریوی بازی انتخاب نشده';
    final total = _draftPlayers.length;
    if (total < _minPlayers) return 'حداقل $_minPlayers بازیکن لازمه (الان $total نفر)';
    final townTotal = _townTeamTotal(scenario);
    final assigned = _assignedTotalFor(scenario);
    final townTeam = scenarioTeam(scenario, scenario.townTeamId);
    final simpleTown = scenarioRoleById(scenario, scenario.setupRules.simpleTownRoleId);
    if (townTotal < 1) return 'باید حداقل ۱ نفر در ${townTeam.name} باشه — تعدادِ ${simpleTown.name} رو زیاد کن';
    final diff = total - assigned;
    final simpleLeader = scenarioRoleById(scenario, scenario.setupRules.simpleLeaderRoleId);
    if (diff > 0) return 'هنوز $diff نفر نقش نگرفتن — تعدادِ ${simpleLeader.name} یا ${simpleTown.name} رو زیاد کن';
    if (diff < 0) return 'مجموعِ نقش‌ها ${-diff} نفر بیشتر از بازیکن‌هاست — تعدادِ ${simpleLeader.name} یا ${simpleTown.name} رو کم کن';
    return null;
  }

  bool get _isPowerUnbalanced {
    final scenario = _selectedScenario;
    final fraction = scenario?.setupRules.minTownTeamFraction;
    if (scenario == null || fraction == null) return false;
    final total = _draftPlayers.length;
    return total > 0 && _townTeamTotal(scenario) < total * fraction;
  }

  bool get _isLeaderTeamUnbalanced {
    final scenario = _selectedScenario;
    final fraction = scenario?.setupRules.maxLeaderTeamFraction;
    if (scenario == null || fraction == null) return false;
    final total = _draftPlayers.length;
    final leaderTotal = _leaderTeamTotal(scenario);
    return total > 0 && leaderTotal > 0 && leaderTotal > total * fraction;
  }

  Future<void> _onStartPressed() async {
    final error = _validationError;
    if (error != null) return;
    final scenario = _selectedScenario;
    if (scenario == null) return;
    if ((_isLeaderTeamUnbalanced || _isPowerUnbalanced) && scenario.setupRules.balanceWarning != null) {
      final proceed = await _showBalanceWarning(scenario.setupRules.balanceWarning!);
      if (proceed != true) return;
    }
    _startScenario(scenario);
  }

  Future<bool?> _showBalanceWarning(String message) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.uiSurface,
        title: Text('قدرت بازی بالانس نیست'.tr.tr.tr, style: TextStyle(color: AppTheme.uiPrimaryLight)),
        content: Text(message, style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('بازگشت و تغییر'.tr.tr),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('همینطوری ادامه بده'.tr.tr),
          ),
        ],
      ),
    );
  }

  void _startScenario(GameScenario scenario) {
    final leaderRoleIds = scenario.setupRoleKeysForTeam(scenario.leaderTeamId).where((key) => _isRoleIncluded(scenario, key)).map(scenario.roleIdFor).toList();
    final townRoleIds = scenario.setupRoleKeysForTeam(scenario.townTeamId).where((key) => _isRoleIncluded(scenario, key)).map(scenario.roleIdFor).toList();
    final rules = scenario.setupRules;
    _startScenarioWithRoles(
      scenario: scenario,
      leaderCount: _leaderTeamTotal(scenario),
      independentCount: _independentTotal(scenario),
      leaderRoleIds: leaderRoleIds,
      townRoleIds: townRoleIds,
      independentEnabled: _isIndependentTeamEnabled(scenario),
      slaughterRoleId: rules.slaughterRoleId,
      revolutionaryRoleId: rules.revolutionaryRoleId,
      warGunRoleId: rules.warGunRoleId,
      intelRoleId: rules.intelRoleId,
      guaranteeRoleId: rules.guaranteeRoleId,
      armorRoleIds: rules.armorRoleIds,
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
    final assigned = _assignedTotalFor(scenario);
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
          icon: Icon(Icons.arrow_back_rounded),
          tooltip: 'تغییر سناریو'.tr.tr,
          onPressed: () => setState(() => _selectedScenario = null),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 800;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1080),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 16, wide ? 28 : 16, 28),
                  children: [
                    Container(
                      padding: EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.uiCard,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _selectedScenario!.color.withAlpha(64)),
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(56), blurRadius: 24, offset: Offset(0, 10))],
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
                            child: Text(_selectedScenario!.emoji, style: TextStyle(fontSize: 29)),
                          ),
                          SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selectedScenario!.name, style: AppTheme.headingFont(size: 22)),
                                SizedBox(height: 3),
                                Text(
                                  _selectedScenario!.description,
                                  style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12, height: 1.45),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('$total نفر', style: AppTheme.headingFont(size: 17, color: AppTheme.uiPrimaryLight)),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
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
                    SizedBox(height: 14),
                    _buildSetupSection(
                      icon: Icons.hub_rounded,
                      title: 'تیم‌ها و نقش‌ها',
                      subtitle: '$assigned از $total نفر نقش‌بندی شده',
                      child: Column(
                        children: [
                          ...teams.map(
                            (entry) => Padding(
                              padding: EdgeInsets.only(bottom: 10),
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
                                : AppTheme.uiSubtleText,
                            count: _isIndependentTeamEnabled(scenario) ? 1 : 0,
                            onTap: _showIndependentTeamPage,
                          ),
                          SizedBox(height: 2),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: (assigned == total && total > 0)
                                  ? AppTheme.uiPrimary.withAlpha(18)
                                  : AppColors.bloodRed.withAlpha(51),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: assigned == total && total > 0
                                    ? AppTheme.uiPrimary.withAlpha(89)
                                    : AppColors.bloodRedLight.withAlpha(140),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  assigned == total && total > 0 ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                                  color: assigned == total && total > 0 ? AppTheme.uiPrimaryLight : AppColors.bloodRedLight,
                                ),
                                SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    'نقش‌بندی‌شده: $assigned از $total نفر',
                                    style: TextStyle(
                                      color: assigned == total && total > 0 ? AppTheme.uiPrimaryLight : AppColors.bloodRedLight,
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
                    SizedBox(height: 14),
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
                          SizedBox(height: 6),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              'معارفه و چالش: $introSeconds ثانیه',
                              style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12),
                            ),
                          ),
                          SizedBox(height: 12),
                          _buildSettingRow(
                            icon: Icons.health_and_safety_outlined,
                            title: 'نجات خودِ دکتر',
                            value: '$_doctorMaxSelfSaves بار',
                            onMinus: () => setState(() { if (_doctorMaxSelfSaves > 0) _doctorMaxSelfSaves--; }),
                            onPlus: () => setState(() => _doctorMaxSelfSaves++),
                          ),
                          SizedBox(height: 12),
                          TextField(
                            controller: _locationController,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'محل بازی (اختیاری)'.tr.tr,
                              hintText: 'مثلاً خانه، کافه...'.tr.tr,
                              prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.uiPrimary),
                              filled: true,
                              fillColor: AppTheme.uiSurface,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: AppTheme.uiPrimaryDark.withAlpha(89))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: AppTheme.uiPrimaryDark.withAlpha(89))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: AppTheme.uiPrimary)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    if (error != null)
                      Container(
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.bloodRed.withAlpha(56),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.bloodRedLight.withAlpha(153)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: AppColors.bloodRedLight),
                            SizedBox(width: 10),
                            Expanded(child: Text(error, style: TextStyle(color: AppColors.bloodRedLight, fontWeight: FontWeight.w700))),
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.uiSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.uiPrimary.withAlpha(26)),
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
                  color: AppTheme.uiPrimaryDark.withAlpha(36),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppTheme.uiPrimaryLight),
              ),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.headingFont(size: 17)),
                    SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 13),
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
        Icon(icon, color: AppTheme.uiPrimaryLight, size: 22),
        SizedBox(width: 10),
        Expanded(child: Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
        IconButton(onPressed: onMinus, icon: Icon(Icons.remove_circle_outline_rounded), color: AppTheme.uiPrimary),
        Text(value, style: TextStyle(color: AppTheme.uiPrimaryLight, fontWeight: FontWeight.w900)),
        IconButton(onPressed: onPlus, icon: Icon(Icons.add_circle_outline_rounded), color: AppTheme.uiPrimary),
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
      padding: EdgeInsets.only(bottom: 10),
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
            backgroundColor: Color.alphaBlend(appBarTint.withAlpha(71), AppTheme.uiSurface),
          ),
          body: StatefulBuilder(
            builder: (context, setSheetState) => SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: builder(context),
            ),
          ),
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _showPlayersPage() {
    _pushSection('بازیکن‌ها', AppTheme.uiPrimary, (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'اسم بازیکن'.tr.tr,
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) {
                      _addPlayer();
                      setSheetState(() {});
                    },
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _addPlayer();
                    setSheetState(() {});
                  },
                  child: Text('افزودن'.tr.tr),
                ),
              ],
            ),
            SizedBox(height: 8),
            OutlinedButton.icon(
              icon: Icon(Icons.groups, color: AppTheme.uiPrimary),
              label: Text('افزودن از لیستِ بازیکنان (${_roster.length} نفر)'),
              onPressed: _roster.isEmpty
                  ? null
                  : () async {
                      await _showAddFromRosterSheet();
                      setSheetState(() {});
                    },
            ),
            SizedBox(height: 12),
            Text(
              'با نگه‌داشتن و کشیدن، می‌تونی ترتیبِ بازیکن‌ها رو عوض کنی.'.tr.tr,
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            SizedBox(height: 4),
            ReorderableListView(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                _reorderDraftPlayers(oldIndex, newIndex);
                setSheetState(() {});
              },
              children: _draftPlayers.asMap().entries.map((entry) {
                final index = entry.key;
                final name = entry.value;
                return Card(
                  key: ValueKey('draft-player-$index-$name'),
                  color: AppTheme.uiCard,
                  margin: EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: AppTheme.uiPrimary.withAlpha(77)),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.drag_handle, color: Colors.white38),
                    title: Text(name, style: TextStyle(color: Colors.white)),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: AppColors.bloodRedLight),
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
    final team = GameTeams.byId(teamId);
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
    for (final role in GameRoles.forScenario(scenario.id)) {
      if (role.id == roleId) return role;
    }
    throw StateError('Unknown role ' + roleId + ' for scenario ' + scenario.id);
  }

  void _showIndependentTeamPage() {
    final scenario = _selectedScenario;
    if (scenario == null) return;
    final team = scenarioTeam(scenario, scenario.independentTeamId);
    final role = scenarioRoleById(scenario, scenario.independentLeaderRoleId);
    if (team.id.isEmpty || role.id.isEmpty) return;

    _pushSection('تیمِ مستقل', team.color, (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final enabled = _isIndependentTeamEnabled(scenario);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('اختیاریه.'.tr.tr, style: TextStyle(color: Colors.white60, fontSize: 12)),
              SizedBox(height: 8),
              RadioListTile<String>(
                value: 'none',
                groupValue: enabled ? team.id : 'none',
              onChanged: (_) {
                _setIndependentTeamEnabled(scenario, false);
                setSheetState(() {});
              },
              activeColor: AppTheme.uiPrimary,
              title: Text('بدون تیم مستقل'.tr.tr.tr, style: TextStyle(color: Colors.white)),
            ),
            RadioListTile<String>(
              value: team.id,
              groupValue: enabled ? team.id : 'none',
              onChanged: (_) {
                _setIndependentTeamEnabled(scenario, true);
                setSheetState(() {});
              },
              activeColor: team.color,
              title: Text(team.localizedName, style: TextStyle(color: Colors.white)),
            ),
            if (enabled) ...[
              SizedBox(height: 4),
              Text(
                'فعلاً تنها نقشِ این تیم «${role.localizedName}» است، پس این تیم همیشه دقیقاً ۱ نفره:',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              SizedBox(height: 4),
              _mandatoryRoleRow(role),
            ],
            ],
          );
        },
      );
    });
  }
  void _showTeamSetupPage(GameScenario scenario, String teamId) {
    final team = scenarioTeam(scenario, teamId);
    final isLeader = teamId == scenario.leaderTeamId;
    final simpleRoleId = isLeader ? scenario.setupRules.simpleLeaderRoleId : scenario.setupRules.simpleTownRoleId;
    final defaultRole = scenarioRoleById(scenario, simpleRoleId);
    final defaultCount = _simpleRoleCount(scenario, simpleRoleId);

    void setDefaultCount(int value) => _setSimpleRoleCount(scenario, simpleRoleId, value);

    _pushSection(team.localizedName, team.color, (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isLeader ? 'جلوی هر نقش، تعدادش رو مشخص کن؛ خودِ برنامه موقعِ شروعِ بازی کاملاً تصادفی مشخص می‌کنه کدوم بازیکن کدوم نقش رو می‌گیره.' : 'همینطور جلوی هر نقشِ این تیم، تعدادش رو مشخص کن؛ عضوِ ساده همون عضوِ بدونِ قابلیتِ خاصه.', style: TextStyle(color: Colors.white60, fontSize: 12)),
            SizedBox(height: 8),
            ...scenario.setupRoleKeysForTeam(teamId).map((key) => _roleToggle(role: scenarioRole(scenario, key), value: _isRoleIncluded(scenario, key), onChanged: (v) => setSheetState(() => _includedRoles[_roleStateKey(scenario, key)] = v))),
            SizedBox(height: 4),
            _roleCountStepper(role: defaultRole, value: defaultCount, onDecrement: () => setSheetState(() => setDefaultCount(defaultCount > 0 ? defaultCount - 1 : 0)), onIncrement: () => setSheetState(() => setDefaultCount(defaultCount + 1))),
            SizedBox(height: 4),
            Text('مجموعِ ${team.localizedName}: ${_teamMemberCountFor(scenario, teamId)} نفر', style: TextStyle(color: AppTheme.uiPrimaryLight, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    });
  }

  VoidCallback? _teamSetupPageFor(GameScenario scenario, String teamId) {
    if (teamId != scenario.leaderTeamId && teamId != scenario.townTeamId) return null;
    return () => _showTeamSetupPage(scenario, teamId);
  }

  Widget _buildScenarioPicker() {
    return Scaffold(
      appBar: AppBar(title: Text('شروع بازی — انتخابِ سناریو'.tr.tr.tr)),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(
            ('اول سناریوی بازی رو انتخاب کن — تیم‌ها و نقش‌های قابل‌انتخاب '
            'کاملاً به همین انتخاب بستگی دارن.').tr,
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          SizedBox(height: 16),
          ...GameScenarios.all.map(
            (scenario) => Card(
              color: AppTheme.uiCard,
              margin: EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: scenario.color.withAlpha(153), width: 1.5),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _selectedScenario = scenario),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(scenario.emoji, style: TextStyle(fontSize: 26)),
                          SizedBox(width: 10),
                          Text(
                            scenario.localizedName,
                            style: AppTheme.headingFont(size: 22, color: scenario.color),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        scenario.localizedDescription,
                        style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
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
      activeColor: AppTheme.uiPrimary,
      title: Text(role.localizedName, style: TextStyle(color: Colors.white)),
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
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(role.localizedName, style: TextStyle(color: Colors.white70, fontSize: 14)),
          ),
          IconButton(
            icon: Icon(Icons.remove, color: AppTheme.uiPrimary),
            onPressed: onDecrement,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.uiPrimaryLight, fontSize: 16),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, color: AppTheme.uiPrimary),
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }

  Widget _mandatoryRoleRow(GameRole role) {
    return ListTile(
      dense: true,
      leading: Icon(Icons.check_circle, color: AppTheme.uiPrimary),
      title: Text(role.localizedName, style: TextStyle(color: Colors.white)),
      trailing: Text('همیشه فعال'.tr.tr, style: TextStyle(color: Colors.white38, fontSize: 12)),
    );
  }
}

class StartGameScreen extends StatefulWidget {
  final GameScenario? initialScenario;

  StartGameScreen({
    super.key,
    this.initialScenario,
  });

  @override
  State<StartGameScreen> createState() => _StartGameScreenState();
}