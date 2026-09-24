import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../models/subscription.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

const _uuid = Uuid();

const _categories = <_Category>[
  _Category('streaming', Icons.movie_filter_outlined, 'Streaming'),
  _Category('music', Icons.music_note_outlined, 'Music'),
  _Category('productivity', Icons.work_outline, 'Productivity'),
  _Category('cloud', Icons.cloud_outlined, 'Cloud / Storage'),
  _Category('gaming', Icons.sports_esports_outlined, 'Gaming'),
  _Category('news', Icons.menu_book_outlined, 'News'),
  _Category('fitness', Icons.fitness_center_outlined, 'Fitness'),
  _Category('education', Icons.school_outlined, 'Education'),
  _Category('utilities', Icons.bolt_outlined, 'Utilities'),
  _Category('insurance', Icons.shield_outlined, 'Insurance'),
  _Category('other', Icons.subscriptions_outlined, 'Other'),
];

const _currencies = <String>['BDT', 'INR', 'USD', 'EUR', 'GBP', 'JPY'];

const _palette = <int>[
  0xFFEC4899,
  0xFF6366F1,
  0xFF06B6D4,
  0xFF10B981,
  0xFFF59E0B,
  0xFFEF4444,
  0xFF8B5CF6,
  0xFF0EA5E9,
];

const _reminderOffsets = <int?>[null, 1, 3, 7];

class SubscriptionFormScreen extends StatefulWidget {
  final Subscription? existing;
  const SubscriptionFormScreen({super.key, this.existing});

  @override
  State<SubscriptionFormScreen> createState() => _SubscriptionFormScreenState();
}

