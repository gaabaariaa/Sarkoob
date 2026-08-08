import 'package:flutter/material.dart';
import '../models/history.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class RosterScreen extends StatefulWidget {
  const RosterScreen({super.key});

  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  final StorageService _storage = StorageService();
  final TextEditingController _nameController = TextEditingController();
  List<SavedPlayerProfile> _roster = [];
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
    setState(() {
      _roster = roster;
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
    final profile = SavedPlayerProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
    );
    setState(() {
      _roster.add(profile);
      _nameController.clear();
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
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    setState(() => profile.name = newName);
    await _storage.saveRoster(_roster);
  }

  Future<void> _deletePlayer(SavedPlayerProfile profile) async {
    setState(() => _roster.removeWhere((p) => p.id == profile.id));
    await _storage.saveRoster(_roster);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بازیکنان')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'این لیست دائمیه و بینِ بازی‌های مختلف می‌مونه؛ موقعِ '
                    'شروعِ بازیِ جدید می‌تونی مستقیم ازش اسم اضافه کنی.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'اسمِ بازیکنِ جدید',
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
                  Expanded(
                    child: _roster.isEmpty
                        ? const Center(
                            child: Text(
                              'هنوز کسی تو لیست نیست.',
                              style: TextStyle(color: Colors.white38),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _roster.length,
                            itemBuilder: (context, index) {
                              final profile = _roster[index];
                              return Card(
                                color: AppColors.surfaceCard,
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(color: AppColors.gold.withOpacity(0.3)),
                                ),
                                child: ListTile(
                                  title: Text(
                                    profile.name,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: AppColors.goldLight),
                                        onPressed: () => _renamePlayer(profile),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: AppColors.bloodRedLight),
                                        onPressed: () => _deletePlayer(profile),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
