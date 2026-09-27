import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/vault_credential.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';

const _uuid = Uuid();

/// Vault editor — add or edit a credential.
class VaultEditorScreen extends StatefulWidget {
  final VaultCredential? existing;
  const VaultEditorScreen({super.key, this.existing});

  @override
  State<VaultEditorScreen> createState() => _VaultEditorScreenState();
}

class _VaultEditorScreenState extends State<VaultEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _url;
  late String _category;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _username = TextEditingController(text: e?.username ?? '');
    _password = TextEditingController(text: e?.password ?? '');
    _url = TextEditingController(text: e?.url ?? '');
    _category = e?.category ?? 'other';
  }

  @override
  void dispose() {
    _title.dispose();
    _username.dispose();
    _password.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = _title.text.trim();
    if (t.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context, 'একটি শিরোনাম লিখুন', 'Please enter a title'))));
      return;
    }
    if (widget.existing != null) {
      final e = widget.existing!;
      e.title = t;
      e.username = _username.text;
      e.password = _password.text;
      e.url = _url.text.trim().isEmpty ? null : _url.text.trim();
      e.category = _category;
      await e.save();
    } else {
      final c = VaultCredential(
        id: _uuid.v4(),
        title: t,
        username: _username.text,
        password: _password.text,
        url: _url.text.trim().isEmpty ? null : _url.text.trim(),
        category: _category,
        iconCodePoint: Icons.lock_outline.codePoint,
        colorValue: 0xFF0EA5E9,
        createdAt: DateTime.now(),
      );
      await HiveService.vault.put(c.id, c);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEdit = widget.existing != null;
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.notifier,
      builder: (context, locale, _) {
        return Scaffold(
          backgroundColor: scheme.surfaceContainerLow,
          appBar: AppBar(title: Text(isEdit ? tr(context, 'সম্পাদনা', 'Edit') : tr(context, 'নতুন ক্রেডেনশিয়াল', 'New credential'))),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _field(tr(context, 'শিরোনাম', 'Title'), _title),
              const SizedBox(height: 12),
              _field(tr(context, 'ইউজারনেম / ইমেইল', 'Username / email'), _username),
              const SizedBox(height: 12),
              _passwordField(),
              const SizedBox(height: 12),
              _field(tr(context, 'URL (ঐচ্ছিক)', 'URL (optional)'), _url),
              const SizedBox(height: 16),
              Text(
                tr(context, 'ক্যাটেগরি', 'Category'),
                style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(context, 'banking', tr(context, 'ব্যাংকিং', 'Banking'), Icons.account_balance_outlined),
                  _chip(context, 'social', tr(context, 'সোশ্যাল', 'Social'), Icons.mail_outline),
                  _chip(context, 'work', tr(context, 'কাজ', 'Work'), Icons.work_outline),
                  _chip(context, 'other', tr(context, 'অন্যান্য', 'Other'), Icons.lock_outline),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(backgroundColor: AppColors.vault, minimumSize: const Size(0, 52)),
                child: Text(isEdit ? tr(context, 'সংরক্ষণ', 'Save') : tr(context, 'যোগ করুন', 'Add credential')),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _field(String label, TextEditingController c) => TextField(controller: c, decoration: InputDecoration(labelText: label));

  Widget _passwordField() => TextField(
        controller: _password,
        obscureText: _obscure,
        decoration: InputDecoration(
          labelText: tr(context, 'পাসওয়ার্ড', 'Password'),
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      );

  Widget _chip(BuildContext context, String key, String label, IconData icon) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _category == key;
    return ChoiceChip(
      label: Text(label),
      avatar: Icon(icon, size: 16, color: selected ? AppColors.vault : null),
      selected: selected,
      onSelected: (_) => setState(() => _category = key),
      selectedColor: AppColors.vault.withValues(alpha: 0.18),
      labelStyle: TextStyle(color: selected ? AppColors.vault : scheme.onSurface, fontWeight: FontWeight.w700),
    );
  }
}