class _SubscriptionFormScreenState extends State<SubscriptionFormScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _notesCtrl;
  late BillingCycle _cycle;
  late DateTime _renewalDate;
  late String _category;
  late String _currency;
  late int? _reminderDaysBefore;
  late int _colorValue;
  late bool _isActive;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _amountCtrl = TextEditingController(text: e == null ? '' : e.amount.toStringAsFixed(2));
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _cycle = e?.cycle ?? BillingCycle.monthly;
    _renewalDate = e?.nextRenewalDate ?? _defaultRenewal();
    _category = e?.category ?? 'streaming';
    _currency = e?.currency ?? 'BDT';
    _reminderDaysBefore = e?.reminderDaysBefore;
    _colorValue = e?.colorValue ?? _palette.first;
    _isActive = e?.isActive ?? true;
  }

  static DateTime _defaultRenewal() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, now.day);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _categoryLabel(BuildContext c, String key) {
    final found = _categories.firstWhere((x) => x.key == key, orElse: () => _categories.last);
    return tr(c, _bengaliCategory(key), found.label);
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _renewalDate.isBefore(now) ? now : _renewalDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      helpText: tr(context, 'পরবর্তী রিনিউয়ালের তারিখ বাছাই করুন', 'Pick the next renewal date'),
    );
    if (picked != null) {
      setState(() => _renewalDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final box = HiveService.subscriptions;
    final isEdit = widget.existing != null;
    final id = widget.existing?.id ?? _uuid.v4();
    final createdAt = widget.existing?.createdAt ?? DateTime.now();

    final amount = double.parse(_amountCtrl.text.trim());

    // Cancel old reminder before assigning new id, so we never leave a
    // dangling notification tied to a deleted record.
    if (isEdit && widget.existing!.notificationId != null) {
      await NotificationService.cancel(widget.existing!.notificationId);
    }

    final sub = Subscription(
      id: id,
      title: _titleCtrl.text.trim(),
      amount: amount,
      cycle: _cycle,
      nextRenewalDate: _renewalDate,
      category: _category,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      reminderDaysBefore: _reminderDaysBefore,
      notificationId: null,
      currency: _currency,
      isActive: _isActive,
      colorValue: _colorValue,
      createdAt: createdAt,
    );

    if (_isActive && _reminderDaysBefore != null) {
      final fireAt = DateTime(
        _renewalDate.year,
        _renewalDate.month,
        _renewalDate.day,
        9,
      ).subtract(Duration(days: _reminderDaysBefore!));
      if (fireAt.isAfter(DateTime.now())) {
        final symbol = _currencySymbol(_currency);
        final cycleText = _cycleLabel(context, _cycle);
        final dateText = DateFormat('d MMM yyyy').format(_renewalDate);
        final daysBefore = _reminderDaysBefore!;
        final notifId = await NotificationService.scheduleReminder(
          idKey: 'sub_$id',
          title: tr(context, '$daysBefore দিন পর ${sub.title} রিনিউ হবে', '$daysBefore days until ${sub.title} renews'),
          body: tr(
            context,
            '$symbol${amount.toStringAsFixed(2)} $cycleText — তারিখ: $dateText',
            '$symbol${amount.toStringAsFixed(2)} $cycleText — on $dateText',
          ),
          fireAt: fireAt,
        );
        sub.notificationId = notifId;
      }
    }

    await box.put(sub.id, sub);
    if (mounted) Navigator.of(context).pop(sub);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? tr(context, 'নতুন সাবস্ক্রিপশন', 'New subscription') : tr(context, 'সাবস্ক্রিপশন সম্পাদনা', 'Edit subscription')),
        actions: [
          IconButton(
            tooltip: tr(context, 'সংরক্ষণ', 'Save'),
            icon: const Icon(Icons.check_rounded),
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _colorHero(scheme),
            const SizedBox(height: 18),
            Text(tr(context, 'বিবরণ', 'Details'), style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            _field(
              label: tr(context, 'শিরোনাম', 'Title'),
              child: TextFormField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: tr(context, 'শিরোনাম', 'Title'), hintText: tr(context, 'যেমন: Netflix, জিম', 'e.g. Netflix, Gym')),
                validator: (v) => v == null || v.trim().isEmpty ? tr(context, 'শিরোনাম দিন', 'Please enter a title') : null,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _field(
                    label: tr(context, 'মূল্য', 'Amount'),
                    child: TextFormField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                      decoration: InputDecoration(
                        labelText: tr(context, 'মূল্য', 'Amount'),
                        hintText: '0.00',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 8),
                          child: Center(
                            widthFactor: 1,
                            child: Text(_currencySymbol(_currency), style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w800)),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return tr(context, 'মূল্য দিন', 'Enter amount');
                        final d = double.tryParse(v.trim());
                        if (d == null || d <= 0) return tr(context, 'সঠিক মূল্য দিন', 'Invalid amount');
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _field(
                    label: tr(context, 'মুদ্রা', 'Currency'),
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: tr(context, 'মুদ্রা', 'Currency')),
                      items: [
                        for (final c in _currencies)
                          DropdownMenuItem(
                            value: c,
                            child: Text('${_currencySymbol(c)}  $c', style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                      ],
                      onChanged: (v) => setState(() => _currency = v ?? 'BDT'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _field(
              label: tr(context, 'বিলিং চক্র', 'Billing cycle'),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final cycle in BillingCycle.values)
                    ChoiceChip(
                      label: Text(_cycleLabel(context, cycle)),
                      selected: _cycle == cycle,
                      onSelected: (_) => setState(() => _cycle = cycle),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _field(
              label: tr(context, 'পরবর্তী রিনিউয়াল', 'Next renewal'),
              child: InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('EEE, d MMM yyyy').format(_renewalDate),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(tr(context, 'ক্যাটাগরি', 'Category'), style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in _categories)
                  ChoiceChip(
                    avatar: Icon(cat.icon, size: 18),
                    label: Text(_categoryLabel(context, cat.key)),
                    selected: _category == cat.key,
                    onSelected: (_) => setState(() => _category = cat.key),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(tr(context, 'রিমাইন্ডার', 'Reminder'), style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(tr(context, 'নেই', 'None')),
                  selected: _reminderDaysBefore == null,
                  onSelected: (_) => setState(() => _reminderDaysBefore = null),
                ),
                for (final d in _reminderOffsets.where((x) => x != null).cast<int>())
                  ChoiceChip(
                    label: Text(tr(context, '$d দিন আগে', '$d days before')),
                    selected: _reminderDaysBefore == d,
                    onSelected: (_) => setState(() => _reminderDaysBefore = d),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(tr(context, 'রঙ', 'Color'), style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final c in _palette)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => _colorValue = c),
                        child: AnimatedContainer(
                          duration: AppAnimations.fast,
                          width: _colorValue == c ? 44 : 36,
                          height: _colorValue == c ? 44 : 36,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                          ),
                          child: _colorValue == c
                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr(context, 'সক্রিয়', 'Active'), style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(
                _isActive
                    ? tr(context, 'রিনিউয়াল ও রিমাইন্ডার চালু থাকবে', 'Renews and reminds as scheduled')
                    : tr(context, 'পজ রাখা হয়েছে', 'Paused — no reminders'),
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 8),
            _field(
              label: tr(context, 'নোট (ঐচ্ছিক)', 'Notes (optional)'),
              child: TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: tr(context, 'নোট', 'Notes'),
                  hintText: tr(context, 'যেকোনো তথ্য...', 'Any extra info...'),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: Text(widget.existing == null ? tr(context, 'সাবস্ক্রিপশন যোগ করুন', 'Add subscription') : tr(context, 'পরিবর্তন সংরক্ষণ করুন', 'Save changes')),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: Color(_colorValue),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorHero(ColorScheme scheme) {
    final c = Color(_colorValue);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c, c.withValues(alpha: 0.78)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(color: c.withValues(alpha: 0.28), blurRadius: 18, offset: const Offset(0, 8)),
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
                child: Icon(_iconForCategory(_category), color: Colors.white, size: 22),
              ),
              const Spacer(),
              if (_isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(999)),
                  child: Text(tr(context, 'সক্রিয়', 'Active'), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _titleCtrl.text.trim().isEmpty ? tr(context, 'নতুন সাবস্ক্রিপশন', 'New subscription') : _titleCtrl.text,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.3),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            '${_currencySymbol(_currency)}${_amountCtrl.text.isEmpty ? '0.00' : _amountCtrl.text} • ${_cycleLabel(context, _cycle)}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.event_outlined, color: Colors.white, size: 14),
              const SizedBox(width: 5),
              Text(
                '${tr(context, 'পরবর্তী: ', 'Next: ')}${DateFormat('d MMM').format(_renewalDate)}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        child,
      ],
    );
  }

  IconData _iconForCategory(String key) {
    final found = _categories.firstWhere((c) => c.key == key, orElse: () => _categories.last);
    return found.icon;
  }
}

class _Category {
  final String key;
  final IconData icon;
  final String label;
  const _Category(this.key, this.icon, this.label);
}
