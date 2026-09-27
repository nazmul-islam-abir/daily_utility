import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../models/mood_entry.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import 'mood_screen.dart';

const _uuid = Uuid();

const _kPrompts = [
  ['আজ কী আপনাকে হাসিয়েছে?', 'What made you smile today?'],
  ['আজ আপনি কৃতজ্ঞ কিসের?', 'What are you grateful for today?'],
  ['আজকের সেরা মুহূর্ত কোনটি?', 'What was the best moment of today?'],
  ['আজ আপনি কী শিখেছেন?', 'What did you learn today?'],
  ['আজ আপনি কী অর্জন করেছেন?', 'What did you accomplish today?'],
];

/// Mood logger — design #7. Date strip, prompt, 5 emoji faces, free-text
/// reflection, Save Entry button, last-saved footer.
class MoodLoggerScreen extends StatefulWidget {
  const MoodLoggerScreen({super.key});

  @override
  State<MoodLoggerScreen> createState() => _MoodLoggerScreenState();
}

class _MoodLoggerScreenState extends State<MoodLoggerScreen> {
  late DateTime _date;
  int _mood = 0;
  final _body = TextEditingController();
  int _promptIndex = 0;
  DateTime? _lastSavedAt;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
    final existing = entryForDate(_date);
    if (existing != null) {
      _mood = existing.moodLevel;
      _body.text = existing.body;
      _lastSavedAt = existing.createdAt;
    }
    _promptIndex = DateTime.now().day % _kPrompts.length;
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_mood == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'একটি মেজাজ বেছে নিন', 'Pick a mood')),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      );
      return;
    }
    final existing = entryForDate(_date);
    final now = DateTime.now();
    if (existing != null) {
      existing.moodLevel = _mood;
      existing.body = _body.text;
      existing.prompt = _kPrompts[_promptIndex][LocaleService.isBangla ? 0 : 1];
      existing.createdAt = now;
      await existing.save();
    } else {
      final entry = MoodEntry(
        id: _uuid.v4(),
        date: DateTime(_date.year, _date.month, _date.day),
        moodLevel: _mood,
        prompt: _kPrompts[_promptIndex][LocaleService.isBangla ? 0 : 1],
        body: _body.text,
        createdAt: now,
      );
      await HiveService.moods.put(entry.id, entry);
    }
    setState(() => _lastSavedAt = now);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'সংরক্ষিত!', 'Saved!')),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.notifier,
      builder: (context, locale, _) {
        final weekStart = _date.subtract(Duration(days: _date.weekday - 1));
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // Top section: "X mood entries" info badge.
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.emoji_emotions_outlined, size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  ValueListenableBuilder(
                    valueListenable: HiveService.moods.listenable(),
                    builder: (context, _, __) {
                      final count = HiveService.moods.length;
                      return Text(
                        tr(context, '$count টি মেজাজ এন্ট্রি', '$count mood entries'),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  tr(context, 'তারিখ বাছাই', 'SELECT DATE'),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
                Text(_formatMonth(_date), style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 78,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 14,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final d = weekStart.add(Duration(days: i));
                  final isSelected = d.year == _date.year && d.month == _date.month && d.day == _date.day;
                  return GestureDetector(
                    onTap: () async {
                      setState(() => _date = d);
                      final existing = entryForDate(d);
                      setState(() {
                        _mood = existing?.moodLevel ?? 0;
                        _body.text = existing?.body ?? '';
                        _lastSavedAt = existing?.createdAt;
                      });
                    },
                    child: AnimatedContainer(
                      duration: AppAnimations.fast,
                      width: 56,
                      decoration: BoxDecoration(
                        color: isSelected ? scheme.primary : scheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][d.weekday - 1],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? scheme.onPrimary.withValues(alpha: 0.85) : scheme.onSurfaceVariant,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${d.day}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? scheme.onPrimary : scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.cardGradient(AppColors.mood),
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, 'দৈনিক প্রম্পট', 'Daily Prompt'),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: scheme.onSurfaceVariant, letterSpacing: 0.4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(context, _kPrompts[_promptIndex][0], _kPrompts[_promptIndex][1]),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: scheme.onSurface, height: 1.2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              tr(context, 'আপনি কেমন বোধ করছেন?', 'HOW ARE YOU FEELING?'),
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: scheme.onSurfaceVariant, letterSpacing: 0.6),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (i) {
                final lvl = i + 1;
                final color = moodColors[i];
                final selected = _mood == lvl;
                return GestureDetector(
                  onTap: () => setState(() => _mood = lvl),
                  child: AnimatedContainer(
                    duration: AppAnimations.fast,
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? color.withValues(alpha: 0.18) : scheme.surfaceContainerHigh,
                      border: Border.all(
                        color: selected ? color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(moodEmojis[i], style: const TextStyle(fontSize: 26)),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Center(
              child: AnimatedSwitcher(
                duration: AppAnimations.fast,
                child: _mood == 0
                    ? const SizedBox.shrink()
                    : Text(
                        moodLabel(context, _mood),
                        key: ValueKey(_mood),
                        style: TextStyle(fontWeight: FontWeight.w800, color: moodColors[_mood - 1]),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              tr(context, 'আজকের প্রতিফলন', "TODAY'S REFLECTION"),
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: scheme.onSurfaceVariant, letterSpacing: 0.6),
            ),
            const SizedBox(height: 8),
            Container(
              height: 180,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: TextField(
                controller: _body,
                maxLines: null,
                expands: true,
                style: TextStyle(color: scheme.onSurface, fontSize: 14),
                decoration: InputDecoration.collapsed(
                  hintText: tr(context, 'আপনার ভাবনা এখানে লিখুন…', 'Write your thoughts here…'),
                  hintStyle: TextStyle(color: scheme.onSurfaceVariant),
                  border: InputBorder.none,
                  fillColor: Colors.transparent,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_body.text.split(RegExp(r"\s+")).where((s) => s.isNotEmpty).length} ${tr(context, 'শব্দ', 'words')}',
                style: TextStyle(color: scheme.outline, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.mood, foregroundColor: Colors.white, minimumSize: const Size(0, 56)),
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(tr(context, 'এন্ট্রি সংরক্ষণ', 'Save Entry'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            if (_lastSavedAt != null) ...[
              const SizedBox(height: 14),
              Center(
                child: Text(
                  tr(context, 'সর্বশেষ সংরক্ষণ: ${_ago(_lastSavedAt!)}', 'Last saved: ${_ago(_lastSavedAt!)}'),
                  style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String _formatMonth(DateTime d) {
    const m = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${m[d.month - 1]} ${d.year}';
  }

  String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return tr(context, 'এখনই', 'just now');
    if (diff.inMinutes < 60) return tr(context, '${diff.inMinutes} মিনিট আগে', '${diff.inMinutes} min ago');
    if (diff.inHours < 24) return tr(context, '${diff.inHours} ঘণ্টা আগে', '${diff.inHours} h ago');
    return tr(context, '${diff.inDays} দিন আগে', '${diff.inDays} d ago');
  }
}
