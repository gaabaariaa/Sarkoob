import 'package:flutter/material.dart';
import '../controllers/game_flow_controller.dart';
import '../models/game_session.dart';
import '../models/history.dart';
import '../models/role.dart';
import '../models/score_event.dart';
import '../models/team.dart';
import '../services/music_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_strings.dart';
import '../widgets/countdown_timer_widget.dart';
import '../widgets/game_3d_button.dart';
import '../widgets/modern_speaking_panel.dart';
import '../widgets/modern_defense_panel.dart';
import '../widgets/modern_night_panel.dart';

class GameFlowScreen extends StatefulWidget {
  final List<SessionPlayer> players;
  final GameSettings settings;

  GameFlowScreen({
    super.key,
    required this.players,
    required this.settings,
  });

  @override
  State<GameFlowScreen> createState() => _GameFlowScreenState();
}

class _GameFlowScreenState extends State<GameFlowScreen> {
  late final GameFlowController controller;
  final StorageService _storage = StorageService();
  bool _showTeamCounts = false;

  /// یادداشتِ آزادِ گرداننده برای خودش (مظنون‌ها، حساب‌وکتابِ رأی، هرچی) —
  /// فقط تو حافظه‌ی همین جلسه، مثلِ بقیه‌ی وضعیتِ زنده‌ی بازی؛ چیزِ
  /// دیگه‌ای هم تو این اپ بینِ نشستن‌ها/ری‌استارت پایدار نمی‌مونه.
  String _moderatorNotes = '';

  // «تیمِ رهبرِ» این جلسه سرکوبه یا مافیا؟ چندجا تو UIی مرحله‌ی تیمِ رهبر
  // لازمه، برای همینم یه getterِ مشترکه به‌جایِ محاسبه‌ی پراکنده.
  String get _leaderTeamName => controller.scenario.localizedName;
  String get _leaderRoleName => controller.roleNameForScenario(controller.scenario.leaderRoleId);
  String get _plainCitizenLabel => _roleName(controller.scenario.townDefaultRoleId);
  String get _plainLeaderTeamLabel => _roleName(controller.scenario.leaderDefaultRoleId);
  String get _independentLeaderRoleName => _roleName(controller.scenario.roleIdFor('independentLeader'));
  String get _rapperRoleName => _roleName(controller.scenario.roleIdFor('rapper'));
  String get _resistanceGroupLabel => controller.scenario.resistanceGroupLabel;
  String get _hackerRoleName => _roleName(controller.scenario.roleIdFor('hacker'));
  String get _politicalAnalystRoleName => _roleName(controller.scenario.roleIdFor('politicalAnalyst'));
  String get _rebelRoleName => _roleName(controller.scenario.roleIdFor('rebel'));
  String get _revolutionaryRoleName => _roleName(controller.scenario.roleIdFor('revolutionary'));
  String get _nationalHeroRoleName => _roleName(controller.scenario.roleIdFor('nationalHero'));
  String get _revolutionaryActionLabel => controller.scenario.revolutionaryActionLabel;
  String get _civicActivistRoleName => _roleName(controller.scenario.roleIdFor('civicActivist'));
  String get _lawyerRoleName => _roleName(controller.scenario.roleIdFor('lawyer'));
  String get _forbiddenWordLabel => controller.scenario.forbiddenWordLabel;
  String _roleName(String roleId) => controller.roleNameForScenario(roleId);

  @override
  void initState() {
    super.initState();
    controller = GameFlowController(players: widget.players, settings: widget.settings);
    // ست‌کردنِ مسیرِ موزیکِ ذخیره‌شده (اگه از قبل تو تنظیمات انتخاب شده)
    // رو غیرِمنتظر می‌ذاریم؛ تا اولین شب برسه، این fetchِ سریعِ محلی
    // بدونِ‌شک تموم شده.
    _storage.loadMusicPaths().then((paths) => MusicService.instance.setPlaylist(paths));
    controller.addListener(_handleMusicForPhase);
  }

  @override
  void dispose() {
    controller.removeListener(_handleMusicForPhase);
    MusicService.instance.stop();
    MusicService.instance.stopAlert();
    super.dispose();
  }

  bool? _lastMusicShouldPlay;

  /// شب (معارفه یا عادی) همیشه بله — به‌جز خودِ صفحه‌ی خلاصه‌ی صبح
  /// (مرحله‌ی done، بعدِ زدنِ «پایانِ شب»)، چون فازِ گیم هنوز night ه
  /// (moveToDay فقط با دکمه‌ی «ادامه به روز»ی زیرِ همون خلاصه صدا زده
  /// می‌شه)، ولی موزیک باید همینجا قطع بشه، نه بعدِ اون دکمه.
  /// روز فقط دقیقاً همون لحظه‌ای که _buildBody واقعاً صفحه‌ی خواب‌نیمروزی
  /// رو نشون می‌ده (نه کلِ روزی که یه بمبِ حل‌نشده وجود داره) — عیناً
  /// همون زنجیره‌ی شرط‌های _buildBody — به‌جز خودِ صفحه‌ی نتیجه‌ی نهایی
  /// (بعدِ resolveBombCode، قبلِ تأییدِ acknowledgeBombOutcome)، که
  /// bombPendingResolution هنوز true می‌مونه ولی موزیک باید قطع بشه.
  bool get _shouldPlayMusic {
    final phase = controller.phase;
    if (phase == GamePhaseType.introNight || phase == GamePhaseType.night) {
      return controller.lastNightSummary == null;
    }
    if (phase == GamePhaseType.day &&
        controller.autoDetectedWinnerTeamId == null &&
        !controller.chaosPhaseActive &&
        controller.lastResolution == null &&
        !controller.isSecondVoteRound &&
        !controller.inDefense &&
        !controller.votingStarted &&
        controller.isSpeakingRoundDone &&
        controller.bombPendingResolution) {
      return controller.bombOutcomeMessage == null;
    }
    return false;
  }

