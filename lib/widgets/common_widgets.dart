import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/todo_item.dart';
import '../services/locale_service.dart';

/// The home-feed "video card" — a flat-coloured thumbnail block with an
/// icon, a bold title underneath, and a small grey meta line. Tapping it
/// opens the section.
class SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const SectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Icon(icon, size: 24, color: color),
                ),
                const Spacer(),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const EmptyState({super.key, required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: scheme.outline),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared "when should we remind you" picker — always shows a "No reminder"
/// option first since reminders are optional everywhere in this app.
class ReminderPicker extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  const ReminderPicker({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text(tr(context, 'রিমাইন্ডার নেই', 'No reminder')),
          selected: value == null,
          onSelected: (_) => onChanged(null),
        ),
        for (final m in kReminderOffsets)
          ChoiceChip(
            label: Text(reminderOffsetLabel(context, m)),
            selected: value == m,
            onSelected: (_) => onChanged(m),
          ),
      ],
    );
  }
}

class StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const StatPill({super.key, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// A titled, boxed container used to hold one self-contained mini-tool
/// (used throughout the calculator and date-tools screens so every
/// calculator shares the same look without needing its own route).
class ToolCard extends StatelessWidget {
  final String title;
  final Widget child;
  final String? note;
  const ToolCard({super.key, required this.title, required this.child, this.note});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
            if (note != null) ...[
              const SizedBox(height: 10),
              Text(note!, style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant, height: 1.3)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Big, prominent number result shown under a calculator's inputs.
class ResultText extends StatelessWidget {
  final String value;
  final Color color;
  const ResultText(this.value, {super.key, this.color = AppColors.calculator});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effective = color == AppColors.calculator ? scheme.primary : color;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: effective)),
    );
  }
}

Future<bool> confirmDelete(BuildContext context, {String? title, String? message}) async {
  final t = title ?? tr(context, 'মুছে ফেলবেন?', 'Delete?');
  final m = message ?? tr(context, 'এই তথ্যটি স্থায়ীভাবে মুছে যাবে।', 'This will be permanently deleted.');
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(t),
      content: Text(m),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr(ctx, 'বাতিল', 'Cancel'))),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(tr(ctx, 'মুছুন', 'Delete')),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Tinted rounded square with an icon — the "thumbnail block" pattern
/// from the UtilityHub designs. Used for home cards, vault credentials,
/// habits list, etc.
class GradientIconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double radius;
  final bool gradient;
  const GradientIconTile({super.key, required this.icon, required this.color, this.size = 44, this.radius = 12, this.gradient = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: gradient ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.cardGradient(color)) : null,
        color: gradient ? null : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Small uppercase section label — appears above grouped lists in the
/// UtilityHub designs ("BANKING", "GROCERIES", "TODAY", "UPCOMING FOCUS").
class MiniSectionLabel extends StatelessWidget {
  final String text;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  const MiniSectionLabel(this.text, {super.key, this.fontSize = 11.5, this.padding = const EdgeInsets.fromLTRB(2, 0, 2, 8)});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: scheme.onSurfaceVariant, letterSpacing: 0.8),
      ),
    );
  }
}

/// A small two-line stat card: tiny coloured icon tile + big value +
/// label below. Used inside hero cards.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;
  final bool emphasised;
  const StatCard({super.key, required this.label, required this.value, required this.color, this.icon, this.emphasised = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: emphasised ? color.withValues(alpha: 0.16) : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
          ],
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color.withValues(alpha: 0.9), letterSpacing: 0.6)),
        ],
      ),
    );
  }
}

/// Full-width hero card with a coloured gradient background. Used on the
/// home Welcome, Finance balance, and Vault Security Health.
class HeroCard extends StatelessWidget {
  final List<Color> gradient;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool darkForeground;
  const HeroCard({super.key, required this.gradient, required this.child, this.padding = const EdgeInsets.all(20), this.radius = AppRadius.xl, this.darkForeground = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: darkForeground ? Colors.white : AppColors.text),
        child: child,
      ),
    );
  }
}

/// InkWell wrapper that scales down slightly on press for tactile feedback.
class PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final double radius;
  final List<BoxShadow>? shadow;
  final Border? border;
  const PressableCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.color,
    this.radius = AppRadius.xl,
    this.shadow,
    this.border,
  });

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: AppAnimations.fast,
      curve: AppAnimations.curve,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Container(
          margin: widget.margin,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.color ?? scheme.surface,
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: widget.shadow,
            border: widget.border,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Horizontal scroll of pill chips. Selected chip uses the section colour.
class FilterChipsRow extends StatelessWidget {
  final List<String> items;
  final String? selected;
  final ValueChanged<String?> onSelect;
  final Color Function(String)? colorFor;
  final EdgeInsetsGeometry padding;
  const FilterChipsRow({super.key, required this.items, required this.selected, required this.onSelect, this.colorFor, this.padding = const EdgeInsets.symmetric(horizontal: 16)});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final label = items[i];
          final isSel = label == selected;
          return ChoiceChip(
            label: Text(label),
            selected: isSel,
            showCheckmark: false,
            onSelected: (_) => onSelect(isSel ? null : label),
            selectedColor: scheme.onSurface,
            backgroundColor: scheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            labelStyle: TextStyle(color: isSel ? scheme.surface : scheme.onSurface, fontWeight: FontWeight.w800, fontSize: 12.5),
          );
        },
      ),
    );
  }
}

/// Counts up to the given numeric value when first painted. Useful for
/// hero cards displaying balance, streak days, etc.
class AnimatedCounter extends StatelessWidget {
  final double value;
  final String prefix;
  final String suffix;
  final TextStyle? style;
  final int decimals;
  final Duration duration;
  const AnimatedCounter({super.key, required this.value, this.prefix = '', this.suffix = '', this.style, this.decimals = 0, this.duration = AppAnimations.counter});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: AppAnimations.curve,
      builder: (context, v, _) {
        final formatted = decimals == 0 ? v.toInt().toString() : v.toStringAsFixed(decimals);
        return Text('$prefix$formatted$suffix', style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
      },
    );
  }
}

/// A simple stagger fade-in. Wrap each child with [StaggeredFadeIn] to
/// fade and slide them up sequentially on first paint.
class StaggeredFadeIn extends StatefulWidget {
  final int index;
  final Duration delay;
  final Duration duration;
  final Widget child;
  const StaggeredFadeIn({super.key, required this.index, required this.child, this.delay = const Duration(milliseconds: 60), this.duration = const Duration(milliseconds: 380)});

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _ctrl, curve: AppAnimations.curve);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(_opacity);
    Future.delayed(widget.delay * widget.index, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: SlideTransition(position: _slide, child: widget.child));
  }
}

