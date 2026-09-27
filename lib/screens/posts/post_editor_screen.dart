import 'dart:io';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/post.dart';
import '../../services/data_refresh_service.dart';
import '../../services/hive_service.dart';
import '../../services/image_storage_service.dart';
import '../../services/locale_service.dart';
import '../../services/post_share_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';

/// Professional Broadcast Studio / Post Editor screen inspired by modern creator tools.
class PostEditorScreen extends StatefulWidget {
  final Post? initial;
  const PostEditorScreen({super.key, this.initial});

  @override
  State<PostEditorScreen> createState() => _PostEditorScreenState();
}

class _PostEditorScreenState extends State<PostEditorScreen> {
  static const _uuid = Uuid();

  static const _palette = <int>[
    0xFF3D5AFE, // Blue
    0xFFE11D48, // Rose
    0xFF8B5CF6, // Violet
    0xFF10B981, // Emerald
    0xFF06B6D4, // Cyan
    0xFFF59E0B, // Amber
  ];

  late TextEditingController _titleCtrl;
  late TextEditingController _bodyCtrl;
  late TextEditingController _tagCtrl;
  late TextEditingController _locationCtrl;

  late PostCategory _category;
  late int _colorValue;
  late List<String> _imagePaths;
  late List<String> _tags;
  late bool _pinned;
  late DateTime _createdAt;
  int _activeImageIndex = 0;
  String _publishingMode = 'instant'; // 'instant', 'pinned', 'draft'
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _bodyCtrl = TextEditingController(text: p?.body ?? '');
    _tagCtrl = TextEditingController();
    _locationCtrl = TextEditingController(text: LocaleService.isBangla ? 'স্টুডিও হাব' : 'Studio Hub');
    _category = p?.category ?? PostCategory.general;
    _colorValue = p?.colorValue ?? _palette.first;
    _imagePaths = List<String>.from(p?.imagePaths ?? const <String>[]);
    _tags = List<String>.from(p?.tags ?? const <String>[]);
    _pinned = p?.pinned ?? false;
    _createdAt = p?.createdAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _tagCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final t = tag.trim().replaceAll('#', '');
    if (t.isEmpty) return;
    if (_tags.contains(t)) return;
    if (_tags.length >= 8) {
      _snack(tr(context, 'সর্বোচ্চ ৮টি ট্যাগ', 'Maximum 8 tags allowed'));
      return;
    }
    setState(() => _tags.add(t));
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _pickImages() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.post),
              title: Text(tr(ctx, 'ক্যামেরা', 'Camera')),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.post),
              title: Text(tr(ctx, 'গ্যালারি থেকে একাধিক', 'Multiple from gallery')),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    final List<String> newPaths;
    if (choice == 'camera') {
      final p = await ImageStorageService.instance.captureFromCamera(subdir: 'posts');
      newPaths = p == null ? const [] : [p];
    } else {
      newPaths = await ImageStorageService.instance.pickFromGallery(subdir: 'posts');
    }
    if (newPaths.isEmpty || !mounted) return;
    setState(() {
      _imagePaths.addAll(newPaths);
      _activeImageIndex = _imagePaths.length - 1;
    });
  }

  void _removeImage(int index) {
    final path = _imagePaths[index];
    setState(() {
      _imagePaths.removeAt(index);
      if (_activeImageIndex >= _imagePaths.length) {
        _activeImageIndex = (_imagePaths.length - 1).clamp(0, 99);
      }
    });
    ImageStorageService.instance.deleteIfExists(path);
  }

  void _aiEnhance() {
    final text = _bodyCtrl.text;
    if (text.trim().isEmpty) {
      _snack(tr(context, 'প্রথমে কিছু লেখা লিখুন', 'Write text before polishing'));
      return;
    }
    final formatted = text
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .split('. ')
        .map((s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '')
        .join('. ');

    setState(() {
      _bodyCtrl.text = formatted;
    });
    _snack(tr(context, 'লেখা পরিমার্জিত করা হয়েছে ✨', 'Text polished with ✨ AI Enhance'));
  }

  Future<void> _save({bool isDraft = false}) async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty && _bodyCtrl.text.trim().isEmpty && _imagePaths.isEmpty) {
      _snack(tr(context, 'কিছু শিরোনাম বা পোস্ট লিখুন', 'Enter a title or post body'));
      return;
    }
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final postTitle = title.isEmpty ? (_bodyCtrl.text.trim().split('\n').first) : title;
      if (widget.initial == null) {
        final post = Post(
          id: _uuid.v4(),
          title: postTitle,
          body: _bodyCtrl.text.trim(),
          category: _category,
          tags: List<String>.from(_tags),
          colorValue: _colorValue,
          imagePaths: List<String>.from(_imagePaths),
          pinned: _pinned || _publishingMode == 'pinned',
          createdAt: _createdAt,
          updatedAt: now,
        );
        await HiveService.posts.put(post.id, post);
      } else {
        final p = widget.initial!;
        p.title = postTitle;
        p.body = _bodyCtrl.text.trim();
        p.category = _category;
        p.colorValue = _colorValue;
        p.imagePaths = List<String>.from(_imagePaths);
        p.tags = List<String>.from(_tags);
        p.pinned = _pinned || _publishingMode == 'pinned';
        p.updatedAt = now;
        await p.save();
      }
      DataRefreshService.instance.bump();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _share() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _snack(tr(context, 'শেয়ার করতে একটি শিরোনাম দিন', 'Add a title before sharing'));
      return;
    }
    await _save();
    final p = widget.initial ?? HiveService.posts.values.lastOrNull;
    if (p != null && mounted) {
      await PostShareService.instance.sharePost(
        p,
        isBangla: LocaleService.isBangla,
        sharePositionOrigin: _shareOrigin(context),
      );
    }
  }

  Rect? _shareOrigin(BuildContext ctx) {
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final settings = SettingsService.instance;
    final authorName = settings.userName;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      appBar: AppBar(
        title: Row(
          children: [
            Text(tr(context, 'ব্রডকাস্ট স্টুডিও', 'Broadcast Studio')),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
              child: Row(
                children: [
                  const CircleAvatar(radius: 3, backgroundColor: AppColors.success),
                  const SizedBox(width: 4),
                  Text(tr(context, '• লাইভ', '• Live'), style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: tr(context, 'শেয়ার', 'Share'),
            icon: const Icon(Icons.share_outlined),
            onPressed: _saving ? null : _share,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          // 1. Channel Header Card
          _buildChannelHeaderCard(context, scheme, authorName),
          const SizedBox(height: 16),

          // 2. Carousel Deck (Media Deck)
          _buildCarouselDeckCard(context, scheme),
          const SizedBox(height: 16),

          // 3. Caption & Content Section
          _buildCaptionCard(context, scheme),
          const SizedBox(height: 16),

          // 4. Publishing Mode Section
          _buildPublishingModeCard(context, scheme),
          const SizedBox(height: 16),

          // 5. Feed Simulation Preview
          _buildFeedSimulationCard(context, scheme, authorName),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: scheme.surface,
          boxShadow: [BoxShadow(color: scheme.shadow.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
                  onPressed: _saving ? null : () => _save(isDraft: true),
                  child: Text(tr(context, 'ড্রাফট হিসেবে রাখুন', 'Save Draft')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, minimumSize: const Size(0, 52)),
                  onPressed: _saving ? null : () => _save(),
                  icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded, size: 20),
                  label: Text(tr(context, 'পোস্ট ব্রডকাস্ট করুন', 'Publish Broadcast')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelHeaderCard(BuildContext context, ColorScheme scheme, String authorName) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(authorName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, size: 16, color: AppColors.primary),
                        ],
                      ),
                      Text('@${authorName.toLowerCase().replaceAll(' ', '_')}', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(999)),
                  child: Row(
                    children: [
                      const Icon(Icons.public, size: 14),
                      const SizedBox(width: 4),
                      Text(tr(context, 'পাবলিক', 'Public'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Destination Platform Badges
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final c in PostCategory.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(kPostCategoryMeta[c]!.icon, size: 16, color: _category == c ? Colors.white : AppColors.primary),
                        label: Text(tr(context, kPostCategoryMeta[c]!.bn, kPostCategoryMeta[c]!.en)),
                        selected: _category == c,
                        onSelected: (_) => setState(() => _category = c),
                        selectedColor: AppColors.primary,
                        backgroundColor: scheme.surfaceContainerHigh,
                        labelStyle: TextStyle(color: _category == c ? Colors.white : scheme.onSurface, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselDeckCard(BuildContext context, ColorScheme scheme) {
    final hasImages = _imagePaths.isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.view_carousel_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(tr(context, 'ক্যারোজেল ডেক', 'Carousel Deck'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(8)),
                  child: Text(tr(context, '১:১ বর্গাকার', '1:1 Square'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Hero Active Preview Box
            if (hasImages) ...[
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: FileImage(File(_imagePaths[_activeImageIndex.clamp(0, _imagePaths.length - 1)])),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(99)),
                        child: Text(tr(context, '${_activeImageIndex + 1} / ${_imagePaths.length}', '${_activeImageIndex + 1} of ${_imagePaths.length}'), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.black.withValues(alpha: 0.6),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close, color: Colors.white, size: 16),
                          onPressed: () => _removeImage(_activeImageIndex),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(99)),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(tr(context, 'স্টুডিও হাব', 'Studio Hub'), style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Thumbnails Row & Add Media
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _imagePaths.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  if (i == _imagePaths.length) {
                    return InkWell(
                      onTap: _pickImages,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 22),
                            const SizedBox(height: 2),
                            Text(tr(context, '+ মিডিয়া', '+ Add'), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.primary)),
                          ],
                        ),
                      ),
                    );
                  }
                  final path = _imagePaths[i];
                  final isSelected = i == _activeImageIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _activeImageIndex = i),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? Border.all(color: AppColors.primary, width: 2.5) : null,
                        image: DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptionCard(BuildContext context, ColorScheme scheme) {
    final charCount = _bodyCtrl.text.length;
    final tagCount = _tags.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(tr(context, 'ক্যাপশন ও কন্টেন্ট', 'Caption & Content'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _aiEnhance,
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: Text(tr(context, '✨ এআই এনহ্যান্স', '✨ AI Enhance'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title Field
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              maxLines: 2,
              minLines: 1,
              decoration: InputDecoration(
                hintText: tr(context, 'শিরোনাম (ঐচ্ছিক)…', 'Post Title (optional)…'),
                hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const Divider(height: 16),

            // Body Field
            TextField(
              controller: _bodyCtrl,
              maxLines: null,
              minLines: 4,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(fontSize: 15, height: 1.5),
              decoration: InputDecoration(
                hintText: tr(context, 'পোস্টের বিস্তারিত বিষয়বস্তু লিখুন…', 'Write your post caption and thoughts here…'),
                hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),

            // Char & Tag Counter
            Row(
              children: [
                Text(tr(context, '$charCount / ২,২০০ অক্ষর', '$charCount / 2,200 chars'), style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
                const SizedBox(width: 12),
                Text(tr(context, '$tagCount / ৩০ টি ট্যাগ', '$tagCount / 30 tags'), style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(tr(context, 'অটো-সিঙ্কড', 'Auto-synced'), style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),

            // Tags row
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final t in _tags)
                  InputChip(
                    label: Text('#$t'),
                    onDeleted: () => _removeTag(t),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _tagCtrl,
                    style: const TextStyle(fontSize: 13),
                    onSubmitted: (v) {
                      _addTag(v);
                      _tagCtrl.clear();
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: tr(context, '+ ট্যাগ দিন', '+ tag'),
                      hintStyle: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublishingModeCard(BuildContext context, ColorScheme scheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.send_time_extension_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(tr(context, 'পাবলিশিং মোড', 'Publishing Mode'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                const Spacer(),
                Text(tr(context, 'অপটিমাল উইন্ডো', 'Optimal Window'), style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            _modeOptionTile(
              context,
              id: 'instant',
              title: tr(context, 'সরাসরি ব্রডকাস্ট করুন', 'Publish Instantly'),
              subtitle: tr(context, 'তাত্ক্ষণিকভাবে পোস্ট ফিডে যুক্ত হবে', 'Broadcast immediately across feed'),
              icon: Icons.flash_on_rounded,
            ),
            const SizedBox(height: 8),
            _modeOptionTile(
              context,
              id: 'pinned',
              title: tr(context, 'পিনড পোস্ট (উপরে রাখুন)', 'Pin to Top of Feed'),
              subtitle: tr(context, 'ফিডের সবার উপরে পিন করা থাকবে', 'Keep highlighted at top of community feed'),
              icon: Icons.push_pin_rounded,
            ),
            const SizedBox(height: 8),
            _modeOptionTile(
              context,
              id: 'draft',
              title: tr(context, 'ড্রাফট হিসেবে রাখুন', 'Save as Local Draft'),
              subtitle: tr(context, 'পরে সম্পাদনা বা ব্রডকাস্টের জন্য সংরক্ষণ', 'Store locally to review and broadcast later'),
              icon: Icons.drafts_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeOptionTile(BuildContext context, {required String id, required String title, required String subtitle, required IconData icon}) {
    final scheme = Theme.of(context).colorScheme;
    final isSelected = _publishingMode == id;
    return InkWell(
      onTap: () => setState(() => _publishingMode = id),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : scheme.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : scheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: isSelected ? AppColors.primary : scheme.onSurface)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(icon, size: 18, color: isSelected ? AppColors.primary : scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedSimulationCard(BuildContext context, ColorScheme scheme, String authorName) {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    final hasImage = _imagePaths.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.preview_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(tr(context, 'ফিড সিমুলেশন প্রিভিউ', 'Feed Simulation'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(tr(context, 'লাইভ মকআপ', 'Live Mockup'), style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Mockup Feed Card Box
            Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: scheme.shadow.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary,
                          child: Text(authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(authorName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                            Text(tr(context, 'স্টুডিও হাব', 'Studio Hub'), style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Image Preview
                  if (hasImage)
                    Image.file(File(_imagePaths.first), height: 180, width: double.infinity, fit: BoxFit.cover)
                  else
                    Container(
                      height: 100,
                      width: double.infinity,
                      color: AppColors.primary.withValues(alpha: 0.08),
                      child: const Center(child: Icon(Icons.image_outlined, color: AppColors.primary, size: 36)),
                    ),

                  // Actions Row
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.favorite_border_rounded, size: 20),
                        SizedBox(width: 12),
                        Icon(Icons.mode_comment_outlined, size: 20),
                        SizedBox(width: 12),
                        Icon(Icons.share_outlined, size: 20),
                        Spacer(),
                        Icon(Icons.bookmark_border_rounded, size: 20),
                      ],
                    ),
                  ),

                  // Caption Text
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title.isNotEmpty) Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                        if (body.isNotEmpty) Text(body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
