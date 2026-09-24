import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../models/post.dart';
import '../../services/data_refresh_service.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../services/post_share_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'post_editor_screen.dart';

class PostsListScreen extends StatefulWidget {
  const PostsListScreen({super.key});

  @override
  State<PostsListScreen> createState() => _PostsListScreenState();
}

class _PostsListScreenState extends State<PostsListScreen> {
  String _query = '';
  PostCategory? _categoryFilter;
  bool _pinnedOnly = false;

  bool _matches(Post p) {
    if (_pinnedOnly && !p.pinned) return false;
    if (_categoryFilter != null && p.category != _categoryFilter) return false;
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    if (p.title.toLowerCase().contains(q)) return true;
    if (p.body.toLowerCase().contains(q)) return true;
    for (final t in p.tags) {
      if (t.toLowerCase().contains(q)) return true;
    }
    return false;
  }

  Future<void> _openEditor({Post? initial}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PostEditorScreen(initial: initial)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _sharePost(Post p) async {
    await PostShareService.instance.sharePost(
      p,
      isBangla: LocaleService.isBangla,
      sharePositionOrigin: _shareOrigin(context),
    );
  }

  Future<void> _confirmDelete(Post p) async {
    final ok = await confirmDelete(
      context,
      title: tr(context, 'পোস্ট মুছবেন?', 'Delete post?'),
      message: tr(context, 'পোস্টের সব ছবিও মুছে যাবে।', 'Attached images will also be deleted.'),
    );
    if (!ok) return;
    for (final path in p.imagePaths) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    await p.delete();
    if (mounted) {
      setState(() {});
      DataRefreshService.instance.bump();
    }
  }

  Future<void> _togglePin(Post p) async {
    p.pinned = !p.pinned;
    p.updatedAt = DateTime.now();
    await p.save();
    if (mounted) setState(() {});
  }

  Future<void> _toggleLike(Post p) async {
    p.liked = !p.liked;
    p.likes = (p.likes + (p.liked ? 1 : -1)).clamp(0, 1 << 30);
    if (p.liked) {
      p.impressions = (p.impressions + 1).clamp(0, 1 << 30);
    }
    p.updatedAt = DateTime.now();
    await p.save();
    if (mounted) setState(() {});
  }

  Future<void> _bumpImpression(Post p) async {
    p.impressions = (p.impressions + 1).clamp(0, 1 << 30);
    await p.save();
  }

  Future<void> _showActions(Post p) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(p.pinned ? Icons.push_pin : Icons.push_pin_outlined, color: AppColors.primary),
              title: Text(p.pinned ? tr(ctx, 'পিন খুলুন', 'Unpin') : tr(ctx, 'পিন করুন', 'Pin to top')),
              onTap: () {
                Navigator.pop(ctx);
                _togglePin(p);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
              title: Text(tr(ctx, 'সম্পাদনা', 'Edit')),
              onTap: () {
                Navigator.pop(ctx);
                _openEditor(initial: p);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined, color: AppColors.primary),
              title: Text(tr(ctx, 'শেয়ার', 'Share')),
              onTap: () {
                Navigator.pop(ctx);
                _sharePost(p);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.danger),
              title: Text(tr(ctx, 'মুছুন', 'Delete'), style: const TextStyle(color: AppColors.danger)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(p);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Rect? _shareOrigin(BuildContext ctx) {
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'পোস্ট', 'Posts')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: tr(context, 'নতুন পোস্ট', 'New post'),
            onPressed: () => _openEditor(),
          ),
        ],
      ),
      body: ValueListenableBuilder<Locale>(
        valueListenable: LocaleService.instance.notifier,
        builder: (context, locale, _) {
          return AnimatedBuilder(
            animation: Listenable.merge([
              HiveService.posts.listenable(),
              DataRefreshService.instance.notifier,
              SettingsService.instance.revision,
            ]),
            builder: (context, _) {
              final all = HiveService.posts.values.toList()
                ..sort((a, b) {
                  if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
                  return b.updatedAt.compareTo(a.updatedAt);
                });
              final visible = all.where(_matches).toList();
              return Column(
                children: [
                  _buildSearchAndFilters(context),
                  Expanded(
                    child: all.isEmpty
                        ? RefreshIndicator(
                            onRefresh: () async {
                              DataRefreshService.instance.bump();
                              await Future<void>.delayed(const Duration(milliseconds: 350));
                            },
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                const SizedBox(height: 80),
                                EmptyState(
                                  icon: Icons.article_outlined,
                                  title: tr(context, 'কোনো পোস্ট নেই', 'No posts yet'),
                                  message: tr(context, 'আপনার প্রথম ব্লগ-স্টাইল পোস্ট তৈরি করুন', 'Create your first blog-style post'),
                                ),
                              ],
                            ),
                          )
                        : visible.isEmpty
                            ? RefreshIndicator(
                                onRefresh: () async {
                                  DataRefreshService.instance.bump();
                                  await Future<void>.delayed(const Duration(milliseconds: 350));
                                },
                                child: ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    const SizedBox(height: 80),
                                    EmptyState(
                                      icon: Icons.search_off,
                                      title: tr(context, 'কিছু পাওয়া যায়নি', 'Nothing found'),
                                      message: tr(context, 'ফিল্টার বা কিওয়ার্ড পরিবর্তন করে দেখুন', 'Try a different filter or keyword'),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () async {
                                  DataRefreshService.instance.bump();
                                  await Future<void>.delayed(const Duration(milliseconds: 350));
                                },
                                child: ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 110),
                                  itemCount: visible.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (_, i) => _FeedCard(
                                    post: visible[i],
                                    onOpen: () => _openEditor(initial: visible[i]),
                                    onLongPress: () => _showActions(visible[i]),
                                    onShare: () => _sharePost(visible[i]),
                                    onLike: () => _toggleLike(visible[i]),
                                    onView: () => _bumpImpression(visible[i]),
                                  ),
                                ),
                              ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.post,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(tr(context, 'নতুন পোস্ট', 'New post')),
        onPressed: () => _openEditor(),
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: tr(context, 'পোস্ট খুঁজুন…', 'Search posts…'),
            ),
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip(
                  label: tr(context, 'সব', 'All'),
                  icon: Icons.dashboard_rounded,
                  selected: _categoryFilter == null && !_pinnedOnly,
                  onSelected: () => setState(() {
                    _categoryFilter = null;
                    _pinnedOnly = false;
                  }),
                ),
                const SizedBox(width: 6),
                _filterChip(
                  label: tr(context, 'পিনড', 'Pinned'),
                  icon: Icons.push_pin_rounded,
                  selected: _pinnedOnly,
                  onSelected: () => setState(() => _pinnedOnly = !_pinnedOnly),
                ),
                const SizedBox(width: 6),
                for (final c in PostCategory.values) ...[
                  _filterChip(
                    label: tr(context, kPostCategoryMeta[c]!.bn, kPostCategoryMeta[c]!.en),
                    icon: kPostCategoryMeta[c]!.icon,
                    selected: _categoryFilter == c,
                    onSelected: () => setState(() => _categoryFilter = _categoryFilter == c ? null : c),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: selected ? Colors.white : AppColors.post),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: AppColors.post,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      side: BorderSide.none,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
      ),
    );
  }
}

/// Facebook / Instagram-style feed card.
class _FeedCard extends StatefulWidget {
  final Post post;
  final VoidCallback onOpen;
  final VoidCallback onLongPress;
  final VoidCallback onShare;
  final VoidCallback onLike;
  final VoidCallback onView;
  const _FeedCard({
    required this.post,
    required this.onOpen,
    required this.onLongPress,
    required this.onShare,
    required this.onLike,
    required this.onView,
  });

  @override
  State<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<_FeedCard> {
  int _currentImageIndex = 0;
  late final PageController _pageController = PageController();
  bool _viewed = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _ensureView() {
    if (_viewed) return;
    _viewed = true;
    widget.onView();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cat = kPostCategoryMeta[widget.post.category]!;
    final accent = Color(widget.post.colorValue);
    final settings = SettingsService.instance;
    final authorName = widget.post.authorName?.trim().isNotEmpty == true
        ? widget.post.authorName!.trim()
        : settings.userName;
    final avatarPath = widget.post.authorAvatarPath ?? settings.avatarPath;

    return GestureDetector(
      onLongPress: widget.onLongPress,
      onTap: widget.onOpen,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.soft(accent.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context, scheme, cat, accent, authorName, avatarPath),
            if (widget.post.title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                child: Text(
                  widget.post.title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, height: 1.25),
                ),
              ),
            if (widget.post.body.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
                child: Text(
                  widget.post.body,
                  style: TextStyle(fontSize: 14, color: scheme.onSurface, height: 1.4),
                ),
              ),
            if (widget.post.imagePaths.isNotEmpty) _imageCarousel(context, accent),
            _tags(context, scheme, accent),
            _footer(context, scheme, accent),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, ColorScheme scheme, PostCategoryMeta cat, Color accent, String authorName, String? avatarPath) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
      child: Row(
        children: [
          _avatar(context, authorName, avatarPath, accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        authorName,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.post.pinned) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.push_pin_rounded, size: 14, color: accent),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(cat.icon, size: 12, color: accent),
                    const SizedBox(width: 4),
                    Text(
                      '${tr(context, cat.bn, cat.en)} · ${_relativeDate(context, widget.post.updatedAt)}',
                      style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded),
            onPressed: widget.onLongPress,
            tooltip: tr(context, 'আরো', 'More'),
          ),
        ],
      ),
    );
  }

  Widget _avatar(BuildContext context, String name, String? path, Color accent) {
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [accent, accent.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: path != null && File(path).existsSync()
          ? Image.file(File(path), fit: BoxFit.cover, width: 42, height: 42)
          : Center(
              child: Text(
                letter,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ),
    );
  }

  Widget _imageCarousel(BuildContext context, Color accent) {
    final paths = widget.post.imagePaths;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 260,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentImageIndex = i),
                itemCount: paths.length,
                itemBuilder: (_, i) {
                  final p = paths[i];
                  if (!File(p).existsSync()) {
                    return Container(color: accent.withValues(alpha: 0.1));
                  }
                  return GestureDetector(
                    onTap: widget.onOpen,
                    child: Image.file(File(p), fit: BoxFit.cover, width: double.infinity),
                  );
                },
              ),
              if (paths.length > 1)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(99)),
                    child: Text(
                      '${_currentImageIndex + 1}/${paths.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(paths.length, (i) {
                    final active = i == _currentImageIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: active ? 18 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tags(BuildContext context, ColorScheme scheme, Color accent) {
    if (widget.post.tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final t in widget.post.tags)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
              child: Text('#$t', style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 11.5)),
            ),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context, ColorScheme scheme, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
      child: Row(
        children: [
          _actionButton(
            icon: widget.post.liked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
            color: widget.post.liked ? AppColors.post : scheme.onSurfaceVariant,
            label: _formatCount(widget.post.likes),
            tooltip: tr(context, 'লাইক', 'Like'),
            onTap: widget.onLike,
          ),
          _actionButton(
            icon: Icons.mode_comment_outlined,
            color: scheme.onSurfaceVariant,
            label: _formatCount(widget.post.comments),
            tooltip: tr(context, 'মন্তব্য', 'Comment'),
            onTap: () {
              _ensureView();
              widget.onOpen();
            },
          ),
          _actionButton(
            icon: Icons.share_outlined,
            color: scheme.onSurfaceVariant,
            label: tr(context, 'শেয়ার', 'Share'),
            tooltip: tr(context, 'শেয়ার', 'Share'),
            onTap: () {
              _ensureView();
              widget.onShare();
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Icon(Icons.visibility_outlined, size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  _formatCount(widget.post.impressions),
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String label,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12.5)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCount(int n) {
    if (n < 1000) return n.toString();
    if (n < 1000000) return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K';
    return '${(n / 1000000).toStringAsFixed(1)}M';
  }

  String _relativeDate(BuildContext context, DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return tr(context, 'এখনই', 'just now');
    if (diff.inMinutes < 60) return tr(context, '${diff.inMinutes} মিনিট আগে', '${diff.inMinutes} min ago');
    if (diff.inHours < 24) return tr(context, '${diff.inHours} ঘণ্টা আগে', '${diff.inHours} h ago');
    if (diff.inDays < 7) return tr(context, '${diff.inDays} দিন আগে', '${diff.inDays} d ago');
    return DateFormat('d MMM').format(dt);
  }
}
