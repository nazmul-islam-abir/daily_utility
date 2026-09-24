import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../models/vault_credential.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'vault_editor_screen.dart';

/// Vault — password manager. Plain-text local storage (no master PIN).
/// Security Health card on top: weak = password length < 8,
/// compromised = common weak phrases ("password", "123456", etc.).
class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  String _query = '';
  String _filter = 'all'; // all | banking | social | work | other

  Color _colorForFilter(String f) {
    switch (f) {
      case 'banking':
        return AppColors.finance;
      case 'social':
        return AppColors.mood;
      case 'work':
        return AppColors.loan;
      case 'other':
        return AppColors.vault;
      default:
        return AppColors.primary;
    }
  }

  IconData _iconForCategory(String c) {
    switch (c) {
      case 'banking':
        return Icons.account_balance_outlined;
      case 'social':
        return Icons.mail_outline;
      case 'work':
        return Icons.work_outline;
      default:
        return Icons.lock_outline;
    }
  }

  Color _colorForCategory(String c) {
    switch (c) {
      case 'banking':
        return AppColors.finance;
      case 'social':
        return AppColors.mood;
      case 'work':
        return AppColors.loan;
      default:
        return AppColors.vault;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.notifier,
      builder: (context, locale, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            title: Text(tr(context, 'ভল্ট', 'Vault'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            actions: [
              IconButton(icon: const Icon(Icons.search), onPressed: () => showSearch(context: context, delegate: _VaultSearchDelegate())),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.vault,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VaultEditorScreen())),
            child: const Icon(Icons.add),
          ),
          body: ValueListenableBuilder(
            valueListenable: HiveService.vault.listenable(),
            builder: (context, Box<VaultCredential> box, _) {
              final all = box.values.toList();
              final weak = all.where((v) => v.isWeak).length;
              final compromised = all.where((v) => v.isCompromised).length;
              final filtered = all.where((v) {
                if (_filter != 'all' && v.category != _filter) return false;
                if (_query.isEmpty) return true;
                final q = _query.toLowerCase();
                return v.title.toLowerCase().contains(q) || v.username.toLowerCase().contains(q);
              }).toList();

              // group by category
              final grouped = <String, List<VaultCredential>>{};
              for (final v in filtered) {
                grouped.putIfAbsent(v.category, () => []).add(v);
              }

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: HeroCard(
                        gradient: const [Color(0xFFE0EAFF), Color(0xFFF2F4F8)],
                        darkForeground: false,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(tr(context, 'নিরাপত্তা স্বাস্থ্য', 'Security Health'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.text)),
                                ),
                                Icon(Icons.shield_outlined, color: AppColors.danger, size: 22),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(tr(context, 'মোট ${all.length}টি ক্রেডেনশিয়াল মনিটরিং', 'Monitoring ${all.length} active credentials'), style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: StatCard(label: tr(context, 'দুর্বল', 'Weak'), value: '$weak', color: AppColors.text, icon: Icons.warning_amber_outlined),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: StatCard(label: tr(context, 'আপস', 'Compromised'), value: '$compromised', color: AppColors.danger, icon: Icons.report_gmailerrorred_outlined, emphasised: true),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: TextField(
                        decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: tr(context, 'ক্রেডেনশিয়াল খুঁজুন…', 'Search credentials…')),
                        onChanged: (v) => setState(() => _query = v.trim()),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: FilterChipsRow(
                      items: [tr(context, 'সব', 'All'), tr(context, 'ব্যাংকিং', 'Banking'), tr(context, 'সোশ্যাল', 'Social'), tr(context, 'কাজ', 'Work'), tr(context, 'অন্যান্য', 'Other')],
                      selected: _filter == 'all' ? null : _filter,
                      colorFor: _colorForFilter,
                      onSelect: (v) => setState(() => _filter = v ?? 'all'),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.lock_outline,
                        title: tr(context, 'কোনো ক্রেডেনশিয়াল নেই', 'No credentials yet'),
                        message: tr(context, '+ বাটনে চেপে প্রথম এন্ট্রি যোগ করুন', 'Tap + to add your first credential'),
                      ),
                    )
                  else
                    for (final entry in grouped.entries) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                          child: Row(
                            children: [
                              MiniSectionLabel(_categoryLabel(entry.key)),
                              const Expanded(child: Divider(indent: 12)),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        sliver: SliverList.separated(
                          itemCount: entry.value.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) => _CredentialCard(
                            cred: entry.value[i],
                            icon: _iconForCategory(entry.key),
                            color: _colorForCategory(entry.key),
                          ),
                        ),
                      ),
                    ],
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
          ),
        );
      },
    );
  }

  String _categoryLabel(String key) {
    switch (key) {
      case 'banking':
        return tr(context, 'ব্যাংকিং', 'Banking');
      case 'social':
        return tr(context, 'সোশ্যাল', 'Social');
      case 'work':
        return tr(context, 'কাজ', 'Work');
      default:
        return tr(context, 'অন্যান্য', 'Other');
    }
  }
}

class _CredentialCard extends StatefulWidget {
  final VaultCredential cred;
  final IconData icon;
  final Color color;
  const _CredentialCard({required this.cred, required this.icon, required this.color});

  @override
  State<_CredentialCard> createState() => _CredentialCardState();
}

class _CredentialCardState extends State<_CredentialCard> {
  bool _reveal = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.cred;
    return PressableCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VaultEditorScreen(existing: c))),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GradientIconTile(icon: widget.icon, color: widget.color, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(child: Text(c.username, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 6),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: c.username));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context, 'ইউজারনেম কপি হয়েছে', 'Username copied')), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md))));
                          },
                          child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.copy_outlined, size: 16, color: AppColors.textMuted)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _reveal ? c.password : '•' * (c.password.length.clamp(6, 16)),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: Icon(_reveal ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _reveal = !_reveal),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_outlined),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: c.password));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context, 'পাসওয়ার্ড কপি হয়েছে', 'Password copied')), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md))));
                  },
                ),
              ],
            ),
          ),
          if (c.isWeak || c.isCompromised)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(c.isCompromised ? Icons.report_gmailerrorred : Icons.warning_amber_outlined, size: 14, color: AppColors.danger),
                  const SizedBox(width: 4),
                  Text(c.isCompromised ? tr(context, 'আপসকৃত — পরিবর্তন করুন', 'Compromised — change it') : tr(context, 'দুর্বল পাসওয়ার্ড', 'Weak password'), style: const TextStyle(fontSize: 11.5, color: AppColors.danger, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _VaultSearchDelegate extends SearchDelegate {
  @override
  String get searchFieldLabel => LocaleService.isBangla ? 'ক্রেডেনশিয়াল খুঁজুন…' : 'Search credentials…';

  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final all = HiveService.vault.values.toList();
    final q = query.toLowerCase();
    final filtered = all.where((v) => v.title.toLowerCase().contains(q) || v.username.toLowerCase().contains(q)).toList();
    if (filtered.isEmpty) {
      return EmptyState(icon: Icons.search_off, title: tr(context, 'কিছু পাওয়া যায়নি', 'No matches'), message: tr(context, 'অন্য কিওয়ার্ড দিয়ে চেষ্টা করুন', 'Try a different keyword'));
    }
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final c = filtered[i];
        return ListTile(
          leading: const Icon(Icons.lock_outline),
          title: Text(c.title),
          subtitle: Text(c.username),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VaultEditorScreen(existing: c))),
        );
      },
    );
  }
}