  void _handleMusicForPhase() {
    final should = _shouldPlayMusic;
    if (should == _lastMusicShouldPlay) return;
    _lastMusicShouldPlay = should;
    if (should) {
      MusicService.instance.play();
    } else {
      MusicService.instance.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // بکِ سیستمی/AppBar به‌جای بازگشت به منو، فقط یه فاز/روزِ گردانندگی
    // رو برمی‌گردونه عقب. اگه چیزی برای برگشتن نباشه (شروعِ بازی)، پاپ
    // نمی‌شه — برای خروجِ واقعی از دکمه‌ی «پایانِ بازی» پایینِ صفحه استفاده می‌شه.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (controller.canStepBackPhase) {
          controller.stepBackOnePhase();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('برای خروج از گردانندگی، از دکمه‌ی «پایانِ بازی» تو نوارِ پایین استفاده کن.'.tr),
            ),
          );
        }
      },
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            title: Text(_titleFor(controller)),
          ),
          body: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildNowPlayingBox(),
                if (_showTeamCounts) _buildTeamCountsBanner(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
          bottomNavigationBar: BottomAppBar(
            color: AppTheme.uiBackground,
            elevation: 0,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: _bottomBarAction(
                      icon: Icons.groups,
                      label: 'بازیکنان',
                      onPressed: _showRosterDialog,
                    ),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: _bottomBarAction(
                      icon: Icons.swap_vert,
                      label: 'جابه‌جایی',
                      onPressed: _showReorderDialog,
                    ),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: _bottomBarAction(
                      icon: Icons.gavel,
                      label: 'تنبیه',
                      onPressed: _showDisciplineDialog,
                    ),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: _bottomBarAction(
                      icon: _showTeamCounts ? Icons.pie_chart : Icons.pie_chart_outline,
                      label: 'تعدادِ زنده',
                      active: _showTeamCounts,
                      onPressed: () => setState(() => _showTeamCounts = !_showTeamCounts),
                    ),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: _bottomBarAction(
                      icon: _moderatorNotes.trim().isEmpty ? Icons.note_add_outlined : Icons.note_alt,
                      label: 'یادداشت',
                      active: _moderatorNotes.trim().isNotEmpty,
                      onPressed: _showNotesDialog,
                    ),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: _bottomBarAction(
                      icon: Icons.flag,
                      label: 'پایانِ بازی',
                      onPressed: _showEndGameDialog,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// باکسِ «درحالِ پخش» — هروقت موزیک واقعاً در حالِ پخشه (چه در حالِ
  /// اجرا چه موقتاً مکث‌شده) بالای صفحه نشون داده می‌شه: اسمِ آهنگ +
  /// دکمه‌ی مکث/ادامه + دکمه‌ی بعدی. با ListenableBuilderِ جداگونه‌ی
  /// خودش، چون MusicService مستقل از GameFlowControllerه.
  Widget _buildNowPlayingBox() {
    return ListenableBuilder(
      listenable: MusicService.instance,
      builder: (context, _) {
        if (!MusicService.instance.isPlaying) return SizedBox.shrink();
        final trackName = MusicService.instance.currentTrackName ?? 'موزیکِ پس‌زمینه';
        final isPaused = MusicService.instance.isPaused;
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.uiSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.uiPrimary.withAlpha(102)),
          ),
          child: Row(
            children: [
              Icon(Icons.music_note, color: AppTheme.uiPrimaryLight, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  trackName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              IconButton(
                iconSize: 24,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, color: AppTheme.uiPrimaryLight),
                tooltip: isPaused ? 'ادامه' : 'مکث',
                onPressed: () {
                  if (isPaused) {
                    MusicService.instance.resume();
                  } else {
                    MusicService.instance.pause();
                  }
                },
              ),
              IconButton(
                iconSize: 24,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(Icons.skip_next, color: AppTheme.uiPrimaryLight),
                tooltip: 'آهنگِ بعدی'.tr,
                onPressed: () => MusicService.instance.skipToNext(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// دیالوگِ یادداشتِ آزادِ گرداننده — یه TextFieldِ چندخطی، با «ذخیره»
  /// تغییرات تو _moderatorNotes می‌شینه (و آیکونِ دکمه‌ی BottomAppBar
  /// طبقِ خالی/پرـبودنش عوض می‌شه).
  void _showNotesDialog() {
    final notesController = TextEditingController(text: _moderatorNotes);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.uiCard,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppTheme.uiPrimary.withAlpha(56)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.uiPrimaryDark.withAlpha(56),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.note_alt_rounded, color: AppTheme.uiPrimaryLight),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('یادداشتِ گرداننده'.tr, style: AppTheme.headingFont(size: 20)),
                        SizedBox(height: 3),
                        Text('نکته‌های مهم میز بازی را ثبت کن.'.tr.tr, style: TextStyle(color: AppTheme.uiMutedText, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: notesController,
                autofocus: true,
                maxLines: 10,
                minLines: 6,
                textDirection: TextDirection.rtl,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'مثلاً: مظنون‌ها، حساب‌وکتابِ رأی، هر نکته‌ای...'.tr,
                  hintStyle: TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: AppTheme.uiSurface,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 86),
                    child: Icon(Icons.edit_note_rounded, color: AppTheme.uiPrimaryLight),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppTheme.uiPrimary.withAlpha(41)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppTheme.uiPrimary.withAlpha(41)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppTheme.uiPrimary, width: 1.2),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text('انصراف'.tr.tr),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Game3DButton(
                      label: 'ذخیره',
                      icon: Icons.save_rounded,
                      onPressed: () {
                        setState(() => _moderatorNotes = notesController.text);
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// دکمه‌ی استاندارد برای BottomAppBar گرداننده: آیکون + لیبلِ کوچیک،
  /// برای اینکه هم انگشتیِ راحت‌تر باشه (پایینِ صفحه) هم AppBar شلوغ نشه.
  Widget _bottomBarAction({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool active = false,
  }) {
    return Game3DBottomBarButton(
      icon: icon,
      label: label,
      onPressed: onPressed,
      active: active,
    );
  }

  String _titleFor(GameFlowController c) {
    switch (c.phase) {
      case GamePhaseType.introDay:
        return 'روز معارفه';
      case GamePhaseType.introNight:
        return 'شب معارفه';
      case GamePhaseType.day:
        return 'روز ${c.roundNumber}';
      case GamePhaseType.night:
        return 'شب ${c.roundNumber}';
    }
  }

  /// پنلِ نمایشِ تعدادِ زنده‌های هر تیم (مثلاً «سرکوب: ۲ / شهروند: ۴»)؛
  /// با آیکونِ نمودارِ AppBar روشن/خاموش می‌شه. برخلافِ بقیه‌ی ابزارهای
  /// گرداننده، دیالوگ نیست — یه بنرِ کوچیکِ بالای صفحه‌ست که تا وقتی
  /// دوباره لمس نشه، سرِ جاش می‌مونه (برای نشون‌دادنِ سریع به بازیکن‌ها).
  Widget _buildTeamCountsBanner() {
    final counts = controller.aliveCountsByTeam;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.uiCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.uiPrimary.withAlpha(128)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 24,
        runSpacing: 8,
        children: [
          for (final entry in counts)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 5, backgroundColor: entry.key.color),
                SizedBox(width: 8),
                Text(
                  '${entry.key.name}: ${entry.value}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// لیستِ کاملِ همه‌ی بازیکنان با تیم، نقش، و وضعیتِ زنده/نیمه‌جان/حذف —
  /// همیشه در دسترسِ گرداننده، هم شب هم روز.
  void _showRosterDialog() {
    bool showOnlyAlive = false;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.uiSurface,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, scrollController) => StatefulBuilder(
          builder: (context, setSheetState) {
            final list = showOnlyAlive
                ? controller.players.where((p) => p.isAlive).toList()
                : controller.players;
            return ListView(
              controller: scrollController,
              padding: EdgeInsets.all(16),
              children: [
                Text('بازیکنان و نقش‌ها'.tr, style: AppTheme.headingFont(size: 20)),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppTheme.uiPrimary,
                  title: Text('فقط بازیکنانِ زنده'.tr.tr, style: TextStyle(color: Colors.white, fontSize: 14)),
                  value: showOnlyAlive,
                  onChanged: (v) => setSheetState(() => showOnlyAlive = v),
                ),
                SizedBox(height: 4),
                ...list.map((p) {
                  final role = p.roleId != null ? GameRoles.byId(p.roleId!) : null;
                  final teamName = GameTeams.byId(p.teamId)?.name ?? p.teamId;
                  final status =
                      !p.isAlive ? (p.isHalfAlive ? 'نیمه‌جان' : 'حذف‌شده') : 'زنده';
                  return ListTile(
                    dense: true,
                    title: Text(p.name, style: TextStyle(color: Colors.white)),
                    subtitle: Text(
                      '$teamName${role != null ? ' — ${role.localizedName}' : ''}'
                      '${p.disciplineStage > 0 ? ' — ${disciplineStageLabel(p.disciplineStage)}' : ''}'
                      '${!controller.hasVotingRightsToday(p) ? ' — 🚫 بدونِ حقِ رأیِ امروز' : ''}',
                      style: TextStyle(color: AppTheme.uiPrimaryLight),
                    ),
                    trailing: Text(status, style: TextStyle(color: Colors.white54)),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  /// جابه‌جاییِ ترتیبِ بازیکنان (اگه سرِ میز جابه‌جا شدن)؛ فقط ترتیبِ
  /// نوبتِ صحبتِ روزهای بعد رو عوض می‌کنه، چیزی رو وسطِ کار خراب نمی‌کنه.
  void _showReorderDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .72,
        minChildSize: .45,
        maxChildSize: .92,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppTheme.uiCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) => Column(children: [
              SizedBox(height: 10),
              Container(width: 44, height: 5,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8))),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(children: [
                  Container(width: 42, height: 42,
                    decoration: BoxDecoration(color: AppTheme.uiPrimaryDark.withAlpha(56), shape: BoxShape.circle),
                    child: Icon(Icons.swap_vert_rounded, color: AppTheme.uiPrimaryLight)),
                  SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('ترتیب بازیکنان'.tr, style: AppTheme.headingFont(size: 19)),
                    Text('با نگه‌داشتن و کشیدن جابه‌جا کن.'.tr,
                      style: TextStyle(color: AppTheme.uiMutedText, fontSize: 11)),
                  ])),
                  CircleAvatar(radius: 17, backgroundColor: AppTheme.uiPrimaryDark.withAlpha(56),
                    child: Text('${controller.players.length}',
                      style: TextStyle(color: AppTheme.uiPrimaryLight, fontSize: 12))),
                ]),
              ),
              SizedBox(height: 8),
              Expanded(
                child: ReorderableListView(
                  scrollController: scrollController,
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                  onReorder: (oldIndex, newIndex) {
                    controller.reorderPlayers(oldIndex, newIndex);
                    setSheetState(() {});
                  },
                  children: controller.players.map((p) => Material(
                    key: ValueKey('reorder-${p.id}'),
                    color: AppTheme.uiSurface,
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      leading: CircleAvatar(radius: 17,
                        backgroundColor: AppTheme.uiPrimaryDark.withAlpha(51),
                        child: Text('${controller.players.indexOf(p) + 1}',
                          style: TextStyle(color: AppTheme.uiPrimaryLight, fontSize: 12))),
                      title: Text(p.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      trailing: Icon(Icons.drag_handle_rounded, color: Colors.white38),
                    ),
                  )).toList(),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  /// تنبیهِ انضباطیِ یه بازیکن توسطِ گرداننده — هم تو شب هم تو روز در
  /// دسترسه. بعدِ انتخابِ بازیکن، گرداننده بینِ دو راه انتخاب می‌کنه:
  /// «تنبیه» (درجه‌بندی‌شده: اخطار → منعِ چالش → سکوت → اخراج) یا
  /// «اخراجِ» مستقیم و فوری (افشای نقش، تقلبِ آشکار، و مواردِ مشابه).
  void _showDisciplineDialog() {
    SessionPlayer? selectedTarget;
    String actionMode = 'discipline'; // discipline | expel | revokeVote
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final nextStage = selectedTarget == null ? 0 : selectedTarget!.disciplineStage + 1;
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.uiCard,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppTheme.uiPrimary.withAlpha(56)),
              ),
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.bloodRed.withAlpha(82),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.gavel_rounded, color: AppColors.bloodRedLight),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text('تنبیهِ انضباطی'.tr, style: AppTheme.headingFont(size: 20)),
                ),
              ],
            ),
                SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.uiCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.uiPrimary.withAlpha(31)),
                    ),
                    child: Text(
                      'مستقل از قوانینِ عادیِ بازیه؛ برای رفتارِ خارج از نظمِ جلسه.'.tr,
                      style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.45),
                    ),
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<SessionPlayer>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'بازیکن'.tr,
                      prefixIcon: Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(),
                    ),
                    dropdownColor: AppTheme.uiSurface,
                    value: selectedTarget,
                    items: controller.alivePlayers
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.name, style: TextStyle(color: Colors.white)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedTarget = v),
                  ),
                  if (selectedTarget != null) ...[
                    SizedBox(height: 4),
                    Text(
                      'سابقه‌ی انضباطیِ فعلی: ${disciplineStageLabel(selectedTarget!.disciplineStage)}',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              backgroundColor:
                                  actionMode == 'discipline' ? AppTheme.uiPrimaryDark.withAlpha(89) : null,
                              side: BorderSide(
                                color: actionMode == 'discipline' ? AppTheme.uiPrimary : Colors.white24,
                              ),
                            ),
                            onPressed: () => setDialogState(() => actionMode = 'discipline'),
                            child: Text('تنبیه'.tr, style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              backgroundColor:
                                  actionMode == 'revokeVote' ? AppTheme.uiPrimaryDark.withAlpha(89) : null,
                              side: BorderSide(
                                color: actionMode == 'revokeVote' ? AppTheme.uiPrimary : Colors.white24,
                              ),
                            ),
                            onPressed: () => setDialogState(() => actionMode = 'revokeVote'),
                            child: Text('گرفتنِ حقِ رأی'.tr, style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              backgroundColor: actionMode == 'expel'
                                  ? AppColors.bloodRedLight.withAlpha(89)
                                  : null,
                              side: BorderSide(
                                color: actionMode == 'expel' ? AppColors.bloodRedLight : Colors.white24,
                              ),
                            ),
                            onPressed: () => setDialogState(() => actionMode = 'expel'),
                            child: Text('اخراجِ مستقیم'.tr, style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    if (actionMode == 'discipline')
                      Text(
                        nextStage >= 4
                            ? 'این چهارمین تخلفشه؛ همین الان از بازی اخراج می‌شه.'
                            : 'نتیجه‌ی این تنبیه: ${disciplineStageLabel(nextStage)}',
                        style: TextStyle(color: AppTheme.uiPrimaryLight, fontSize: 13),
                      )
                    else if (actionMode == 'revokeVote')
                      Text(
                        'تا پایانِ امروز نمی‌تونه تو رأی‌گیریِ حذف/دفاعیه رأی بده؛ فردا خودکار برمی‌گرده.'.tr,
                        style: TextStyle(color: AppTheme.uiPrimaryLight, fontSize: 13),
                      )
                    else
                      Text(
                        'اخراجِ فوری و برگشت‌ناپذیر — بدونِ عبور از مراحلِ درجه‌بندی‌شده.'.tr,
                        style: TextStyle(color: AppColors.bloodRedLight, fontSize: 13),
                      ),
                    SizedBox(height: 8),
                    TextField(
                      controller: reasonController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(hintText: 'دلیل (مثلاً حرفِ خارج از نوبت، تقلب)'.tr),
                    ),
                  ],
                ],
              ),
            ),
                Row(
                  children: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('انصراف'.tr.tr),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: actionMode == 'expel' ? AppColors.bloodRedLight : AppTheme.uiPrimary,
                  // باگِ قبلی: چون foregroundColor ست نبود، تمِ سراسری
                  // (colorScheme.primary=طلایی) فونتِ دکمه رو هم طلایی
                  // می‌کرد — یعنی رو حالتِ «تنبیه» (پس‌زمینه‌ی طلایی)
                  // فونت با پس‌زمینه قاطی و نامرئی می‌شد.
                  foregroundColor: actionMode == 'expel' ? Colors.white : Colors.black,
                ),
                onPressed: selectedTarget != null
                    ? () {
                        final reason = reasonController.text.trim().isEmpty
                            ? 'نامشخص'
                            : reasonController.text.trim();
                        final String resultMessage;
                        switch (actionMode) {
                          case 'expel':
                            controller.disciplinaryExpel(selectedTarget!.id, reason);
                            resultMessage = controller.disciplinaryExpelMessage ?? '';
                            break;
                          case 'revokeVote':
                            resultMessage = controller.revokeVotingRights(selectedTarget!.id, reason);
                            break;
                          default:
                            resultMessage = controller.applyNextDisciplineStage(selectedTarget!.id, reason);
                        }
                        Navigator.of(dialogContext).pop();
                        if (resultMessage.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(resultMessage)),
                          );
                        }
                      }
                    : null,
                child: Text(actionMode == 'expel' ? 'اخراج' : (actionMode == 'revokeVote' ? 'گرفتنِ حقِ رأی' : 'اعمالِ تنبیه')),
              ),
                  ],
                ),
              ],
            ),
          ),
          );
        },
      ),
    );
  }

  /// ذخیره‌ی نتیجه‌ی بازی تو تاریخچه‌ی دائمی — مشترک بینِ ثبتِ دستیِ
  /// گرداننده (دیالوگِ پایینی، انتخابِ تیم) و ثبتِ خودکارِ پایانِ
  /// خودکارِ بازی (_confirmAutoGameOver).
  Future<void> _saveGameHistoryEntry(String winnerId) async {
    final entry = GameHistoryEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      scenarioId: controller.settings.scenarioId,
      playedAt: DateTime.now(),
      winningTeamId: winnerId,
      location: controller.settings.location,
      players: controller.players
          .map(
            (p) => GameHistoryPlayerRecord(
              rosterId: p.rosterId,
              name: p.name,
              teamId: p.teamId,
              roleId: p.roleId,
              survived: p.isAlive,
              wasOnWinningSide: p.teamId == winnerId,
              disciplineStage: p.disciplineStage,
              totalScore: p.scoreTotal,
              challengesGiven: p.challengesGivenTotal,
              challengesReceived: p.challengesReceivedTotal,
              totalSpeakingSeconds: p.totalSpeakingSeconds,
              scoreEvents: List.of(p.scoreEvents),
            ),
          )
          .toList(),
    );
    await _storage.addHistoryEntry(entry);
  }

  /// ثبتِ دستیِ نتیجه‌ی بازی (دکمه‌ی 🏁) — اینجا گرداننده خودش تیمِ
  /// برنده رو مشخص می‌کنه، چون این مسیر برای وقتیه که خودِ گرداننده
  /// (نه تریگرِ خودکار) تشخیص داده بازی تموم شده؛ اپ نمی‌دونه کدوم تیم
  /// برده. برای پایانِ خودکارِ بازی (وقتی autoDetectedWinnerTeamId از
  /// قبل با قطعیت مشخصه)، این دیالوگ اصلاً لازم نیست — _confirmAutoGameOver
  /// رو ببین.
  void _showEndGameDialog({String? preselectedTeamId}) {
    final presentTeamIds = controller.players.map((p) => p.teamId).toSet().toList();
    String? selectedTeamId = preselectedTeamId;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: BoxConstraints(maxWidth: 520),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.uiCard,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppTheme.uiPrimary.withAlpha(56)),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(89), blurRadius: 28, offset: Offset(0, 14)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58, height: 58,
                  decoration: BoxDecoration(
                    color: AppTheme.uiPrimaryDark.withAlpha(56),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.uiPrimary.withAlpha(64)),
                  ),
                  child: Icon(Icons.flag_rounded, color: AppTheme.uiPrimaryLight, size: 29),
                ),
                SizedBox(height: 14),
                Text('پایانِ بازی و ثبت'.tr, style: AppTheme.headingFont(size: 22)),
                SizedBox(height: 7),
                Text(
                  'تیم برنده را مشخص کن. نتیجه در تاریخچه و آمار ثبت می‌شود.'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12, height: 1.5),
                ),
                SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('تیمِ برنده'.tr, style: AppTheme.headingFont(size: 14)),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedTeamId,
                  isExpanded: true,
                  dropdownColor: AppTheme.uiCard,
                  decoration: InputDecoration(
                    hintText: 'انتخابِ تیمِ برنده'.tr,
                    prefixIcon: Icon(Icons.emoji_events_rounded, color: AppTheme.uiPrimaryLight),
                    filled: true,
                    fillColor: AppTheme.uiSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppTheme.uiPrimary.withAlpha(41)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppTheme.uiPrimary.withAlpha(41)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppTheme.uiPrimary, width: 1.2),
                    ),
                  ),
                  items: [
                    ...presentTeamIds.map(
                      (teamId) => DropdownMenuItem(
                        value: teamId,
                        child: Text(GameTeams.byId(teamId)?.name ?? teamId),
                      ),
                    ),
                    DropdownMenuItem(value: 'unknown', child: Text('نامشخص'.tr)),
                  ],
                  onChanged: (v) => setDialogState(() => selectedTeamId = v),
                ),
                SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text('انصراف'.tr.tr),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Game3DButton(
                        label: 'ثبت نتیجه',
                        icon: Icons.check_rounded,
                        onPressed: selectedTeamId == null
                            ? null
                            : () async {
                                final winnerId = selectedTeamId!;
                                if (controller.autoDetectedWinnerTeamId == null) {
                                  controller.awardSurvivalBonus(winnerId);
                                }
                                await _saveGameHistoryEntry(winnerId);
                                if (!dialogContext.mounted) return;
                                Navigator.of(dialogContext).pop();
                                if (!mounted) return;
                                final team = GameTeams.byId(winnerId);
                                await showDialog<void>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (confirmContext) => Dialog(
                                    backgroundColor: Colors.transparent,
                                    insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                                    child: Container(
                                      padding: EdgeInsets.all(22),
                                      decoration: BoxDecoration(
                                        color: AppTheme.uiCard,
                                        borderRadius: BorderRadius.circular(26),
                                        border: Border.all(color: AppTheme.uiPrimary.withAlpha(56)),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 64, height: 64,
                                            decoration: BoxDecoration(
                                              color: (team?.color ?? AppTheme.uiPrimary).withAlpha(41),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.emoji_events_rounded,
                                              color: team?.color ?? AppTheme.uiPrimaryLight,
                                              size: 34,
                                            ),
                                          ),
                                          SizedBox(height: 14),
                                          Text('بازی تموم شد'.tr, style: AppTheme.headingFont(size: 23)),
                                          SizedBox(height: 8),
                                          Text(
                                            'بردِ تیمِ ${team?.name ?? 'نامشخص'} ثبت شد.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: team?.color ?? Colors.white70,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'نتیجه در تاریخچه ذخیره شد.'.tr,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12),
                                          ),
                                          SizedBox(height: 16),
                                          _bestWorstRow(controller.players),
                                          SizedBox(height: 12),
                                          _scoreDetailButton(confirmContext, controller.players),
                                          SizedBox(height: 16),
                                          SizedBox(
                                            width: double.infinity,
                                            child: Game3DButton(
                                              label: 'تأیید و بازگشت به منو',
                                              icon: Icons.home_rounded,
                                              onPressed: () => Navigator.of(confirmContext).pop(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                                if (!mounted) return;
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (controller.phase) {
      case GamePhaseType.introDay:
        return _buildSpeakingPhase(isIntro: true);
      case GamePhaseType.introNight:
        return _buildIntroNight();
      case GamePhaseType.day:
        if (controller.autoDetectedWinnerTeamId != null) return _buildGameOverScreen();
        if (controller.pendingDiscloserPlayerId != null) return _buildDiscloserPrompt();
        if (controller.chaosPhaseActive) return _buildChaosPhase();
        if (controller.lastResolution != null) return _buildDayResolved();
        if (controller.isSecondVoteRound) return _buildEliminationVoteSequence();
        if (controller.inDefense && !controller.defenseAnnouncementShown) {
          return _buildDefenseAnnouncement();
        }
        if (controller.inDefense) return _buildDefensePhase();
        if (controller.votingStarted) return _buildEliminationVoteSequence();
        if (controller.isSpeakingRoundDone && controller.bombPendingResolution) {
          return _buildBombResolutionPhase();
        }
        if (controller.isSpeakingRoundDone && controller.referendumScheduledToday) {
          return _buildReferendumPhase();
        }
        if (controller.isSpeakingRoundDone) return _buildStartVoteButton();
        return _buildSpeakingPhase(isIntro: false);
      case GamePhaseType.night:
        return _buildNightPhase();
    }
  }

  // ---------- روز معارفه / روزهای عادی: نوبت صحبت ----------

  Widget _buildSpeakingPhase({required bool isIntro}) {
    final speaker = controller.speakerForDisplay;
    final isChallenge = controller.activeChallengerId != null;

    if (speaker == null) {
      return isIntro ? _buildStartIntroNightButton() : _buildStartVoteButton();
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          if (!isIntro && controller.guaranteedPlayerId != null)
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.uiPrimaryDark.withAlpha(77),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🛡️ «${controller.playerById(controller.guaranteedPlayerId!).name}» تضمینِ ${GameRoles.byId(controller.playerById(controller.guaranteedPlayerId!).roleId!)?.name ?? "قهرمانِ ملی"} رو داره؛ '
                'امروز نمی‌تونه رأی بیاره و در امانه.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.uiPrimaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (!isIntro && controller.referendumScheduledToday)
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.uiPrimaryDark.withAlpha(77),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🗳️ امروز، درست قبل از شروعِ رأی‌گیریِ حذف، رفراندومِ انتخابِ رهبرِ جامعه برگزار می‌شه.'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.uiPrimaryLight, fontWeight: FontWeight.bold),
              ),
            ),
          if (!isIntro && controller.assassinationResultMessage != null)
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                controller.assassinationResultMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.bloodRedLight, fontWeight: FontWeight.bold),
              ),
            ),
          if (!isIntro && controller.gunFireResultMessage != null)
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                controller.gunFireResultMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.uiPrimaryLight, fontWeight: FontWeight.bold),
              ),
            ),
          if (!isIntro && controller.armedPlayers.isNotEmpty) _buildGunBanner(),
          if (!isIntro && controller.canAssassinateNow) _buildMercenaryDayBanner(),
          if (!isIntro && controller.bombTargetId != null && !controller.bombFullyResolved)
            _buildBombDayBanner(),
          if (!isIntro && controller.activeExecutionWord != null) _buildExecutionWordBanner(),
          if (isIntro)
            Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                'هر بازیکن به ترتیب، خودش رو معرفی می‌کنه.'.tr,
                style: TextStyle(color: Colors.white60),
              ),
            ),
          ModernSpeakingPanel(
            key: ValueKey('${speaker.id}-$isChallenge'),
            speakerName: speaker.name,
            remainingPlayers: controller.alivePlayers
                .where((p) => !p.hasSpokenThisRound && p.id != speaker.id)
                .length,
            seconds: controller.currentTurnSeconds,
            challengeActive: isChallenge,
            onNext: () {
              MusicService.instance.stopAlert();
              if (isChallenge) {
                controller.finishChallenge();
              } else {
                controller.advanceSpeaker();
              }
            },
            onChooseChallenge: (!isIntro &&
                    !isChallenge &&
                    controller.challengeEligiblePlayers.isNotEmpty &&
                    controller.canCurrentSpeakerGiveChallenge)
                ? () {
                    MusicService.instance.stopAlert();
                    _showChallengePicker();
                  }
                : null,
            onSecondElapsed: () => controller.addSpeakingSecond(speaker.id),
            nextLabel: isChallenge ? 'پایان چالش' : 'نفر بعدی',
            eyebrow: isIntro ? 'معارفه' : 'نوبت صحبت',
          ),
          if (controller.todaysChallenges.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              'چالش‌های امروز:\n${controller.todaysChallenges.map((c) => '${controller.playerById(c.giverId).name} ← چالش داد به → ${controller.playerById(c.receiverId).name}').join('\n')}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  /// جعبه‌ابزارِ مشترکِ همه‌ی «انتخابِ یه بازیکن از لیست» — قبلاً هرکدوم
  /// جدا نوشته شده بودن و بدونِ اسکرول، که با تعدادِ بازیکنِ واقعی
  /// (۹+ نفر) از پایین overflow می‌کردن. اینجا هم isScrollControlled
  /// هست هم خودِ لیست تو یه Expanded(ListView) ـه، پس هر تعداد بازیکن
  /// جا می‌شه و اسکرول می‌خوره.
  void _showPlayerListPicker({
    required String title,
    required List<SessionPlayer> targets,
    required ValueChanged<SessionPlayer> onSelected,
    String emptyMessage = 'الان کسی برای انتخاب نیست.',
    String Function(SessionPlayer)? labelBuilder,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.52,
        maxChildSize: 0.88,
        minChildSize: 0.36,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppTheme.uiSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                SizedBox(height: 10),
                Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(99))),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(color: AppTheme.uiPrimaryDark.withAlpha(64), shape: BoxShape.circle, border: Border.all(color: AppTheme.uiPrimary.withAlpha(64))),
                        child: Icon(Icons.people_alt_rounded, color: AppTheme.uiPrimaryLight),
                      ),
                      SizedBox(width: 10),
                      Expanded(child: Text(title, style: AppTheme.headingFont(size: 19))),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: AppTheme.uiCard, borderRadius: BorderRadius.circular(99)),
                        child: Text('${targets.length} نفر', style: TextStyle(color: AppTheme.uiMutedText, fontSize: 11)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: targets.isEmpty
                      ? Center(child: Padding(padding: EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.person_off_rounded, color: AppTheme.uiMutedText, size: 38),
                          SizedBox(height: 10),
                          Text(emptyMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.white38)),
                        ])))
                      : ListView.separated(
                          controller: scrollController,
                          padding: EdgeInsets.fromLTRB(16, 4, 16, 20),
                          itemCount: targets.length,
                          separatorBuilder: (_, __) => SizedBox(height: 8),
                          itemBuilder: (_, index) {
                            final p = targets[index];
                            final label = labelBuilder != null ? labelBuilder(p) : p.name;
                            return Material(
                              color: AppTheme.uiCard,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () { Navigator.of(sheetContext).pop(); onSelected(p); },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Row(children: [
                                    Container(width: 38, height: 38, decoration: BoxDecoration(color: AppTheme.uiPrimaryDark.withAlpha(56), shape: BoxShape.circle), child: Center(child: Text('${index + 1}', style: TextStyle(color: AppTheme.uiPrimaryLight, fontWeight: FontWeight.w800)))),
                                    SizedBox(width: 12),
                                    Expanded(child: Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                                    Icon(Icons.chevron_left_rounded, color: Colors.white38),
                                  ]),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );;
  }

  void _showChallengePicker() {
    _showPlayerListPicker(
      title: 'کدوم بازیکن چالش می‌گیره؟',
      targets: controller.challengeEligiblePlayers,
      onSelected: (p) => controller.useChallenge(p.id),
    );
  }

  Widget _buildStartVoteButton() {
    final notices = <Widget>[];
    if (controller.guaranteedPlayerId != null) {
      final player = controller.playerById(controller.guaranteedPlayerId!);
      final roleName = GameRoles.byId(player.roleId!)?.name ?? 'قهرمانِ ملی';
      notices.add(_modernNotice(
        icon: Icons.shield_rounded,
        text: '«' + player.name + '» تضمینِ ' + roleName + ' رو داره؛ امروز نمی‌تونه رأی بیاره و در امانه.',
      ));
    }
    if (controller.assassinationResultMessage != null) {
      notices.add(_modernNotice(icon: Icons.gavel_rounded, text: controller.assassinationResultMessage!, danger: true));
    }
    if (controller.gunFireResultMessage != null) {
      notices.add(_modernNotice(icon: Icons.gps_fixed_rounded, text: controller.gunFireResultMessage!));
    }
    if (controller.communityLeaderExpulsionMessage != null) {
      notices.add(_modernNotice(icon: Icons.person_remove_rounded, text: controller.communityLeaderExpulsionMessage!));
    }
    if (controller.discloserAnnouncement != null) {
      notices.add(_modernNotice(icon: Icons.visibility_rounded, text: controller.discloserAnnouncement!));
    }

    return ModernNightPanel(
      eyebrow: 'روز ' + controller.roundNumber.toString() + ' • آماده‌سازی',
      title: 'همه صحبت کردند',
      icon: Icons.how_to_vote_rounded,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'مرحله‌ی صحبت تمام شده. قبل از رأی‌گیری، رویدادهای فعال امروز رو مرور کن.'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
          if (notices.isNotEmpty) ...[
            SizedBox(height: 14),
            ...notices.map((w) => Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: w,
            )),
          ],
          if (controller.armedPlayers.isNotEmpty) ...[
            SizedBox(height: 4),
            _buildGunBanner(),
          ],
          if (controller.canAssassinateNow) ...[
            SizedBox(height: 8),
            _buildMercenaryDayBanner(),
          ],
          if (controller.activeExecutionWord != null) ...[
            SizedBox(height: 8),
            _buildExecutionWordBanner(),
          ],
        ],
      ),
      actionLabel: 'شروع رأی‌گیری',
      onAction: controller.startVoting,
    );
  }

  Widget _modernNotice({required IconData icon, required String text, bool danger = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: (danger ? AppColors.bloodRed : AppTheme.uiPrimaryDark).withAlpha(41),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (danger ? AppColors.bloodRedLight : AppTheme.uiPrimary).withAlpha(77),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: danger ? AppColors.bloodRedLight : AppTheme.uiPrimaryLight, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.white, fontSize: 12, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartIntroNightButton() {
    return ModernNightPanel(
      eyebrow: 'معارفه • پایان مرحله',
      title: 'همه معارفه کردند',
      icon: Icons.nightlight_round,
      body: Text(
        'معارفه‌ی بازیکنان تمام شد. حالا گرداننده می‌تونه وارد شب معارفه بشه.'.tr,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70, height: 1.5),
      ),
      actionLabel: 'ادامه به شب معارفه',
      onAction: controller.moveToIntroNight,
    );
  }

  Widget _buildGunBanner() {
    final armed = controller.armedPlayers;
    return _buildDayEventBanner(
      icon: Icons.gps_fixed_rounded,
      title: 'اسلحه آماده‌ی شلیک است',
      description: 'دارندگان اسلحه: ${armed.map((p) => p.name).join('، ')}',
      actionLabel: 'اعلامِ اسلحه و شلیک',
      onAction: _showFireGunDialog,
    );
  }

  Widget _buildDayEventBanner({
    required IconData icon,
    required String title,
    required String description,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bloodRed.withAlpha(51),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.bloodRedLight.withAlpha(140)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.bloodRedLight.withAlpha(46),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.bloodRedLight, size: 21),
          ),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: Game3DButton(
                      label: actionLabel,
                      icon: Icons.arrow_back_rounded,
                      onPressed: onAction,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMercenaryDayBanner() {
    final merc = controller.mercenaryPlayer!;
    return _buildDayEventBanner(
      icon: Icons.gavel_rounded,
      title: 'مزدور لباس‌شخصی آماده‌ی ترور است',
      description: 'این قابلیت فقط تا قبل از شروع رأی‌گیری در دسترس است.',
      actionLabel: 'ترور',
      onAction: () => _showAssassinatePicker(merc),
    );
  }

  void _showFireGunDialog() {
    final shooters = controller.armedPlayers;
    SessionPlayer? selectedShooter;
    SessionPlayer? selectedTarget;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final targets = controller.alivePlayers
              .where((p) => p.id != selectedShooter?.id)
              .toList();
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.uiCard,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppTheme.uiPrimary.withAlpha(56)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppColors.bloodRed.withAlpha(71),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.gps_fixed_rounded, color: AppTheme.uiPrimaryLight, size: 29),
                  ),
                  SizedBox(height: 14),
                  Text('اعلامِ اسلحه'.tr, style: AppTheme.headingFont(size: 22)),
                  SizedBox(height: 6),
                  Text(
                    'شلیک‌کننده و هدف را مشخص کن.'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12),
                  ),
                  SizedBox(height: 18),
                  DropdownButtonFormField<SessionPlayer>(
                    value: selectedShooter,
                    isExpanded: true,
                    dropdownColor: AppTheme.uiCard,
                    decoration: InputDecoration(
                      labelText: 'شلیک‌کننده'.tr,
                      prefixIcon: Icon(Icons.person_rounded, color: AppTheme.uiPrimaryLight),
                      filled: true,
                      fillColor: AppTheme.uiSurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    items: shooters
                        .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                        .toList(),
                    onChanged: (v) => setDialogState(() {
                      selectedShooter = v;
                      selectedTarget = null;
                    }),
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<SessionPlayer>(
                    value: selectedTarget,
                    isExpanded: true,
                    dropdownColor: AppTheme.uiCard,
                    decoration: InputDecoration(
                      labelText: 'هدف'.tr,
                      prefixIcon: Icon(Icons.my_location_rounded, color: AppTheme.uiPrimaryLight),
                      filled: true,
                      fillColor: AppTheme.uiSurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    items: targets
                        .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedTarget = v),
                  ),
                  SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: Text('انصراف'.tr.tr),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Game3DButton(
                          label: 'شلیک',
                          icon: Icons.local_fire_department_rounded,
                          onPressed: (selectedShooter != null && selectedTarget != null)
                              ? () {
                                  controller.fireGun(selectedShooter!.id, selectedTarget!.id);
                                  Navigator.of(dialogContext).pop();
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExecutionWordBanner() {
    return _buildDayEventBanner(
      icon: Icons.spellcheck_rounded,
      title: 'حکم اعدام فعال است',
      description: '$_forbiddenWordLabel: «${controller.activeExecutionWord}»',
      actionLabel: 'یکی این کلمه رو گفت!',
      onAction: _showForbiddenWordPicker,
    );
  }

  /// بمب هنوز حل‌نشده‌ست؛ فقط اطلاع‌رسانیه — حل‌وفصلش خودکار، آخرِ همین
  /// روز و قبل از رأی‌گیری، تو _buildBombResolutionPhase انجام می‌شه.
  Widget _buildBombDayBanner() {
    final target = controller.bombTargetPlayer;
    if (target == null) return SizedBox.shrink();
    return _buildDayEventBanner(
      icon: Icons.warning_amber_rounded,
      title: 'بمب فعال است',
      description: 'بمب جلوی «${target.name}» گذاشته شده و آخرِ همین روز، قبل از رأی‌گیری، خودکار حل‌وفصل می‌شود.',
    );
  }

  void _showForbiddenWordPicker() {
    _showPlayerListPicker(
      title: 'کی این کلمه رو گفت؟',
      targets: controller.alivePlayers,
      onSelected: (p) => controller.executePlayerForForbiddenWord(p.id),
    );
  }

  // ---------- شب معارفه ----------

  Widget _buildIntroNight() {
    final conspiracyTeamId = controller.leaderTeamId;
    final wakingMembers = controller.players
        .where((p) => p.teamId == conspiracyTeamId && !p.isModiri)
        .toList();

    return ModernNightPanel(
      eyebrow: 'شب معارفه',
      title: 'اعضای ${controller.scenario.localizedName} بیدار شوند',
      icon: Icons.groups_rounded,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'اعضای ${controller.scenario.leaderLabel} بیدار بشن و همدیگه رو ببینن:',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          SizedBox(height: 14),
          ...wakingMembers.asMap().entries.map(
            (entry) => Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.bloodRed.withAlpha(61),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.bloodRedLight.withAlpha(89)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.bloodRedLight.withAlpha(51),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${entry.key + 1}',
                      style: TextStyle(color: AppTheme.uiPrimaryLight, fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(child: Text(entry.value.name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                  if (entry.value.roleId != null)
                    Text(
                      GameRoles.byId(entry.value.roleId!)?.name ?? '',
                      style: TextStyle(color: AppTheme.uiPrimaryLight, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 6),
          Center(
            child: Text('فرصت برای مشورت'.tr, style: TextStyle(color: Colors.white38, fontSize: 11)),
          ),
        ],
      ),
      actionLabel: 'ادامه به روز اول',
      onAction: () => controller.moveToDay(1),
    );
  }

  // ---------- رأی‌گیری (دور اول یا دوم) ----------

  // ---------- رأی‌گیریِ دورِ اول، نفربه‌نفر ----------

  // VOTING_UI_V2 — ظاهرِ مدرنِ رأی‌گیری؛ منطقِ Controller دست‌نخورده است.
  Widget _buildEliminationVoteSequence() {
    final subject = controller.currentVoteSequenceSubject;
    if (subject == null) {
      return Center(child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppTheme.uiCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.uiPrimary.withAlpha(89))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 64, height: 64, decoration: BoxDecoration(color: AppTheme.uiPrimaryDark.withAlpha(64), shape: BoxShape.circle), child: Icon(Icons.how_to_vote_rounded, color: AppTheme.uiPrimaryLight, size: 32)),
          SizedBox(height: 16),
          Text('رأی‌گیری تمام شد'.tr, style: AppTheme.headingFont(size: 22)),
          SizedBox(height: 6),
          Text('رأی همه‌ی بازیکنان ثبت شده؛ نتیجه را محاسبه کن.'.tr, textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, fontSize: 13)),
          SizedBox(height: 20),
          SizedBox(width: double.infinity, child: Game3DButton(label: 'محاسبه‌ی نتیجه', icon: Icons.checklist_rounded, onPressed: controller.isSecondVoteRound ? controller.resolveSecondVoteRound : controller.resolveFirstVoteRound)),
        ]),
      ));
    }
    final electors = controller.voteSequenceElectors;
    final totalSubjects = controller.voteSequenceSubjects.length;
    final currentIndex = controller.voteSequenceIndex + 1;
    final progress = totalSubjects == 0 ? 0.0 : currentIndex / totalSubjects;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (controller.gunExplosionSummary != null) Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(color: AppColors.bloodRed.withAlpha(89), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.bloodRedLight.withAlpha(204))),
        child: Row(children: [Icon(Icons.warning_amber_rounded, color: AppColors.bloodRedLight, size: 20), SizedBox(width: 9), Expanded(child: Text(controller.gunExplosionSummary!, textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 12, height: 1.35)))]),
      ),
      Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.uiCard, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppTheme.uiPrimary.withAlpha(71))), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: controller.isSecondVoteRound ? AppColors.bloodRed.withAlpha(115) : AppTheme.uiPrimaryDark.withAlpha(71), borderRadius: BorderRadius.circular(20)), child: Text(controller.isSecondVoteRound ? 'دور دوم' : 'رأی‌گیری حذف', style: TextStyle(color: controller.isSecondVoteRound ? AppColors.bloodRedLight : AppTheme.uiPrimaryLight, fontWeight: FontWeight.w800, fontSize: 11))), Spacer(), Text('$currentIndex / $totalSubjects', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w700, fontSize: 12))]),
        SizedBox(height: 12), ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0), minHeight: 6, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.uiPrimary))),
        SizedBox(height: 18), Text('موضوعِ رأی'.tr, style: TextStyle(color: Colors.white54, fontSize: 11)), SizedBox(height: 4), Text(subject.name, textAlign: TextAlign.right, style: AppTheme.headingFont(size: 25)), SizedBox(height: 8),
        Row(children: [Icon(Icons.how_to_vote_rounded, color: AppTheme.uiPrimaryLight, size: 18), SizedBox(width: 7), Text('${subject.votes} رأی', style: TextStyle(color: AppTheme.uiPrimaryLight, fontWeight: FontWeight.w800)), SizedBox(width: 8), Text('•', style: TextStyle(color: Colors.white24)), SizedBox(width: 8), Expanded(child: Text('رأی‌دهنده‌هایی را که علیه این بازیکن رأی داده‌اند انتخاب کن.'.tr, style: TextStyle(color: Colors.white54, fontSize: 11)))]),
      ])),
      SizedBox(height: 12),
      Expanded(child: electors.isEmpty ? Center(child: Text('رأی‌دهنده‌ای برای ثبت وجود ندارد.'.tr, style: TextStyle(color: Colors.white38))) : GridView.builder(padding: EdgeInsets.only(bottom: 4), gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 190, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.45), itemCount: electors.length, itemBuilder: (context, index) { final e=electors[index]; final isSelected=controller.votersAgainstCurrentSubject.contains(e.id); final enabled=controller.electorCanActOnCurrentSubject(e); return _voteCandidateButton(e, isSelected: isSelected, enabled: enabled, onTap: () => controller.toggleVoterForCurrentSubject(e.id)); })),
      SizedBox(height: 10), SafeArea(top: false, child: SizedBox(width: double.infinity, child: Game3DButton(label: 'نفر بعدی', icon: Icons.arrow_back_rounded, onPressed: controller.advanceVoteSequence))),
    ]);
  }

  Widget _voteCandidateButton(SessionPlayer c, {required bool isSelected, required bool enabled, required VoidCallback onTap}) {
    final isLocked=!enabled; final palette=isSelected ? Game3DPalette.danger : Game3DPalette.gold; final colors=Game3DColors.of(palette);
    return Game3DSurface(onPressed: enabled ? onTap : null, palette: palette, depth: enabled ? 5 : 2, borderRadius: BorderRadius.circular(18), padding: EdgeInsets.all(3), semanticLabel: c.name, child: Container(
      decoration: BoxDecoration(color: isSelected ? AppColors.bloodRed.withAlpha(89) : Colors.black.withAlpha(31), borderRadius: BorderRadius.circular(15), border: Border.all(color: isSelected ? AppColors.bloodRedLight : Colors.white.withOpacity(enabled ? 0.08 : 0.04), width: isSelected ? 1.4 : 1)),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 9), child: Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: isSelected ? AppColors.bloodRedLight.withAlpha(71) : Colors.white.withAlpha(13), shape: BoxShape.circle), child: Icon(isSelected ? Icons.check_rounded : (isLocked ? Icons.lock_outline_rounded : Icons.person_outline_rounded), color: isSelected ? AppColors.bloodRedLight : (isLocked ? Colors.white24 : colors.text), size: 20)),
        SizedBox(width: 9), Expanded(child: Text(c.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: isLocked ? Colors.white30 : Colors.white, fontWeight: FontWeight.w800, fontSize: 13, height: 1.2))),
      ])));
  }

  // ---------- رفراندومِ فعالِ مدنی (روزِ بعد از درخواست، قبل از رأی‌گیریِ حذف) ----------

  Widget _buildReferendumPhase() {
    if (controller.communityLeaderId == null) {
      return _buildReferendumVoting();
    }
    return _buildCommunityLeaderChoice();
  }

  Widget _buildReferendumVoting() {
    final voter = controller.currentReferendumVoter;
    final isRunoff = controller.isReferendumRunoff;

    if (voter == null) {
      return ModernNightPanel(
        eyebrow: 'رفراندوم • پایان رأی‌گیری',
        title: 'رأی‌گیری رهبر تمام شد',
        icon: Icons.how_to_vote_rounded,
        body: Text(
          'رأی همه‌ی بازیکنان ثبت شده. نتیجه را محاسبه کن تا رهبر جامعه مشخص شود.'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actionLabel: 'تعیینِ رهبر',
        onAction: controller.resolveReferendumRound,
      );
    }

    final candidates = controller.referendumCandidates;
    final currentIndex = controller.referendumVoterIndex + 1;
    final totalVoters = controller.referendumVoters.length;
    final progress = totalVoters == 0 ? 0.0 : currentIndex / totalVoters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.uiCard,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.uiPrimary.withAlpha(71)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isRunoff ? AppColors.bloodRed.withAlpha(89) : AppTheme.uiPrimaryDark.withAlpha(71),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(isRunoff ? 'رأی‌گیری مجدد' : 'انتخاب رهبر', style: TextStyle(color: isRunoff ? AppColors.bloodRedLight : AppTheme.uiPrimaryLight, fontWeight: FontWeight.w800, fontSize: 11)),
                ),
                Spacer(),
                Text('$currentIndex / $totalVoters', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w700, fontSize: 12)),
              ]),
              SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0), minHeight: 6, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.uiPrimary)),
              ),
              SizedBox(height: 16),
              Text(isRunoff ? 'رفراندومِ مجدد به‌دلیل تساوی' : 'رفراندوم: انتخابِ رهبرِ جامعه', textAlign: TextAlign.center, style: AppTheme.headingFont(size: 19)),
              if (isRunoff) ...[
                SizedBox(height: 5),
                Text('فقط بین نامزدهای مساوی دوباره رأی می‌گیریم.'.tr, textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 11)),
              ],
              SizedBox(height: 14),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: AppTheme.uiPrimaryDark.withAlpha(38), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.uiPrimary.withAlpha(61))),
                child: Row(children: [
                  Icon(Icons.how_to_vote_rounded, color: AppTheme.uiPrimaryLight, size: 22),
                  SizedBox(width: 10),
                  Expanded(child: Text('انتخابِ رهبری برای «${voter.name}»', textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                ]),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Expanded(
          child: candidates.isEmpty
              ? Center(child: Text('نامزدی برای انتخاب وجود ندارد.'.tr, style: TextStyle(color: Colors.white38)))
              : GridView.builder(
                  padding: EdgeInsets.only(bottom: 4),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 190, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.45),
                  itemCount: candidates.length,
                  itemBuilder: (context, index) {
                    final candidate = candidates[index];
                    return _voteCandidateButton(candidate, isSelected: false, enabled: candidate.isAlive && candidate.id != voter.id, onTap: () => controller.castReferendumVoteAndAdvance(candidate.id));
                  },
                ),
        ),
      ],
    );
  }
  Widget _buildCommunityLeaderChoice() {
    final leader = controller.playerById(controller.communityLeaderId!);
    final targets = controller.alivePlayers.where((p) => p.id != leader.id).toList();

    return ModernNightPanel(
      eyebrow: 'رفراندوم • تصمیم رهبر',
      title: 'اخراج از جامعه',
      icon: Icons.person_remove_rounded,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.uiPrimaryDark.withAlpha(41),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.uiPrimary.withAlpha(66)),
            ),
            child: Row(
              children: [
                Icon(Icons.workspace_premium_rounded, color: AppTheme.uiPrimaryLight, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'رهبر جامعه: ${leader.name}',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Text(
            'رهبر جامعه یک نفر را برای اخراج انتخاب می‌کند. این حذف قطعی است.'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
          SizedBox(height: 14),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.bloodRed.withAlpha(41),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.bloodRedLight.withAlpha(71)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.bloodRedLight, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'بعد از انتخاب، اخراج بدون رأی‌گیری انجام می‌شود.'.tr,
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14),
          if (targets.isEmpty)
            Padding(
              padding: EdgeInsets.all(18),
              child: Text('بازیکن دیگری برای اخراج باقی نمانده.'.tr, textAlign: TextAlign.center, style: TextStyle(color: Colors.white38)),
            )
          else
            ...targets.map(
              (p) => Padding(
                padding: EdgeInsets.only(bottom: 9),
                child: Game3DSurface(
                  onPressed: () => controller.communityLeaderExpel(p.id),
                  palette: Game3DPalette.gold,
                  depth: 4,
                  borderRadius: BorderRadius.circular(17),
                  padding: EdgeInsets.all(3),
                  semanticLabel: 'اخراج ${p.name}',
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                    decoration: BoxDecoration(color: Colors.black.withAlpha(31), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        Icon(Icons.person_outline_rounded, color: AppTheme.uiPrimaryLight, size: 21),
                        SizedBox(width: 10),
                        Expanded(child: Text(p.name, textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                        Icon(Icons.arrow_back_rounded, color: AppTheme.uiPrimaryLight, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      actionLabel: 'بازگشت به مرحله قبل',
      onAction: null,
    );
  }

  // ---------- دفاعیه ----------

  Widget _buildDiscloserPrompt() {
    final discloser = controller.playerById(controller.pendingDiscloserPlayerId!);
    return ModernNightPanel(
      eyebrow: 'روز • افشاگری',
      title: 'افشاگر از بازی خارج شد',
      icon: Icons.campaign_rounded,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.uiPrimaryDark.withAlpha(36),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.uiPrimary.withAlpha(71)),
            ),
            child: Column(
              children: [
                Text(
                  '«'+discloser.name+'»',
                  textAlign: TextAlign.center,
                  style: AppTheme.headingFont(size: 20),
                ),
                SizedBox(height: 5),
                Text(
                  'افشاگر از بازی خارج شد.'.tr,
                  style: TextStyle(color: AppTheme.uiPrimaryLight, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          SizedBox(height: 14),
          Text(
            'قبل از رفتن، می‌تونه مافیابودن یا نبودنِ یک نفر رو علناً افشا کنه.'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
      actionLabel: 'بله، افشا کنه',
      onAction: () => _showDiscloserPicker(discloser),
    );
  }
  void _showDiscloserPicker(SessionPlayer discloser) {
    _showPlayerListPicker(
      title: 'افشاگر کی رو افشا کنه؟',
      targets: controller.alivePlayers,
      onSelected: (p) => controller.discloserReveal(p.id),
    );
  }

  Widget _buildDefenseAnnouncement() {
    final candidates = controller.defenseCandidates;
    return ModernNightPanel(
      eyebrow: 'رأی‌گیری • دفاعیه',
      title: 'دفاعیه شروع شد',
      icon: Icons.gavel_rounded,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'این بازیکنان وارد مرحله دفاع می‌شوند. هر نفر به‌ترتیب فرصت صحبت دارد.'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
          SizedBox(height: 14),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.bloodRed.withAlpha(36),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.bloodRedLight.withAlpha(71)),
            ),
            child: Row(
              children: [
                Icon(Icons.record_voice_over_rounded, color: AppColors.bloodRedLight, size: 19),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${candidates.length} نفر برای دفاعیه انتخاب شده‌اند',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          ...candidates.asMap().entries.map(
            (entry) => Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withAlpha(18)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.uiPrimaryDark.withAlpha(64),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${entry.key + 1}',
                      style: TextStyle(color: AppTheme.uiPrimaryLight, fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.value.name,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Icon(Icons.mic_none_rounded, color: Colors.white30, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
      actionLabel: 'شروع دفاعیه',
      onAction: controller.acknowledgeDefenseAnnouncement,
    );
  }

  Widget _buildDefensePhase() {
    final speaker = controller.currentDefenseSpeaker;
    final candidates = controller.defenseCandidates;
    if (speaker == null) {
      return Center(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(22),
          decoration: BoxDecoration(color: AppTheme.uiCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.uiPrimary.withAlpha(71))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 62, height: 62, decoration: BoxDecoration(color: AppTheme.uiPrimaryDark.withAlpha(61), shape: BoxShape.circle), child: Icon(Icons.how_to_vote_rounded, color: AppTheme.uiPrimaryLight, size: 31)),
            SizedBox(height: 14),
            Text('دفاعیه تمام شد'.tr, style: AppTheme.headingFont(size: 23)),
            SizedBox(height: 7),
            Text('دفاع همه‌ی افراد ثبت شد. حالا وارد رأی‌گیری نهایی شو.'.tr, textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.5)),
            SizedBox(height: 18),
            SizedBox(width: double.infinity, child: Game3DButton(label: 'شروع رأی‌گیری نهایی', icon: Icons.arrow_back_rounded, onPressed: controller.startSecondVoteRound)),
          ]),
        ),
      );
    }
    final index = candidates.indexWhere((p) => p.id == speaker.id) + 1;
    return ModernDefensePanel(
      key: ValueKey('modern-defense-${speaker.id}'),
      speakerName: speaker.name,
      currentIndex: index.clamp(1, candidates.length),
      totalCandidates: candidates.length,
      seconds: widget.settings.speakSeconds,
      onNext: () {
        MusicService.instance.stopAlert();
        controller.advanceDefenseSpeaker();
      },
      onTimerFinished: () => MusicService.instance.playAlertLoop(),
      onSecondElapsed: () => controller.addSpeakingSecond(speaker.id),
    );
  }

  // ---------- نتیجه‌ی روز ----------

  // ---------- پایانِ خودکارِ بازی / فازِ آشوب ----------

  /// پایانِ خودکارِ بازی: برخلافِ 🏁ی دستی، اینجا تیمِ برنده از قبل با
  /// قطعیت مشخصه (_checkGameEndCondition تشخیصش داده)، پس نیازی به
  /// پرسیدنِ گرداننده نیست — مستقیم ذخیره می‌شه و برمی‌گردیم به منو.
  Future<void> _confirmAutoGameOver(String winnerId) async {
    await _saveGameHistoryEntry(winnerId);
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _buildGameOverScreen() {
    final teamId = controller.autoDetectedWinnerTeamId!;
    final team = GameTeams.byId(teamId);
    return ModernNightPanel(
      eyebrow: 'پایان بازی • نتیجه نهایی',
      title: 'بازی تموم شد!',
      icon: Icons.emoji_events_rounded,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: (team?.color ?? AppTheme.uiPrimary).withAlpha(31),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: (team?.color ?? AppTheme.uiPrimary).withAlpha(89)),
            ),
            child: Column(
              children: [
                Icon(Icons.emoji_events_rounded, color: team?.color ?? AppTheme.uiPrimaryLight, size: 42),
                SizedBox(height: 10),
                Text(
                  '«' + (team?.name ?? teamId) + '» برنده شد',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: team?.color ?? AppTheme.uiPrimaryLight, fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          if (controller.gameEndMessage != null) ...[
            SizedBox(height: 12),
            Text(controller.gameEndMessage!, textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, height: 1.5)),
          ],
          SizedBox(height: 14),
          _bestWorstRow(controller.players),
          SizedBox(height: 10),
          _scoreDetailButton(context, controller.players),
        ],
      ),
      actionLabel: 'تأیید و بازگشت به منو',
      onAction: () => _confirmAutoGameOver(teamId),
    );
  }

  /// کارتِ کوچیکِ بهترین/بدترین بازیکنِ همین بازی، بر اساسِ scoreTotal
  /// (سندِ طراحیِ امتیازدهی). اگه کمتر از ۲ نفر باشن یا امتیازشون مساوی
  /// باشه، چیزی نشون نمی‌ده (فرقی برای نشون‌دادن نیست).
  Widget _bestWorstRow(List<SessionPlayer> players) {
    if (players.length < 2) return SizedBox.shrink();
    final sorted = players.toList()..sort((a, b) => b.scoreTotal.compareTo(a.scoreTotal));
    final best = sorted.first;
    final worst = sorted.last;
    if (best.id == worst.id || best.scoreTotal == worst.scoreTotal) return SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: _miniPlayerScoreCard(
            icon: Icons.star,
            color: AppTheme.uiPrimary,
            title: 'بهترین بازیکن',
            player: best,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _miniPlayerScoreCard(
            icon: Icons.sentiment_very_dissatisfied,
            color: AppColors.bloodRedLight,
            title: 'بدترین بازیکن',
            player: worst,
          ),
        ),
      ],
    );
  }

  Widget _miniPlayerScoreCard({
    required IconData icon,
    required Color color,
    required String title,
    required SessionPlayer player,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.uiCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          SizedBox(height: 4),
          Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(
            player.name,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            '${player.scoreTotal >= 0 ? '+' : ''}${player.scoreTotal} امتیاز',
            style: TextStyle(color: color, fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// دکمه‌ای که صفحه‌ی جزئیاتِ امتیازِ همه‌ی بازیکنان رو باز می‌کنه — هم
  /// از صفحه‌ی پایانِ خودکارِ بازی صدا زده می‌شه، هم از دیالوگِ ثبتِ دستی.
  Widget _scoreDetailButton(BuildContext ctx, List<SessionPlayer> players) {
    return OutlinedButton.icon(
      onPressed: () => Navigator.of(ctx).push(
        MaterialPageRoute(builder: (_) => _PlayerScoreDetailScreen(players: players)),
      ),
      icon: Icon(Icons.list_alt),
      label: Text('جزئیاتِ امتیازِ همه‌ی بازیکنان'.tr.tr),
      style: OutlinedButton.styleFrom(minimumSize: Size.fromHeight(46)),
    );
  }

  Widget _buildChaosPhase() {
    final trio = controller.chaosPhasePlayers;
    if (trio.length != 3) return SizedBox.shrink();
    final a = trio[0];
    final b = trio[1];
    final c = trio[2];

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.uiCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.uiPrimary.withAlpha(61)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(46),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppTheme.uiPrimaryDark.withAlpha(56),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.uiPrimary.withAlpha(71)),
                  ),
                  child: Icon(
                    Icons.cyclone_rounded,
                    color: AppTheme.uiPrimaryLight,
                    size: 28,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرحله ویژه'.tr,
                        style: TextStyle(
                          color: AppTheme.uiPrimaryLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'فازِ آشوب'.tr,
                        style: AppTheme.headingFont(size: 23),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.bloodRed.withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.bloodRedLight.withAlpha(89)),
                  ),
                  child: Text(
                    '۳ نفر'.tr,
                    style: TextStyle(
                      color: AppColors.bloodRedLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 18),
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(31),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withAlpha(18)),
              ),
              child: Text(
                'فقط ۳ نفر باقی موندن. دو نفر باید در زمانِ مشخص با هم به توافق برسن و متحد بشن؛ نفرِ سوم طرفِ مقابله‌ست.'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.55),
              ),
            ),
            SizedBox(height: 16),
            CountdownTimerWidget(
              totalSeconds: controller.settings.speakSeconds * 2,
            ),
            SizedBox(height: 18),
            Text(
              'بعدِ توافق، مشخص کن کدوم دو نفر با هم دست دادن:'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.uiPrimaryLight,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 10),
            _chaosPairButton(a, b),
            _chaosPairButton(a, c),
            _chaosPairButton(b, c),
          ],
        ),
      ),
    );
  }

  Widget _chaosPairButton(SessionPlayer p1, SessionPlayer p2) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(minimumSize: Size.fromHeight(48)),
        onPressed: () => controller.resolveChaosPhase(p1.id, p2.id),
        child: Text('${p1.name}   🤝   ${p2.name}'),
      ),
    );
  }


  Widget _buildDayResolved() {
    return ModernNightPanel(
      eyebrow: 'روز ${controller.roundNumber} • نتیجه',
      title: 'نتیجه‌ی رأی‌گیری',
      icon: Icons.gavel_rounded,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.uiSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.uiPrimary.withAlpha(56)),
            ),
            child: Text(
              controller.lastResolution?.message ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, height: 1.55, fontWeight: FontWeight.w700),
            ),
          ),
          if (controller.discloserAnnouncement != null) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.uiPrimaryDark.withAlpha(41),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.uiPrimary.withAlpha(115)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.campaign_rounded, color: AppTheme.uiPrimaryLight, size: 20),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      controller.discloserAnnouncement!,
                      textAlign: TextAlign.right,
                      style: TextStyle(color: AppTheme.uiPrimaryLight, fontWeight: FontWeight.w700, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 10),
          Text(
            'نتیجه ثبت شد و منطق بازی آماده‌ی ورود به مرحله‌ی بعد است.'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
      actionLabel: 'ورود به شب',
      onAction: () {
        controller.discloserAnnouncement = null;
        controller.moveToNight(controller.roundNumber);
      },
    );
  }

  // ---------- شب (بعد از معارفه) ----------

  Widget _buildNightPhase() {
    if (controller.lastNightSummary != null) {
      return ModernNightPanel(
        eyebrow: 'شب ${controller.roundNumber} • خلاصه',
        title: 'نتیجه‌ی شب آماده است',
        icon: Icons.wb_twilight_rounded,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'این متن رو عیناً به جمع اعلام کن:'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.uiPrimaryLight, fontSize: 12, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(36),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.uiPrimary.withAlpha(89)),
              ),
              child: Text(
                controller.lastNightSummary!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16, height: 1.55, fontWeight: FontWeight.w600),
              ),
            ),
            if (controller.nightPrivateNotes != null) ...[
              SizedBox(height: 14),
              Container(
                padding: EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'یادداشت خصوصی گرداننده'.tr,
                      textAlign: TextAlign.right,
                      style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 6),
                    Text(
                      controller.nightPrivateNotes!,
                      textAlign: TextAlign.right,
                      style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
            if (controller.statusInquiryChargesRemaining > 0 ||
                controller.statusInquiryResultMessage != null) ...[
              SizedBox(height: 14),
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.uiSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.uiPrimary.withAlpha(41)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.fact_check_rounded, color: AppTheme.uiPrimaryLight, size: 19),
                        SizedBox(width: 7),
                        Expanded(
                          child: Text('استعلام وضعیت'.tr, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        ),
                        Text(
                          '${controller.statusInquiryChargesRemaining} تا باقی مانده',
                          style: TextStyle(color: AppTheme.uiPrimaryLight, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    if (controller.statusInquiryResultMessage != null) ...[
                      if (controller.statusInquiryLastVotePassed == true) ...[
                        Text(
                          'استعلام رأی آورد — این رو عیناً اعلام کن:'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.uiPrimaryLight, fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 7),
                      ],
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: controller.statusInquiryLastVotePassed == true
                              ? AppTheme.uiPrimaryDark.withAlpha(41)
                              : Colors.white.withAlpha(6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: controller.statusInquiryLastVotePassed == true
                                ? AppTheme.uiPrimary.withAlpha(140)
                                : Colors.white24,
                          ),
                        ),
                        child: Text(
                          controller.statusInquiryResultMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 13, height: 1.45),
                        ),
                      ),
                    ] else if (controller.statusInquiryVoteOpen) ...[
                      Text(
                        'موافق‌های استعلام: ${controller.statusInquiryYesVotes} از ${controller.aliveCount} نفر زنده',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 190,
                          mainAxisSpacing: 9,
                          crossAxisSpacing: 9,
                          childAspectRatio: 1.45,
                        ),
                        itemCount: controller.alivePlayers.length,
                        itemBuilder: (context, index) {
                          final p = controller.alivePlayers[index];
                          final isSelected = controller.statusInquiryYesVoters.contains(p.id);
                          return _voteCandidateButton(
                            p,
                            isSelected: isSelected,
                            enabled: true,
                            onTap: () => controller.toggleStatusInquiryVoter(p.id),
                          );
                        },
                      ),
                      SizedBox(height: 10),
                      Game3DButton(
                        label: 'ثبت نتیجه‌ی رأی',
                        icon: Icons.check_rounded,
                        onPressed: controller.resolveStatusInquiryVote,
                      ),
                    ] else
                      OutlinedButton.icon(
                        onPressed: controller.openStatusInquiryVote,
                        icon: Icon(Icons.how_to_vote_rounded),
                        label: Text('شروع استعلام وضعیت • ${controller.statusInquiryChargesRemaining} بار'),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actionLabel: 'ادامه به روز ${controller.roundNumber + 1}',
        onAction: () => controller.moveToDay(controller.roundNumber + 1),
      );
    }

    switch (controller.currentNightStep) {
      case NightStepKind.leaderTeam:
        return _buildLeaderTeamStep();
      case NightStepKind.independentLeader:
        return _buildRoleNightStep(
          wakeLabel: '$_independentLeaderRoleName بیدار بشه',
          sleepLabel: '$_independentLeaderRoleName چشمش رو ببنده',
          playerName: controller.independentLeaderPlayer?.name,
          body: _buildIndependentLeaderSection(),
          canAdvance: controller.canAdvancePastIndependentLeaderStep,
        );
      case NightStepKind.rapper:
        return _buildRoleNightStep(
          wakeLabel: '$_rapperRoleName بیدار بشه',
          sleepLabel: '$_rapperRoleName چشمش رو ببنده',
          playerName: controller.rapperPlayer?.name,
          body: _buildRapperSection(),
        );
      case NightStepKind.hacker:
        return _buildRoleNightStep(
          wakeLabel: '$_hackerRoleName بیدار بشه',
          sleepLabel: '$_hackerRoleName چشمش رو ببنده',
          playerName: controller.hackerPlayer?.name,
          body: _buildHackerSection(),
        );
      case NightStepKind.politicalAnalyst:
        return _buildRoleNightStep(
          wakeLabel: '$_politicalAnalystRoleName بیدار بشه',
          sleepLabel: '$_politicalAnalystRoleName چشمش رو ببنده',
          playerName: controller.politicalAnalystPlayer?.name,
          body: _buildPoliticalAnalystSection(),
        );
      case NightStepKind.doctor:
        return _buildRoleNightStep(
          wakeLabel: 'دکتر بیدار بشه',
          sleepLabel: 'دکتر چشمش رو ببنده',
          playerName: controller.doctorPlayer?.name,
          body: _buildDoctorSection(),
        );
      case NightStepKind.rebel:
        return _buildRoleNightStep(
          wakeLabel: '$_rebelRoleName بیدار بشه',
          sleepLabel: '$_rebelRoleName چشمش رو ببنده',
          playerName: controller.rebelPlayer?.name,
          body: _buildRebelSection(),
        );
      case NightStepKind.nationalHero:
        return _buildRoleNightStep(
          wakeLabel: '$_nationalHeroRoleName بیدار بشه',
          sleepLabel: '$_nationalHeroRoleName چشمش رو ببنده',
          playerName: controller.nationalHeroPlayer?.name,
          body: _buildNationalHeroSection(),
        );
      case NightStepKind.revolutionary:
        return _buildRoleNightStep(
          wakeLabel: '$_revolutionaryRoleName بیدار بشه',
          sleepLabel: '$_revolutionaryRoleName چشمش رو ببنده',
          playerName: controller.revolutionaryFighterPlayer?.name,
          body: _buildRevolutionarySection(),
        );
      case NightStepKind.civicActivist:
        return _buildRoleNightStep(
          wakeLabel: '$_civicActivistRoleName بیدار بشه',
          sleepLabel: '$_civicActivistRoleName چشمش رو ببنده',
          playerName: controller.civicActivistPlayer?.name,
          body: _buildCivicActivistSection(),
        );
      case NightStepKind.lawyer:
        return _buildRoleNightStep(
          wakeLabel: '$_lawyerRoleName بیدار بشه',
          sleepLabel: '$_lawyerRoleName چشمش رو ببنده',
          playerName: controller.lawyerPlayer?.name,
          body: _buildLawyerSection(),
        );
      case NightStepKind.done:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'همه‌ی نقش‌ها اقدامِ امشب‌شون رو انجام دادن.'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: controller.finishNight,
                child: Text('پایان شب'.tr),
              ),
            ],
          ),
        );
    }
  }

  /// مرحله‌ی مشترکِ «تیمِ سرکوب بیدار می‌شه»: تصمیمِ ولی‌فقیه + مذاکره‌ی وزیر
  /// امور خارجه + حکمِ اعدامِ رئیس قوه قضاییه، چون هر سه عضوِ همین تیم‌ان.
  /// لیستِ اعضای زنده‌ی تیمِ سرکوب به‌همراهِ نقشِ دقیقشون، برای این‌که
  /// گرداننده مطمئن باشه داره با آدمِ درست حرف می‌زنه.
  Widget _buildLeaderTeamRoster() {
    final leaderTeamId = controller.leaderTeamId;
    final members = controller.alivePlayers.where((p) => p.teamId == leaderTeamId).toList();
    if (members.isEmpty) return SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.uiCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: members.map((p) {
          final role = p.roleId != null ? GameRoles.byId(p.roleId!) : null;
          return Text(
            '👤 ${p.name} — ${role?.name ?? '$_plainLeaderTeamLabel (بدون نقشِ خاص)'}',
            style: TextStyle(color: Colors.white),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLeaderTeamStep() {
    final teamLabel = _leaderTeamName;
    return ModernNightPanel(
      eyebrow: 'شب ${controller.roundNumber}',
      title: 'اعضای $teamLabel بیدار شوند',
      icon: Icons.groups_rounded,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLeaderTeamRoster(),
          SizedBox(height: 14),
          if (controller.leaderTeamDisabledTonight)
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withAlpha(20)),
              ),
              child: Text(
                'امشب تیمِ رهبر قابلیتی ندارد؛ فقط به مرحله‌ی بعد برو.'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, height: 1.5),
              ),
            )
          else ...[
            _buildLeaderDecisionSection(),
            if (controller.canIssueExecutionOrder) ...[
              SizedBox(height: 18),
              Divider(color: Colors.white12),
              SizedBox(height: 10),
              _buildJudiciarySection(),
            ],
            if (controller.interrogatorPlayer != null) ...[
              SizedBox(height: 18),
              Divider(color: Colors.white12),
              SizedBox(height: 10),
              _buildInterrogatorSection(),
            ],
            if (controller.intelligenceMinisterPlayer != null) ...[
              SizedBox(height: 18),
              Divider(color: Colors.white12),
              SizedBox(height: 10),
              _buildIntelQuestionSection(),
            ],
            if (controller.policeCommanderPlayer != null) ...[
              SizedBox(height: 18),
              Divider(color: Colors.white12),
              SizedBox(height: 10),
              _buildDetentionSection(),
            ],
            if (controller.mercenaryPlayer != null &&
                controller.isStillActiveTonight(controller.mercenaryPlayer!)) ...[
              SizedBox(height: 18),
              Divider(color: Colors.white12),
              SizedBox(height: 10),
              _buildMercenaryNightSection(),
            ],
            if (controller.natashaPlayer != null &&
                controller.isStillActiveTonight(controller.natashaPlayer!) &&
                !controller.natashaPlayer!.natashaSilenceUsed) ...[
              SizedBox(height: 18),
              Divider(color: Colors.white12),
              SizedBox(height: 10),
              _buildNatashaSection(),
            ],
            if (controller.saboteurPlayer != null &&
                controller.isStillActiveTonight(controller.saboteurPlayer!)) ...[
              SizedBox(height: 18),
              Divider(color: Colors.white12),
              SizedBox(height: 10),
              _buildSaboteurSection(),
            ],
            if (controller.bomberPlayer != null) ...[
              SizedBox(height: 18),
              Divider(color: Colors.white12),
              SizedBox(height: 10),
              _buildBomberSection(),
            ],
          ],
        ],
      ),
      actionLabel: 'اعضای $teamLabel چشم‌هاشون رو ببندن',
      onAction: controller.canAdvancePastLeaderTeamStep ? controller.advanceNightStep : null,
    );
  }

  /// بخشِ بمب‌گذار تو مرحله‌ی تیمِ رهبر — کاملاً مستقل از شات/سلاخی/مذاکره،
  /// چون یک‌بارمصرفِ کلِ بازیه، نه یه تصمیمِ هرشبه.
  Widget _buildBomberSection() {
    if (controller.bomberChargeUsed) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.uiSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.bloodRedLight.withAlpha(71)),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_rounded, color: AppTheme.uiMutedText),
            SizedBox(width: 12),
            Expanded(child: Text(
              'بمب‌گذار قبلاً بمبش رو کار گذاشته؛ این قابلیت یک‌بارمصرفه و تا حل‌شدنش پیگیری می‌شه.'.tr,
              style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12, height: 1.45),
            )),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.uiCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.uiPrimary.withAlpha(46)),
      ),
      child: Column(
        children: [
          Container(
            width: 58, height: 58,
            decoration: BoxDecoration(color: AppColors.bloodRed.withAlpha(71), shape: BoxShape.circle),
            child: Icon(Icons.local_fire_department_rounded, color: AppTheme.uiPrimaryLight, size: 30),
          ),
          SizedBox(height: 12),
          Text('کارگذاری بمب'.tr, style: AppTheme.headingFont(size: 19)),
          SizedBox(height: 7),
          Text(
            'امشب یک‌بار برای همیشه جلوی یک بازیکن بمب بگذار و رمز خنثی‌سازی ۱ تا ۴ را انتخاب کن.'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12, height: 1.5),
          ),
          SizedBox(height: 14),
          Game3DButton(
            label: 'کارگذاریِ بمب',
            icon: Icons.local_fire_department_rounded,
            onPressed: controller.canPlantBombTonight ? _showBomberPicker : null,
          ),
        ],
      ),
    );
  }


  void _showBomberPicker() {
    _showPlayerListPicker(
      title: 'بمب جلوی کی گذاشته بشه؟',
      targets: controller.alivePlayers,
      onSelected: _showBombCodePicker,
    );
  }

  void _showBombCodePicker(SessionPlayer target) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.uiCard,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppTheme.uiPrimary.withAlpha(56)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: AppTheme.uiPrimaryDark.withAlpha(64), shape: BoxShape.circle),
                child: Icon(Icons.password_rounded, color: AppTheme.uiPrimaryLight, size: 28),
              ),
              SizedBox(height: 12),
              Text('رمزِ خنثی‌سازی'.tr, style: AppTheme.headingFont(size: 20)),
              SizedBox(height: 5),
              Text('یکی از چهار رمز را برای این بمب انتخاب کن.'.tr, style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12)),
              SizedBox(height: 16),
              _buildBombCodeGrid((code) {
                Navigator.of(dialogContext).pop();
                controller.plantBomb(target.id, code);
              }),
            ],
          ),
        ),
      ),
    );
  }


  /// فازِ «خواب نیمروزی»: آخرِ روز، قبل از رأی‌گیری، اگه بمبی هنوز حل‌نشده
  /// باشه. سه شاخه‌ی مکالمه‌ای (هدف=محافظ / پرسیدن از محافظ / حدسِ خودِ
  /// هدف) + یه صفحه‌ی نتیجه‌ی نهایی که با تأییدِ گرداننده می‌ره سراغِ
  /// رأی‌گیری.
  Widget _buildBombResolutionPhase() {
    final target = controller.bombTargetPlayer;
    if (target == null) return SizedBox.shrink();

    if (controller.bombOutcomeMessage != null) {
      return ModernNightPanel(
        eyebrow: 'خواب نیمروزی • نتیجه',
        title: 'نتیجه‌ی بمب',
        icon: Icons.local_fire_department_rounded,
        body: Column(
          children: [
            Text(controller.bombOutcomeMessage!, textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.uiPrimaryLight, fontWeight: FontWeight.w700, fontSize: 15, height: 1.5)),
            SizedBox(height: 10),
            Text('حالا بگو همه چشماشون رو باز کنن.'.tr,
              textAlign: TextAlign.center, style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12)),
          ],
        ),
        actionLabel: 'ادامه به رأی‌گیری',
        actionIcon: Icons.how_to_vote_rounded,
        onAction: controller.acknowledgeBombOutcome,
      );
    }

    Widget branch;
    if (controller.bombTargetIsGuardSelf) {
      branch = _buildBombGuardSelfBranch(target, controller.guardPlayer!);
    } else if (controller.shouldAskGuardForBomb && controller.guardSacrificeAnswer == null) {
      branch = _buildBombAskGuardBranch();
    } else if (controller.shouldAskGuardForBomb && controller.guardSacrificeAnswer == true) {
      branch = _buildBombCodeGuessBranch(guesser: controller.guardPlayer!, forTarget: target);
    } else {
      branch = _buildBombCodeGuessBranch(guesser: target, forTarget: target);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ModernNightPanel(
            eyebrow: 'خواب نیمروزی',
            title: 'حل معمای بمب',
            icon: Icons.lock_clock_rounded,
            body: Text('همه‌ی بازیکن‌ها چشماشون رو ببندن؛ یک تصمیم مخفیانه در جریانه.'.tr,
              textAlign: TextAlign.center, style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12, height: 1.5)),
            actionLabel: 'ادامه‌ی فرایند',
            actionIcon: Icons.arrow_downward_rounded,
            onAction: null,
          ),
          SizedBox(height: 12),
          branch,
        ],
      ),
    );
  }


  Widget _playerBadge(String label, String name) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.uiCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.uiPrimary.withAlpha(102)),
      ),
      child: Text(
        '$label: $name',
        style: TextStyle(color: AppTheme.uiPrimaryLight, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBombGuardSelfBranch(SessionPlayer target, SessionPlayer guard) {
    return ModernNightPanel(
      eyebrow: 'بمب • محافظ',
      title: 'محافظ خودش هدف است',
      icon: Icons.shield_rounded,
      body: Column(
        children: [
          _playerBadge('👤 هدفِ بمب و محافظ، هردو', guard.name),
          SizedBox(height: 14),
          Text('رمز درست را بی‌سروصدا به محافظ نشان بده: ${controller.bombCorrectCode}',
            textAlign: TextAlign.center, style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12, height: 1.5)),
        ],
      ),
      actionLabel: 'تأیید — بمب خنثی شد',
      actionIcon: Icons.verified_rounded,
      onAction: () => controller.resolveBombCode(controller.bombCorrectCode!),
    );
  }


  Widget _buildBombAskGuardBranch() {
    final guard = controller.guardPlayer!;
    return ModernNightPanel(
      eyebrow: 'بمب • تصمیم محافظ',
      title: 'آیا محافظ فدا می‌شود؟',
      icon: Icons.shield_moon_rounded,
      body: Column(
        children: [
          _playerBadge('👤 این نقش (محافظ)', guard.name),
          SizedBox(height: 14),
          Text('محافظ را بی‌سروصدا بیدار کن و بپرس: می‌خواهی برای نجات هدف فدا شوی؟'.tr,
            textAlign: TextAlign.center, style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12, height: 1.5)),
        ],
      ),
      actionLabel: 'بله، فدا می‌شود',
      actionIcon: Icons.shield_rounded,
      onAction: () => controller.recordGuardSacrificeAnswer(true),
    );
  }


  /// چیدمانِ ۲در۲ برای انتخابِ عددِ ۱ تا ۴ (کدِ بمب) — هم موقعِ
  /// گذاشتنِ بمب هم موقعِ حدسِ خنثی‌سازی استفاده می‌شه. دکمه‌های بزرگ
  /// (۸۸×۸۸) و فونتِ درشت، برای انتخابِ راحت‌ترِ روی گوشی.
  Widget _buildBombCodeGrid(void Function(int code) onPicked) {
    Widget codeButton(int code) {
      return Game3DSurface(
        onPressed: () => onPicked(code),
        depth: 6,
        borderRadius: BorderRadius.circular(16),
        padding: EdgeInsets.zero,
        semanticLabel: 'رمز $code',
        child: SizedBox(
          width: 88,
          height: 88,
          child: Center(
            child: Text(
              '$code',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF2A1B02)),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [codeButton(1), SizedBox(width: 16), codeButton(2)],
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [codeButton(3), SizedBox(width: 16), codeButton(4)],
        ),
      ],
    );
  }

  Widget _buildBombCodeGuessBranch({required SessionPlayer guesser, required SessionPlayer forTarget}) {
    final isSelf = guesser.id == forTarget.id;
    return ModernNightPanel(
      eyebrow: 'بمب • حدس رمز',
      title: 'انتخاب رمز خنثی‌سازی',
      icon: Icons.password_rounded,
      body: Column(
        children: [
          _playerBadge(isSelf ? '👤 این نقش (هدف)' : '👤 این نقش (محافظ)', guesser.name),
          SizedBox(height: 14),
          Text(
            isSelf
                ? '«${guesser.name}» باید رمز خنثی‌سازی را حدس بزند:'
                : '«${guesser.name}» به‌جایِ «${forTarget.name}» رمز را حدس می‌زند:',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12, height: 1.5),
          ),
          SizedBox(height: 14),
          _buildBombCodeGrid((code) => controller.resolveBombCode(code)),
        ],
      ),
      actionLabel: 'رمز را انتخاب کن',
      actionIcon: Icons.password_rounded,
      onAction: null,
    );
  }

  /// مرحله‌ی مشترکِ هر نقشِ خاصِ شهروندی که تنها و جداگونه بیدار می‌شه.
  Widget _buildRoleNightStep({
    required String wakeLabel,
    required String sleepLabel,
    required Widget body,
    String? playerName,
    bool canAdvance = true,
  }) {
    return ModernNightPanel(
      eyebrow: 'شب ${controller.roundNumber}',
      title: wakeLabel.replaceFirst('🔓 ', ''),
      playerName: playerName,
      icon: Icons.visibility_rounded,
      body: body,
      actionLabel: sleepLabel,
      onAction: canAdvance ? controller.advanceNightStep : null,
    );
  }

  // ---------- رهبرِ موساد ----------

  Widget _buildIndependentLeaderSection() {
    final leader = controller.independentLeaderPlayer!;

    if (controller.roundNumber == 1) {
      if (leader.independentLeaderPlaystyle != null) {
        return Text(
          leader.independentLeaderPlaystyle == IndependentLeaderPlaystyle.assassination
              ? 'شیوه انتخاب شد: 🕶 عملیاتِ ترور'
              : 'شیوه انتخاب شد: 🗡 عملیاتِ سری',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.uiPrimaryLight, fontWeight: FontWeight.bold),
        );
      }
      return Column(
        children: [
          Text(
            'رهبرِ موساد باید همین امشب، برای همیشه، شیوه‌ی بازیش رو انتخاب کنه:'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(50)),
            onPressed: () => controller.chooseIndependentLeaderPlaystyle(IndependentLeaderPlaystyle.assassination),
            child: Text('🕶 عملیاتِ ترور'.tr),
          ),
          SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(50)),
            onPressed: () => controller.chooseIndependentLeaderPlaystyle(IndependentLeaderPlaystyle.secretOperation),
            child: Text('🗡 عملیاتِ سری'.tr),
          ),
        ],
      );
    }

    if (!controller.isStillActiveTonight(leader)) {
      return Text(
        '$_independentLeaderRoleName دیگه در بازی نیست.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white38),
      );
    }

    final isAssassination = leader.independentLeaderPlaystyle == IndependentLeaderPlaystyle.assassination;
    final resultText = controller.independentLeaderAssassinationResultMessage;
    return Column(
      children: [
        Text(
          isAssassination
              ? 'شیوه: 🕶 عملیاتِ ترور — هدف + حدسِ نقش (فقط رو اعضای سرکوب اثر داره)'
              : 'شیوه: 🗡 عملیاتِ سری — یه شاتِ ساده رو یه بازیکن (زره جلوشو می‌گیره)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        if (isAssassination && resultText != null) ...[
          SizedBox(height: 8),
          Text(
            resultText,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.uiPrimaryLight, fontWeight: FontWeight.bold),
          ),
        ],
        SizedBox(height: 16),
        if (controller.canIndependentLeaderActTonight)
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(50)),
            onPressed: () => isAssassination
                ? _showIndependentLeaderAssassinationPicker(leader)
                : _showIndependentLeaderShootPicker(leader),
            child: Text(isAssassination ? 'ترور (هدف + حدسِ نقش)' : 'شات'),
          )
        else
          Text('امشب دیگه اقدامی ممکن نیست.'.tr, style: TextStyle(color: Colors.white38)),
      ],
    );
  }

  void _showIndependentLeaderAssassinationPicker(SessionPlayer leader) {
    final targets = controller.alivePlayers.where((p) => p.id != leader.id).toList();
    SessionPlayer? selectedTarget;
    String? selectedRoleId;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.uiSurface,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('ترور: هدف + حدسِ نقش'.tr, style: TextStyle(color: AppTheme.uiPrimaryLight)),
                    SizedBox(height: 12),
                    DropdownButton<SessionPlayer>(
                      hint: Text('انتخاب هدف'.tr, style: TextStyle(color: Colors.white70)),
                      dropdownColor: AppTheme.uiSurface,
                      value: selectedTarget,
                      items: targets
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.name, style: TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                      onChanged: (v) => setSheetState(() => selectedTarget = v),
                    ),
                    SizedBox(height: 8),
                    DropdownButton<String>(
                      hint: Text('حدسِ نقش'.tr, style: TextStyle(color: Colors.white70)),
                      dropdownColor: AppTheme.uiSurface,
                      value: selectedRoleId,
                      items: controller.rolesInPlayForTeam(controller.scenario.leaderTeamId)
                          .map((r) => DropdownMenuItem(
                                value: r.id,
                                child: Text(r.name, style: TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                      onChanged: (v) => setSheetState(() => selectedRoleId = v),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: (selectedTarget != null && selectedRoleId != null)
                          ? () {
                              controller.independentLeaderAssassinate(selectedTarget!.id, selectedRoleId!);
                              Navigator.of(context).pop();
                            }
                          : null,
                      child: Text('تایید ترور'.tr),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showIndependentLeaderShootPicker(SessionPlayer leader) {
    _showPlayerListPicker(
      title: 'شات روی کی؟',
      targets: controller.alivePlayers.where((p) => p.id != leader.id).toList(),
      onSelected: (p) => controller.independentLeaderShoot(p.id),
    );
  }

  // ---------- تحلیلگرِ سیاسی ----------

  Widget _buildPoliticalAnalystSection() {
    final result = controller.lastIndependentInvestigationResult;
    final targetName = controller.lastIndependentInvestigationTargetName;
    final membershipQuestion = controller.scenario.independentInvestigationQuestion;
    final membershipYes = controller.scenario.independentInvestigationYes;
    final membershipNo = controller.scenario.independentInvestigationNo;
    return Column(
      children: [
        Text(
          '$_politicalAnalystRoleName می‌تونه امشب یکی از بازیکن‌ها رو استعلام بگیره: '
          'آیا $membershipQuestion؟',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        SizedBox(height: 8),
        if (result != null && targetName != null) ...[
          Text(
            result == InvestigationResult.like
                ? '🔍 نتیجه‌ی «$targetName»: 👍 لایک ($membershipYes)'
                : '🔍 نتیجه‌ی «$targetName»: 👎 دیس‌لایک ($membershipNo)',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.uiPrimaryLight, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'این نتیجه رو فقط خصوصی و درِگوشی به خودِ $_politicalAnalystRoleName بگو.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
          SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          icon: Icon(Icons.travel_explore),
          label: Text('استعلامِ یه بازیکن'.tr.tr),
          onPressed: controller.canPoliticalAnalystActTonight ? _showPoliticalAnalystPicker : null,
        ),
      ],
    );
  }

  void _showPoliticalAnalystPicker() {
    final analyst = controller.politicalAnalystPlayer!;
    _showPlayerListPicker(
      title: 'استعلام روی کی؟',
      targets: controller.alivePlayers.where((p) => p.id != analyst.id).toList(),
      onSelected: (p) => controller.politicalAnalystInvestigate(p.id),
    );
  }

  // ---------- فعالِ مدنی ----------

  Widget _buildCivicActivistSection() {
    final activist = controller.civicActivistPlayer!;
    if (activist.referendumUsed) {
      return Text(
        '$_civicActivistRoleName قبلاً درخواستِ رفراندومش رو مصرف کرده.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white38),
      );
    }
    return Column(
      children: [
        Text(
          '$_civicActivistRoleName می‌تونه امشب، یک‌بار برای همیشه، تقاضای رفراندوم بده. '
          'فردا — درست قبل از رأی‌گیریِ حذف — رفراندومِ انتخابِ رهبرِ جامعه '
          'برگزار می‌شه.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        SizedBox(height: 16),
        ElevatedButton.icon(
          icon: Icon(Icons.how_to_vote),
          label: Text('درخواستِ رفراندوم'.tr.tr),
          style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(50)),
          onPressed: controller.canRequestReferendumTonight ? controller.requestReferendum : null,
        ),
      ],
    );
  }

  Widget _buildRapperSection() {
    final rapper = controller.rapperPlayer!;
    final result = controller.rapperResultMessage;
    final resistance = controller.activeResistanceMembers;
    // نتیجه‌ی انتخابِ اوشن باید همان لحظه برای خودش مشخص باشد؛ اگر انتخاب
    // اشتباه بوده، اوشن حذف شده ولی پیام نباید به اعلامِ صبح موکول شود.
    // دکمه‌ی پایینِ پنل همان «چشمش رو ببنده» است و بعد از دیدنِ نتیجه
    // می‌تواند به مرحله‌ی بعد برود.
    final showResult = result != null;
    return Column(
      children: [
        Text(
          '$_rapperRoleName می‌تونه امشب یه نفر رو برای عضوگیری تو $_resistanceGroupLabel انتخاب کنه:',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        SizedBox(height: 8),
        if (showResult) ...[
          Text(
            result,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.uiPrimaryLight, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          if (resistance.isNotEmpty)
            Text(
              'حالا بگو: اعضای $_resistanceGroupLabel (${resistance.map((p) => p.name).join('، ')}) بیدار بشن '
              'تا وضعیتِ جدید رو ببینن.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          icon: Icon(Icons.groups),
          label: Text('انتخابِ یه بازیکن'.tr.tr),
          onPressed: controller.canRapperActTonight ? () => _showRapperPicker(rapper) : null,
        ),
      ],
    );
  }

  void _showRapperPicker(SessionPlayer rapper) {
    _showPlayerListPicker(
      title: 'کی رو برای $_resistanceGroupLabel انتخاب کنه؟',
      targets: controller.alivePlayers.where((p) => p.id != rapper.id).toList(),
      onSelected: (p) => controller.rapperRecruit(p.id),
    );
  }

  Widget _buildNatashaSection() {
    final natasha = controller.natashaPlayer!;
    return Column(
      children: [
        Text(
          'ناتاشا می‌تونه (فقط یک‌بار در کلِ بازی) یه نفر رو تا پایانِ روزِ بعد ساکت کنه:'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        SizedBox(height: 8),
        OutlinedButton.icon(
          icon: Icon(Icons.voice_over_off_rounded),
          label: Text('انتخابِ یه بازیکن'.tr.tr),
          onPressed: controller.canNatashaSilenceTonight ? () => _showNatashaPicker(natasha) : null,
        ),
      ],
    );
  }

  void _showNatashaPicker(SessionPlayer natasha) {
    _showPlayerListPicker(
      title: 'ناتاشا کی رو ساکت کنه؟',
      targets: controller.alivePlayers.where((p) => p.id != natasha.id).toList(),
      onSelected: (p) => controller.natashaSilence(p.id),
    );
  }

  Widget _buildSaboteurSection() {
    final saboteur = controller.saboteurPlayer!;
    final target = controller.saboteurTargetPlayerId != null
        ? controller.playerById(controller.saboteurTargetPlayerId!)
        : null;
    return Column(
      children: [
        Text(
          'خرابکار می‌تونه امشب رو تفنگِ یه نفر خرابکاری کنه (اگه فردا با اسلحه‌ی جنگی شلیک کنه، تیر به خودش برمی‌گرده):'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        if (target != null) ...[
          SizedBox(height: 6),
          Text('امشب رو تفنگِ «${target.name}» خرابکاری شده.',
              style: TextStyle(color: AppTheme.uiPrimaryLight, fontSize: 12)),
        ],
        SizedBox(height: 8),
        OutlinedButton.icon(
          icon: Icon(Icons.build_circle_outlined),
          label: Text('انتخابِ یه بازیکن'.tr.tr),
          onPressed: controller.canSaboteurActTonight ? () => _showSaboteurPicker(saboteur) : null,
        ),
      ],
    );
  }

  void _showSaboteurPicker(SessionPlayer saboteur) {
    _showPlayerListPicker(
      title: 'خرابکار رو تفنگِ کی خرابکاری کنه؟',
      targets: controller.alivePlayers.where((p) => p.id != saboteur.id).toList(),
      onSelected: (p) => controller.saboteurChooseTarget(p.id),
    );
  }

  Widget _buildLeaderDecisionSection() {
    final leader = controller.valiFaghihPlayer;
    final leaderAlive = leader != null && leader.isAlive;
    final fallback = controller.canFallbackShoot;
    final enraged = controller.godfatherEnragedTonight;
    final canActAgain = controller.leaderActionsUsedTonight < (enraged ? 2 : 1);

    if (!controller.nightActionTaken || (enraged && canActAgain)) {
      return Column(
        children: [
          if (enraged) ...[
            Text(
              '🔥 معشوقه دیشب از بازی خارج شد؛ $_leaderRoleName عصبانیه و امشب می‌تونه '
              '۲بار شات/سلاخی بزنه (${controller.leaderActionsUsedTonight} از ۲ استفاده شده).',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.bloodRedLight, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
          ],
          Text(
            leaderAlive
                ? '$_leaderTeamName بیدار می‌شه و باهم مشورت می‌کنن؛ تصمیم نهایی با $_leaderRoleName‌ست.'
                : fallback
                    ? '$_leaderRoleName دیگه در بازی نیست؛ سلاخی از بین رفته، ولی شاتِ معمولیِ تیمی همیشه باقی می‌مونه.'
                    : 'هیچ عضوِ زنده‌ای از $_leaderTeamName باقی نمونده؛ شاتی در کار نیست.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60),
          ),
          SizedBox(height: 24),
          if (leaderAlive) ...[
            ElevatedButton.icon(
              icon: Icon(Icons.gps_fixed),
              label: Text('شات (حذف تیمی)'.tr.tr),
              style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(50)),
              onPressed: () => _showShootPicker(leader),
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              icon: Icon(Icons.content_cut),
              label: Text('سلاخی (${leader.slaughterChargesRemaining ?? 0} باقیمانده)'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size.fromHeight(50),
                backgroundColor: AppColors.bloodRedLight,
              ),
              onPressed: (leader.slaughterChargesRemaining ?? 0) > 0
                  ? () => _showSlaughterPicker(leader)
                  : null,
            ),
          ] else if (fallback) ...[
            ElevatedButton.icon(
              icon: Icon(Icons.gps_fixed),
              label: Text('شات (حذف تیمی)'.tr.tr),
              style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(50)),
              onPressed: _showFallbackShootPicker,
            ),
          ],
          // نکته‌ی مهم: این شرط از رویِ زنده‌بودنِ رهبر مستقل بررسی می‌شه،
          // چون قابلیتِ مذاکره به رهبر ربطی نداره و حتی بعدِ حذفِ رهبر هم
          // باید در دسترس بمونه.
          if (controller.canUseNegotiate) ...[
            SizedBox(height: 12),
            ElevatedButton.icon(
              icon: Icon(Icons.handshake),
              label: Text('مذاکره (اغفالِ $_plainCitizenLabel)'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size.fromHeight(50),
                backgroundColor: AppTheme.uiPrimaryDark,
              ),
              onPressed: () => _showNegotiatePicker(),
            ),
          ],
        ],
      );
    }

    return Column(
      children: [
        if (controller.slaughterResultMessage != null)
          Text(
            controller.slaughterResultMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16),
          )
        else if (controller.negotiateResultMessage != null)
          Text(
            controller.negotiateResultMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16),
          )
        else
          Text('تصمیمِ امشب ثبت شد.'.tr, style: TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _buildJudiciarySection() {
    return Column(
      children: [
        Text(
          '${_roleName(controller.scenario.roleIdFor('judiciary'))} می‌تونه (فقط یک‌بار در کل بازی) حکم اعدام صادر کنه:',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        SizedBox(height: 8),
        OutlinedButton.icon(
          icon: Icon(Icons.gavel),
          label: Text('صدور حکم اعدام'.tr.tr),
          onPressed: _showExecutionWordDialog,
        ),
      ],
    );
  }

  void _showExecutionWordDialog() {
    final wordController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.uiCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.bloodRed.withAlpha(56),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.gavel_rounded, color: AppTheme.uiPrimaryLight),
            ),
            SizedBox(width: 12),
            Expanded(child: Text('کلمه‌ی حکم اعدام'.tr)),
          ],
        ),
        content: TextField(
          controller: wordController,
          autofocus: true,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'کلمه رو وارد کن'.tr,
            prefixIcon: Icon(Icons.key_rounded),
            filled: true,
            fillColor: AppTheme.uiSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.uiPrimary.withAlpha(46)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('انصراف'.tr.tr),
          ),
          Game3DButton(
            label: 'ثبت حکم',
            icon: Icons.check_rounded,
            onPressed: () {
              if (wordController.text.trim().isNotEmpty) {
                controller.issueExecutionOrder(wordController.text);
                Navigator.of(dialogContext).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInterrogatorSection() {
    final interrogator = controller.interrogatorPlayer!;
    final target = controller.lastInterrogationTargetName;
    return Column(
      children: [
        Text(
          interrogator.interrogationUsed
              ? 'بازجو خبرنگار قابلیتِ یک‌بارمصرفِ بازجویی رو مصرف کرده.'
              : 'بازجو خبرنگار می‌تونه (فقط یک‌بار در کل بازی) یه نفر رو بازجویی کنه:',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        SizedBox(height: 8),
        if (target != null)
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'بازجوییِ انجام‌شده: «$target»'
              '${controller.lastInterrogationQuestion != null ? ' — سوال: ${controller.lastInterrogationQuestion}' : ''}',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.uiPrimaryLight),
            ),
          ),
        if (!interrogator.interrogationUsed)
          OutlinedButton.icon(
            icon: Icon(Icons.record_voice_over),
            label: Text('بازجوییِ یه بازیکن'.tr.tr),
            onPressed: controller.canInterrogateTonight ? _showInterrogationDialog : null,
          ),
      ],
    );
  }

  void _showInterrogationDialog() {
    final targets = controller.alivePlayers;
    SessionPlayer? selectedTarget;
    final questionController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.uiCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(children: [
            Container(width: 42, height: 42,
              decoration: BoxDecoration(color: AppTheme.uiPrimaryDark.withAlpha(56), shape: BoxShape.circle),
              child: Icon(Icons.record_voice_over_rounded, color: AppTheme.uiPrimaryLight)),
            SizedBox(width: 12), Text('بازجویی'.tr),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('هدف و سؤال اختیاری را برای ثبت این بازجویی انتخاب کن.'.tr,
                style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12)),
            SizedBox(height: 14),
            DropdownButtonFormField<SessionPlayer>(
              isExpanded: true, value: selectedTarget, dropdownColor: AppTheme.uiCard,
              decoration: InputDecoration(labelText: 'هدف بازجویی'.tr, prefixIcon: Icon(Icons.person_search_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
              items: targets.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
              onChanged: (v) => setDialogState(() => selectedTarget = v),
            ),
            SizedBox(height: 10),
            TextField(controller: questionController, style: TextStyle(color: Colors.white),
              decoration: InputDecoration(labelText: 'سؤال (اختیاری)'.tr, hintText: 'فقط برای یادآوری خودت'.tr,
                prefixIcon: Icon(Icons.help_outline_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)))),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text('انصراف'.tr.tr)),
            Game3DButton(label: 'ثبت بازجویی', icon: Icons.check_rounded,
              onPressed: selectedTarget != null ? () {
                controller.interrogate(selectedTarget!.id, question: questionController.text);
                Navigator.of(dialogContext).pop();
              } : null),
          ],
        ),
      ),
    );
  }

  Widget _buildIntelQuestionSection() {
    final minister = controller.intelligenceMinisterPlayer!;
    final result = controller.lastIntelQuestionResult;
    final names = controller.lastIntelQuestionTargetNames;
    return Column(
      children: [
        Text(
          'وزیر اطلاعات: ${minister.intelQuestionsRemaining ?? 0} سؤالِ اطلاعاتیِ باقیمانده در کلِ بازی '
          '(هر شب فقط یکی).',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        if (result != null && names != null) ...[
          SizedBox(height: 8),
          Text(
            '🔍 «${names.join('، ')}» نقش دارن؟ → '
            '${result == InvestigationResult.like ? '👍 لایک (همه‌شون نقش دارن)' : '👎 دیس‌لایک (حداقل یکی‌شون نداره)'}',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.uiPrimaryLight, fontWeight: FontWeight.bold),
          ),
        ],
        SizedBox(height: 8),
        OutlinedButton.icon(
          icon: Icon(Icons.help_outline),
          label: Text('پرسیدنِ سؤالِ اطلاعاتی'.tr.tr),
          onPressed: controller.canAskIntelQuestionTonight ? _showIntelQuestionDialog : null,
        ),
      ],
    );
  }

  void _showIntelQuestionDialog() {
    final targets = controller.alivePlayers;
    final selected = <int>{};
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.uiCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(children: [
            Container(width: 42, height: 42,
              decoration: BoxDecoration(color: AppTheme.uiPrimaryDark.withAlpha(56), shape: BoxShape.circle),
              child: Icon(Icons.psychology_rounded, color: AppTheme.uiPrimaryLight)),
            SizedBox(width: 12), Expanded(child: Text('سؤال اطلاعاتی'.tr)),
          ]),
          content: SizedBox(width: double.maxFinite,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('بازیکن‌های مورد سؤال را انتخاب کن.'.tr,
                style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12)),
              SizedBox(height: 10),
              ...targets.map((p) => Material(
                color: selected.contains(p.id) ? AppTheme.uiPrimaryDark.withAlpha(41) : AppTheme.uiSurface,
                borderRadius: BorderRadius.circular(14),
                child: CheckboxListTile(
                  dense: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  value: selected.contains(p.id), activeColor: AppTheme.uiPrimary,
                  onChanged: (v) => setDialogState(() {
                    if (v ?? false) { selected.add(p.id); } else { selected.remove(p.id); }
                  }),
                  title: Text(p.name, style: TextStyle(color: Colors.white)),
                  secondary: CircleAvatar(radius: 16, backgroundColor: AppTheme.uiPrimaryDark.withAlpha(61),
                    child: Text('\${targets.indexOf(p) + 1}',
                      style: TextStyle(color: AppTheme.uiPrimaryLight, fontSize: 12))),
                ),
              )),
            ])),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text('انصراف'.tr.tr)),
            Game3DButton(label: 'پرسیدن سؤال', icon: Icons.arrow_back_rounded,
              onPressed: selected.isNotEmpty ? () {
                controller.askIntelQuestion(selected.toList());
                Navigator.of(dialogContext).pop();
              } : null),
          ],
        ),
      ),
    );
  }

  Widget _buildDetentionSection() {
    final detainedName =
        controller.detainedPlayerId != null ? controller.playerById(controller.detainedPlayerId!).name : null;
    return Column(
      children: [
        Text(
          detainedName != null
              ? 'امشب «$detainedName» بازداشت شده و قابلیتِ نقشِ خودش رو نداره.'
              : 'فرمانده نیروی انتظامی می‌تونه امشب یه بازیکن رو بازداشت کنه (بازداشتیِ دیشب دوباره مجاز نیست).',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        SizedBox(height: 8),
        OutlinedButton.icon(
          icon: Icon(Icons.local_police),
          label: Text('بازداشتِ یه بازیکن'.tr.tr),
          onPressed: controller.canDetainTonight ? _showDetainPicker : null,
        ),
      ],
    );
  }

  void _showDetainPicker() {
    _showPlayerListPicker(
      title: 'کی بازداشت بشه؟',
      targets: controller.detainEligibleTargets,
      onSelected: (p) => controller.detainPlayer(p.id),
    );
  }

  Widget _buildMercenaryNightSection() {
    final merc = controller.mercenaryPlayer!;
    return Column(
      children: [
        Text(
          'مزدور لباس‌شخصی می‌تونه امشب یه نفر رو ترور کنه — ولی خودش هم بلافاصله لو می‌ره و حذف می‌شه.'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        SizedBox(height: 8),
        OutlinedButton.icon(
          icon: Icon(Icons.dangerous),
          label: Text('ترور'.tr.tr),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.bloodRedLight),
          onPressed: controller.canAssassinateTonight ? () => _showAssassinatePicker(merc) : null,
        ),
      ],
    );
  }

  void _showAssassinatePicker(SessionPlayer merc) {
    _showPlayerListPicker(
      title: 'ترور روی کی؟',
      targets: controller.alivePlayers.where((p) => p.id != merc.id).toList(),
      onSelected: (p) => controller.assassinate(p.id),
    );
  }

  Widget _buildNationalHeroSection() {
    final hero = controller.nationalHeroPlayer!;
    return Column(
      children: [
        Text(
          '$_nationalHeroRoleName می‌تونه امشب یه بازیکن رو تضمین کنه (${hero.guaranteesRemaining ?? 0} '
          'تضمینِ باقیمانده در کلِ بازی).',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        SizedBox(height: 8),
        OutlinedButton.icon(
          icon: Icon(Icons.shield),
          label: Text('تضمینِ یه بازیکن'.tr.tr),
          onPressed: controller.canGuaranteeTonight ? () => _showGuaranteePicker(hero) : null,
        ),
      ],
    );
  }

  void _showGuaranteePicker(SessionPlayer hero) {
    _showPlayerListPicker(
      title: 'کی تضمین بشه؟',
      targets: controller.alivePlayers,
      onSelected: (p) => controller.guaranteePlayer(p.id),
    );
  }

  Widget _buildRebelSection() {
    final rebel = controller.rebelPlayer!;
    final armed = controller.armedPlayers;
    return Column(
      children: [
        Text(
          '$_rebelRoleName می‌تونه امشب به هر تعداد بازیکن اسلحه بده. اسلحه‌ی جنگیِ '
          'باقیمانده: ${rebel.warGunsRemaining ?? 0} (مشقی نامحدوده).',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        SizedBox(height: 10),
        if (armed.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: armed
                .map(
                  (p) => Chip(
                    label: Text(
                      '${p.name} (${p.heldGunType == GunType.war ? 'جنگی' : 'مشقی'})',
                    ),
                    backgroundColor: AppTheme.uiCard,
                    labelStyle: TextStyle(color: Colors.white),
                    deleteIconColor: AppColors.bloodRedLight,
                    onDeleted: () => controller.takeBackGun(p.id),
                  ),
                )
                .toList(),
          ),
        SizedBox(height: 10),
        OutlinedButton.icon(
          icon: Icon(Icons.front_hand),
          label: Text('دادنِ اسلحه به یه بازیکن'.tr.tr),
          onPressed: () => _showGiveGunDialog(rebel),
        ),
      ],
    );
  }

  void _showGiveGunDialog(SessionPlayer rebel) {
    final targets = controller.alivePlayers;
    SessionPlayer? selectedTarget;
    GunType selectedType = GunType.blank;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.uiCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(children: [
            Container(width: 42, height: 42,
              decoration: BoxDecoration(color: AppTheme.uiPrimaryDark.withAlpha(56), shape: BoxShape.circle),
              child: Icon(Icons.front_hand_rounded, color: AppTheme.uiPrimaryLight)),
            SizedBox(width: 12), Text('دادنِ اسلحه'.tr),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<SessionPlayer>(
              isExpanded: true, value: selectedTarget, dropdownColor: AppTheme.uiCard,
              decoration: InputDecoration(labelText: 'بازیکن دریافت‌کننده'.tr, prefixIcon: Icon(Icons.person_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
              items: targets.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
              onChanged: (v) => setDialogState(() => selectedTarget = v),
            ),
            SizedBox(height: 12),
            RadioListTile<GunType>(
              value: GunType.blank, groupValue: selectedType, activeColor: AppTheme.uiPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onChanged: (v) => setDialogState(() => selectedType = v!),
              title: Text('مشقی'.tr.tr, style: TextStyle(color: Colors.white)),
              subtitle: Text('برای تمرین؛ شلیک واقعی ندارد.'.tr.tr, style: TextStyle(color: AppTheme.uiMutedText, fontSize: 11)),
            ),
            RadioListTile<GunType>(
              value: GunType.war, groupValue: selectedType, activeColor: AppColors.bloodRedLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onChanged: (rebel.warGunsRemaining ?? 0) > 0 ? (v) => setDialogState(() => selectedType = v!) : null,
              title: Text('جنگی (${rebel.warGunsRemaining ?? 0} باقیمانده)', style: TextStyle(color: Colors.white)),
              subtitle: Text('گلوله واقعی و قابل شلیک.'.tr.tr, style: TextStyle(color: AppTheme.uiMutedText, fontSize: 11)),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text('انصراف'.tr.tr)),
            Game3DButton(label: 'تحویل اسلحه', icon: Icons.check_rounded,
              onPressed: selectedTarget != null ? () {
                controller.giveGun(selectedTarget!.id, selectedType);
                Navigator.of(dialogContext).pop();
              } : null),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorSection() {
    final doc = controller.doctorPlayer!;
    final saved = controller.savedPlayersTonight;
    return Column(
      children: [
        Text(
          'دکتر امشب می‌تونه ${controller.doctorNightlyCapacity} نفر رو در برابر '
          'شاتِ شبِ $_leaderTeamName نجات بده (${saved.length} از ${controller.doctorNightlyCapacity} استفاده شده).',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        SizedBox(height: 4),
        Text(
          'نجاتِ خودش: ${doc.selfSavesUsed} از ${widget.settings.doctorMaxSelfSaves} بار در کلِ بازی',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
        SizedBox(height: 10),
        if (saved.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: saved
                .map(
                  (p) => Chip(
                    label: Text(p.name),
                    backgroundColor: AppTheme.uiCard,
                    labelStyle: TextStyle(color: Colors.white),
                    deleteIconColor: AppColors.bloodRedLight,
                    onDeleted: () => controller.undoDoctorSave(p.id),
                  ),
                )
                .toList(),
          ),
        SizedBox(height: 10),
        OutlinedButton.icon(
          icon: Icon(Icons.healing),
          label: Text('نجاتِ یه بازیکنِ دیگه'.tr.tr),
          onPressed: controller.canDoctorSaveTonight ? () => _showDoctorSavePicker(doc) : null,
        ),
      ],
    );
  }

  void _showDoctorSavePicker(SessionPlayer doc) {
    _showPlayerListPicker(
      title: 'امشب کی رو نجات بده؟',
      // از isStillActiveTonight استفاده می‌کنیم نه alivePlayers خام: کسی که
      // امشب سلاخی شده نباید از لیست غیب بشه (لو می‌ده)، برای همینم تو لیست
      // می‌مونه؛ اگه دکتر همونو انتخاب کنه، چون تو _pendingHits نیست، انتخابش
      // طبقِ منطقِ خودِ doctorSave خودکار بی‌اثر می‌مونه.
      targets: controller.players
          .where((p) => controller.isStillActiveTonight(p) && controller.canDoctorSaveTarget(p.id))
          .toList(),
      onSelected: (p) => controller.doctorSave(p.id),
      emptyMessage: 'کسی برای نجات باقی نمونده.',
      labelBuilder: (p) => p.id == doc.id ? '${p.name} (خودش)' : p.name,
    );
  }

  Widget _buildHackerSection() {
    final result = controller.lastInvestigationResult;
    final targetName = controller.lastInvestigationTargetName;
    return Column(
      children: [
        Text(
          '$_hackerRoleName می‌تونه امشب یکی از بازیکن‌ها رو استعلام بگیره:',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        SizedBox(height: 8),
        if (result != null && targetName != null) ...[
          Text(
            result == InvestigationResult.like
                ? '🔍 نتیجه‌ی «$targetName»: 👍 لایک'
                : '🔍 نتیجه‌ی «$targetName»: 👎 دیس‌لایک',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.uiPrimaryLight, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'این نتیجه رو فقط خصوصی و درِگوشی به خودِ $_hackerRoleName بگو.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
          SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          icon: Icon(Icons.search),
          label: Text('استعلامِ یه بازیکن'.tr.tr),
          onPressed: controller.canHackerInvestigateTonight ? _showHackerInvestigatePicker : null,
        ),
      ],
    );
  }

  void _showHackerInvestigatePicker() {
    final hacker = controller.hackerPlayer!;
    _showPlayerListPicker(
      title: 'استعلام روی کی؟',
      targets: controller.alivePlayers.where((p) => p.id != hacker.id).toList(),
      onSelected: (p) => controller.hackerInvestigate(p.id),
    );
  }

  Widget _buildRevolutionarySection() {
    final fighter = controller.revolutionaryFighterPlayer!;
    final charges = fighter.revolutionaryChargesRemaining ?? 0;
    final result = controller.revolutionaryResultMessage;
    // همون منطقِ رپر معترض: اگه انتخابِ اشتباه باعثِ حذفِ خودش شده باشه،
    // همین‌جا نشونش نمی‌دیم تا نقشش لو نره؛ فقط تو جمع‌بندیِ آخرِ شب میاد.
    // isStillActiveTonight (نه isAlive خام)، چون اگه یکیِ دیگه امشب
    // سلاخی/ترورش کرده باشه، نتیجه‌ی موفقِ خودِ همین نوبت باید دیده بشه.
    final showResult = result != null && controller.isStillActiveTonight(fighter);
    return Column(
      children: [
        Text(
          '$_revolutionaryRoleName: $charges استفاده‌ی باقیمانده از $_revolutionaryActionLabel/سلاخی'
          '${fighter.canStillSlaughter ? '' : ' (سلاخی دیگه در دسترسش نیست)'}',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        if (showResult) ...[
          SizedBox(height: 8),
          Text(
            result,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.uiPrimaryLight, fontWeight: FontWeight.bold),
          ),
        ],
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              icon: Icon(Icons.gps_fixed_rounded),
              label: Text('شلیک'.tr.tr),
              onPressed: (controller.canRevolutionaryActTonight && charges > 0)
                  ? () => _showRevolutionaryExecutePicker(fighter)
                  : null,
            ),
            SizedBox(width: 12),
            OutlinedButton.icon(
              icon: Icon(Icons.content_cut),
              label: Text('سلاخی'.tr.tr),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.bloodRedLight),
              onPressed: (controller.canRevolutionaryActTonight &&
                      charges > 0 &&
                      fighter.canStillSlaughter)
                  ? () => _showRevolutionarySlaughterPicker(fighter)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  void _showRevolutionaryExecutePicker(SessionPlayer fighter) {
    _showPlayerListPicker(
      title: '$_revolutionaryActionLabel روی کی؟',
      targets: controller.alivePlayers.where((p) => p.id != fighter.id).toList(),
      onSelected: (p) => controller.revolutionaryExecute(p.id),
    );
  }

  void _showRevolutionarySlaughterPicker(SessionPlayer fighter) {
    final targets = controller.alivePlayers.where((p) => p.id != fighter.id).toList();
    SessionPlayer? selectedTarget;
    String? selectedRoleId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: AppTheme.uiCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: AppTheme.uiPrimary.withAlpha(56))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 44, height: 5, decoration: BoxDecoration(color: AppTheme.uiPrimary.withAlpha(77), borderRadius: BorderRadius.circular(10))),
                SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(color: AppColors.bloodRed.withAlpha(89), shape: BoxShape.circle),
                      child: Icon(Icons.warning_amber_rounded, color: AppTheme.uiPrimaryLight),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('سلاخی'.tr, style: AppTheme.headingFont(size: 20)),
                          SizedBox(height: 3),
                          Text('هدف و حدسِ نقش را مشخص کن'.tr, style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18),
                DropdownButtonFormField<SessionPlayer>(
                  value: selectedTarget,
                  isExpanded: true,
                  dropdownColor: AppTheme.uiCard,
                  decoration: InputDecoration(
                    labelText: 'هدف'.tr,
                    prefixIcon: Icon(Icons.person_search_rounded, color: AppTheme.uiPrimaryLight),
                    filled: true, fillColor: AppTheme.uiSurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  items: targets.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                  onChanged: (v) => setSheetState(() => selectedTarget = v),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRoleId,
                  isExpanded: true,
                  dropdownColor: AppTheme.uiCard,
                  decoration: InputDecoration(
                    labelText: 'حدسِ نقش'.tr,
                    prefixIcon: Icon(Icons.badge_rounded, color: AppTheme.uiPrimaryLight),
                    filled: true, fillColor: AppTheme.uiSurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  items: controller.rolesInPlay.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))).toList(),
                  onChanged: (v) => setSheetState(() => selectedRoleId = v),
                ),
                SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: Game3DButton(
                    label: 'تأیید سلاخی',
                    icon: Icons.flash_on_rounded,
                    onPressed: (selectedTarget != null && selectedRoleId != null)
                        ? () {
                            controller.revolutionarySlaughter(selectedTarget!.id, selectedRoleId!);
                            Navigator.of(context).pop();
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLawyerSection() {
    final lawyer = controller.lawyerPlayer!;
    final halfAlive = controller.halfAlivePlayers;
    return Column(
      children: [
        Text(
          controller.isStillActiveTonight(lawyer)
              ? '$_lawyerRoleName هنوز قابلیتِ یک‌بارمصرفِ جان‌بخشیش رو مصرف نکرده.'
              : '$_lawyerRoleName («${lawyer.name}») خودش الان نیمه‌جانه یا حذف شده و نمی‌تونه فعلاً از این قابلیت استفاده کنه.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        SizedBox(height: 8),
        if (halfAlive.isEmpty)
          Text(
            'فعلاً هیچ بازیکنِ نیمه‌جانی برای برگردوندن نیست.'.tr,
            style: TextStyle(color: Colors.white38, fontSize: 12),
          )
        else
          OutlinedButton.icon(
            icon: Icon(Icons.favorite),
            label: Text('برگردوندنِ یه بازیکنِ نیمه‌جان'.tr.tr),
            onPressed: controller.canLawyerReviveTonight ? _showLawyerRevivePicker : null,
          ),
      ],
    );
  }

  void _showLawyerRevivePicker() {
    _showPlayerListPicker(
      title: 'کی به بازی برگرده؟',
      targets: controller.halfAlivePlayers,
      onSelected: (p) => controller.lawyerRevive(p.id),
    );
  }

  void _showFallbackShootPicker() {
    _showPlayerListPicker(
      title: 'شات روی کی؟',
      targets: controller.alivePlayers,
      onSelected: (p) => controller.leaderShoot(p.id),
    );
  }

  void _showShootPicker(SessionPlayer leader) {
    _showPlayerListPicker(
      title: 'شات روی کی؟',
      targets: controller.alivePlayers.where((p) => p.id != leader.id).toList(),
      onSelected: (p) => controller.leaderShoot(p.id),
    );
  }

  void _showNegotiatePicker() {
    final minister = controller.foreignMinisterPlayer;
    _showPlayerListPicker(
      title: 'با کی می‌خوان مذاکره کنن؟',
      targets: controller.alivePlayers.where((p) => minister == null || p.id != minister.id).toList(),
      onSelected: (p) => controller.leaderNegotiate(p.id),
    );
  }

  void _showSlaughterPicker(SessionPlayer leader) {
    final targets = controller.alivePlayers.where((p) => p.id != leader.id).toList();
    SessionPlayer? selectedTarget;
    String? selectedRoleId;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.uiSurface,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('سلاخی: هدف + حدسِ نقش'.tr, style: TextStyle(color: AppTheme.uiPrimaryLight)),
                    SizedBox(height: 12),
                    DropdownButton<SessionPlayer>(
                      hint: Text('انتخاب هدف'.tr, style: TextStyle(color: Colors.white70)),
                      dropdownColor: AppTheme.uiSurface,
                      value: selectedTarget,
                      items: targets
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.name, style: TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                      onChanged: (v) => setSheetState(() => selectedTarget = v),
                    ),
                    SizedBox(height: 8),
                    DropdownButton<String>(
                      hint: Text('حدسِ نقش'.tr, style: TextStyle(color: Colors.white70)),
                      dropdownColor: AppTheme.uiSurface,
                      value: selectedRoleId,
                      items: controller.rolesInPlay
                          .map((r) => DropdownMenuItem(
                                value: r.id,
                                child: Text(r.name, style: TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                      onChanged: (v) => setSheetState(() => selectedRoleId = v),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: (selectedTarget != null && selectedRoleId != null)
                          ? () {
                              controller.leaderSlaughter(selectedTarget!.id, selectedRoleId!);
                              Navigator.of(context).pop();
                            }
                          : null,
                      child: Text('تایید سلاخی'.tr),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// صفحه‌ی جزئیاتِ امتیازِ همه‌ی بازیکنان — هر بازیکن یه کارتِ بازشونده
/// داره که تک‌تکِ رویدادهایِ امتیازیش (مکانیزم + امتیاز + دور/فاز) رو
/// نشون می‌ده. مرتب‌شده بر اساسِ امتیازِ کل، از بیشترین به کمترین.
class _PlayerScoreDetailScreen extends StatelessWidget {
  final List<SessionPlayer> players;
  _PlayerScoreDetailScreen({required this.players});

  @override
  Widget build(BuildContext context) {
    final sorted = players.toList()..sort((a, b) => b.scoreTotal.compareTo(a.scoreTotal));
    final totalPositive = sorted.where((p) => p.scoreTotal > 0).length;
    final totalNegative = sorted.where((p) => p.scoreTotal < 0).length;
    return Scaffold(
      appBar: AppBar(
        title: Text('جزئیاتِ امتیاز'.tr.tr),
        actions: [
          Padding(
            padding: EdgeInsetsDirectional.only(end: 14),
            child: Center(
              child: Text(
                '\${sorted.length} بازیکن',
                style: TextStyle(color: AppTheme.uiMutedText, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.uiCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.uiPrimary.withAlpha(46)),
            ),
            child: Row(
              children: [
                _scoreStat(Icons.emoji_events_rounded, 'مثبت', totalPositive, AppTheme.uiPrimary),
                SizedBox(width: 10),
                _scoreStat(Icons.remove_circle_outline_rounded, 'منفی', totalNegative, AppColors.bloodRedLight),
                SizedBox(width: 10),
                _scoreStat(Icons.groups_rounded, 'کل', sorted.length, AppTheme.uiPrimaryLight),
              ],
            ),
          ),
          SizedBox(height: 14),
          if (sorted.isEmpty)
            Container(
              padding: EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.uiCard,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  Icon(Icons.scoreboard_rounded, color: AppTheme.uiPrimaryLight, size: 42),
                  SizedBox(height: 10),
                  Text('هنوز بازیکنی برای نمایش نیست.'.tr, style: TextStyle(color: AppTheme.uiMutedText)),
                ],
              ),
            )
          else
            ...sorted.asMap().entries.map((entry) {
              final index = entry.key;
              final p = entry.value;
              final teamName = GameTeams.byId(p.teamId)?.name ?? p.teamId;
              final roleName = p.roleId != null ? GameRoles.byId(p.roleId!)?.name : null;
              final total = p.scoreTotal;
              final scoreColor = total > 0
                  ? AppTheme.uiPrimary
                  : (total < 0 ? AppColors.bloodRedLight : Colors.white60);
              return Container(
                margin: EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppTheme.uiCard,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: scoreColor.withAlpha(56)),
                ),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  childrenPadding: EdgeInsets.only(bottom: 8),
                  iconColor: AppTheme.uiPrimary,
                  collapsedIconColor: AppTheme.uiMutedText,
                  leading: CircleAvatar(
                    radius: 19,
                    backgroundColor: scoreColor.withAlpha(36),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(color: scoreColor, fontWeight: FontWeight.w800),
                    ),
                  ),
                  title: Text(
                    p.name,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                  subtitle: Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Text(
                      '${roleName ?? teamName} • $teamName',
                      style: TextStyle(color: AppTheme.uiMutedText, fontSize: 11),
                    ),
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                      color: scoreColor.withAlpha(31),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '\${total >= 0 ? '+' : ''}\${total}',
                      style: TextStyle(color: scoreColor, fontWeight: FontWeight.w900, fontSize: 17),
                    ),
                  ),
                  children: p.scoreEvents.isEmpty
                      ? [
                          Padding(
                            padding: EdgeInsets.fromLTRB(20, 2, 20, 16),
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                'هیچ رویدادِ امتیازی‌ای ثبت نشده.'.tr,
                                style: TextStyle(color: AppTheme.uiSubtleText, fontSize: 12),
                              ),
                            ),
                          ),
                        ]
                      : [
                          Divider(color: scoreColor.withAlpha(31), height: 1),
                          ...p.scoreEvents.map((e) => _scoreEventRow(e)),
                        ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _scoreStat(IconData icon, String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(31)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(height: 5),
            Text('\${value}', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 17)),
            SizedBox(height: 2),
            Text(label, style: TextStyle(color: AppTheme.uiMutedText, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _scoreEventRow(ScoreEvent e) {
    final eColor = e.points > 0 ? AppTheme.uiPrimary : AppColors.bloodRedLight;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${e.mechanism} — ${e.phaseLabel}ِ دورِ ${e.roundNumber}',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Text(
            '${e.points > 0 ? '+' : ''}${e.points}',
            style: TextStyle(color: eColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
