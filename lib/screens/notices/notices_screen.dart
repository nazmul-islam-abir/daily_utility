import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../../services/locale_service.dart';
import '../../services/notice_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// In-app notice board — fetches notices from the Firestore `notice`
/// collection and shows them in a list. The bell icon on the dashboard
/// opens this screen.
class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh on open so Firebase is initialized and Firestore fetched.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NoticeService.instance.refresh();
    });
  }

  Future<void> _openLink(String raw) async {
    var uri = Uri.tryParse(raw);
    if (uri == null) return;
    if (!uri.hasScheme) uri = Uri.parse('https://$raw');
    try {
      await url_launcher.launchUrl(uri, mode: url_launcher.LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      appBar: AppBar(
        title: Text(tr(context, 'নোটিশ বোর্ড', 'Notice Board')),
        actions: [
          IconButton(
            tooltip: tr(context, 'রিফ্রেশ', 'Refresh'),
            onPressed: () => NoticeService.instance.refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: NoticeService.instance.configured,
        builder: (context, configured, _) {
          if (!configured) {
            return _notConfiguredState(context);
          }
          return ValueListenableBuilder<bool>(
            valueListenable: NoticeService.instance.loading,
            builder: (context, loading, _) {
              return ValueListenableBuilder<List<Notice>>(
                valueListenable: NoticeService.instance.notices,
                builder: (context, list, _) {
                  if (loading && list.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // Show any underlying error so the user (and we) can see
                  // why the list might be empty — usually a Firestore
                  // security-rules denial.
                  return Column(
                    children: [
                      ValueListenableBuilder<String?>(
                        valueListenable: NoticeService.instance.lastError,
                        builder: (context, err, _) {
                          if (err == null || err.isEmpty) return const SizedBox.shrink();
                          return _ErrorBanner(error: err);
                        },
                      ),
                      Expanded(
                        child: list.isEmpty
                            ? RefreshIndicator(
                                onRefresh: () => NoticeService.instance.refresh(),
                                child: ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    const SizedBox(height: 80),
                                    EmptyState(
                                      icon: Icons.notifications_none_rounded,
                                      title: tr(context, 'এখনো কোনো নোটিশ নেই', 'No notices yet'),
                                      message: tr(context, 'অ্যাডমিন নতুন নোটিশ পাঠালে এখানে দেখা যাবে।', 'New notices from the admin will appear here.'),
                                    ),
                                    const SizedBox(height: 24),
                                    _DebugFooter(),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () => NoticeService.instance.refresh(),
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: list.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, i) {
                                    final n = list[i];
                                    return _NoticeCard(
                                      notice: n,
                                      onOpenLink: n.linkUrl == null ? null : () => _openLink(n.linkUrl!),
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
                'ইন্টারনেট কানেকশন রিফ্রেশ করুন অথবা পুনরায় রিফ্রেশ চাপুন।',
                'Check internet connection or tap retry below.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => NoticeService.instance.refresh(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(tr(context, 'পুনরায় চেষ্টা করুন', 'Retry Connection')),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final Notice notice;
  final VoidCallback? onOpenLink;
  const _NoticeCard({required this.notice, this.onOpenLink});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasImage = notice.imageUrl != null && notice.imageUrl!.isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.campaign_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    notice.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (notice.isPinned)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.push_pin_rounded, size: 12, color: AppColors.warning),
                        const SizedBox(width: 3),
                        Text(
                          tr(context, 'পিন', 'Pinned'),
                          style: const TextStyle(color: AppColors.warning, fontSize: 10.5, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat('d MMM y, hh:mm a').format(notice.createdAt.toLocal()),
              style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            if (hasImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Image.network(
                  notice.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 140,
                    alignment: Alignment.center,
                    color: scheme.surfaceContainerHigh,
                    child: Icon(Icons.broken_image_outlined, color: scheme.outline),
                  ),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 140,
                      alignment: Alignment.center,
                      color: scheme.surfaceContainerHigh,
                      child: const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              notice.body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            if (onOpenLink != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: onOpenLink,
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text(tr(context, 'বিস্তারিত দেখুন', 'Read more')),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: tr(context, 'লিংক কপি করুন', 'Copy link'),
                    icon: const Icon(Icons.link_rounded, size: 18),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: notice.linkUrl ?? ''));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(tr(context, 'লিংক কপি হয়েছে', 'Link copied'))),
                      );
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small diagnostic footer shown under the empty state so the user can
/// see at a glance: which Firebase project is configured, whether it's
/// reachable, and how many docs were read on the last query. Tapping the
/// footer copies the full debug text to the clipboard.
class _DebugFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<List<Notice>>(
      valueListenable: NoticeService.instance.notices,
      builder: (context, list, _) {
        return GestureDetector(
          onTap: () async {
            final dbg = NoticeService.instance.debugSummary();
            await Clipboard.setData(ClipboardData(text: dbg));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(tr(context, 'ডিবাগ তথ্য কপি হয়েছে', 'Debug info copied'))),
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
              NoticeService.instance.debugSummary(),
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

/// Small red banner shown at the top of the Notice Board whenever the
/// Firestore query fails — typically because security rules deny public
/// reads. Tapping the banner copies the raw error to the clipboard so
/// the user can paste it into a chat when debugging.
class _ErrorBanner extends StatelessWidget {
  final String error;
  const _ErrorBanner({required this.error});

  String _humanise(String raw) {
    if (raw.contains('permission-denied') || raw.contains('PERMISSION_DENIED')) {
      return 'Firestore security rules are blocking reads. '
          'Open Firebase console → Firestore → Rules and allow '
          'read access to the `notice` collection.';
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
            SnackBar(content: Text(tr(context, 'ত্রুটি কপি হয়েছে', 'Error copied to clipboard'))),
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
