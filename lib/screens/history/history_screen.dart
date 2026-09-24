import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/history_entry.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// Unified history: every calculation result and finance record. Each entry
/// is stored in the local `history` box so it survives app restarts and
/// (when backup is enabled) syncs to Google Drive alongside everything else.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'all'; // all | calculator | finance | note
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final entries = HiveService.history.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final filtered = entries.where((e) {
      if (_filter != 'all' && e.kind != _filter) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return e.title.toLowerCase().contains(q) || e.subtitle.toLowerCase().contains(q) || e.result.toLowerCase().contains(q);
    }).toList();

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.notifier,
      builder: (context, locale, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(tr(context, 'হিস্টোরি', 'History')),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: tr(context, 'সব মুছুন', 'Clear all'),
                onPressed: entries.isEmpty
                    ? null
                    : () async {
                        final ok = await confirmDelete(
                          context,
                          title: tr(context, 'সব হিস্টোরি মুছবেন?', 'Clear every record?'),
                          message: tr(context, 'এই অপারেশন পূর্বাবস্থায় ফেরানো যাবে না।', 'This cannot be undone.'),
                        );
                        if (ok) {
                          await HiveService.history.clear();
                          if (mounted) setState(() {});
                        }
                      },
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: tr(context, 'খুঁজুন…', 'Search…')),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _chip('all', tr(context, 'সব', 'All') + ' (${entries.length})', entries.length, AppColors.primary),
                    const SizedBox(width: 8),
                    _chip('calculator', tr(context, 'ক্যালকুলেটর', 'Calculator'), entries.where((e) => e.kind == 'calculator').length, AppColors.calculator),
                    const SizedBox(width: 8),
                    _chip('finance', tr(context, 'আর্থিক', 'Finance'), entries.where((e) => e.kind == 'finance').length, AppColors.finance),
                    const SizedBox(width: 8),
                    _chip('note', tr(context, 'নোট', 'Notes'), entries.where((e) => e.kind == 'note').length, AppColors.notes),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.history_rounded,
                        title: tr(context, 'কোনো হিস্টোরি নেই', 'No history yet'),
                        message: _query.isEmpty
                            ? tr(context, 'কোনো হিসাব বা লেনদেন করলে এখানে জমা হবে।', 'Calculations and transactions will show up here.')
                            : tr(context, 'এই ফিল্টারে কিছু পাওয়া যায়নি।', 'Nothing matches this filter.'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final e = filtered[i];
                          return _HistoryCard(entry: e);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chip(String key, String label, int count, Color color) {
    final selected = _filter == key;
    final scheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = key),
      selectedColor: color.withValues(alpha: 0.18),
      checkmarkColor: color,
      labelStyle: TextStyle(color: selected ? color : scheme.onSurfaceVariant, fontWeight: FontWeight.w800, fontSize: 12),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final HistoryEntry entry;
  const _HistoryCard({required this.entry});

  Color get _color {
    switch (entry.kind) {
      case 'calculator':
        return AppColors.calculator;
      case 'finance':
        return AppColors.finance;
      case 'note':
        return AppColors.notes;
      default:
        return AppColors.primary;
    }
  }

  IconData get _icon {
    switch (entry.kind) {
      case 'calculator':
        return Icons.calculate_outlined;
      case 'finance':
        return Icons.account_balance_wallet_outlined;
      case 'note':
        return Icons.sticky_note_2_outlined;
      default:
        return Icons.history;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => entry.delete(),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: _color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(_icon, color: _color),
          ),
          title: Text(entry.title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.subtitle.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(entry.subtitle, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: _color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                    child: Text(entry.result, style: TextStyle(color: _color, fontSize: 12, fontWeight: FontWeight.w900)),
                  ),
                  const Spacer(),
                  Text(DateFormat('d MMM, hh:mm a').format(entry.createdAt), style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
          onTap: () {
            if (entry.inputs.isEmpty) return;
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              builder: (_) => Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(entry.subtitle, style: TextStyle(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: _color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.md)),
                      child: Text(entry.result, style: TextStyle(color: _color, fontSize: 20, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(height: 16),
                    Text(tr(context, 'ইনপুট', 'Inputs'), style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    ...entry.inputs.entries.map((kv) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(flex: 4, child: Text(kv.key, style: TextStyle(color: scheme.onSurfaceVariant))),
                              Expanded(flex: 5, child: Text(kv.value, style: const TextStyle(fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
