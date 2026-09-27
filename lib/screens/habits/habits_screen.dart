import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/habit.dart';
import '../../services/habit_service.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'habit_editor_sheet.dart';

IconData _iconFromCode(int cp) {
  // ignore: non_const_argument_for_const_parameter
  final icon = IconData(cp, fontFamily: 'MaterialIcons', matchTextDirection: false);
  return icon;
}

/// Habits screen — design #5. Hero with Current Streak + Consistency, a
/// 7-day weekly-view row, today's habits with circular check buttons, and
/// a monthly-trend sparkline at the bottom.
class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.notifier,
      builder: (context, locale, _) {
        return Scaffold(
          backgroundColor: scheme.surfaceContainerLow,
          appBar: AppBar(title: Text(tr(context, 'অভ্যাস', 'Habits'))),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.habits,
            onPressed: () => _addHabit(context),
            child: const Icon(Icons.add),
          ),
          body: ValueListenableBuilder(
            valueListenable: HiveService.habits.listenable(),
            builder: (context, Box<Habit> box, _) {
              final habits = box.values.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
              final today = DateTime.now();
              final longestStreak = habits.isEmpty ? 0 : habits.map((h) => HabitService.currentStreak(h, today: today)).fold(0, (a, b) => a > b ? a : b);
              final avgConsistency = habits.isEmpty ? 0 : (habits.map((h) => HabitService.consistency(h, today: today)).fold(0, (a, b) => a + b) / habits.length).round();

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Icon(Icons.spa_outlined, size: 16, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            tr(context, '${habits.length} টি অভ্যাস', '${habits.length} habits'),
                            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: Row(
                        children: [
                          Expanded(child: _statTile(tr(context, 'বর্তমান ধারা', 'CURRENT STREAK'), '$longestStreak', tr(context, 'দিন', 'days'), AppColors.habits)),
                          const SizedBox(width: 10),
                          Expanded(child: _statTile(tr(context, 'সামঞ্জস্য', 'CONSISTENCY'), '$avgConsistency', '%', AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: Row(
                        children: [
                          Text(tr(context, 'সাপ্তাহিক ভিউ', 'Weekly View'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: scheme.onSurface)),
                          const Spacer(),
                          Text(_weekRange(today), style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _WeeklyRow(habits: habits, today: today),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      child: Row(
                        children: [
                          Text(tr(context, 'আজকের অভ্যাস', "Today's Habits"), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: scheme.onSurface)),
                          const Spacer(),
                          TextButton.icon(onPressed: () => _addHabit(context), icon: const Icon(Icons.add, size: 16), label: Text(tr(context, 'নতুন', 'New'))),
                        ],
                      ),
                    ),
                  ),
                  if (habits.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(icon: Icons.spa_outlined, title: tr(context, 'কোনো অভ্যাস নেই', 'No habits yet'), message: tr(context, '+ বাটনে চেপে প্রথম অভ্যাস যোগ করুন', 'Tap + to add your first habit')),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      sliver: SliverList.separated(
                        itemCount: habits.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final h = habits[i];
                          final due = HabitService.isDueToday(h, today: today);
                          final done = HabitService.isChecked(h, today);
                          return _HabitRow(habit: h, dueToday: due, doneToday: done);
                        },
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      child: _MonthlyTrendCard(habits: habits),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _statTile(String label, String value, String suffix, Color color) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.6)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedCounter(value: double.tryParse(value) ?? 0, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: scheme.onSurface)),
              const SizedBox(width: 4),
              Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(suffix, style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700))),
            ],
          ),
        ],
      ),
    );
  }

  void _addHabit(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: scheme.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (_) => const HabitEditorSheet());
  }

  String _weekRange(DateTime t) {
    final start = t.subtract(Duration(days: t.weekday - 1));
    final end = start.add(const Duration(days: 6));
    final m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${m[start.month - 1]} ${start.day} – ${m[end.month - 1]} ${end.day}';
  }
}

class _WeeklyRow extends StatelessWidget {
  final List<Habit> habits;
  final DateTime today;
  const _WeeklyRow({required this.habits, required this.today});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final d = weekStart.add(Duration(days: i));
          final isToday = d.year == today.year && d.month == today.month && d.day == today.day;
          int due = 0;
          int done = 0;
          for (final h in habits) {
            final applies = h.recurrence == 'daily' || h.daysOfWeek.contains(d.weekday);
            if (!applies) continue;
            due++;
            if (HabitService.isChecked(h, d)) done++;
          }
          final allDone = due > 0 && done == due;
          final someDone = done > 0 && !allDone;
          final isFuture = d.isAfter(today);

