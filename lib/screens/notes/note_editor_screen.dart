import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../models/note.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';

const _uuid = Uuid();

const List<int> kNoteColors = [
  0x00000000, // Default / Theme surface
  0xFFF2A93B, // Amber / Orange
  0xFF3D5AFE, // Blue
  0xFF16A34A, // Green
  0xFFE1493D, // Red / Coral
  0xFF9C5CF0, // Purple
  0xFF1CA7B8, // Teal / Cyan
  0xFFEF6C9B, // Pink
];

/// Google Keep / Word Document style note editor — "Note Khata".
/// Title is completely optional; user can write freeform text immediately.
/// Auto-saves on navigate back. Discards completely blank notes.
class NoteEditorScreen extends StatefulWidget {
  final Note? existing;
  const NoteEditorScreen({super.key, this.existing});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _newChecklistCtrl = TextEditingController();

  String _type = 'text'; // 'text', 'checklist'
  bool _pinned = false;
  bool _sticky = false;
  int _color = 0x00000000;
  late List<ChecklistItem> _checklist;
  bool _hasSaved = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _checklist = (e?.checklistItems ?? [])
        .map((c) => ChecklistItem(id: c.id, text: c.text, checked: c.checked))
        .toList();
    if (e != null) {
      _titleCtrl.text = e.title;
      _bodyCtrl.text = e.body;
      _type = e.type;
      _pinned = e.isPinned;
      _sticky = e.isSticky;
      _color = e.colorValue;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _newChecklistCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveNote({bool popAfter = false}) async {
    if (_hasSaved && popAfter) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    final hasChecklist = _type == 'checklist' && _checklist.any((c) => c.text.trim().isNotEmpty);

    // If completely empty, delete existing or discard new
    if (title.isEmpty && body.isEmpty && !hasChecklist) {
      if (widget.existing != null) {
        await widget.existing!.delete();
      }
      _hasSaved = true;
      if (popAfter && mounted) Navigator.of(context).pop();
      return;
    }

    final isNew = widget.existing == null;
    final note = widget.existing ??
        Note(
          id: _uuid.v4(),
          title: title,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    note
      ..title = title
      ..body = _bodyCtrl.text
      ..type = _type
      ..checklistItems = _checklist
      ..isPinned = _pinned
      ..isSticky = _sticky
      ..colorValue = _color
      ..updatedAt = DateTime.now();

    if (isNew) {
      await HiveService.notes.put(note.id, note);
    } else {
      await note.save();
    }

    _hasSaved = true;
    if (popAfter && mounted) Navigator.of(context).pop();
  }

  void _addChecklistLine([String? text]) {
    final t = (text ?? _newChecklistCtrl.text).trim();
    if (t.isEmpty) return;
    setState(() {
      _checklist.add(ChecklistItem(id: _uuid.v4(), text: t));
      _newChecklistCtrl.clear();
    });
  }

  Color _getBackgroundColor(ColorScheme scheme) {
    if (_color == 0 || _color == 0x00000000) {
      return scheme.surfaceContainerLow;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = Color(_color);
    return isDark
        ? Color.alphaBlend(baseColor.withValues(alpha: 0.25), scheme.surface)
        : Color.alphaBlend(baseColor.withValues(alpha: 0.12), Colors.white);
  }

  void _showColorPicker(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr(context, 'নোটের রঙ', 'Note colour'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: kNoteColors.map((c) {
                final isDefault = c == 0 || c == 0x00000000;
                final col = isDefault ? scheme.surfaceContainerHigh : Color(c);
                final isSelected = _color == c;
                return GestureDetector(
                  onTap: () {
                    setState(() => _color = c);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: col,
                      shape: BoxShape.circle,
                    ),
                    child: isDefault
                        ? Icon(Icons.format_color_reset_outlined, size: 18, color: scheme.onSurfaceVariant)
                        : (isSelected ? const Icon(Icons.check, size: 18, color: Colors.white) : null),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = _getBackgroundColor(scheme);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _saveNote(popAfter: true);
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: tr(context, 'ফিরে যান', 'Back'),
            onPressed: () => _saveNote(popAfter: true),
          ),
          actions: [
            IconButton(
              tooltip: _pinned ? tr(context, 'পিন মুক্ত করুন', 'Unpin') : tr(context, 'পিন করুন', 'Pin'),
              icon: Icon(
                _pinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: _pinned ? AppColors.notes : scheme.onSurfaceVariant,
              ),
              onPressed: () => setState(() => _pinned = !_pinned),
            ),
            IconButton(
              tooltip: tr(context, 'রঙ পরিবর্তন', 'Change colour'),
              icon: Icon(Icons.palette_outlined, color: scheme.onSurfaceVariant),
              onPressed: () => _showColorPicker(context),
            ),
            IconButton(
              tooltip: tr(context, 'সংরক্ষণ করুন', 'Save'),
              icon: Icon(Icons.check, color: scheme.primary),
              onPressed: () => _saveNote(popAfter: true),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  // Title — Borderless, large font like Google Keep / Word file header
                  TextField(
                    controller: _titleCtrl,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: tr(context, 'শিরোনাম (ঐচ্ছিক)', 'Title'),
                      hintStyle: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Note Body / Khata Document Canvas
                  if (_type == 'text')
                    TextField(
                      controller: _bodyCtrl,
                      autofocus: widget.existing == null && _titleCtrl.text.isEmpty,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.55,
                        color: scheme.onSurface,
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: tr(context, 'নোট লিখুন...', 'Note...'),
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                  else
                    _buildChecklistEditor(scheme),
                ],
              ),
            ),
            // Bottom bar — Type switcher (Text / Checklist) & time indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: bg,
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: _type == 'checklist' ? tr(context, 'সাধারণ টেক্সট', 'Text mode') : tr(context, 'চেকলিস্ট', 'Checklist mode'),
                      icon: Icon(
                        _type == 'checklist' ? Icons.subject : Icons.check_box_outlined,
                        color: scheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        setState(() {
                          _type = _type == 'checklist' ? 'text' : 'checklist';
                        });
                      },
                    ),
                    const Spacer(),
                    Text(
                      widget.existing != null
                          ? tr(context, 'সম্পাদিত: ${DateFormat('d MMM, h:mm a').format(widget.existing!.updatedAt)}', 'Edited: ${DateFormat('d MMM, h:mm a').format(widget.existing!.updatedAt)}')
                          : tr(context, 'নতুন নোট', 'New note'),
                      style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistEditor(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _checklist.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Checkbox(
                  value: _checklist[i].checked,
                  activeColor: scheme.primary,
                  onChanged: (v) => setState(() => _checklist[i].checked = v ?? false),
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: _checklist[i].text,
                    style: TextStyle(
                      fontSize: 15.5,
                      color: scheme.onSurface,
                      decoration: _checklist[i].checked ? TextDecoration.lineThrough : null,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      hintText: tr(context, 'আইটেম…', 'Item…'),
                      hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    ),
                    onChanged: (v) => _checklist[i].text = v,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: scheme.onSurfaceVariant),
                  onPressed: () => setState(() => _checklist.removeAt(i)),
                ),
              ],
            ),
          ),
        Row(
          children: [
            const Icon(Icons.add, size: 20, color: AppColors.notes),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _newChecklistCtrl,
                style: TextStyle(fontSize: 15.5, color: scheme.onSurface),
                decoration: InputDecoration(
                  hintText: tr(context, 'নতুন আইটেম যোগ করুন', 'Add new item'),
                  hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
                onSubmitted: _addChecklistLine,
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle, color: scheme.primary),
              onPressed: () => _addChecklistLine(),
            ),
          ],
        ),
      ],
    );
  }
}
