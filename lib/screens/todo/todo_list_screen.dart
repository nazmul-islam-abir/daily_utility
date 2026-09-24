import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../models/todo_item.dart';
import '../../services/data_refresh_service.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'todo_editor_screen.dart' show TodoEditorScreen, kPriorityColors, priorityLabel;

const _uuid = Uuid();

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  Future<void> _toggleComplete(TodoItem item) async {
    if (item.isCompleted) {
      item.isCompleted = false;
      item.completedAt = null;
      await item.save();
      return;
    }

    // Recurring tasks: log this occurrence into completed history as its own
    // record, then roll the live task forward to its next due date so it
    // keeps showing up under "চলমান" (active).
    if (item.recurrence != 'none' && item.dueAt != null) {
      final historyEntry = TodoItem(
        id: _uuid.v4(),
        title: item.title,
        notes: item.notes,
        priority: item.priority,
        dueAt: item.dueAt,
        recurrence: 'none',
        isCompleted: true,
        completedAt: DateTime.now(),
        createdAt: item.createdAt,
      );
      await HiveService.todos.put(historyEntry.id, historyEntry);

      final next = _nextOccurrence(item.dueAt!, item.recurrence);
      await NotificationService.cancel(item.notificationId);
      item.dueAt = next;
      item.isCompleted = false;
      item.completedAt = null;
      item.notificationId = null;
      if (item.reminderMinutesBefore != null) {
        final bn = LocaleService.isBangla;
        item.notificationId = await NotificationService.scheduleReminder(
          idKey: item.id,
          title: bn ? 'কাজ: ${item.title}' : 'Task: ${item.title}',
          body: DateFormat('d MMM, hh:mm a').format(next),
          fireAt: next.subtract(Duration(minutes: item.reminderMinutesBefore!)),
        );
      }
      await item.save();
    } else {
      item.isCompleted = true;
      item.completedAt = DateTime.now();
      await NotificationService.cancel(item.notificationId);
      await item.save();
    }
  }

  DateTime _nextOccurrence(DateTime from, String recurrence) {
    switch (recurrence) {
      case 'daily':
        return from.add(const Duration(days: 1));
      case 'weekly':
        return from.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(from.year, from.month + 1, from.day, from.hour, from.minute);
      default:
        return from;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<int>(
      valueListenable: DataRefreshService.instance.notifier,
      builder: (context, _, __) {
        return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [scheme.surfaceContainerLow, scheme.surface])),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(scheme: scheme),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: HiveService.todos.listenable(),
                  builder: (context, Box<TodoItem> box, _) {
                    final all = box.values.toList();
                    final active = all.where((t) => !t.isCompleted).toList()
                      ..sort((a, b) {
                        if (a.dueAt == null && b.dueAt == null) return b.createdAt.compareTo(a.createdAt);
                        if (a.dueAt == null) return 1;
                        if (b.dueAt == null) return -1;
                        return a.dueAt!.compareTo(b.dueAt!);
                      });
                    final completed = all.where((t) => t.isCompleted).toList()
                      ..sort((a, b) => (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));

                    return TabBarView(
                      controller: _tab,
                      children: [
                        _buildList(active, showCheckbox: true, total: all.length),
                        _buildList(completed, showCheckbox: true, isHistory: true, total: all.length),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.todo,
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TodoEditorScreen())),
        child: const Icon(Icons.add),
      ),
    );
      },
    );
  }

  Widget _buildHeader({required ColorScheme scheme}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(tr(context, 'কাজ', 'Tasks'), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: scheme.onSurface, letterSpacing: -0.5))),
              AnimatedBuilder(
                animation: Listenable.merge([HiveService.todos.listenable(), DataRefreshService.instance.notifier]),
                builder: (context, _) {
                  final all = HiveService.todos.values.toList();
                  final done = all.where((t) => t.isCompleted).length;
                  final pct = all.isEmpty ? 0 : ((done / all.length) * 100).round();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.todo.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.task_alt, size: 14, color: AppColors.todo),
                      const SizedBox(width: 4),
                      Text('$pct%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.todo)),
                    ]),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(tr(context, 'প্রবাহ সহজ করুন, আরও অর্জন করুন।', 'Simplify your flow, achieve more.'), style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 14),
          TabBar(
            controller: _tab,
            labelColor: AppColors.todo,
            unselectedLabelColor: scheme.onSurfaceVariant,
            indicatorColor: AppColors.todo,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800),
            tabs: [Tab(text: tr(context, 'চলমান', 'Active')), Tab(text: tr(context, 'সম্পন্ন', 'Completed'))],
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<TodoItem> items, {required bool showCheckbox, bool isHistory = false, int total = 0}) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          DataRefreshService.instance.bump();
          await Future<void>.delayed(const Duration(milliseconds: 350));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            EmptyState(
              icon: isHistory ? Icons.history : Icons.task_alt,
              title: isHistory ? tr(context, 'এখনো কোনো কাজ সম্পন্ন হয়নি', 'No completed tasks yet') : tr(context, 'কোনো কাজ নেই', 'No tasks yet'),
              message: isHistory ? tr(context, 'সম্পন্ন করা কাজ এখানে দেখা যাবে।', 'Completed tasks will appear here.') : tr(context, '+ বাটনে চেপে নতুন কাজ যোগ করুন।', 'Tap + to add a new task.'),
            ),
          ],
        ),
      );
    }
    final now = DateTime.now();
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: () async {
        DataRefreshService.instance.bump();
        await Future<void>.delayed(const Duration(milliseconds: 350));
      },
      child: ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final item = items[i];
        final overdue = !isHistory && item.dueAt != null && item.dueAt!.isBefore(now);
        return StaggeredFadeIn(
          index: i,
          child: Dismissible(
            key: ValueKey(item.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(AppRadius.lg)),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            confirmDismiss: (_) async {
              final ok = await confirmDelete(context, title: tr(context, 'কাজটি মুছবেন?', 'Delete this task?'));
              if (ok) {
                await NotificationService.cancel(item.notificationId);
              }
              return ok;
            },
            onDismissed: (_) => item.delete(),
            child: PressableCard(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TodoEditorScreen(existing: item))),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  _AnimatedCheck(
                    value: item.isCompleted,
                    color: AppColors.todo,
                    onTap: () => _toggleComplete(item),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                            color: item.isCompleted ? scheme.onSurfaceVariant : scheme.onSurface,
                            fontSize: 15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.dueAt != null || item.priority != 'medium' || item.recurrence != 'none' || item.reminderMinutesBefore != null) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _priorityDot(item.priority, scheme),
                              if (item.dueAt != null)
                                Text(
                                  DateFormat('d MMM, hh:mm a').format(item.dueAt!),
                                  style: TextStyle(fontSize: 12, color: overdue ? AppColors.danger : scheme.onSurfaceVariant, fontWeight: overdue ? FontWeight.w700 : FontWeight.w500),
                                ),
                              if (item.recurrence != 'none')
                                Icon(Icons.repeat, size: 12, color: scheme.onSurfaceVariant),
                              if (item.reminderMinutesBefore != null)
                                Icon(Icons.notifications_active_outlined, size: 12, color: scheme.onSurfaceVariant),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      ),
    );
  }

  Widget _priorityDot(String priority, ColorScheme scheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: kPriorityColors[priority], shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(priorityLabel(context, priority), style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
      ],
    );
  }
}

class _AnimatedCheck extends StatelessWidget {
  final bool value;
  final Color color;
  final VoidCallback onTap;
  const _AnimatedCheck({required this.value, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: value ? color : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: value ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
      ),
    );
  }
}
