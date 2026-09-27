import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/locale_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../home/main_shell.dart';
import 'onboarding_screen.dart';

/// Polished launch screen shown while the OS warm-starts the app and Flutter
/// paints its first frame. Decides whether to route into onboarding (first
/// launch) or straight into [MainShell].
///
/// Design direction: minimal, elegant, adaptive. The whole screen is a
/// quiet stage for the wordmark — subtle brand glow, a thin accent rule
/// and the tagline. Adapts to light / dark via the live ColorScheme.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _fade;
  late final Animation<double> _ruleGrow;
  late final Animation<double> _wordmarkRise;

  @override
  void initState() {
    super.initState();
    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _fade = CurvedAnimation(parent: _introCtrl, curve: Curves.easeOut);
    _ruleGrow = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _introCtrl,
        curve: const Interval(0.25, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _wordmarkRise = Tween<double>(begin: 18, end: 0).animate(
      CurvedAnimation(
        parent: _introCtrl,
        curve: const Interval(0.05, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _introCtrl.forward();
    Future.delayed(const Duration(milliseconds: 1900), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final onboardingDone = SettingsService.instance.onboardingComplete;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) =>
            onboardingDone ? const MainShell() : const OnboardingScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    // Fall back to the user-chosen theme if the system value is unreliable
    // (e.g. during warm-start before the MaterialApp has built).
    final isDark = brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    // Background palette — adaptive but anchored on the brand.
    final bgTop = isDark ? const Color(0xFF0B0E1A) : const Color(0xFFF6F7FB);
    final bgBottom =
        isDark ? const Color(0xFF15171C) : const Color(0xFFFFFFFF);
    final glowColor = AppColors.primary.withValues(alpha: isDark ? 0.32 : 0.14);

    final wordmarkColor = isDark ? const Color(0xFFF6F7FB) : const Color(0xFF111319);
    final taglineColor =
        isDark ? const Color(0xFFB8BCCB) : const Color(0xFF5C6072);
    final footerColor =
        isDark ? const Color(0xFF7B8094) : const Color(0xFF8A8E96);
    final ruleColor =
        isDark ? AppColors.primary.withValues(alpha: 0.7) : AppColors.primary;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: bgBottom,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        // Letting the gradient fill the whole Scaffold (instead of using
        // scaffoldBackgroundColor) keeps it edge-to-edge behind the
        // system navigation bar.
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Adaptive gradient background.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [bgTop, bgBottom],
                ),
              ),
            ),
            // Subtle brand glow that breathes — two soft blurred orbs.
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, _) {
                    final t = Curves.easeInOut.transform(_pulseCtrl.value);
                    return CustomPaint(
                      painter: _GlowPainter(
                        glowColor: glowColor,
                        pulse: t,
                        seed: 17,
                      ),
                    );
                  },
                ),
              ),
            ),
            // Wordmark + tagline + footer.
            SafeArea(
              child: FadeTransition(
                opacity: _fade,
                child: Column(
                  children: [
                    const Spacer(flex: 5),
                    // Tiny mark above the wordmark for character.
                    _OverlineMark(
                      color: ruleColor,
                      fade: _fade,
                    ),
                    const SizedBox(height: 22),
                    // Main wordmark.
                    AnimatedBuilder(
                      animation: _introCtrl,
                      builder: (context, _) {
                        return Opacity(
                          opacity: _fade.value,
                          child: Transform.translate(
                            offset: Offset(0, _wordmarkRise.value),
                            child: _Wordmark(
                              color: wordmarkColor,
                              scheme: scheme,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    // Thin animated accent rule.
                    AnimatedBuilder(
                      animation: _introCtrl,
                      builder: (context, _) {
                        return SizedBox(
                          width: 96 * _ruleGrow.value,
                          height: 2,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  ruleColor.withValues(alpha: 0),
                                  ruleColor,
                                  ruleColor.withValues(alpha: 0),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    // Tagline.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        tr(
                          context,
                          'আপনার দৈনন্দিন সবকিছু এক জায়গায়',
                          'Everything for your day, in one place',
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: taglineColor,
                          fontSize: 15,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    const Spacer(flex: 6),
                    // Loading dots.
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, _) {
                        return _LoadingDots(
                          color: scheme.primary,
                          phase: _pulseCtrl.value,
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    // Footer tagline.
                    Text(
                      tr(
                        context,
                        'হালকা • দ্রুত • সম্পূর্ণ অফলাইন',
                        'Lightweight • Fast • Fully offline',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: footerColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tiny decorative line above the wordmark — gives the wordmark a "title"
/// to belong to. Fades in slightly delayed relative to the wordmark.
class _OverlineMark extends StatelessWidget {
  final Color color;
  final Animation<double> fade;
  const _OverlineMark({required this.color, required this.fade});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: fade, curve: const Interval(0.35, 0.85)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 18, height: 1, color: color.withValues(alpha: 0.4)),
          const SizedBox(width: 8),
          Text(
            'U T I L I T Y H U B',
            style: TextStyle(
              color: color.withValues(alpha: 0.75),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 4.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 18, height: 1, color: color.withValues(alpha: 0.4)),
        ],
      ),
    );
  }
}

/// The headline wordmark — large, bold, with a subtle brand-coloured
/// underline accent. Two-line layout gives it presence without needing
/// a big illustration.
class _Wordmark extends StatelessWidget {
  final Color color;
  final ColorScheme scheme;
  const _Wordmark({required this.color, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // "Daily" in a softer weight, then "UTILITY" huge.
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Daily',
                style: TextStyle(
                  color: color.withValues(alpha: 0.78),
                  fontSize: 30,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.5,
                  height: 1.0,
                ),
              ),
              const WidgetSpan(child: SizedBox(width: 8)),
              TextSpan(
                text: 'Utility',
                style: TextStyle(
                  color: color,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Tagline pill under the wordmark.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'all-in-one • offline-first',
            style: TextStyle(
              color: scheme.primary,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }
}

/// Three small dots that pulse in sequence while the splash is on screen.
class _LoadingDots extends StatelessWidget {
  final Color color;
  final double phase;
  const _LoadingDots({required this.color, required this.phase});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(3, (i) {
          // Phase offset per dot.
          final p = (phase + i / 3) % 1.0;
          final size = 5 + 4 * Curves.easeInOut.transform(p);
          final opacity = 0.35 + 0.65 * Curves.easeInOut.transform(p);
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: opacity.clamp(0.0, 1.0)),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}

/// Paints two soft, blurred brand-glow orbs that slowly breathe.
/// Positions are derived deterministically from [seed] so the layout is
/// stable across rebuilds.
class _GlowPainter extends CustomPainter {
  final Color glowColor;
  final double pulse;
  final int seed;
  _GlowPainter({required this.glowColor, required this.pulse, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    // Two anchors placed at pleasing thirds.
    final centres = [
      Offset(size.width * (0.18 + rnd.nextDouble() * 0.04),
          size.height * (0.22 + rnd.nextDouble() * 0.04)),
      Offset(size.width * (0.82 - rnd.nextDouble() * 0.04),
          size.height * (0.78 - rnd.nextDouble() * 0.04)),
    ];
    for (final c in centres) {
      final radius = (size.shortestSide * 0.55) *
          (0.85 + 0.15 * Curves.easeInOut.transform(pulse));
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            glowColor,
            glowColor.withValues(alpha: 0),
          ],
          stops: const [0, 1],
        ).createShader(Rect.fromCircle(center: c, radius: radius));
      canvas.drawCircle(c, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlowPainter old) =>
      old.pulse != pulse || old.glowColor != glowColor;
}
