import 'dart:io';

import 'package:flutter/material.dart';

import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../backup/backup_screen.dart';
import '../profile/profile_screen.dart';

/// App-wide settings: language, theme, backup launcher, data tools, about.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _clearHistory() async {
    final ok = await confirmDelete(
      context,
      title: tr(context, 'হিস্টোরি মুছবেন?', 'Clear history?'),
      message: tr(context, 'সব হিসাবের ইতিহাস মুছে যাবে।', 'Every calculation record will be removed.'),
    );
    if (!ok) return;
    await HiveService.history.clear();
    if (mounted) setState(() {});
    _toast(tr(context, 'হিস্টোরি মুছে ফেলা হয়েছে', 'History cleared'));
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
        return ValueListenableBuilder<int>(
          valueListenable: SettingsService.instance.revision,
          builder: (context, _, __) {
        final name = SettingsService.instance.userName;
        final avatar = SettingsService.instance.avatarPath;
        final last = SettingsService.instance.lastBackupAt;
        final mode = SettingsService.instance.themeMode;
        final lang = LocaleService.instance.current;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: scheme.surfaceContainerLow,
            elevation: 0,
            title: Text(
              tr(context, 'সেটিংস', 'Settings'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [scheme.surfaceContainerLow, scheme.surfaceContainer])),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _section(tr(context, 'প্রোফাইল', 'Profile')),
                Card(
                  child: ListTile(
                    leading: SizedBox(
                      width: 44,
                      height: 44,
                      child: ClipOval(
                        child: avatar != null && File(avatar).existsSync()
                            ? Image.file(File(avatar), fit: BoxFit.cover, width: 44, height: 44)
                            : Container(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                alignment: Alignment.center,
                                child: Text(
                                  name.isNotEmpty ? name.characters.first.toUpperCase() : 'U',
                                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 18),
                                ),
                              ),
                      ),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(tr(context, 'অবতার, নাম, বায়ো, হোম সিটি', 'Avatar, name, bio, home city'), style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
                  ),
                ),
                const SizedBox(height: 24),
                _section(tr(context, 'ভাষা', 'Language')),
                Card(
                  child: Column(
                    children: [
                      for (final l in AppLanguage.values)
                        RadioListTile<AppLanguage>(
                          value: l,
                          groupValue: lang,
                          activeColor: AppColors.primary,
                          title: Text(l.native, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(l.englishName, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                          secondary: Icon(l == AppLanguage.bangla ? Icons.translate : Icons.language, color: AppColors.primary),
                          onChanged: (v) async {
                            if (v == null) return;
                            await LocaleService.instance.setLanguage(v);
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _section(tr(context, 'ব্যাকআপ', 'Backup')),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.save_outlined, color: AppColors.primary),
                        title: Text(tr(context, 'ব্যাকআপ ও রিস্টোর', 'Backup & restore'), style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          last != null
                              ? tr(context, 'শেষ ব্যাকআপ: $last', 'Last backup: $last')
                              : tr(context, 'এখনো কোনো ব্যাকআপ নেই', 'No backup yet'),
                          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BackupScreen())),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _section(tr(context, 'প্রদর্শন', 'Display')),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.light_mode_outlined, color: AppColors.primary),
                        title: Text(tr(context, 'থিম', 'Theme'), style: const TextStyle(fontWeight: FontWeight.w700)),
                        trailing: DropdownButton<ThemeMode>(
                          value: mode,
                          underline: const SizedBox.shrink(),
                          onChanged: (m) async {
                            if (m == null) return;
                            await SettingsService.instance.setThemeMode(m);
                            if (mounted) setState(() {});
                          },
                          items: [
                            DropdownMenuItem(value: ThemeMode.system, child: Text(tr(context, 'সিস্টেম', 'System'))),
                            DropdownMenuItem(value: ThemeMode.light, child: Text(tr(context, 'হালকা', 'Light'))),
                            DropdownMenuItem(value: ThemeMode.dark, child: Text(tr(context, 'অন্ধকার', 'Dark'))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _section(tr(context, 'ডেটা', 'Data')),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.history_rounded, color: AppColors.primary),
                        title: Text(tr(context, 'হিস্টোরি মুছুন', 'Clear history'), style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          tr(context, 'ক্যালকুলেটর ও লেনদেনের সব ইতিহাস মুছে দিন', 'Remove every calculation and transaction record'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: _clearHistory,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _section(tr(context, 'সম্পর্কে', 'About')),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outline, color: AppColors.primary),
                        title: const Text('Daily Utility', style: TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text(tr(context, 'সংস্করণ 1.0.0', 'Version 1.0.0'), style: const TextStyle(fontSize: 12)),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.shield_outlined, color: AppColors.success),
                        title: Text(tr(context, 'অফলাইন-প্রথম', 'Offline first'), style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(tr(context, 'সব ডেটা ফোনে সংরক্ষিত থাকে', 'All data lives on your device'), style: const TextStyle(fontSize: 12)),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.save_outlined, color: AppColors.primary),
                        title: Text(tr(context, 'ফাইল ব্যাকআপ', 'File backup'), style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          tr(context, 'Google অ্যাকাউন্ট ছাড়াই .json ফাইলে এক্সপোর্ট/ইমপোর্ট', 'Export / import as a .json file — no Google account needed'),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      if (name.isNotEmpty) ...[
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.person_outline, color: AppColors.primary),
                          title: Text(tr(context, 'ব্যবহারকারী', 'User'), style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(name, style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text('Daily Utility © 2026', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                ),
              ],
            ),
          ),
        );
          },
        );
      },
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Builder(builder: (context) {
          final s = Theme.of(context).colorScheme;
          return Text(
            title,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: s.onSurfaceVariant, letterSpacing: 0.4),
          );
        }),
      );
}
