import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/data_refresh_service.dart';
import '../../services/locale_service.dart';
import '../../services/local_backup_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';

/// Backup screen — full-page when navigated to, embedded (no header) when
/// used inside the Backup tab.
///
/// Uses a portable file-based backup. The user exports a `.json` file via
/// the OS share sheet (save to Downloads, email to themselves, AirDrop,
/// upload to their own Drive / Dropbox, etc.) and imports it on another
/// device. No Google account is required.
class BackupScreen extends StatefulWidget {
  final bool embedded;
  const BackupScreen({super.key, this.embedded = false});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;

  Future<void> _exportNow() async {
    if (_busy) return;
    setState(() => _busy = true);
    final r = await LocalBackupService.instance.exportAndShare();
    if (!mounted) return;
    if (r.status == LocalBackupStatus.success) {
      await SettingsService.instance.setLastBackupAt(DateTime.now());
    }
    if (r.message != null) _toast(r.message!);
    setState(() => _busy = false);
  }

  Future<void> _importNow() async {
    if (_busy) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        title: Text(tr(context, 'ব্যাকআপ থেকে রিস্টোর?', 'Restore from backup?')),
        content: Text(
          tr(context, 
            'আপনার বর্তমান সব লোকাল ডেটা মুছে গিয়ে নির্বাচিত ব্যাকআপ ফাইলের ডেটা দিয়ে প্রতিস্থাপিত হবে। এই কাজটি পূর্বাবস্থায় ফেরানো যাবে না।',
            'Your current local data will be replaced with the contents of the selected backup file. This cannot be undone.',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr(context, 'বাতিল', 'Cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr(context, 'ফাইল নির্বাচন করুন', 'Pick file')),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _busy = true);
    final r = await LocalBackupService.instance.pickAndImport();
    if (!mounted) return;
    if (r.status == LocalBackupStatus.success) {
      await SettingsService.instance.setLastBackupAt(DateTime.now());
      _toastWithAction(
        r.message ?? tr(context, 'রিস্টোর সম্পন্ন', 'Restore complete'),
        actionLabel: tr(context, 'হোমে যান', 'Go to Home'),
        onAction: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      );
    } else if (r.status == LocalBackupStatus.cancelled) {
      // user backed out of the picker — no toast
    } else {
      _toast(r.message ?? tr(context, 'রিস্টোর ব্যর্থ', 'Restore failed'));
    }
    setState(() => _busy = false);
  }

  void _toastWithAction(String msg, {required String actionLabel, required VoidCallback onAction}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        action: SnackBarAction(label: actionLabel, onPressed: onAction),
      ),
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.notifier,
      builder: (context, locale, _) {
        final name = SettingsService.instance.userName;
        final last = SettingsService.instance.lastBackupAt;

        final body = ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          children: [
            _headerCard(name: name, last: last),
            const SizedBox(height: 16),
            _actionsCard(scheme: scheme),
            const SizedBox(height: 16),
            _infoCard(scheme: scheme),
          ],
        );

        if (widget.embedded) return body;
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            title: Text(
              tr(context, 'ব্যাকআপ', 'Backup'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            actions: [
              IconButton(
                tooltip: tr(context, 'রিফ্রেশ', 'Refresh'),
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () {
                  DataRefreshService.instance.bump();
                  _toast(tr(context, 'রিফ্রেশ হয়েছে', 'Refreshed'));
                },
              ),
            ],
          ),
          body: body,
        );
      },
    );
  }

  Widget _headerCard({required String name, required DateTime? last}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF6366F1)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), shape: BoxShape.circle),
            child: const Icon(Icons.save_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  last != null
                      ? tr(context, 'শেষ ব্যাকআপ: ${DateFormat('d MMM, hh:mm a').format(last)}', 'Last backup: ${DateFormat('d MMM, hh:mm a').format(last)}')
                      : tr(context, 'এখনো কোনো ব্যাকআপ নেই', 'No backup yet'),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionsCard({required ColorScheme scheme}) {
    return Container(
      decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(AppRadius.xl)),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.file_upload_outlined, color: scheme.primary, size: 22),
              ),
              title: Text(
                tr(context, 'ব্যাকআপ ফাইল তৈরি ও শেয়ার', 'Create & share backup file'),
                style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface),
              ),
              subtitle: Text(
                tr(context, 'সব লোকাল ডেটার একটি .json ফাইল তৈরি করে WhatsApp / ইমেইল / Drive / Downloads-এ সেভ করুন', 'Generate a .json file with all local data and save to WhatsApp / Email / Drive / Downloads'),
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              trailing: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(Icons.chevron_right, color: scheme.outline),
              onTap: _busy ? null : _exportNow,
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.file_download_outlined, color: scheme.primary, size: 22),
              ),
              title: Text(
                tr(context, 'ব্যাকআপ থেকে রিস্টোর', 'Restore from backup file'),
                style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface),
              ),
              subtitle: Text(
                tr(context, 'আগের তৈরি করা .json ফাইল থেকে ডেটা ফিরিয়ে আনুন', 'Pick a previously saved .json and bring its data back'),
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              trailing: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(Icons.chevron_right, color: scheme.outline),
              onTap: _busy ? null : _importNow,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({required ColorScheme scheme}) {
    const boxes = <(IconData, String, String)>[
      (Icons.check_circle_outline, 'কাজ', 'Tasks'),
      (Icons.sticky_note_2_outlined, 'নোট', 'Notes'),
      (Icons.account_balance_wallet_outlined, 'ফাইন্যান্স', 'Finance'),
      (Icons.people_outline, 'বাকি খাতা', 'Baki Khata'),
      (Icons.credit_card_outlined, 'লোন', 'Loans'),
      (Icons.shopping_cart_outlined, 'শপিং তালিকা', 'Shopping list'),
      (Icons.spa_outlined, 'অভ্যাস', 'Habits'),
      (Icons.emoji_emotions_outlined, 'মেজাজ', 'Mood'),
      (Icons.lock_outline, 'ভল্ট', 'Vault'),
      (Icons.psychology_outlined, 'কুইজ ফলাফল', 'Quiz results'),
      (Icons.history_rounded, 'ক্যালকুলেটর ইতিহাস', 'Calculator history'),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                tr(context, 'নিরাপদ ও ব্যক্তিগত', 'Safe & private'),
                style: TextStyle(fontWeight: FontWeight.w900, color: scheme.primary, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            tr(context, 
              'ব্যাকআপ ফাইলটি কোনো সার্ভারে যায় না। আপনি নিজে শেয়ার বা সেভ করেন — ইমেইল, WhatsApp, অথবা আপনার নিজের Drive / Dropbox-এ। ফাইলটি পুরোপুরি আপনার হাতে।',
              'The backup file never leaves your phone through our servers. You choose where to save it — email, WhatsApp, or your own Drive / Dropbox. The file stays entirely in your hands.',
            ),
            style: TextStyle(fontSize: 13, color: scheme.onSurface, height: 1.45),
          ),
          const SizedBox(height: 16),
          Text(
            tr(context, 'কী কী ব্যাকআপ হয়', 'What gets backed up'),
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: scheme.onSurface),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: boxes
                .map((b) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(b.$1, size: 12, color: scheme.onPrimaryContainer),
                          const SizedBox(width: 4),
                          Text(
                            tr(context, b.$2, b.$3),
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: scheme.onPrimaryContainer),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
