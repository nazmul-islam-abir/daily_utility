import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../models/subscription.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'subscription_form_screen.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  String _query = '';
  String _filter = 'all'; // all, active, paused, due, overdue

  String _currencySymbol(String code) {
    switch (code) {
      case 'BDT':
        return '৳';
      case 'INR':
        return '₹';
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
      default:
        return '¥';
    }
  }

  IconData _iconForCategory(String key) {
    switch (key) {
      case 'streaming':
        return Icons.movie_filter_outlined;
      case 'music':
        return Icons.music_note_outlined;
      case 'productivity':
        return Icons.work_outline;
      case 'cloud':
        return Icons.cloud_outlined;
      case 'gaming':
        return Icons.sports_esports_outlined;
      case 'news':
        return Icons.menu_book_outlined;
      case 'fitness':
        return Icons.fitness_center_outlined;
      case 'education':
        return Icons.school_outlined;
      case 'utilities':
        return Icons.bolt_outlined;
      case 'insurance':
        return Icons.shield_outlined;
      case 'other':
      default:
        return Icons.subscriptions_outlined;
    }
  }

  String _bengaliCategory(String key) {
    switch (key) {
      case 'streaming':
        return 'স্ট্রিমিং';
      case 'music':
        return 'মিউজিক';
      case 'productivity':
        return 'প্রোডাক্টিভিটি';
      case 'cloud':
        return 'ক্লাউড';
      case 'gaming':
        return 'গেমিং';
      case 'news':
        return 'নিউজ';
      case 'fitness':
        return 'ফিটনেস';
      case 'education':
        return 'শিক্ষা';
      case 'utilities':
        return 'ইউটিলিটি';
      case 'insurance':
        return 'বীমা';
      case 'other':
      default:
        return 'অন্যান্য';
    }
  }

  String _cycleLabel(BuildContext c, BillingCycle cycle) {
    switch (cycle) {
      case BillingCycle.weekly:
        return tr(c, 'সাপ্তাহিক', 'Weekly');
      case BillingCycle.monthly:
        return tr(c, 'মাসিক', 'Monthly');
      case BillingCycle.quarterly:
        return tr(c, 'ত্রৈমাসিক', 'Quarterly');
      case BillingCycle.yearly:
        return tr(c, 'বার্ষিক', 'Yearly');
    }
  }

  Future<void> _deleteSubscription(Subscription s) async {
    if (s.notificationId != null) {
      await NotificationService.cancel(s.notificationId);
    }
    await s.delete();
  }

  Future<void> _markPaid(Subscription s) async {
    final advanced = Subscription.advance(s.nextRenewalDate, s.cycle);
    s.nextRenewalDate = advanced;
    if (s.notificationId != null) {
      await NotificationService.cancel(s.notificationId);
    }
    s.notificationId = null;
    await s.save();
    if (!mounted) return;
    final renewalText = DateFormat('d MMM yyyy').format(advanced);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr(context, 'পরবর্তী রিনিউয়াল: $renewalText', 'Next renewal: $renewalText')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final all = HiveService.subscriptions.values.toList();

    final active = all.where((s) => s.isActive).toList();
    final monthlyTotal = active.fold<double>(0, (sum, s) => sum + s.monthlyEquivalent);
    final yearlyTotal = active.fold<double>(0, (sum, s) => sum + s.yearlyEquivalent);
    final nextDue = active.where((s) => s.daysUntilRenewal() >= 0).toList()
      ..sort((a, b) => a.daysUntilRenewal().compareTo(b.daysUntilRenewal()));
    final overdue = active.where((s) => s.daysUntilRenewal() < 0).toList()
      ..sort((a, b) => a.daysUntilRenewal().compareTo(b.daysUntilRenewal()));
    final dueSoon = nextDue.where((s) => s.daysUntilRenewal() <= 7).toList();

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      appBar: AppBar(
        title: Text(tr(context, 'সাবস্ক্রিপশন', 'Subscriptions')),
        actions: [
          IconButton(
            tooltip: tr(context, 'নতুন', 'New'),
            icon: const Icon(Icons.add),
            onPressed: () => _openForm(context),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: HiveService.subscriptions.listenable(),
        builder: (context, _) {
          final q = _query.trim().toLowerCase();
          final filtered = all.where((s) {
            if (q.isNotEmpty) {
              final hit = s.title.toLowerCase().contains(q) || s.category.toLowerCase().contains(q);
              if (!hit) return false;
            }
            switch (_filter) {
              case 'active':
                return s.isActive;
              case 'paused':
                return !s.isActive;
              case 'due':
                return s.isActive && s.daysUntilRenewal() <= 7;
              case 'overdue':
                return s.isActive && s.daysUntilRenewal() < 0;
              case 'all':
              default:
                return true;
            }
          }).toList()
            ..sort((a, b) {
              if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
              return a.daysUntilRenewal().compareTo(b.daysUntilRenewal());
            });

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            children: [
              _summaryHero(
                scheme: scheme,
                activeCount: active.length,
                monthly: monthlyTotal,
                yearly: yearlyTotal,
                dueSoonCount: dueSoon.length,
                overdueCount: overdue.length,
              ),
              const SizedBox(height: 14),
              _searchBar(scheme),
              const SizedBox(height: 10),
              _filterChips(scheme),
              const SizedBox(height: 12),
              if (overdue.isNotEmpty && _filter == 'all') ...[
                _sectionLabel(scheme, tr(context, 'বকেয়া রিনিউয়াল', 'Overdue'), AppColors.danger),
                for (final s in overdue) _subCard(context, s, scheme, highlight: true),
                const SizedBox(height: 14),
              ],
              if (dueSoon.isNotEmpty && _filter == 'all') ...[
                _sectionLabel(scheme, tr(context, 'এই সপ্তাহে বাকি', 'Due this week'), AppColors.warning),
                for (final s in dueSoon.where((s) => !overdue.contains(s))) _subCard(context, s, scheme),
                const SizedBox(height: 14),
              ],
              if (filtered.isEmpty) ...[
                const SizedBox(height: 40),
                EmptyState(
                  icon: Icons.subscriptions_outlined,
                  title: all.isEmpty
                      ? tr(context, 'কোনো সাবস্ক্রিপশন নেই', 'No subscriptions yet')
                      : tr(context, 'কিছু পাওয়া যায়নি', 'Nothing matches'),
                  message: all.isEmpty
                      ? tr(context, 'Netflix, Spotify, জিম যোগ করুন এবং রিনিউয়াল ভুলে যান না।', 'Add Netflix, Spotify, gym and never miss a renewal.')
                      : tr(context, 'ফিল্টার বা সার্চ পরিবর্তন করে দেখুন।', 'Try a different filter or search.'),
                ),
              ] else ...[
                _sectionLabel(scheme, tr(context, '${filtered.length}টি সাবস্ক্রিপশন', '${filtered.length} subscription${filtered.length == 1 ? '' : 's'}'), AppColors.subscription),
                for (final s in filtered) _subCard(context, s, scheme),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.subscription,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: Text(tr(context, 'যোগ করুন', 'Add')),
      ),
    );
  }

  void _openForm(BuildContext context, {Subscription? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SubscriptionFormScreen(existing: existing)),
    );
  }

  Widget _summaryHero({
    required ColorScheme scheme,
    required int activeCount,
    required double monthly,
    required double yearly,
    required int dueSoonCount,
    required int overdueCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.subscription, AppColors.subscriptionDeep],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(color: AppColors.subscription.withValues(alpha: 0.32), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(AppRadius.md)),
                child: const Icon(Icons.subscriptions_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tr(context, 'মাসিক খরচ', 'Monthly spend'),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
              if (overdueCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    tr(context, '$overdueCount বকেয়া', '$overdueCount overdue'),
                    style: const TextStyle(color: AppColors.subscriptionDeep, fontSize: 11, fontWeight: FontWeight.w900),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedCounter(
            value: monthly,
            prefix: '৳',
            decimals: 0,
            style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: -1),
          ),
          const SizedBox(height: 4),
          Text(
            tr(context, '$activeCountটি সক্রিয় • ৳${yearly.toStringAsFixed(0)} / বছরে', '$activeCount active • ৳${yearly.toStringAsFixed(0)} / year'),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _heroPill(
                  icon: Icons.alarm,
                  label: tr(context, 'এই সপ্তাহে', 'Due this week'),
                  value: dueSoonCount.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _heroPill(
                  icon: Icons.check_circle_outline,
                  label: tr(context, 'মোট সক্রিয়', 'Total active'),
                  value: activeCount.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroPill({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 10.5, fontWeight: FontWeight.w800)),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar(ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: tr(context, 'সাবস্ক্রিপশন খুঁজুন...', 'Search subscriptions...'),
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _query = ''),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        onChanged: (v) => setState(() => _query = v),
      ),
    );
  }

  Widget _filterChips(ColorScheme scheme) {
    final filters = <_Filter>[
      _Filter('all', tr(context, 'সব', 'All'), AppColors.subscription),
      _Filter('active', tr(context, 'সক্রিয়', 'Active'), AppColors.success),
      _Filter('paused', tr(context, 'পজ', 'Paused'), AppColors.warning),
      _Filter('due', tr(context, 'শীঘ্রই', 'Due soon'), AppColors.warning),
      _Filter('overdue', tr(context, 'বকেয়া', 'Overdue'), AppColors.danger),
    ];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = filters[i];
          final isSel = _filter == f.key;
          return ChoiceChip(
            label: Text(f.label),
            selected: isSel,
            onSelected: (_) => setState(() => _filter = f.key),
            selectedColor: f.color,
            backgroundColor: scheme.surface,
            labelStyle: TextStyle(color: isSel ? Colors.white : scheme.onSurface, fontWeight: FontWeight.w800),
            side: BorderSide.none,
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _sectionLabel(ColorScheme scheme, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(text.toUpperCase(), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
        ],
      ),
    );
  }

  Widget _subCard(BuildContext context, Subscription s, ColorScheme scheme, {bool highlight = false}) {
    final color = Color(s.colorValue);
    final days = s.daysUntilRenewal();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(s.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        confirmDismiss: (_) => confirmDelete(context, title: tr(context, 'সাবস্ক্রিপশনটি মুছবেন?', 'Delete this subscription?')),
        onDismissed: (_) => _deleteSubscription(s),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openForm(context, existing: s),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(_iconForCategory(s.category), color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                s.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: s.isActive ? scheme.onSurface : scheme.onSurfaceVariant,
                                  decoration: s.isActive ? null : TextDecoration.lineThrough,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                _bengaliCategory(s.category),
                                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_currencySymbol(s.currency)}${s.amount.toStringAsFixed(2)} • ${_cycleLabel(context, s.cycle)}',
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        _dueBadge(s, days, scheme),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: scheme.onSurfaceVariant),
                    onSelected: (v) async {
                      if (v == 'edit') _openForm(context, existing: s);
                      if (v == 'paid') _markPaid(s);
                      if (v == 'toggle') {
                        s.isActive = !s.isActive;
                        await s.save();
                      }
                      if (v == 'delete') {
                        final ok = await confirmDelete(context, title: tr(context, 'সাবস্ক্রিপশনটি মুছবেন?', 'Delete this subscription?'));
                        if (ok) await _deleteSubscription(s);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit_outlined, size: 18), const SizedBox(width: 8), Text(tr(context, 'সম্পাদনা', 'Edit'))])),
                      if (s.isActive)
                        PopupMenuItem(value: 'paid', child: Row(children: [const Icon(Icons.check_circle_outline, size: 18), const SizedBox(width: 8), Text(tr(context, 'পরিশোধিত হিসেবে চিহ্নিত করুন', 'Mark as paid'))])),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(children: [
                          Icon(s.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline, size: 18),
                          const SizedBox(width: 8),
                          Text(s.isActive ? tr(context, 'পজ করুন', 'Pause') : tr(context, 'চালু করুন', 'Resume')),
                        ]),
                      ),
                      PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: AppColors.danger), const SizedBox(width: 8), Text(tr(context, 'মুছুন', 'Delete'), style: const TextStyle(color: AppColors.danger))])),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dueBadge(Subscription s, int days, ColorScheme scheme) {
    if (!s.isActive) {
      return Row(
        children: [
          Icon(Icons.pause_circle_outline, size: 12, color: scheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(tr(context, 'পজ করা হয়েছে', 'Paused'), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      );
    }

    Color color;
    String label;
    IconData icon;
    if (days < 0) {
      color = AppColors.danger;
      label = tr(context, '${-days} দিন বকেয়া', '${-days} days overdue');
      icon = Icons.error_outline;
    } else if (days == 0) {
      color = AppColors.danger;
      label = tr(context, 'আজ রিনিউ', 'Renews today');
      icon = Icons.notifications_active;
    } else if (days <= 7) {
      color = AppColors.warning;
      label = tr(context, '$days দিনের মধ্যে', 'In $days days');
      icon = Icons.schedule;
    } else {
      color = AppColors.success;
      label = tr(context, '$days দিন বাকি', 'In $days days');
      icon = Icons.event_outlined;
    }
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(width: 8),
        Text('• ${DateFormat('d MMM').format(s.nextRenewalDate)}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w700)),
        if (s.reminderDaysBefore != null) ...[
          const SizedBox(width: 6),
          Icon(Icons.alarm, size: 12, color: scheme.onSurfaceVariant),
        ],
      ],
    );
  }
}

class _Filter {
  final String key;
  final String label;
  final Color color;
  _Filter(this.key, this.label, this.color);
}