          return Column(
            children: [
              Text(days[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: AppAnimations.fast,
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: allDone ? scheme.onSurface : (someDone ? AppColors.habits.withValues(alpha: 0.4) : Colors.transparent),
                  shape: BoxShape.circle,
                ),
                child: allDone
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : isFuture
                        ? Text('${d.day}', style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700))
                        : Text(d.day.toString(), style: TextStyle(fontSize: 13, color: isToday ? scheme.onSurface : scheme.onSurfaceVariant, fontWeight: FontWeight.w800)),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  final Habit habit;
  final bool dueToday;
  final bool doneToday;
  const _HabitRow({required this.habit, required this.dueToday, required this.doneToday});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = Color(habit.colorValue);
    final icon = _iconFromCode(habit.iconCodePoint);
    return PressableCard(
      color: scheme.surface,
      onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: scheme.surface, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (_) => HabitEditorSheet(existing: habit)),
      onLongPress: () async {
        final ok = await confirmDelete(context, title: tr(context, 'অভ্যাস মুছবেন?', 'Delete habit?'));
        if (ok) await habit.delete();
      },
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          GradientIconTile(icon: icon, color: color, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(habit.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: doneToday ? scheme.onSurfaceVariant : scheme.onSurface, decoration: doneToday ? TextDecoration.lineThrough : null)),
                if (habit.subtitle.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 2), child: Text(habit.subtitle, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))),
              ],
            ),
          ),
          _RoundCheck(
            done: doneToday,
            disabled: !dueToday,
            color: color,
            onTap: () async {
              if (!dueToday) return;
              await HabitService.setChecked(habit, DateTime.now(), !doneToday);
            },
          ),
        ],
      ),
    );
  }
}

class _RoundCheck extends StatefulWidget {
  final bool done;
  final bool disabled;
  final Color color;
  final VoidCallback onTap;
  const _RoundCheck({required this.done, required this.disabled, required this.color, required this.onTap});

  @override
  State<_RoundCheck> createState() => _RoundCheckState();
}

class _RoundCheckState extends State<_RoundCheck> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 2),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    if (widget.done) {
      _ctrl.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _RoundCheck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.done != oldWidget.done) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: widget.disabled ? null : widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.done ? widget.color : (widget.disabled ? scheme.surfaceContainer : Colors.transparent),
            shape: BoxShape.circle,
          ),
          child: widget.done
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : widget.disabled
                  ? null
                  : const SizedBox(),
        ),
      ),
    );
  }
}

class _MonthlyTrendCard extends StatelessWidget {
  final List<Habit> habits;
  const _MonthlyTrendCard({required this.habits});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final days = List.generate(30, (i) => today.subtract(Duration(days: 29 - i)));
    final counts = days.map((d) {
      int c = 0;
      for (final h in habits) {
        if (h.recurrence == 'weekly' && !h.daysOfWeek.contains(d.weekday)) continue;
        if (HabitService.isChecked(h, d)) c++;
      }
      return c;
    }).toList();
    final maxC = counts.fold<int>(0, (a, b) => a > b ? a : b).clamp(1, 1000);
    final cardGrad = Brightness.dark == Theme.of(context).brightness
        ? [scheme.surfaceContainerHigh, scheme.surfaceContainer]
        : [const Color(0xFFE0EAFF), const Color(0xFFF2F4F8)];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: cardGrad),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: scheme.onSurface)),
          const SizedBox(height: 4),
          Text(tr(context, 'আপনার অগ্রগতি ধীরে ধীরে বাড়ছে', 'Your progress is increasing steadily.'), style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: CustomPaint(
              size: Size.infinite,
              painter: _SparkPainter(values: counts, maxValue: maxC.toDouble(), color: AppColors.habits),
            ),
          ),
        ],
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<int> values;
  final double maxValue;
  final Color color;
  _SparkPainter({required this.values, required this.maxValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final stepX = size.width / (values.length - 1);
    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y = size.height - (values[i] / maxValue) * size.height;
      points.add(Offset(x, y));
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final p = points[i];
      final prev = points[i - 1];
      final mid = Offset((prev.dx + p.dx) / 2, (prev.dy + p.dy) / 2);
      path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    final fill = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    final fillPaint = Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withValues(alpha: 0.30), color.withValues(alpha: 0.0)]).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fill, fillPaint);
    final linePaint = Paint()..color = color..strokeWidth = 2.4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.values != values || old.color != color;
}