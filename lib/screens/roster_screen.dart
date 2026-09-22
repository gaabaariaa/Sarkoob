import 'package:flutter/material.dart';
import '../models/history.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class RosterScreen extends StatefulWidget {
  final bool selectionMode;
  final List<String> initialSelection;
  RosterScreen({super.key, this.selectionMode = false, this.initialSelection = []});
  @override State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  final StorageService _storage = StorageService();
  final TextEditingController _nameController = TextEditingController();
  List<SavedPlayerProfile> _roster = [];
  final Set<String> _selectedIds = <String>{};
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _nameController.dispose(); super.dispose(); }

  Future<void> _load() async {
    final roster = await _storage.loadRoster();
    if (!mounted) return;
    setState(() {
      _roster = roster;
      _selectedIds..clear()..addAll(roster.where((p) => widget.initialSelection.contains(p.name)).map((p) => p.id));
      _loading = false;
    });
  }

  Future<void> _addPlayer() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _roster.any((p) => p.name == name)) { _nameController.clear(); return; }
    final profile = SavedPlayerProfile(id: DateTime.now().microsecondsSinceEpoch.toString(), name: name);
    setState(() { _roster.add(profile); _nameController.clear(); if (widget.selectionMode) _selectedIds.add(profile.id); });
    await _storage.saveRoster(_roster);
  }

  Future<void> _renamePlayer(SavedPlayerProfile profile) async {
    final controller = TextEditingController(text: profile.name);
    final newName = await showDialog<String>(context: context, builder: (dialogContext) => AlertDialog(
      backgroundColor: AppTheme.uiSurface,
      title: Text('ویرایشِ اسم', style: TextStyle(color: AppTheme.uiPrimaryLight)),
      content: TextField(controller: controller, style: TextStyle(color: Colors.white), autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text('انصراف')),
        ElevatedButton(onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()), child: Text('ذخیره')),
      ],
    ));
    controller.dispose();
    if (newName == null || newName.isEmpty) return;
    setState(() => profile.name = newName);
    await _storage.saveRoster(_roster);
  }

  Future<void> _deletePlayer(SavedPlayerProfile profile) async {
    setState(() { _roster.removeWhere((p) => p.id == profile.id); _selectedIds.remove(profile.id); });
    await _storage.saveRoster(_roster);
  }

  void _toggleAll() {
    setState(() {
      if (_selectedIds.length == _roster.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(_roster.map((p) => p.id));
      }
    });
  }

  void _finishSelection() {
    final names = _roster.where((p) => _selectedIds.contains(p.id)).map((p) => p.name).toList();
    Navigator.of(context).pop(names);
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _roster.removeAt(oldIndex);
      _roster.insert(newIndex, item);
    });
    await _storage.saveRoster(_roster);
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _roster.isNotEmpty && _selectedIds.length == _roster.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectionMode ? 'انتخاب بازیکنان' : 'بازیکنان'),
        actions: widget.selectionMode ? [
          TextButton.icon(onPressed: _toggleAll, icon: Icon(allSelected ? Icons.deselect_rounded : Icons.select_all_rounded), label: Text(allSelected ? 'لغو همه' : 'انتخاب همه')),
          TextButton(onPressed: _finishSelection, child: Text('تأیید (${_selectedIds.length})')),
        ] : null,
      ),
      body: _loading ? Center(child: CircularProgressIndicator()) : Padding(
        padding: EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(widget.selectionMode ? 'بازیکن‌ها را انتخاب کن. برای جابه‌جایی ترتیب، دستت را روی آیکون ☰ نگه دار و بکش.' : 'این لیست دائمیه و بینِ بازی‌های مختلف می‌مونه؛ موقعِ شروعِ بازیِ جدید می‌تونی مستقیم ازش اسم اضافه کنی.', style: TextStyle(color: Colors.white60, fontSize: 12)),
          SizedBox(height: 12),
          Row(children: [Expanded(child: TextField(controller: _nameController, style: TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'اسمِ بازیکنِ جدید', border: OutlineInputBorder()), onSubmitted: (_) => _addPlayer())), SizedBox(width: 8), ElevatedButton(onPressed: _addPlayer, child: Text('افزودن'))]),
          SizedBox(height: 12),
          Expanded(child: _roster.isEmpty ? Center(child: Text('هنوز کسی تو لیست نیست.', style: TextStyle(color: Colors.white38))) : ReorderableListView.builder(
            itemCount: _roster.length,
            onReorder: _reorder,
            buildDefaultDragHandles: false,
            itemBuilder: (context, index) {
              final profile = _roster[index];
              final selected = _selectedIds.contains(profile.id);
              return Card(
                key: ValueKey(profile.id),
                color: AppTheme.uiCard,
                margin: EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: selected ? AppTheme.uiPrimary : AppTheme.uiPrimary.withAlpha(77))),
                child: ListTile(
                  onTap: widget.selectionMode ? () => setState(() => selected ? _selectedIds.remove(profile.id) : _selectedIds.add(profile.id)) : null,
                  leading: widget.selectionMode ? Checkbox(value: selected, onChanged: (_) => setState(() => selected ? _selectedIds.remove(profile.id) : _selectedIds.add(profile.id))): null,
                  title: Text(profile.name, style: TextStyle(color: Colors.white)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: Icon(Icons.edit, color: AppTheme.uiPrimaryLight), onPressed: () => _renamePlayer(profile)),
                    IconButton(icon: Icon(Icons.delete, color: AppColors.bloodRedLight), onPressed: () => _deletePlayer(profile)),
                    ReorderableDragStartListener(index: index, child: Padding(padding: EdgeInsets.all(8), child: Icon(Icons.drag_handle_rounded, color: AppTheme.uiPrimaryLight))),
                  ]),
                ),
              );
            },
          )),
          if (widget.selectionMode) ...[
            SizedBox(height: 10),
            ElevatedButton.icon(onPressed: _finishSelection, icon: Icon(Icons.check_rounded), label: Text('افزودن ${_selectedIds.length} بازیکن به میز')),
          ],
        ]),
      ),
    );
  }
}
