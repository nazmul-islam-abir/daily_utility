import 'package:flutter/material.dart';

import '../../services/contact_service.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';

/// Contact / support form. The user types a name, email, and description
/// of their issue; tapping Submit writes a new document to the
/// `contact_messages` Firestore collection. The admin reads submissions
/// from the Firebase console and replies by email directly.
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    // Make sure Firebase is initialised so the first submit doesn't pay
    // the cold-start cost. Failure here is silent — submit() retries.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ContactService.instance.init();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final scheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);

    final ok = await ContactService.instance.submit(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      message: _msgCtrl.text,
    );

    if (!mounted) return;
    if (ok) {
      setState(() => _submitted = true);
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: scheme.primaryContainer,
          content: Text(
            tr(
              context,
              'আপনার বার্তা পাঠানো হয়েছে — ধন্যবাদ!',
              'Your message has been sent — thank you!',
            ),
            style: TextStyle(color: scheme.onPrimaryContainer),
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: scheme.errorContainer,
          content: Text(
            tr(
              context,
              'বার্তা পাঠানো যায়নি — ইন্টারনেট সংযোগ পরীক্ষা করুন।',
              'Could not send message — check your internet connection.',
            ),
            style: TextStyle(color: scheme.onErrorContainer),
          ),
        ),
      );
    }
  }

  void _sendAnother() {
    setState(() {
      _submitted = false;
      _nameCtrl.clear();
      _emailCtrl.clear();
      _msgCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: scheme.surfaceContainerLow,
        title: Text(tr(context, 'যোগাযোগ', 'Contact us')),
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: ContactService.instance.submitting,
        builder: (context, busy, _) {
          if (_submitted) return _buildThanks(context, scheme: scheme);
          return _buildForm(context, scheme: scheme, busy: busy);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, {required ColorScheme scheme, required bool busy}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [scheme.surfaceContainerLow, scheme.surface],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _Header(scheme: scheme),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: tr(context, 'আপনার নাম', 'Your name'),
                  hintText: tr(context, 'যেমন: নাজমুল', 'e.g. Nazmul'),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return tr(context, 'নাম দরকার', 'Name is required');
                  }
                  if (v.trim().length < 2) {
                    return tr(context, 'নাম আরেকটু লম্বা হওয়া দরকার',
                        'Name is too short');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: tr(context, 'ইমেইল', 'Email'),
                  hintText: tr(context, 'যেমন: you@example.com', 'e.g. you@example.com'),
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return tr(context, 'ইমেইল দরকার', 'Email is required');
                  }
                  if (!ContactService.isValidEmail(v)) {
                    return tr(context, 'সঠিক ইমেইল দিন', 'Enter a valid email');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _msgCtrl,
                minLines: 5,
                maxLines: 10,
                maxLength: 2000,
                style: TextStyle(color: scheme.onSurface),
                decoration: InputDecoration(
                  labelText: tr(context, 'আপনার সমস্যা / পরামর্শ',
                      'Your issue / suggestion'),
                  hintText: tr(
                    context,
                    'যতটা সম্ভব বিস্তারিত লিখুন — কোন স্ক্রিনে সমস্যা হচ্ছে, কী করলে হয়, ইত্যাদি।',
                    'Please describe in as much detail as you can — which screen, what you did, what happened.',
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return tr(context, 'একটু লিখুন', 'Please write something');
                  }
                  if (v.trim().length < 10) {
                    return tr(context, 'আরেকটু বিস্তারিত লিখুন',
                        'Please add a bit more detail');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<String?>(
                valueListenable: ContactService.instance.lastError,
                builder: (context, err, _) {
                  if (err == null || err.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: _ErrorChip(error: err),
                  );
                },
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: busy ? null : _submit,
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  busy
                      ? tr(context, 'পাঠানো হচ্ছে...', 'Sending...')
                      : tr(context, 'বার্তা পাঠান', 'Send message'),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 54),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined, size: 18, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tr(
                          context,
                          'আপনার বার্তা সরাসরি ডেভেলপারের কাছে পৌঁছে যাবে। শুধুমাত্র সাপোর্টের উদ্দেশ্যে ব্যবহৃত হবে — তৃতীয় পক্ষের কাছে শেয়ার করা হবে না।',
                          'Your message goes directly to the developer. It will only be used for support — never shared with third parties.',
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThanks(BuildContext context, {required ColorScheme scheme}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Center(
            child: Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: AppColors.success, size: 52),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            tr(context, 'বার্তা পৌঁছে গেছে!', 'Message sent!'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(
              context,
              'আপনার বার্তা সফলভাবে পাঠানো হয়েছে। ডেভেলপার শীঘ্রই আপনার ইমেইলে উত্তর দেবেন।',
              'Your message was sent successfully. The developer will reply to your email soon.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 26),
          FilledButton.icon(
            onPressed: _sendAnother,
            icon: const Icon(Icons.edit_outlined),
            label: Text(
              tr(context, 'আরেকটি বার্তা পাঠান', 'Send another'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 52),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.check_rounded),
            label: Text(
              tr(context, 'ঠিক আছে', 'Done'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 52),
              side: BorderSide.none,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero block at the top of the form — sets the tone and tells the user
/// what to expect.
class _Header extends StatelessWidget {
  final ColorScheme scheme;
  const _Header({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.78)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.hero(AppColors.primary),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(context, 'আমরা শুনছি', 'We are listening'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tr(
                    context,
                    'বাগ রিপোর্ট, ফিচার অনুরোধ বা সাধারণ প্রশ্ন — লিখে পাঠান।',
                    'Bug reports, feature requests, or general questions — write to us.',
                  ),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline error chip — used for permission-denied / not-configured /
/// network errors so the user can see what went wrong before the snackbar
/// fades.
class _ErrorChip extends StatelessWidget {
  final String error;
  const _ErrorChip({required this.error});

  String _humanise(BuildContext context, String raw) {
    if (raw.contains('permission-denied') || raw.contains('PERMISSION_DENIED')) {
      return tr(
        context,
        'Firestore সিকিউরিটি রুলে মেসেজ পাঠানো বন্ধ। অ্যাডমিনকে জানান।',
        'Firestore rules block message creation. Please contact the admin.',
      );
    }
    if (raw.contains('unavailable') || raw.contains('UNAVAILABLE')) {
      return tr(
        context,
        'ইন্টারনেট সংযোগ নেই। কানেকশন চেক করে আবার চেষ্টা করুন।',
        'No internet connection. Check connection and try again.',
      );
    }
    if (raw.contains('NOT_CONFIGURED')) {
      return tr(
        context,
        'Firebase সংযুক্ত নয়। অ্যাপ পুনরায় চালু করুন।',
        'Firebase is not connected. Restart the app.',
      );
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 16, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _humanise(context, error),
              style: TextStyle(
                fontSize: 12,
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
