import 'package:flutter/material.dart';

import '../../services/locale_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../home/main_shell.dart';

/// 3-slide first-launch tour shown after the splash. Last slide captures a
/// user name and writes `onboarding_complete = true` before routing into
/// the main app shell.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _nameCtrl = TextEditingController();
  int _page = 0;

  static const _slides = <_OnboardSlide>[
    _OnboardSlide(
      icon: Icons.dashboard_rounded,
      gradient: [Color(0xFF3D5AFE), Color(0xFF5046E5)],
      titleBn: 'আপনার সব টুল এক জায়গায়',
      titleEn: 'Every tool you need, one tap away',
      bodyBn: 'কাজ, নোট, ফাইন্যান্স, অভ্যাস, নামাজের সময় — সব এই একটি অ্যাপে।',
      bodyEn: 'Tasks, notes, finance, habits, prayer times — everything is here.',
    ),
    _OnboardSlide(
      icon: Icons.cloud_off_rounded,
      gradient: [Color(0xFF14B8A6), Color(0xFF0EA5E9)],
      titleBn: 'সম্পূর্ণ অফলাইন কাজ করে',
      titleEn: 'Fully offline, always ready',
      bodyBn: 'ইন্টারনেট ছাড়াই সব ডেটা সংরক্ষিত থাকে। চাইলে Google Drive-এ ব্যাকআপ নিতে পারেন।',
      bodyEn: 'Everything works without internet. Back up to your own Google Drive when you want.',
    ),
    _OnboardSlide(
      icon: Icons.lock_outline,
      gradient: [Color(0xFF7C3AED), Color(0xFFEC4899)],
      titleBn: 'আপনার ডেটা শুধু আপনার',
      titleEn: 'Your data stays yours',
      bodyBn: 'নোট, পাসওয়ার্ড ও লেনদেন শুধু আপনার ফোনে থাকে। কোনো সার্ভারে যায় না।',
      bodyEn: 'Notes, passwords and transactions stay only on your device. Nothing leaves it.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int p) => setState(() => _page = p);

  Future<void> _next() async {
    if (_page < _slides.length - 1) {
      await _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
      return;
    }
    final name = _nameCtrl.text.trim();
    if (name.isNotEmpty) {
      await SettingsService.instance.setUserNameOverride(name);
    }
    await SettingsService.instance.setOnboardingComplete(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _skip() async {
    await SettingsService.instance.setOnboardingComplete(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _slides.length - 1;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: skip button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
              child: Row(
                children: [
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: AppAnimations.fast,
                    child: isLast
                        ? const SizedBox(width: 56, height: 36)
                        : TextButton(
                            key: const ValueKey('skip'),
                            onPressed: _skip,
                            child: Text(tr(context, 'এড়িয়ে যান', 'Skip'), style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (context, i) {
                  final s = _slides[i];
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(28, 8, 28, 8),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Spacer(),
                                Center(
                                  child: AnimatedContainer(
                                    duration: AppAnimations.medium,
                                    curve: AppAnimations.curve,
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: s.gradient),
                                      borderRadius: BorderRadius.circular(34),
                                      boxShadow: [
                                        BoxShadow(color: s.gradient.first.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12)),
                                      ],
                                    ),
                                    child: Icon(s.icon, size: 64, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Text(
                                  tr(context, s.titleBn, s.titleEn),
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.text, letterSpacing: -0.5, height: 1.25),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  tr(context, s.bodyBn, s.bodyEn),
                                  style: const TextStyle(fontSize: 14.5, color: AppColors.textMuted, height: 1.5),
                                ),
                                if (isLast) ...[
                                  const SizedBox(height: 22),
                                  Text(tr(context, 'আপনার নাম (ঐচ্ছিক)', 'Your name (optional)'), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _nameCtrl,
                                    textCapitalization: TextCapitalization.words,
                                    decoration: InputDecoration(
                                      hintText: tr(context, 'যেমন: নাজমুল', 'e.g. Nazmul'),
                                      filled: true,
                                      fillColor: AppColors.surface,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg), borderSide: BorderSide.none),
                                      prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                                    ),
                                  ),
                                ],
                                const Spacer(),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // Bottom: dots + CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: AppAnimations.medium,
                        curve: AppAnimations.curve,
                        width: active ? 28 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : AppColors.line,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLast ? tr(context, 'শুরু করুন', 'Get started') : tr(context, 'পরবর্তী', 'Next'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                        ],
                      ),
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

class _OnboardSlide {
  final IconData icon;
  final List<Color> gradient;
  final String titleBn, titleEn, bodyBn, bodyEn;
  const _OnboardSlide({required this.icon, required this.gradient, required this.titleBn, required this.titleEn, required this.bodyBn, required this.bodyEn});
}
