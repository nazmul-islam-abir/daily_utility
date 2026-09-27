import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../models/note.dart';
import '../../services/data_refresh_service.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'note_editor_screen.dart';
import 'simple_note_sheet.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [scheme.surfaceContainerLow, scheme.surface])),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(scheme: scheme),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: HiveService.notes.listenable(),
                  builder: (context, Box<Note> box, _) {
                    final notes = box.values.toList()
                      ..sort((a, b) {
                        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
                        return b.updatedAt.compareTo(a.updatedAt);
                      });
                    final filtered = _query.isEmpty
                        ? notes
                        : notes.where((n) {
                            final q = _query.toLowerCase();
                            return n.title.toLowerCase().contains(q) || n.body.toLowerCase().contains(q);
                          }).toList();

                    if (notes.isEmpty) {
                      return EmptyState(
                        icon: Icons.lightbulb_outline,
                        title: tr(context, 'কোনো নোট নেই', 'No notes yet'),
                        message: tr(context, '+ বাটনে চেপে প্রথম নোট লিখুন', 'Tap + to capture your first note'),
                      );
                    }
                    if (filtered.isEmpty) {
                      return EmptyState(
                        icon: Icons.search_off,
                        title: tr(context, 'কিছু পাওয়া যায়নি', 'Nothing found'),
                        message: tr(context, 'অন্য কিওয়ার্ড দিয়ে চেষ্টা করুন', 'Try a different keyword'),
                      );
                    }
                    return _MasonryView(notes: filtered);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.notes,
        onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: scheme.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (_) => const SimpleNoteSheet()),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader({required ColorScheme scheme}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr(context, 'একটি ভাবনা ধরুন', 'Capture a thought'), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: scheme.onSurface, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(tr(context, 'আপনার সব নোট এক জায়গায়।', 'All your notes in one place.'), style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          TextField(
            style: TextStyle(color: scheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600),
            cursorColor: scheme.primary,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search, color: scheme.onSurfaceVariant),
              hintText: tr(context, 'নোট খুঁজুন…', 'Search notes…'),
              hintStyle: TextStyle(color: scheme.onSurfaceVariant),
              filled: true,
              fillColor: scheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none),
            ),
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
        ],
      ),
    );
  }
}

class _MasonryView extends StatelessWidget {
  final List<Note> notes;
  const _MasonryView({required this.notes});

  @override
  Widget build(BuildContext context) {
    final left = <Note>[];
    final right = <Note>[];
    for (int i = 0; i < notes.length; i++) {
      if (i.isEven) {
        left.add(notes[i]);
      } else {
        right.add(notes[i]);
      }
    }
    return RefreshIndicator(
      onRefresh: () async {
        DataRefreshService.instance.bump();
        await Future<void>.delayed(const Duration(milliseconds: 350));
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 110),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(children: [for (final n in left) _KeepNoteCard(note: n, paddingBottom: 8)])),
            const SizedBox(width: 8),
            Expanded(child: Column(children: [for (final n in right) _KeepNoteCard(note: n, paddingBottom: 8)])),
          ],
        ),
      ),
    );
  }
}

class _KeepNoteCard extends StatelessWidget {
  final Note note;
  final double paddingBottom;
  const _KeepNoteCard({required this.note, this.paddingBottom = 8});

  String _preview(BuildContext context, Note n) {
    if (n.type == 'checklist') {
      final done = n.checklistItems.where((c) => c.checked).length;
      if (n.checklistItems.isEmpty) return tr(context, 'খালি চেকলিস্ট', 'Empty checklist');
      final lines = n.checklistItems.take(4).map((c) => '${c.checked ? '☑' : '☐'} ${c.text}').join('\n');
      return '$done/${n.checklistItems.length}\n$lines';
    }
    return n.body.isEmpty ? tr(context, 'কোনো লেখা নেই', 'No additional text') : n.body;
  }

  @override
  Widget build(BuildContext context) {
    final cardColorVal = note.colorValue == 0 ? 0xFFF59E0B : note.colorValue;
    final color = Color(cardColorVal);
    final scheme = Theme.of(context).colorScheme;
    final hasTitle = note.title.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: paddingBottom),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => NoteEditorScreen(existing: note))),
          onLongPress: () => _showOptions(context),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasTitle) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          note.title,
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: color.withValues(alpha: 0.95), height: 1.3),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (note.isPinned) Padding(padding: const EdgeInsets.only(left: 4, top: 2), child: Icon(Icons.push_pin, size: 14, color: color)),
                    ],
                  ),
                  const SizedBox(height: 6),
                ] else if (note.isPinned) ...[
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.push_pin, size: 14, color: color),
                    ),
                  ),
                ],
                Text(
                  _preview(context, note),
                  style: TextStyle(
                    fontSize: hasTitle ? 12.5 : 14,
                    fontWeight: hasTitle ? FontWeight.normal : FontWeight.w700,
                    color: scheme.onSurface,
                    height: 1.4,
                  ),
                  maxLines: 12,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (note.type == 'checklist')
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(Icons.check_box_outlined, size: 12, color: color),
                      ),
                    Text(DateFormat('d MMM').format(note.updatedAt), style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.75), fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(note.isPinned ? Icons.push_pin : Icons.push_pin_outlined, color: scheme.primary),
              title: Text(note.isPinned ? tr(context, 'পিন মুক্ত করুন', 'Unpin') : tr(context, 'পিন করুন', 'Pin')),
              onTap: () {
                note.isPinned = !note.isPinned;
                note.updatedAt = DateTime.now();
                note.save();
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: scheme.primary),
              title: Text(tr(context, 'সম্পাদনা', 'Edit')),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => NoteEditorScreen(existing: note)));
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: scheme.error),
              title: Text(tr(context, 'মুছুন', 'Delete'), style: TextStyle(color: scheme.error)),
              onTap: () async {
                final ok = await confirmDelete(context, title: tr(context, 'নোটটি মুছবেন?', 'Delete this note?'));
                if (ok) note.delete();
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
