import 'package:flutter/material.dart';
import '../controllers/game_flow_controller.dart';
import '../models/game_session.dart';
import '../models/history.dart';
import '../models/role.dart';
import '../models/team.dart';
import '../services/music_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/countdown_timer_widget.dart';
import '../widgets/game_3d_button.dart';
import '../widgets/role_card.dart';

class GameFlowScreen extends StatefulWidget {
  final List<SessionPlayer> players;
  final GameSettings settings;

  const GameFlowScreen({
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
  bool get _isMafiaGame => controller.players.any((p) => p.teamId == SarkoobTeams.mafiaGang.id);
  String get _leaderTeamName => _isMafiaGame ? 'تیمِ مافیا' : 'تیمِ سرکوب';
  String get _leaderRoleName => _isMafiaGame ? 'پدرخوانده' : 'ولی‌فقیه';
  String get _plainCitizenLabel => _isMafiaGame ? 'شهروندِ ساده' : 'شهروندِ خاکستری';
  String get _plainLeaderTeamLabel => _isMafiaGame ? 'مافیا ساده' : 'سرکوبگر';
  String get _independentLeaderRoleName => _isMafiaGame ? 'زودیاک' : 'رهبر موساد';
  // بقیه‌ی نقش‌های تکی که تو مافیا هم معادل دارن — همون الگوی بالا.
  String get _rapperRoleName => _isMafiaGame ? 'اوشن' : 'رپر معترض';
  String get _resistanceGroupLabel => _isMafiaGame ? 'تیمِ اوشن' : 'مقاومتِ فعال';
  String get _hackerRoleName => _isMafiaGame ? 'کارآگاه' : 'هکر';
  String get _politicalAnalystRoleName => _isMafiaGame ? 'شرلوک' : 'تحلیلگر سیاسی';
  String get _rebelRoleName => _isMafiaGame ? 'تفنگدار' : 'شورشی';
  String get _revolutionaryRoleName => _isMafiaGame ? 'حرفه‌ای' : 'مبارز انقلابی';
  String get _revolutionaryActionLabel => _isMafiaGame ? 'حذفِ حرفه‌ای' : 'اعدامِ انقلابی';
  String get _civicActivistRoleName => _isMafiaGame ? 'لیدر' : 'فعال مدنی';
  String get _lawyerRoleName => _isMafiaGame ? 'کنستانتین' : 'وکیل';
  String get _forbiddenWordLabel => _isMafiaGame ? 'کلمه‌ی طلسم‌شده' : 'کلمه‌ی ممنوع';

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
            const SnackBar(
              content: Text('برای خروج از گردانندگی، از دکمه‌ی «پایانِ بازی» تو نوارِ پایین استفاده کن.'),
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
            padding: const EdgeInsets.all(16),
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
            color: AppColors.background,
            elevation: 0,
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _bottomBarAction(
                    icon: Icons.groups,
                    label: 'بازیکنان',
                    onPressed: _showRosterDialog,
                  ),
                  _bottomBarAction(
                    icon: Icons.swap_vert,
                    label: 'جابه‌جایی',
                    onPressed: _showReorderDialog,
                  ),
                  _bottomBarAction(
                    icon: Icons.gavel,
                    label: 'تنبیه',
                    onPressed: _showDisciplineDialog,
                  ),
                  _bottomBarAction(
                    icon: _showTeamCounts ? Icons.pie_chart : Icons.pie_chart_outline,
                    label: 'تعدادِ زنده',
                    active: _showTeamCounts,
                    onPressed: () => setState(() => _showTeamCounts = !_showTeamCounts),
                  ),
                  _bottomBarAction(
                    icon: _moderatorNotes.trim().isEmpty ? Icons.note_add_outlined : Icons.note_alt,
                    label: 'یادداشت',
                    active: _moderatorNotes.trim().isNotEmpty,
                    onPressed: _showNotesDialog,
                  ),
                  _bottomBarAction(
                    icon: Icons.flag,
                    label: 'پایانِ بازی',
                    onPressed: _showEndGameDialog,
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
        if (!MusicService.instance.isPlaying) return const SizedBox.shrink();
        final trackName = MusicService.instance.currentTrackName ?? 'موزیکِ پس‌زمینه';
        final isPaused = MusicService.instance.isPaused;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gold.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.music_note, color: AppColors.goldLight, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trackName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              IconButton(
                iconSize: 24,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, color: AppColors.goldLight),
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
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: const Icon(Icons.skip_next, color: AppColors.goldLight),
                tooltip: 'آهنگِ بعدی',
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
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('یادداشتِ گرداننده', style: TextStyle(color: AppColors.goldLight)),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: notesController,
            autofocus: true,
            maxLines: 10,
            minLines: 6,
            textDirection: TextDirection.rtl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'مثلاً: مظنون‌ها، حساب‌وکتابِ رأی، هر نکته‌ای...',
              hintStyle: TextStyle(color: Colors.white38),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _moderatorNotes = notesController.text);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('ذخیره'),
          ),
        ],
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold.withOpacity(0.5)),
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
                const SizedBox(width: 8),
                Text(
                  '${entry.key.name}: ${entry.value}',
                  style: const TextStyle(
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
      backgroundColor: AppColors.surfaceDark,
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
              padding: const EdgeInsets.all(16),
              children: [
                Text('بازیکنان و نقش‌ها', style: AppTheme.headingFont(size: 20)),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.gold,
                  title: const Text('فقط بازیکنانِ زنده', style: TextStyle(color: Colors.white, fontSize: 14)),
                  value: showOnlyAlive,
                  onChanged: (v) => setSheetState(() => showOnlyAlive = v),
                ),
                const SizedBox(height: 4),
                ...list.map((p) {
                  final role = p.roleId != null ? SarkoobRoles.byId(p.roleId!) : null;
                  final teamName = SarkoobTeams.byId(p.teamId)?.name ?? p.teamId;
                  final status =
                      !p.isAlive ? (p.isHalfAlive ? 'نیمه‌جان' : 'حذف‌شده') : 'زنده';
                  return ListTile(
                    dense: true,
                    title: Text(p.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      '$teamName${role != null ? ' — ${role.name}' : ''}'
                      '${p.disciplineStage > 0 ? ' — ${disciplineStageLabel(p.disciplineStage)}' : ''}',
                      style: const TextStyle(color: AppColors.goldLight),
                    ),
                    trailing: Text(status, style: const TextStyle(color: Colors.white54)),
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
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, scrollController) => StatefulBuilder(
          builder: (context, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('ترتیبِ بازیکنان', style: AppTheme.headingFont(size: 20)),
              ),
              const Text(
                'با نگه‌داشتن و کشیدن جابه‌جا کن.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              Expanded(
                child: ReorderableListView(
                  scrollController: scrollController,
                  padding: const EdgeInsets.all(16),
                  onReorder: (oldIndex, newIndex) {
                    controller.reorderPlayers(oldIndex, newIndex);
                    setSheetState(() {});
                  },
                  children: controller.players
                      .map(
                        (p) => ListTile(
                          key: ValueKey('reorder-${p.id}'),
                          leading: const Icon(Icons.drag_handle, color: Colors.white38),
                          title: Text(p.name, style: const TextStyle(color: Colors.white)),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
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
    bool isExpelChoice = false; // false = تنبیهِ درجه‌بندی‌شده، true = اخراجِ مستقیم
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final nextStage = selectedTarget == null ? 0 : selectedTarget!.disciplineStage + 1;
          return AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            title: const Text('تنبیهِ انضباطی', style: TextStyle(color: AppColors.bloodRedLight)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'مستقل از قوانینِ عادیِ بازیه؛ برای رفتارِ خارج از نظمِ جلسه.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<SessionPlayer>(
                    isExpanded: true,
                    hint: const Text('انتخابِ بازیکن', style: TextStyle(color: Colors.white70)),
                    dropdownColor: AppColors.surfaceDark,
                    value: selectedTarget,
                    items: controller.alivePlayers
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.name, style: const TextStyle(color: Colors.white)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedTarget = v),
                  ),
                  if (selectedTarget != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'سابقه‌ی انضباطیِ فعلی: ${disciplineStageLabel(selectedTarget!.disciplineStage)}',
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isExpelChoice ? null : AppColors.goldDark.withOpacity(0.35),
                              side: BorderSide(color: isExpelChoice ? Colors.white24 : AppColors.gold),
                            ),
                            onPressed: () => setDialogState(() => isExpelChoice = false),
                            child: const Text('تنبیه'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  isExpelChoice ? AppColors.bloodRedLight.withOpacity(0.35) : null,
                              side: BorderSide(
                                color: isExpelChoice ? AppColors.bloodRedLight : Colors.white24,
                              ),
                            ),
                            onPressed: () => setDialogState(() => isExpelChoice = true),
                            child: const Text('اخراجِ مستقیم'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!isExpelChoice)
                      Text(
                        nextStage >= 4
                            ? 'این چهارمین تخلفشه؛ همین الان از بازی اخراج می‌شه.'
                            : 'نتیجه‌ی این تنبیه: ${disciplineStageLabel(nextStage)}',
                        style: const TextStyle(color: AppColors.goldLight, fontSize: 13),
                      )
                    else
                      const Text(
                        'اخراجِ فوری و برگشت‌ناپذیر — بدونِ عبور از مراحلِ درجه‌بندی‌شده.',
                        style: TextStyle(color: AppColors.bloodRedLight, fontSize: 13),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reasonController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: 'دلیل (مثلاً حرفِ خارج از نوبت، تقلب)'),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('انصراف'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isExpelChoice ? AppColors.bloodRedLight : AppColors.gold,
                  // باگِ قبلی: چون foregroundColor ست نبود، تمِ سراسری
                  // (colorScheme.primary=طلایی) فونتِ دکمه رو هم طلایی
                  // می‌کرد — یعنی رو حالتِ «تنبیه» (پس‌زمینه‌ی طلایی)
                  // فونت با پس‌زمینه قاطی و نامرئی می‌شد.
                  foregroundColor: isExpelChoice ? Colors.white : Colors.black,
                ),
                onPressed: selectedTarget != null
                    ? () {
                        final reason = reasonController.text.trim().isEmpty
                            ? 'نامشخص'
                            : reasonController.text.trim();
                        final String resultMessage;
                        if (isExpelChoice) {
                          controller.disciplinaryExpel(selectedTarget!.id, reason);
                          resultMessage = controller.disciplinaryExpelMessage ?? '';
                        } else {
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
                child: Text(isExpelChoice ? 'اخراج' : 'اعمالِ تنبیه'),
              ),
            ],
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
      playedAt: DateTime.now(),
      winningTeamId: winnerId,
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
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text('پایانِ بازی و ثبت', style: TextStyle(color: AppColors.goldLight)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'کدوم تیم برنده شد؟ این نتیجه تو تاریخچه و آمار ثبت می‌شه.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                isExpanded: true,
                hint: const Text('انتخابِ تیمِ برنده', style: TextStyle(color: Colors.white70)),
                dropdownColor: AppColors.surfaceDark,
                value: selectedTeamId,
                items: [
                  ...presentTeamIds.map(
                    (teamId) => DropdownMenuItem(
                      value: teamId,
                      child: Text(
                        SarkoobTeams.byId(teamId)?.name ?? teamId,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const DropdownMenuItem(
                    value: 'unknown',
                    child: Text('نامشخص', style: TextStyle(color: Colors.white)),
                  ),
                ],
                onChanged: (v) => setDialogState(() => selectedTeamId = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: selectedTeamId != null
                  ? () async {
                      final winnerId = selectedTeamId!;
                      await _saveGameHistoryEntry(winnerId);
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                      if (!mounted) return;
                      final team = SarkoobTeams.byId(winnerId);
                      await showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        builder: (confirmContext) => AlertDialog(
                          backgroundColor: AppColors.surfaceDark,
                          title: const Text('🏆 بازی تموم شد', style: TextStyle(color: AppColors.goldLight)),
                          content: Text(
                            'بازی با بردِ تیمِ ${team?.name ?? 'نامشخص'} تموم شد و نتیجه تو '
                            'تاریخچه ثبت شد.',
                            style: TextStyle(color: team?.color ?? Colors.white70, fontSize: 15),
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () => Navigator.of(confirmContext).pop(),
                              child: const Text('تأیید'),
                            ),
                          ],
                        ),
                      );
                      if (!mounted) return;
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  : null,
              child: const Text('ثبت'),
            ),
          ],
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
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.goldDark.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🛡️ «${controller.playerById(controller.guaranteedPlayerId!).name}» تضمینِ قهرمانِ ملی رو داره؛ '
                'امروز نمی‌تونه رأی بیاره و در امانه.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
              ),
            ),
          if (!isIntro && controller.referendumScheduledToday)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.goldDark.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '🗳️ امروز، درست قبل از شروعِ رأی‌گیریِ حذف، رفراندومِ انتخابِ رهبرِ جامعه برگزار می‌شه.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
              ),
            ),
          if (!isIntro && controller.assassinationResultMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                controller.assassinationResultMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.bloodRedLight, fontWeight: FontWeight.bold),
              ),
            ),
          if (!isIntro && controller.gunFireResultMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                controller.gunFireResultMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
              ),
            ),
          if (!isIntro && controller.armedPlayers.isNotEmpty) _buildGunBanner(),
          if (!isIntro && controller.canAssassinateNow) _buildMercenaryDayBanner(),
          if (!isIntro && controller.bombTargetId != null && !controller.bombFullyResolved)
            _buildBombDayBanner(),
          if (!isIntro && controller.activeExecutionWord != null) _buildExecutionWordBanner(),
          if (isIntro)
            const Text(
              'هر بازیکن به ترتیب، خودش رو معرفی می‌کنه.',
              style: TextStyle(color: Colors.white60),
            ),
          const SizedBox(height: 16),
          if (isChallenge)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.bloodRed.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.bloodRedLight),
              ),
              child: const Text(
                '⚡ این یه چالشه؛ بعدش نوبتِ عادی ادامه پیدا می‌کنه.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          Text(
            speaker.name,
            style: AppTheme.headingFont(size: 30),
          ),
          const SizedBox(height: 16),
          CountdownTimerWidget(
            key: ValueKey('${speaker.id}-$isChallenge'),
            totalSeconds: controller.currentTurnSeconds,
            onFinished: () => MusicService.instance.playAlertLoop(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              MusicService.instance.stopAlert();
              if (isChallenge) {
                controller.finishChallenge();
              } else {
                controller.advanceSpeaker();
              }
            },
            child: Text(isChallenge ? 'پایان چالش' : 'نفر بعدی'),
          ),
          if (!isIntro && !isChallenge) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: (controller.challengeEligiblePlayers.isEmpty ||
                      !controller.canCurrentSpeakerGiveChallenge)
                  ? null
                  : () {
                      MusicService.instance.stopAlert();
                      _showChallengePicker();
                    },
              icon: const Icon(Icons.bolt),
              label: const Text('چالش گرفتن یه بازیکن دیگه'),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'ترتیب باقی‌مانده: ${controller.alivePlayers.where((p) => !p.hasSpokenThisRound).length} نفر',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          if (controller.todaysChallenges.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'چالش‌های امروز:\n${controller.todaysChallenges.map((c) => '${controller.playerById(c.giverId).name} ← چالش داد به → ${controller.playerById(c.receiverId).name}').join('\n')}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
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
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        builder: (context, scrollController) => SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  title,
                  style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: targets.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(emptyMessage, style: const TextStyle(color: Colors.white38)),
                        ),
                      )
                    : ListView(
                        controller: scrollController,
                        children: targets
                            .map(
                              (p) => ListTile(
                                title: Text(
                                  labelBuilder != null ? labelBuilder(p) : p.name,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                onTap: () {
                                  Navigator.of(sheetContext).pop();
                                  onSelected(p);
                                },
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChallengePicker() {
    _showPlayerListPicker(
      title: 'کدوم بازیکن چالش می‌گیره؟',
      targets: controller.challengeEligiblePlayers,
      onSelected: (p) => controller.useChallenge(p.id),
    );
  }

  Widget _buildStartVoteButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (controller.guaranteedPlayerId != null) ...[
            Text(
              '🛡️ «${controller.playerById(controller.guaranteedPlayerId!).name}» تضمینِ قهرمانِ ملی رو داره؛ '
              'امروز نمی‌تونه رأی بیاره و در امانه.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
          ],
          if (controller.assassinationResultMessage != null) ...[
            Text(
              controller.assassinationResultMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.bloodRedLight, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
          ],
          if (controller.gunFireResultMessage != null) ...[
            Text(
              controller.gunFireResultMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
          ],
          if (controller.communityLeaderExpulsionMessage != null) ...[
            Text(
              controller.communityLeaderExpulsionMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
          ],
          if (controller.discloserAnnouncement != null) ...[
            Text(
              controller.discloserAnnouncement!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
          ],
          if (controller.armedPlayers.isNotEmpty) ...[
            _buildGunBanner(),
            const SizedBox(height: 12),
          ],
          if (controller.canAssassinateNow) ...[
            _buildMercenaryDayBanner(),
            const SizedBox(height: 12),
          ],
          if (controller.activeExecutionWord != null) ...[
            _buildExecutionWordBanner(),
            const SizedBox(height: 12),
          ],
          const Text('همه صحبت کردن.', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: controller.startVoting,
            child: const Text('شروع رأی‌گیری'),
          ),
        ],
      ),
    );
  }

  Widget _buildStartIntroNightButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('همه معارفه کردن.', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: controller.moveToIntroNight,
            child: const Text('ادامه به شب معارفه'),
          ),
        ],
      ),
    );
  }

  Widget _buildGunBanner() {
    final armed = controller.armedPlayers;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bloodRed.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.bloodRedLight),
      ),
      child: Column(
        children: [
          const Text(
            '🔫 یکی از بازیکن‌ها الان اسلحه داره و می‌تونه اعلامِ اسلحه کنه',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '(کسایی که اسلحه دارن: ${armed.map((p) => p.name).join('، ')})',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _showFireGunDialog,
            child: const Text('اعلامِ اسلحه و شلیک'),
          ),
        ],
      ),
    );
  }

  Widget _buildMercenaryDayBanner() {
    final merc = controller.mercenaryPlayer!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bloodRed.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.bloodRedLight),
      ),
      child: Column(
        children: [
          const Text(
            '🔪 مزدور لباس‌شخصی می‌تونه همین الان ترور کنه (تا قبل از رأی‌گیری)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _showAssassinatePicker(merc),
            child: const Text('ترور'),
          ),
        ],
      ),
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
          final targets =
              controller.alivePlayers.where((p) => p.id != selectedShooter?.id).toList();
          return AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            title: const Text('اعلامِ اسلحه', style: TextStyle(color: AppColors.goldLight)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<SessionPlayer>(
                  isExpanded: true,
                  hint: const Text('کی اعلامِ اسلحه می‌کنه؟', style: TextStyle(color: Colors.white70)),
                  dropdownColor: AppColors.surfaceDark,
                  value: selectedShooter,
                  items: shooters
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.name, style: const TextStyle(color: Colors.white)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() {
                    selectedShooter = v;
                    selectedTarget = null;
                  }),
                ),
                const SizedBox(height: 8),
                DropdownButton<SessionPlayer>(
                  isExpanded: true,
                  hint: const Text('روی کی شلیک کنه؟', style: TextStyle(color: Colors.white70)),
                  dropdownColor: AppColors.surfaceDark,
                  value: selectedTarget,
                  items: targets
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.name, style: const TextStyle(color: Colors.white)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedTarget = v),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('انصراف'),
              ),
              ElevatedButton(
                onPressed: (selectedShooter != null && selectedTarget != null)
                    ? () {
                        controller.fireGun(selectedShooter!.id, selectedTarget!.id);
                        Navigator.of(dialogContext).pop();
                      }
                    : null,
                child: const Text('شلیک'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExecutionWordBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bloodRed.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.bloodRedLight),
      ),
      child: Column(
        children: [
          Text(
            '⚖️ حکم اعدام صادر شده؛ $_forbiddenWordLabel: «${controller.activeExecutionWord}»',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _showForbiddenWordPicker,
            child: const Text('یکی این کلمه رو گفت!'),
          ),
        ],
      ),
    );
  }

  /// بمب هنوز حل‌نشده‌ست؛ فقط اطلاع‌رسانیه — حل‌وفصلش خودکار، آخرِ همین
  /// روز و قبل از رأی‌گیری، تو _buildBombResolutionPhase انجام می‌شه.
  Widget _buildBombDayBanner() {
    final target = controller.bombTargetPlayer;
    if (target == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bloodRed.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.bloodRedLight),
      ),
      child: Text(
        '💣 بمب جلوی «${target.name}» گذاشته شده. آخرِ همین روز، قبل از رأی‌گیری، خودکار حل‌وفصل می‌شه.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
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
    // چه سناریوی سرکوب چه مافیا، شبِ معارفه یعنی «تیمِ توطئه‌گر» با هم
    // بیدار بشن و همدیگه رو ببینن — فقط بسته به این بازیِ خاص کدوم سناریو
    // بوده، اون تیم فرق می‌کنه.
    final isMafiaGame = controller.players.any((p) => p.teamId == SarkoobTeams.mafiaGang.id);
    final conspiracyTeamId = isMafiaGame ? SarkoobTeams.mafiaGang.id : SarkoobTeams.suppression.id;
    final wakingMembers = controller.players
        .where((p) => p.teamId == conspiracyTeamId && !p.isModiri)
        .toList();
    return Column(
      children: [
        Text(
          isMafiaGame
              ? 'اعضای مافیا بیدار بشن و همدیگه رو ببینن:'
              : 'اعضای تیم سرکوب بیدار بشن و همدیگه رو ببینن:',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: wakingMembers
                .map(
                  (p) => Card(
                    color: AppColors.bloodRed.withOpacity(0.35),
                    child: ListTile(
                      title: Text(p.name, style: const TextStyle(color: Colors.white)),
                      trailing: Text(
                        p.roleId != null ? (SarkoobRoles.byId(p.roleId!)?.name ?? '') : '',
                        style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'فرصت برای مشورت',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => controller.moveToDay(1),
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: const Text('ادامه به روز اول'),
        ),
      ],
    );
  }

  // ---------- رأی‌گیری (دور اول یا دوم) ----------

  // ---------- رأی‌گیریِ دورِ اول، نفربه‌نفر ----------

  Widget _buildEliminationVoteSequence() {
    final subject = controller.currentVoteSequenceSubject;

    if (subject == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.how_to_vote_rounded, color: AppColors.gold, size: 48),
          const SizedBox(height: 16),
          const Text('رأیِ همه‌ی بازیکنان شمرده شد.', style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 20),
          Game3DButton(
            label: 'محاسبه‌ی نتیجه',
            icon: Icons.checklist_rounded,
            onPressed: controller.isSecondVoteRound
                ? controller.resolveSecondVoteRound
                : controller.resolveFirstVoteRound,
          ),
        ],
      );
    }

    final electors = controller.voteSequenceElectors;
    final totalSubjects = controller.voteSequenceSubjects.length;

    return Column(
      children: [
        if (controller.gunExplosionSummary != null) ...[
          Text(
            controller.gunExplosionSummary!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.bloodRedLight),
          ),
          const SizedBox(height: 8),
        ],
        Text('رأی‌گیری برای «${subject.name}»', style: AppTheme.headingFont(size: 20), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(
          'نفرِ ${controller.voteSequenceIndex + 1} از $totalSubjects   —   ${subject.votes} رأی',
          style: const TextStyle(color: AppColors.goldLight, fontSize: 13),
        ),
        const SizedBox(height: 4),
        const Text(
          'بزن رو هرکی که علیهِ این بازیکن رأی داد',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.3,
            children: electors.map((e) {
              final isSelected = controller.votersAgainstCurrentSubject.contains(e.id);
              final enabled = e.isAlive && e.id != subject.id;
              return _voteCandidateButton(
                e,
                isSelected: isSelected,
                enabled: enabled,
                onTap: () => controller.toggleVoterForCurrentSubject(e.id),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: Game3DButton(
            label: 'بعدی',
            icon: Icons.arrow_forward_rounded,
            onPressed: controller.advanceVoteSequence,
          ),
        ),
      ],
    );
  }

  Widget _voteCandidateButton(
    SessionPlayer c, {
    required bool isSelected,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final palette = isSelected ? Game3DPalette.danger : Game3DPalette.gold;
    final colors = Game3DColors.of(palette);
    return Game3DSurface(
      onPressed: enabled ? onTap : null,
      palette: palette,
      depth: 5,
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      semanticLabel: c.name,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check_circle, color: colors.text, size: 16),
              const SizedBox(height: 2),
            ],
            Text(
              c.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.text, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ],
        ),
      ),
    );
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
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.how_to_vote_rounded, color: AppColors.gold, size: 48),
          const SizedBox(height: 16),
          const Text('رأیِ همه‌ی بازیکنان ثبت شد.', style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 20),
          Game3DButton(
            label: 'تعیینِ رهبر',
            icon: Icons.checklist_rounded,
            onPressed: controller.resolveReferendumRound,
          ),
        ],
      );
    }

    final candidates = controller.referendumCandidates;

    return Column(
      children: [
        Text(
          isRunoff ? 'رفراندوم: رأی‌گیریِ مجدد (تساوی)' : 'رفراندوم: انتخابِ رهبرِ جامعه',
          style: AppTheme.headingFont(size: 18),
          textAlign: TextAlign.center,
        ),
        if (isRunoff) ...[
          const SizedBox(height: 4),
          const Text(
            'رأی‌ها مساوی شد؛ این‌بار فقط بینِ همین نفرات دوباره رأی می‌گیریم.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
        const SizedBox(height: 10),
        Text(
          'انتخابِ رهبری برای «${voter.name}» چیه؟',
          style: AppTheme.headingFont(size: 20),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'نفرِ ${controller.referendumVoterIndex + 1} از ${controller.referendumVoters.length}',
          style: const TextStyle(color: AppColors.goldLight, fontSize: 13),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.3,
            children: candidates.map((c) {
              return _voteCandidateButton(
                c,
                isSelected: false,
                enabled: c.isAlive && c.id != voter.id,
                onTap: () => controller.castReferendumVoteAndAdvance(c.id),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityLeaderChoice() {
    final leader = controller.playerById(controller.communityLeaderId!);
    final targets = controller.alivePlayers.where((p) => p.id != leader.id).toList();
    return Column(
      children: [
        Text('رهبرِ جامعه: ${leader.name}', style: AppTheme.headingFont(size: 20)),
        const SizedBox(height: 8),
        const Text(
          'رهبرِ جامعه یه نفر رو انتخاب می‌کنه تا از جامعه اخراج بشه. این حذف قطعیه.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: targets
                .map(
                  (p) => Card(
                    color: AppColors.surfaceCard,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(p.name, style: const TextStyle(color: Colors.white)),
                      trailing: ElevatedButton(
                        onPressed: () => controller.communityLeaderExpel(p.id),
                        child: const Text('اخراج'),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  // ---------- دفاعیه ----------

  Widget _buildDiscloserPrompt() {
    final discloser = controller.playerById(controller.pendingDiscloserPlayerId!);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.campaign_rounded, color: AppColors.gold, size: 48),
        const SizedBox(height: 16),
        Text(
          '«${discloser.name}» (افشاگر) در روز از بازی خارج شد.',
          textAlign: TextAlign.center,
          style: AppTheme.headingFont(size: 18),
        ),
        const SizedBox(height: 8),
        const Text(
          'می‌خواد قبلِ رفتن، مافیابودن/نبودنِ یه نفر رو علناً افشا کنه؟',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: Game3DButton(
            label: 'بله، افشا کنه',
            icon: Icons.campaign,
            onPressed: () => _showDiscloserPicker(discloser),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: controller.dismissDiscloserPrompt,
          child: const Text('نه، رد کن', style: TextStyle(color: Colors.white54)),
        ),
      ],
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
    final names = controller.defenseCandidates.map((p) => p.name).join('، ');
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.gavel_rounded, color: AppColors.gold, size: 48),
        const SizedBox(height: 16),
        const Text('وارد دفاعیه شدن:', style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        Text(names, textAlign: TextAlign.center, style: AppTheme.headingFont(size: 22)),
        const SizedBox(height: 28),
        Game3DButton(
          label: 'شروعِ دفاعیه',
          icon: Icons.arrow_forward_rounded,
          onPressed: controller.acknowledgeDefenseAnnouncement,
        ),
      ],
    );
  }

  Widget _buildDefensePhase() {
    final speaker = controller.currentDefenseSpeaker;
    if (speaker == null) {
      return Center(
        child: ElevatedButton(
          onPressed: controller.startSecondVoteRound,
          child: const Text('شروع رأی‌گیری نهایی'),
        ),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('در حال دفاعیه:', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        Text(speaker.name, style: AppTheme.headingFont(size: 28)),
        const SizedBox(height: 16),
        CountdownTimerWidget(
          key: ValueKey('defense-${speaker.id}'),
          totalSeconds: widget.settings.speakSeconds,
          onFinished: () => MusicService.instance.playAlertLoop(),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            MusicService.instance.stopAlert();
            controller.advanceDefenseSpeaker();
          },
          child: const Text('پایان دفاعیه‌ی این نفر'),
        ),
      ],
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
    final team = SarkoobTeams.byId(teamId);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('بازی تموم شد!', style: AppTheme.headingFont(size: 26)),
            const SizedBox(height: 8),
            Text(
              '«${team?.name ?? teamId}» برنده شد',
              style: TextStyle(
                color: team?.color ?? AppColors.goldLight,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (controller.gameEndMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                controller.gameEndMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => _confirmAutoGameOver(teamId),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text('تأیید و بازگشت به منو'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChaosPhase() {
    final trio = controller.chaosPhasePlayers;
    if (trio.length != 3) return const SizedBox.shrink();
    final a = trio[0];
    final b = trio[1];
    final c = trio[2];
    return SingleChildScrollView(
      child: Column(
        children: [
          const Text('🌪️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text('فازِ آشوب', style: AppTheme.headingFont(size: 24)),
          const SizedBox(height: 8),
          const Text(
            'فقط ۳ نفر باقی موندن. دو نفر از این سه نفر باید تو زمانِ زیر با '
            'هم به توافق برسن و متحد بشن؛ نفرِ سوم طرفِ مقابله‌ست.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          CountdownTimerWidget(totalSeconds: controller.settings.speakSeconds * 2),
          const SizedBox(height: 24),
          const Text(
            'بعدِ توافق، مشخص کن کدوم دو نفر با هم دست دادن:',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          _chaosPairButton(a, b),
          _chaosPairButton(a, c),
          _chaosPairButton(b, c),
        ],
      ),
    );
  }

  Widget _chaosPairButton(SessionPlayer p1, SessionPlayer p2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        onPressed: () => controller.resolveChaosPhase(p1.id, p2.id),
        child: Text('${p1.name}   🤝   ${p2.name}'),
      ),
    );
  }


  Widget _buildDayResolved() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.gavel, size: 48, color: AppColors.gold),
          const SizedBox(height: 16),
          Text(
            controller.lastResolution?.message ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => controller.moveToNight(controller.roundNumber),
            child: const Text('ورود به شب'),
          ),
        ],
      ),
    );
  }

  // ---------- شب (بعد از معارفه) ----------

  Widget _buildNightPhase() {
    if (controller.lastNightSummary != null) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.nightlight_round, size: 48, color: AppColors.gold),
              const SizedBox(height: 16),
              const Text(
                'این متن رو عیناً به جمع اعلام کن:',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.goldLight, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gold),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  controller.lastNightSummary!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              if (controller.nightPrivateNotes != null) ...[
                const SizedBox(height: 20),
                const Text(
                  'یادداشتِ خصوصیِ گرداننده (این رو اعلام نکن):',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Text(
                  controller.nightPrivateNotes!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
              if (controller.statusInquiryChargesRemaining > 0 ||
                  controller.statusInquiryResultMessage != null) ...[
                const SizedBox(height: 24),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                if (controller.statusInquiryResultMessage != null) ...[
                  if (controller.statusInquiryLastVotePassed == true) ...[
                    const Text(
                      'استعلامِ وضعیت رأی آورد — این رو عیناً اعلام کن:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.goldLight,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: controller.statusInquiryLastVotePassed == true
                            ? AppColors.gold
                            : Colors.white24,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      controller.statusInquiryResultMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ] else if (controller.statusInquiryVoteOpen) ...[
                  Text(
                    'کی‌ها موافقِ استعلامِ وضعیت‌ان؟ (${controller.statusInquiryYesVotes} از ${controller.aliveCount} نفرِ زنده)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.3,
                    children: controller.alivePlayers.map((p) {
                      final isSelected = controller.statusInquiryYesVoters.contains(p.id);
                      return _voteCandidateButton(
                        p,
                        isSelected: isSelected,
                        enabled: true,
                        onTap: () => controller.toggleStatusInquiryVoter(p.id),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: controller.resolveStatusInquiryVote,
                    child: const Text('ثبتِ نتیجه‌ی رأی'),
                  ),
                ] else ...[
                  OutlinedButton(
                    onPressed: controller.openStatusInquiryVote,
                    child: Text(
                      'آیا استعلامِ وضعیت می‌خواید؟ '
                      '(${controller.statusInquiryChargesRemaining} تا مونده)',
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => controller.moveToDay(controller.roundNumber + 1),
                child: Text('ادامه به روز ${controller.roundNumber + 1}'),
              ),
            ],
          ),
        ),
      );
    }

    switch (controller.currentNightStep) {
      case NightStepKind.sorkoobTeam:
        return _buildSorkoobTeamStep();
      case NightStepKind.mossadLeader:
        return _buildRoleNightStep(
          wakeLabel: '$_independentLeaderRoleName بیدار بشه',
          sleepLabel: '$_independentLeaderRoleName چشمش رو ببنده',
          playerName: controller.mossadLeaderPlayer?.name,
          body: _buildMossadLeaderSection(),
          canAdvance: controller.canAdvancePastMossadLeaderStep,
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
          wakeLabel: 'قهرمان ملی بیدار بشه',
          sleepLabel: 'قهرمان ملی چشمش رو ببنده',
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
              const Text(
                'همه‌ی نقش‌ها اقدامِ امشب‌شون رو انجام دادن.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: controller.finishNight,
                child: const Text('پایان شب'),
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
  Widget _buildSorkoobRoster() {
    final leaderTeamId = _isMafiaGame ? SarkoobTeams.mafiaGang.id : SarkoobTeams.suppression.id;
    final members = controller.alivePlayers.where((p) => p.teamId == leaderTeamId).toList();
    if (members.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: members.map((p) {
          final role = p.roleId != null ? SarkoobRoles.byId(p.roleId!) : null;
          return Text(
            '👤 ${p.name} — ${role?.name ?? '$_plainLeaderTeamLabel (بدون نقشِ خاص)'}',
            style: const TextStyle(color: Colors.white),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSorkoobTeamStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Text('شب ${controller.roundNumber}', style: AppTheme.headingFont(size: 24)),
          const SizedBox(height: 8),
          Text(
            '🔴 اعضای $_leaderTeamName بیدار بشن',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildSorkoobRoster(),
          const SizedBox(height: 16),
          if (controller.sorkoobDisabledTonight)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'امشب (به‌خاطرِ حذف‌شدنِ ژینا دیشب) تیمِ سرکوب هیچ قابلیتی '
                'نداره — فقط برو به مرحله‌ی بعد.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            )
          else ...[
            _buildLeaderDecisionSection(),
            if (controller.canIssueExecutionOrder) ...[
              const SizedBox(height: 24),
              const Divider(color: AppColors.gold),
              const SizedBox(height: 8),
              _buildJudiciarySection(),
            ],
            if (controller.interrogatorPlayer != null) ...[
              const SizedBox(height: 24),
              const Divider(color: AppColors.gold),
              const SizedBox(height: 8),
              _buildInterrogatorSection(),
            ],
            if (controller.intelligenceMinisterPlayer != null) ...[
              const SizedBox(height: 24),
              const Divider(color: AppColors.gold),
              const SizedBox(height: 8),
              _buildIntelQuestionSection(),
            ],
            if (controller.policeCommanderPlayer != null) ...[
              const SizedBox(height: 24),
              const Divider(color: AppColors.gold),
              const SizedBox(height: 8),
              _buildDetentionSection(),
            ],
            if (controller.mercenaryPlayer != null &&
                controller.isStillActiveTonight(controller.mercenaryPlayer!)) ...[
              const SizedBox(height: 24),
              const Divider(color: AppColors.gold),
              const SizedBox(height: 8),
              _buildMercenaryNightSection(),
            ],
            if (controller.natashaPlayer != null &&
                controller.isStillActiveTonight(controller.natashaPlayer!) &&
                !controller.natashaPlayer!.natashaSilenceUsed) ...[
              const SizedBox(height: 24),
              const Divider(color: AppColors.gold),
              const SizedBox(height: 8),
              _buildNatashaSection(),
            ],
            if (controller.saboteurPlayer != null &&
                controller.isStillActiveTonight(controller.saboteurPlayer!)) ...[
              const SizedBox(height: 24),
              const Divider(color: AppColors.gold),
              const SizedBox(height: 8),
              _buildSaboteurSection(),
            ],
            if (controller.bomberPlayer != null) ...[
              const SizedBox(height: 24),
              const Divider(color: AppColors.gold),
              const SizedBox(height: 8),
              _buildBomberSection(),
            ],
          ],
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: controller.canAdvancePastSorkoobTeamStep ? controller.advanceNightStep : null,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: Text('🌑 اعضای $_leaderTeamName چشم‌هاشون رو ببندن'),
          ),
        ],
      ),
    );
  }

  /// بخشِ بمب‌گذار تو مرحله‌ی تیمِ رهبر — کاملاً مستقل از شات/سلاخی/مذاکره،
  /// چون یک‌بارمصرفِ کلِ بازیه، نه یه تصمیمِ هرشبه.
  Widget _buildBomberSection() {
    if (controller.bomberChargeUsed) {
      return const Text(
        'بمب‌گذار قبلاً بمبش رو کار گذاشته (یک‌بارمصرفه؛ اگه هنوز حل نشده، '
        'فردا صبح و آخرِ روز خودکار پیگیری می‌شه).',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white38),
      );
    }
    return Column(
      children: [
        const Text(
          'بمب‌گذار می‌تونه امشب، یک‌بار برای همیشه، جلوی یه بازیکن بمب '
          'بذاره و یه رمزِ خنثی‌سازی (۱ تا ۴) انتخاب کنه.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.local_fire_department),
          label: const Text('کارگذاریِ بمب'),
          onPressed: controller.canPlantBombTonight ? _showBomberPicker : null,
        ),
      ],
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
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('رمزِ خنثی‌سازی رو انتخاب کن', style: TextStyle(color: Colors.white)),
        content: _buildBombCodeGrid((code) {
          Navigator.of(dialogContext).pop();
          controller.plantBomb(target.id, code);
        }),
      ),
    );
  }

  /// فازِ «خواب نیمروزی»: آخرِ روز، قبل از رأی‌گیری، اگه بمبی هنوز حل‌نشده
  /// باشه. سه شاخه‌ی مکالمه‌ای (هدف=محافظ / پرسیدن از محافظ / حدسِ خودِ
  /// هدف) + یه صفحه‌ی نتیجه‌ی نهایی که با تأییدِ گرداننده می‌ره سراغِ
  /// رأی‌گیری.
  Widget _buildBombResolutionPhase() {
    final target = controller.bombTargetPlayer;
    if (target == null) return const SizedBox.shrink();

    if (controller.bombOutcomeMessage != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            controller.bombOutcomeMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.goldLight,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'حالا بگو همه چشماشون رو باز کنن.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: controller.acknowledgeBombOutcome,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: const Text('ادامه به رأی‌گیری'),
          ),
        ],
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
      child: Column(
        children: [
          Text('🌙 خواب نیمروزی', style: AppTheme.headingFont(size: 22)),
          const SizedBox(height: 4),
          const Text(
            'همه‌ی بازیکن‌ها چشماشون رو ببندن — یه تصمیمِ مخفیانه در جریانه.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 24),
          branch,
        ],
      ),
    );
  }

  Widget _playerBadge(String label, String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withOpacity(0.4)),
      ),
      child: Text(
        '$label: $name',
        style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBombGuardSelfBranch(SessionPlayer target, SessionPlayer guard) {
    return Column(
      children: [
        _playerBadge('👤 هدفِ بمب و محافظ، هردو', guard.name),
        const SizedBox(height: 16),
        Text(
          'چون خودِ محافظ هدفه، رمزِ درست رو بی‌سروصدا بهش نشون بده: '
          '${controller.bombCorrectCode}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => controller.resolveBombCode(controller.bombCorrectCode!),
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: const Text('تأیید — بمب خنثی شد'),
        ),
      ],
    );
  }

  Widget _buildBombAskGuardBranch() {
    final guard = controller.guardPlayer!;
    return Column(
      children: [
        _playerBadge('👤 این نقش (محافظ)', guard.name),
        const SizedBox(height: 16),
        const Text(
          'محافظ رو بی‌سروصدا بیدار کن و بپرس: می‌خوای برای نجاتِ هدف فدا بشی؟',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => controller.recordGuardSacrificeAnswer(true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.goldDark),
              child: const Text('بله، فدا می‌شه'),
            ),
            const SizedBox(width: 16),
            OutlinedButton(
              onPressed: () => controller.recordGuardSacrificeAnswer(false),
              child: const Text('نه'),
            ),
          ],
        ),
      ],
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
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF2A1B02)),
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
          children: [codeButton(1), const SizedBox(width: 16), codeButton(2)],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [codeButton(3), const SizedBox(width: 16), codeButton(4)],
        ),
      ],
    );
  }

  Widget _buildBombCodeGuessBranch({required SessionPlayer guesser, required SessionPlayer forTarget}) {
    final isSelf = guesser.id == forTarget.id;
    return Column(
      children: [
        _playerBadge(isSelf ? '👤 این نقش (هدف)' : '👤 این نقش (محافظ)', guesser.name),
        const SizedBox(height: 16),
        Text(
          isSelf
              ? 'حالا «${guesser.name}» باید رمزِ خنثی‌سازی رو حدس بزنه:'
              : '«${guesser.name}» به‌جایِ «${forTarget.name}» رمز رو حدس می‌زنه:',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        _buildBombCodeGrid((code) => controller.resolveBombCode(code)),
      ],
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
    return SingleChildScrollView(
      child: Column(
        children: [
          Text(
            '🔓 $wakeLabel',
            textAlign: TextAlign.center,
            style: AppTheme.headingFont(size: 22),
          ),
          if (playerName != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withOpacity(0.4)),
              ),
              child: Text(
                '👤 این نقش: $playerName',
                style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          const SizedBox(height: 16),
          body,
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: canAdvance ? controller.advanceNightStep : null,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: Text('🌑 $sleepLabel'),
          ),
        ],
      ),
    );
  }

  // ---------- رهبرِ موساد ----------

  Widget _buildMossadLeaderSection() {
    final leader = controller.mossadLeaderPlayer!;

    if (controller.roundNumber == 1) {
      if (leader.mossadPlaystyle != null) {
        return Text(
          leader.mossadPlaystyle == MossadPlaystyle.assassination
              ? 'شیوه انتخاب شد: 🕶 عملیاتِ ترور'
              : 'شیوه انتخاب شد: 🗡 عملیاتِ سری',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
        );
      }
      return Column(
        children: [
          const Text(
            'رهبرِ موساد باید همین امشب، برای همیشه، شیوه‌ی بازیش رو انتخاب کنه:',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: () => controller.chooseMossadPlaystyle(MossadPlaystyle.assassination),
            child: const Text('🕶 عملیاتِ ترور'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: () => controller.chooseMossadPlaystyle(MossadPlaystyle.secretOperation),
            child: const Text('🗡 عملیاتِ سری'),
          ),
        ],
      );
    }

    if (!controller.isStillActiveTonight(leader)) {
      return Text(
        '$_independentLeaderRoleName دیگه در بازی نیست.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white38),
      );
    }

    final isAssassination = leader.mossadPlaystyle == MossadPlaystyle.assassination;
    final resultText = controller.mossadAssassinationResultMessage;
    return Column(
      children: [
        Text(
          isAssassination
              ? 'شیوه: 🕶 عملیاتِ ترور — هدف + حدسِ نقش (فقط رو اعضای سرکوب اثر داره)'
              : 'شیوه: 🗡 عملیاتِ سری — یه شاتِ ساده رو یه بازیکن (زره جلوشو می‌گیره)',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
        if (isAssassination && resultText != null) ...[
          const SizedBox(height: 8),
          Text(
            resultText,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
          ),
        ],
        const SizedBox(height: 16),
        if (controller.canMossadActTonight)
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: () => isAssassination
                ? _showMossadAssassinationPicker(leader)
                : _showMossadShootPicker(leader),
            child: Text(isAssassination ? 'ترور (هدف + حدسِ نقش)' : 'شات'),
          )
        else
          const Text('امشب دیگه اقدامی ممکن نیست.', style: TextStyle(color: Colors.white38)),
      ],
    );
  }

  void _showMossadAssassinationPicker(SessionPlayer leader) {
    final targets = controller.alivePlayers.where((p) => p.id != leader.id).toList();
    SessionPlayer? selectedTarget;
    String? selectedRoleId;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('ترور: هدف + حدسِ نقش', style: TextStyle(color: AppColors.goldLight)),
                    const SizedBox(height: 12),
                    DropdownButton<SessionPlayer>(
                      hint: const Text('انتخاب هدف', style: TextStyle(color: Colors.white70)),
                      dropdownColor: AppColors.surfaceDark,
                      value: selectedTarget,
                      items: targets
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.name, style: const TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                      onChanged: (v) => setSheetState(() => selectedTarget = v),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      hint: const Text('حدسِ نقش', style: TextStyle(color: Colors.white70)),
                      dropdownColor: AppColors.surfaceDark,
                      value: selectedRoleId,
                      items: controller.rolesInPlayForTeam(SarkoobTeams.suppression.id)
                          .map((r) => DropdownMenuItem(
                                value: r.id,
                                child: Text(r.name, style: const TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                      onChanged: (v) => setSheetState(() => selectedRoleId = v),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: (selectedTarget != null && selectedRoleId != null)
                          ? () {
                              controller.mossadAssassinate(selectedTarget!.id, selectedRoleId!);
                              Navigator.of(context).pop();
                            }
                          : null,
                      child: const Text('تایید ترور'),
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

  void _showMossadShootPicker(SessionPlayer leader) {
    _showPlayerListPicker(
      title: 'شات روی کی؟',
      targets: controller.alivePlayers.where((p) => p.id != leader.id).toList(),
      onSelected: (p) => controller.mossadShoot(p.id),
    );
  }

  // ---------- تحلیلگرِ سیاسی ----------

  Widget _buildPoliticalAnalystSection() {
    final result = controller.lastIndependentInvestigationResult;
    final targetName = controller.lastIndependentInvestigationTargetName;
    final membershipQuestion = _isMafiaGame ? 'زودیاکه' : 'عضوِ یه تیمِ مستقله';
    final membershipYes = _isMafiaGame ? 'زودیاکه' : 'مستقله';
    final membershipNo = _isMafiaGame ? 'زودیاک نیست' : 'مستقل نیست';
    return Column(
      children: [
        Text(
          '$_politicalAnalystRoleName می‌تونه امشب یکی از بازیکن‌ها رو استعلام بگیره: '
          'آیا $membershipQuestion؟',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        if (result != null && targetName != null) ...[
          Text(
            result == InvestigationResult.like
                ? '🔍 نتیجه‌ی «$targetName»: 👍 لایک ($membershipYes)'
                : '🔍 نتیجه‌ی «$targetName»: 👎 دیس‌لایک ($membershipNo)',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'این نتیجه رو فقط خصوصی و درِگوشی به خودِ $_politicalAnalystRoleName بگو.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          icon: const Icon(Icons.travel_explore),
          label: const Text('استعلامِ یه بازیکن'),
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
        style: const TextStyle(color: Colors.white38),
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
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.how_to_vote),
          label: const Text('درخواستِ رفراندوم'),
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          onPressed: controller.canRequestReferendumTonight ? controller.requestReferendum : null,
        ),
      ],
    );
  }

  Widget _buildRapperSection() {
    final rapper = controller.rapperPlayer!;
    final result = controller.rapperResultMessage;
    final resistance = controller.activeResistanceMembers;
    // نکته‌ی مهم: اگه انتخابِ رپر معترض غلط بوده باشه، خودش حذف می‌شه —
    // ولی این نتیجه رو همین‌جا نشون نمی‌دیم، وگرنه معلوم می‌شه که دقیقاً
    // همین نوبت باعثِ حذفش شده و نقشش لو می‌ره. اون حذف فقط تو جمع‌بندیِ
    // آخرِ شب (کنارِ بقیه‌ی کشته‌ها) اعلام می‌شه. isStillActiveTonight
    // (نه isAlive خام) چون اگه یکیِ دیگه (نه خودِ نتیجه‌ی این نوبت) امشب
    // سلاخی/ترورش کرده باشه، نتیجه‌ی موفقِ خودِ همین نوبت باید دیده بشه.
    final showResult = result != null && controller.isStillActiveTonight(rapper);
    return Column(
      children: [
        Text(
          '$_rapperRoleName می‌تونه امشب یه نفر رو برای عضوگیری تو $_resistanceGroupLabel انتخاب کنه:',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        if (showResult) ...[
          Text(
            result,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (resistance.isNotEmpty)
            Text(
              'حالا بگو: اعضای $_resistanceGroupLabel (${resistance.map((p) => p.name).join('، ')}) بیدار بشن '
              'تا وضعیتِ جدید رو ببینن.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          icon: const Icon(Icons.groups),
          label: const Text('انتخابِ یه بازیکن'),
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
        const Text(
          'ناتاشا می‌تونه (فقط یک‌بار در کلِ بازی) یه نفر رو تا پایانِ روزِ بعد ساکت کنه:',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.voice_over_off_rounded),
          label: const Text('انتخابِ یه بازیکن'),
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
        const Text(
          'خرابکار می‌تونه امشب رو تفنگِ یه نفر خرابکاری کنه (اگه فردا با اسلحه‌ی جنگی شلیک کنه، تیر به خودش برمی‌گرده):',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        if (target != null) ...[
          const SizedBox(height: 6),
          Text('امشب رو تفنگِ «${target.name}» خرابکاری شده.',
              style: const TextStyle(color: AppColors.goldLight, fontSize: 12)),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.build_circle_outlined),
          label: const Text('انتخابِ یه بازیکن'),
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
              style: const TextStyle(color: AppColors.bloodRedLight, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            leaderAlive
                ? '$_leaderTeamName بیدار می‌شه و باهم مشورت می‌کنن؛ تصمیم نهایی با $_leaderRoleName‌ست.'
                : fallback
                    ? '$_leaderRoleName دیگه در بازی نیست؛ سلاخی از بین رفته، ولی شاتِ معمولیِ تیمی همیشه باقی می‌مونه.'
                    : 'هیچ عضوِ زنده‌ای از $_leaderTeamName باقی نمونده؛ شاتی در کار نیست.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 24),
          if (leaderAlive) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.gps_fixed),
              label: const Text('شات (حذف تیمی)'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: () => _showShootPicker(leader),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.content_cut),
              label: Text('سلاخی (${leader.slaughterChargesRemaining ?? 0} باقیمانده)'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: AppColors.bloodRedLight,
              ),
              onPressed: (leader.slaughterChargesRemaining ?? 0) > 0
                  ? () => _showSlaughterPicker(leader)
                  : null,
            ),
          ] else if (fallback) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.gps_fixed),
              label: const Text('شات (حذف تیمی)'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: _showFallbackShootPicker,
            ),
          ],
          // نکته‌ی مهم: این شرط از رویِ زنده‌بودنِ رهبر مستقل بررسی می‌شه،
          // چون قابلیتِ مذاکره به رهبر ربطی نداره و حتی بعدِ حذفِ رهبر هم
          // باید در دسترس بمونه.
          if (controller.canUseNegotiate) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.handshake),
              label: Text('مذاکره (اغفالِ $_plainCitizenLabel)'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: AppColors.goldDark,
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
            style: const TextStyle(color: Colors.white, fontSize: 16),
          )
        else if (controller.negotiateResultMessage != null)
          Text(
            controller.negotiateResultMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          )
        else
          const Text('تصمیمِ امشب ثبت شد.', style: TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _buildJudiciarySection() {
    return Column(
      children: [
        Text(
          '${_isMafiaGame ? "افسونگر" : "رئیس قوه قضاییه"} می‌تونه (فقط یک‌بار در کل بازی) حکم اعدام صادر کنه:',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.gavel),
          label: const Text('صدور حکم اعدام'),
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
        backgroundColor: AppColors.surfaceDark,
        title: const Text('کلمه‌ی حکم اعدام', style: TextStyle(color: AppColors.goldLight)),
        content: TextField(
          controller: wordController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'کلمه رو وارد کن'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () {
              if (wordController.text.trim().isNotEmpty) {
                controller.issueExecutionOrder(wordController.text);
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('ثبت'),
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
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        if (target != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'بازجوییِ انجام‌شده: «$target»'
              '${controller.lastInterrogationQuestion != null ? ' — سوال: ${controller.lastInterrogationQuestion}' : ''}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.goldLight),
            ),
          ),
        if (!interrogator.interrogationUsed)
          OutlinedButton.icon(
            icon: const Icon(Icons.record_voice_over),
            label: const Text('بازجوییِ یه بازیکن'),
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
          backgroundColor: AppColors.surfaceDark,
          title: const Text('بازجویی', style: TextStyle(color: AppColors.goldLight)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<SessionPlayer>(
                isExpanded: true,
                hint: const Text('انتخابِ هدف', style: TextStyle(color: Colors.white70)),
                dropdownColor: AppColors.surfaceDark,
                value: selectedTarget,
                items: targets
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.name, style: const TextStyle(color: Colors.white)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedTarget = v),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: questionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'سوال (اختیاری، فقط یادآوریِ خودت)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: selectedTarget != null
                  ? () {
                      controller.interrogate(selectedTarget!.id, question: questionController.text);
                      Navigator.of(dialogContext).pop();
                    }
                  : null,
              child: const Text('ثبت'),
            ),
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
          style: const TextStyle(color: Colors.white70),
        ),
        if (result != null && names != null) ...[
          const SizedBox(height: 8),
          Text(
            '🔍 «${names.join('، ')}» نقش دارن؟ → '
            '${result == InvestigationResult.like ? '👍 لایک (همه‌شون نقش دارن)' : '👎 دیس‌لایک (حداقل یکی‌شون نداره)'}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
          ),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.help_outline),
          label: const Text('پرسیدنِ سؤالِ اطلاعاتی'),
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
          backgroundColor: AppColors.surfaceDark,
          title: const Text('سؤالِ اطلاعاتی', style: TextStyle(color: AppColors.goldLight)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'انتخاب کن این سؤال دقیقاً درباره‌ی کدوم بازیکن‌هاست:',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                ...targets.map(
                  (p) => CheckboxListTile(
                    dense: true,
                    value: selected.contains(p.id),
                    activeColor: AppColors.gold,
                    onChanged: (v) => setDialogState(() {
                      if (v ?? false) {
                        selected.add(p.id);
                      } else {
                        selected.remove(p.id);
                      }
                    }),
                    title: Text(p.name, style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: selected.isNotEmpty
                  ? () {
                      controller.askIntelQuestion(selected.toList());
                      Navigator.of(dialogContext).pop();
                    }
                  : null,
              child: const Text('پرسیدن'),
            ),
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
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.local_police),
          label: const Text('بازداشتِ یه بازیکن'),
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
        const Text(
          'مزدور لباس‌شخصی می‌تونه امشب یه نفر رو ترور کنه — ولی خودش هم بلافاصله لو می‌ره و حذف می‌شه.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.dangerous),
          label: const Text('ترور'),
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
          'قهرمان ملی می‌تونه امشب یه بازیکن رو تضمین کنه (${hero.guaranteesRemaining ?? 0} '
          'تضمینِ باقیمانده در کلِ بازی).',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.shield),
          label: const Text('تضمینِ یه بازیکن'),
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
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 10),
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
                    backgroundColor: AppColors.surfaceCard,
                    labelStyle: const TextStyle(color: Colors.white),
                    deleteIconColor: AppColors.bloodRedLight,
                    onDeleted: () => controller.takeBackGun(p.id),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          icon: const Icon(Icons.front_hand),
          label: const Text('دادنِ اسلحه به یه بازیکن'),
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
          backgroundColor: AppColors.surfaceDark,
          title: const Text('دادنِ اسلحه', style: TextStyle(color: AppColors.goldLight)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<SessionPlayer>(
                isExpanded: true,
                hint: const Text('انتخابِ بازیکن', style: TextStyle(color: Colors.white70)),
                dropdownColor: AppColors.surfaceDark,
                value: selectedTarget,
                items: targets
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.name, style: const TextStyle(color: Colors.white)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedTarget = v),
              ),
              const SizedBox(height: 8),
              RadioListTile<GunType>(
                value: GunType.blank,
                groupValue: selectedType,
                activeColor: AppColors.gold,
                onChanged: (v) => setDialogState(() => selectedType = v!),
                title: const Text('مشقی', style: TextStyle(color: Colors.white)),
              ),
              RadioListTile<GunType>(
                value: GunType.war,
                groupValue: selectedType,
                activeColor: AppColors.bloodRedLight,
                onChanged: (rebel.warGunsRemaining ?? 0) > 0
                    ? (v) => setDialogState(() => selectedType = v!)
                    : null,
                title: Text(
                  'جنگی (${rebel.warGunsRemaining ?? 0} باقیمانده)',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              onPressed: selectedTarget != null
                  ? () {
                      controller.giveGun(selectedTarget!.id, selectedType);
                      Navigator.of(dialogContext).pop();
                    }
                  : null,
              child: const Text('تایید'),
            ),
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
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Text(
          'نجاتِ خودش: ${doc.selfSavesUsed} از ${widget.settings.doctorMaxSelfSaves} بار در کلِ بازی',
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 10),
        if (saved.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: saved
                .map(
                  (p) => Chip(
                    label: Text(p.name),
                    backgroundColor: AppColors.surfaceCard,
                    labelStyle: const TextStyle(color: Colors.white),
                    deleteIconColor: AppColors.bloodRedLight,
                    onDeleted: () => controller.undoDoctorSave(p.id),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          icon: const Icon(Icons.healing),
          label: const Text('نجاتِ یه بازیکنِ دیگه'),
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
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        if (result != null && targetName != null) ...[
          Text(
            result == InvestigationResult.like
                ? '🔍 نتیجه‌ی «$targetName»: 👍 لایک'
                : '🔍 نتیجه‌ی «$targetName»: 👎 دیس‌لایک',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'این نتیجه رو فقط خصوصی و درِگوشی به خودِ $_hackerRoleName بگو.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          icon: const Icon(Icons.search),
          label: const Text('استعلامِ یه بازیکن'),
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
          style: const TextStyle(color: Colors.white70),
        ),
        if (showResult) ...[
          const SizedBox(height: 8),
          Text(
            result,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.bold),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.gavel),
              label: Text(_revolutionaryActionLabel),
              onPressed: (controller.canRevolutionaryActTonight && charges > 0)
                  ? () => _showRevolutionaryExecutePicker(fighter)
                  : null,
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.content_cut),
              label: const Text('سلاخی'),
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
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('سلاخی: هدف + حدسِ نقش', style: TextStyle(color: AppColors.goldLight)),
                    const SizedBox(height: 12),
                    DropdownButton<SessionPlayer>(
                      hint: const Text('انتخاب هدف', style: TextStyle(color: Colors.white70)),
                      dropdownColor: AppColors.surfaceDark,
                      value: selectedTarget,
                      items: targets
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.name, style: const TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                      onChanged: (v) => setSheetState(() => selectedTarget = v),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      hint: const Text('حدسِ نقش', style: TextStyle(color: Colors.white70)),
                      dropdownColor: AppColors.surfaceDark,
                      value: selectedRoleId,
                      items: controller.rolesInPlay
                          .map((r) => DropdownMenuItem(
                                value: r.id,
                                child: Text(r.name, style: const TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                      onChanged: (v) => setSheetState(() => selectedRoleId = v),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: (selectedTarget != null && selectedRoleId != null)
                          ? () {
                              controller.revolutionarySlaughter(selectedTarget!.id, selectedRoleId!);
                              Navigator.of(context).pop();
                            }
                          : null,
                      child: const Text('تایید سلاخی'),
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
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        if (halfAlive.isEmpty)
          const Text(
            'فعلاً هیچ بازیکنِ نیمه‌جانی برای برگردوندن نیست.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          )
        else
          OutlinedButton.icon(
            icon: const Icon(Icons.favorite),
            label: const Text('برگردوندنِ یه بازیکنِ نیمه‌جان'),
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
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('سلاخی: هدف + حدسِ نقش', style: TextStyle(color: AppColors.goldLight)),
                    const SizedBox(height: 12),
                    DropdownButton<SessionPlayer>(
                      hint: const Text('انتخاب هدف', style: TextStyle(color: Colors.white70)),
                      dropdownColor: AppColors.surfaceDark,
                      value: selectedTarget,
                      items: targets
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.name, style: const TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                      onChanged: (v) => setSheetState(() => selectedTarget = v),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      hint: const Text('حدسِ نقش', style: TextStyle(color: Colors.white70)),
                      dropdownColor: AppColors.surfaceDark,
                      value: selectedRoleId,
                      items: controller.rolesInPlay
                          .map((r) => DropdownMenuItem(
                                value: r.id,
                                child: Text(r.name, style: const TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                      onChanged: (v) => setSheetState(() => selectedRoleId = v),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: (selectedTarget != null && selectedRoleId != null)
                          ? () {
                              controller.leaderSlaughter(selectedTarget!.id, selectedRoleId!);
                              Navigator.of(context).pop();
                            }
                          : null,
                      child: const Text('تایید سلاخی'),
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
