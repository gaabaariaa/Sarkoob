import 'package:flutter/material.dart';
import '../models/history.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class RosterScreen extends StatefulWidget {
  final bool selectionMode;
  final List<String> initialSelection;

  const RosterScreen({super.key, this.selectionMode = false, this.initialSelection = const []});

  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  final StorageService _storage = StorageService();
  final TextEditingController _nameController = TextEditingController();
  List<SavedPlayerProfile> _roster = [];
  final Set<String> _selectedIds = <String>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final roster = await _storage.loadRoster();
    if (!mounted) return;
    setState(() {
      _roster = roster;
      _selectedIds
        ..clear()
        ..addAll(roster.where((p) => widget.initialSelection.contains(p.name)).map((p) => p.id));
      _loading = false;
    });
  }

  Future<void> _addPlayer() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    if (_roster.any((p) => p.name == name)) {
      _nameController.clear();
      return;
    }
    final profile = SavedPlayerProfile(id: DateTime.now().microsecondsSinceEpoch.toString(), name: name);
    setState(() {
      _roster.add(profile);
      _nameController.clear();
      if (widget.selectionMode) _selectedIds.add(profile.id);
    });
    await _storage.saveRoster(_roster);
  }

  Future<void> _renamePlayer(SavedPlayerProfile profile) async {
    final controller = TextEditingController(text: profile.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('ویرایشِ اسم', style: TextStyle(color: AppColors.goldLight)),
        content: TextField(controller: controller, style: const TextStyle(color: Colors.white), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('انصراف')),
          ElevatedButton(onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()), child: const Text('ذخیره')),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || newName.isEmpty) return;
    setState(() => profile.name = newName);
    await _storage.saveRoster(_roster);
  }

  Future<void> _deletePlayer(SavedPlayerProfile profile) async {
    setState(() {
      _roster.removeWhere((p) => p.id == profile.id);
      _selectedIds.remove(profile.id);
    });
    await _storage.saveRoster(_roster);
  }

  void _finishSelection() {
    final names = _roster.where((p) => _selectedIds.contains(p.id)).map((p) => p.name).toList();
    Navigator.of(context).pop(names);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectionMode ? 'انتخاب بازیکنان' : 'بازیکنان'),
        actions: widget.selectionMode
            ? [TextButton(onPressed: _finishSelection, child: Text('تأیید (${_selectedIds.length})'))]
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.selectionMode
                        ? 'بازیکن‌های ذخیره‌شده را برای این میز انتخاب کن. می‌توانی بعداً از صفحه‌ی شروع هم اسم جدید اضافه کنی.'
                        : 'این لیست دائمیه و بینِ بازی‌های مختلف می‌مونه؛ موقعِ شروعِ بازیِ جدید می‌تونی مستقیم ازش اسم اضافه کنی.',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _nameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'اسمِ بازیکنِ جدید', border: OutlineInputBorder()), onSubmitted: (_) => _addPlayer())),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: _addPlayer, child: const Text('افزودن')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _roster.isEmpty
                        ? const Center(child: Text('هنوز کسی تو لیست نیست.', style: TextStyle(color: Colors.white38)))
                        : ListView.builder(
                            itemCount: _roster.length,
                            itemBuilder: (context, index) {
                              final profile = _roster[index];
                              final selected = _selectedIds.contains(profile.id);
                              return Card(
                                color: AppColors.surfaceCard,
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: selected ? AppColors.gold : AppColors.gold.withOpacity(0.3))),
                                child: ListTile(
                                  onTap: widget.selectionMode ? () => setState(() => selected ? _selectedIds.remove(profile.id) : _selectedIds.add(profile.id)) : null,
                                  leading: widget.selectionMode
                                      ? Checkbox(value: selected, onChanged: (_) => setState(() => selected ? _selectedIds.remove(profile.id) : _selectedIds.add(profile.id)))
                                      : null,
                                  title: Text(profile.name, style: const TextStyle(color: Colors.white)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(icon: const Icon(Icons.edit, color: AppColors.goldLight), onPressed: () => _renamePlayer(profile)),
                                      IconButton(icon: const Icon(Icons.delete, color: AppColors.bloodRedLight), onPressed: () => _deletePlayer(profile)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  if (widget.selectionMode) ...[
                    const SizedBox(height: 10),
                    Game3DSelectionButton(count: _selectedIds.length, onPressed: _finishSelection),
                  ],
                ],
              ),
            ),
    );
  }
}

class Game3DSelectionButton extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;
  const Game3DSelectionButton({super.key, required this.count, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.check_rounded),
      label: Text('افزودن ${count} بازیکن به میز'),
    );
  }
}
