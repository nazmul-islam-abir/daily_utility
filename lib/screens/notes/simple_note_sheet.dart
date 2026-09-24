import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/note.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart' show tr;
import '../../theme/app_theme.dart';

const _uuid = Uuid();

const List<int> kNoteColors = [
  0x00000000,
  0xFFF2A93B,
  0xFF3D5AFE,
  0xFF16A34A,
  0xFFE1493D,
  0xFF9C5CF0,
  0xFF1CA7B8,
  0xFFEF6C9B,
];

/// Quick Note Sheet — seamless Google Keep / Word canvas style.
/// Title is optional; saving without a title works automatically.
class SimpleNoteSheet extends StatefulWidget {
  const SimpleNoteSheet({super.key});

  @override
  State<SimpleNoteSheet> createState() => _SimpleNoteSheetState();
}

class _SimpleNoteSheetState extends State<SimpleNoteSheet> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  int _color = 0x00000000;
  bool _pinned = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();

    if (title.isEmpty && body.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final now = DateTime.now();
    final note = Note(
      id: _uuid.v4(),
      title: title,
      body: _bodyCtrl.text,
      type: 'text',
      isPinned: _pinned,
      isSticky: true,
      colorValue: _color,
      createdAt: now,
      updatedAt: now,
    );
    await HiveService.notes.put(note.id, note);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Text(
                tr(context, 'দ্রুত নোট', 'Quick note'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: scheme.onSurface),
              ),
              const Spacer(),
              IconButton(
                tooltip: _pinned ? tr(context, 'পিন মুক্ত করুন', 'Unpin') : tr(context, 'পিন করুন', 'Pin'),
                icon: Icon(
                  _pinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: _pinned ? AppColors.notes : scheme.onSurfaceVariant,
                ),
                onPressed: () => setState(() => _pinned = !_pinned),
              ),
              IconButton(
                tooltip: tr(context, 'সংরক্ষণ', 'Save'),
                icon: Icon(Icons.check, color: scheme.primary),
                onPressed: _save,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Title field — borderless & optional
          TextField(
            controller: _titleCtrl,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: scheme.onSurface),
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: tr(context, 'শিরোনাম (ঐচ্ছিক)', 'Title (optional)'),
              hintStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 8),
          // Body field — borderless khata document style
          TextField(
            controller: _bodyCtrl,
            autofocus: true,
            minLines: 4,
            maxLines: 10,
            style: TextStyle(fontSize: 15.5, height: 1.5, color: scheme.onSurface),
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: tr(context, 'এখানে নোট লিখুন...', 'Type note here...'),
              hintStyle: TextStyle(fontSize: 15.5, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            children: kNoteColors.map((c) {
              final isDefault = c == 0 || c == 0x00000000;
              final col = isDefault ? scheme.surfaceContainerHigh : Color(c);
              final isSelected = _color == c;
              return GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: col,
                    shape: BoxShape.circle,
                  ),
                  child: isDefault
                      ? Icon(Icons.format_color_reset_outlined, size: 14, color: scheme.onSurfaceVariant)
                      : (isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: Text(tr(context, 'সংরক্ষণ করুন', 'Save Note')),
            ),
          ),
        ],
      ),
    );
  }
}
