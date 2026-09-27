import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/quiz_category.dart';
import '../../services/locale_service.dart';
import '../../services/quiz_service.dart';
import '../../widgets/common_widgets.dart';
import 'quiz_screen.dart';

/// Hub screen that lists every quiz category fetched from Firestore.
/// Tapping a card pushes [QuizScreen] with that category's questions.
///
/// Modeled on `notices_screen.dart` (loading / error / empty / debug-footer
/// pattern) + `date_tools_screen.dart` (card list pattern).
class QuizCategoriesScreen extends StatefulWidget {
  const QuizCategoriesScreen({super.key});

  @override
  State<QuizCategoriesScreen> createState() => _QuizCategoriesScreenState();
}

class _QuizCategoriesScreenState extends State<QuizCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh on open so Firebase is initialized and Firestore fetched.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      QuizService.instance.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      appBar: AppBar(
        title: Text(tr(context, 'দৈনিক কুইজ', 'Daily Quiz')),
        actions: [
          IconButton(
            tooltip: tr(context, 'রিফ্রেশ', 'Refresh'),
            onPressed: () => QuizService.instance.refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: QuizService.instance.configured,
        builder: (context, configured, _) {
          if (!configured) {
            return _notConfiguredState(context);
          }
          return ValueListenableBuilder<bool>(
            valueListenable: QuizService.instance.loading,
            builder: (context, loading, _) {
              return ValueListenableBuilder<List<QuizCategory>>(
                valueListenable: QuizService.instance.categories,
                builder: (context, list, _) {
                  if (loading && list.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Column(
                    children: [
                      ValueListenableBuilder<String?>(
                        valueListenable: QuizService.instance.lastError,
                        builder: (context, err, _) {
                          if (err == null || err.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return _ErrorBanner(error: err);
                        },
                      ),
                      Expanded(
                        child: list.isEmpty
                            ? RefreshIndicator(
                                onRefresh: () => QuizService.instance.refresh(),
                                child: ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    const SizedBox(height: 80),
                                    EmptyState(
                                      icon: Icons.quiz_outlined,
                                      title: tr(context, 'এখনো কোনো কুইজ নেই',
                                          'No quizzes yet'),
                                      message: tr(
                                        context,
                                        'অ্যাডমিন Firestore-এ quiz_categories কালেকশনে ক্যাটাগরি যোগ করলে এখানে দেখা যাবে।',
                                        'New quiz categories added by the admin in the Firestore `quiz_categories` collection will appear here.',
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    const _DebugFooter(),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () => QuizService.instance.refresh(),
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: list.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (context, i) {
                                    final c = list[i];
                                    return _CategoryCard(
                                      category: c,
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => QuizScreen(category: c),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _notConfiguredState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: scheme.outline),
            const SizedBox(height: 14),
            Text(
              tr(context, 'Firebase সংযোগ সফল হয়নি', 'Firebase not connected'),
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              tr(
                context,
                'ইন্টারনেট কানেকশন রিফ্রেশ করুন অথবা পুনরায় চেষ্টা করুন।',
                'Check your internet connection or tap retry below.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => QuizService.instance.refresh(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(tr(context, 'পুনরায় চেষ্টা করুন', 'Retry Connection')),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final QuizCategory category;
  final VoidCallback onTap;
  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: category.color.withValues(alpha: 0.14),
          child: Icon(category.icon, color: category.color),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          category.subtitle ??
              tr(context,
                  '${category.playableCount}টি প্রশ্ন', '${category.playableCount} questions'),
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: scheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Diagnostic footer shown under the empty state so the user can see at a
/// glance: which Firebase project is configured, whether it's reachable,
/// and how many categories were read on the last query. Tapping the footer
/// copies the full debug text to the clipboard.
class _DebugFooter extends StatelessWidget {
  const _DebugFooter();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<List<QuizCategory>>(
      valueListenable: QuizService.instance.categories,
      builder: (context, list, _) {
        return GestureDetector(
          onTap: () async {
            final dbg = QuizService.instance.debugSummary();
            await Clipboard.setData(ClipboardData(text: dbg));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(tr(context, 'ডিবাগ তথ্য কপি হয়েছে', 'Debug info copied')),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              QuizService.instance.debugSummary(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontFamily: 'monospace',
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Small red banner shown at the top whenever the Firestore query fails —
/// typically because security rules deny public reads. Tapping the banner
/// copies the raw error to the clipboard so the user can paste it into a
/// chat when debugging. Mirrors `_ErrorBanner` from notices_screen.
class _ErrorBanner extends StatelessWidget {
  final String error;
  const _ErrorBanner({required this.error});

  String _humanise(String raw) {
    if (raw.contains('permission-denied') || raw.contains('PERMISSION_DENIED')) {
      return 'Firestore security rules are blocking reads. '
          'Open Firebase console → Firestore → Rules and allow '
          'read access to the `quiz_categories` collection.';
    }
    if (raw.contains('unavailable') || raw.contains('UNAVAILABLE')) {
      return 'No internet connection. Pull down to retry.';
    }
    if (raw.contains('NOT_CONFIGURED')) {
      return 'Firebase is not initialised. Restart the app.';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer.withValues(alpha: 0.85),
      child: InkWell(
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: error));
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr(context, 'ত্রুটি কপি হয়েছে', 'Error copied to clipboard')),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _humanise(error),
                  style: TextStyle(
                    color: scheme.onErrorContainer,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.copy_rounded, size: 14, color: scheme.onErrorContainer),
            ],
          ),
        ),
      ),
    );
  }
}
