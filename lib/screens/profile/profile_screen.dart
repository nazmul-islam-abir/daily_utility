import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/bd_cities.dart';
import '../../services/image_storage_service.dart';
import '../../services/locale_service.dart';
import '../../services/location_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../settings/settings_screen.dart';

/// User-editable profile: avatar, display name, email (read-only),
/// bio, home city (auto-detect via GPS or manual picker).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final s = SettingsService.instance;
    _nameCtrl = TextEditingController(text: s.userName);
    _bioCtrl = TextEditingController(text: s.bio ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title: Text(tr(ctx, 'ক্যামেরা থেকে তোলা', 'Take a photo')),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: Text(tr(ctx, 'গ্যালারি থেকে বেছে নিন', 'Choose from gallery')),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            if (SettingsService.instance.avatarPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: Text(tr(ctx, 'অবতার মুছুন', 'Remove avatar')),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (action == null || !mounted) return;

    String? newPath;
    if (action == 'camera') {
      newPath = await ImageStorageService.instance.captureFromCamera(subdir: 'avatars');
    } else if (action == 'gallery') {
      final paths = await ImageStorageService.instance.pickFromGallery(subdir: 'avatars');
      if (paths.isNotEmpty) newPath = paths.first;
    } else if (action == 'remove') {
      final old = SettingsService.instance.avatarPath;
      await ImageStorageService.instance.deleteIfExists(old);
      await SettingsService.instance.setAvatarPath(null);
      if (mounted) setState(() {});
      return;
    }

    if (newPath != null) {
      final old = SettingsService.instance.avatarPath;
      await SettingsService.instance.setAvatarPath(newPath);
      if (old != null && old != newPath) {
        await ImageStorageService.instance.deleteIfExists(old);
      }
      if (mounted) setState(() {});
    }
  }

  Future<void> _saveTextFields() async {
    await SettingsService.instance.setUserNameOverride(_nameCtrl.text.trim());
    await SettingsService.instance.setBio(_bioCtrl.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'প্রোফাইল সংরক্ষণ করা হয়েছে', 'Profile saved'))),
      );
    }
  }

  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180.0;
    final dLat = rad(lat2 - lat1);
    final dLng = rad(lng2 - lng1);
    final a = (1 - math.cos(dLat)) / 2 +
        math.cos(rad(lat1)) * math.cos(rad(lat2)) * (1 - math.cos(dLng)) / 2;
    return 2 * r * math.asin(math.sqrt(a));
  }

  Future<void> _detectCityViaGps() async {
    setState(() => _busy = true);
    final res = await LocationService.instance.getCurrent();
    if (!mounted) return;
    setState(() => _busy = false);
    final pos = res.position;
    if (pos != null) {
      String? bestKey;
      double bestDist = double.infinity;
      for (final entry in kBdCities.entries) {
        final d = _haversineKm(pos.latitude, pos.longitude, entry.value.lat, entry.value.lng);
        if (d < bestDist) {
          bestDist = d;
          bestKey = entry.key;
        }
      }
      if (bestKey != null) {
        final city = kBdCities[bestKey]!;
        await SettingsService.instance.setHomeCity(bn: city.bn, en: city.en, lat: city.lat, lng: city.lng);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr(context, 'হোম সিটি আপডেট: ${city.bn}', 'Home city updated: ${city.en}'))),
          );
          setState(() {});
        }
        return;
      }
    }
    final msg = res.failure != null
        ? LocationService.describe(context, res.failure!)
        : tr(context, 'কাছের শহর পাওয়া যায়নি', 'No nearby city found');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    if (res.failure == LocationFailure.permissionDeniedForever) {
      await LocationService.instance.openSettings();
    }
  }

  Future<void> _pickCityManually() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(tr(ctx, 'শহর নির্বাচন করুন', 'Pick a city'), style: Theme.of(ctx).textTheme.titleMedium),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: kBdCities.entries.map((e) {
                  return ListTile(
                    leading: const Icon(Icons.location_city_outlined, color: AppColors.primary),
                    title: Text(tr(ctx, e.value.bn, e.value.en)),
                    onTap: () => Navigator.pop(ctx, e.key),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    final city = kBdCities[chosen]!;
    await SettingsService.instance.setHomeCity(bn: city.bn, en: city.en, lat: city.lat, lng: city.lng);
    if (mounted) setState(() {});
  }

  Future<void> _resetProfile() async {
    final ok = await confirmDelete(
      context,
      title: tr(context, 'প্রোফাইল রিসেট করবেন?', 'Reset profile?'),
      message: tr(context, 'নাম, ইমেইল, বায়ো ও অবতার মুছে যাবে।', 'Name, email, bio and avatar will be cleared.'),
    );
    if (!ok || !mounted) return;
    await SettingsService.instance.clearSignedInAccount();
    await SettingsService.instance.setUserNameOverride(null);
    await SettingsService.instance.setBio(null);
    final oldAvatar = SettingsService.instance.avatarPath;
    await SettingsService.instance.setAvatarPath(null);
    if (oldAvatar != null) {
      await ImageStorageService.instance.deleteIfExists(oldAvatar);
    }
    _nameCtrl.clear();
    _bioCtrl.clear();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'প্রোফাইল রিসেট করা হয়েছে', 'Profile reset'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleService.instance.notifier,
      builder: (context, locale, _) {
        return ValueListenableBuilder<int>(
          valueListenable: SettingsService.instance.revision,
          builder: (context, _, __) {
            final s = SettingsService.instance;
            final avatar = s.avatarPath;
            final cityBn = s.homeCityBn;
            final cityEn = s.homeCityEn;
            final email = s.signedInEmail;

            return Scaffold(
              appBar: AppBar(
                title: Text(tr(context, 'প্রোফাইল', 'Profile')),
                actions: [
                  TextButton.icon(
                    onPressed: _saveTextFields,
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: Text(tr(context, 'সংরক্ষণ', 'Save')),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickAvatar,
                          child: Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppColors.primary, Color(0xFF6366F1)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.32),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: avatar != null && File(avatar).existsSync()
                                  ? Image.file(File(avatar), fit: BoxFit.cover, width: 112, height: 112)
                                  : Center(
                                      child: Text(
                                        s.userName.isNotEmpty ? s.userName.characters.first.toUpperCase() : 'U',
                                        style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _pickAvatar,
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: Text(tr(context, 'অবতার পরিবর্তন', 'Change avatar')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  _SectionHeaderLabel(tr(context, 'পরিচয়', 'Identity')),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _nameCtrl,
                            decoration: InputDecoration(
                              labelText: tr(context, 'প্রদর্শন নাম', 'Display name'),
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (email != null && email.isNotEmpty)
                            InputDecorator(
                              decoration: InputDecoration(
                                labelText: tr(context, 'ইমেইল', 'Email'),
                                prefixIcon: const Icon(Icons.alternate_email),
                              ),
                              child: Text(email, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            )
                          else
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.info_outline, color: AppColors.primary),
                              title: Text(
                                tr(context, 'ইমেইল যোগ করা হয়নি', 'No email linked'),
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(tr(context, 'সেটিংস থেকে যোগ করতে পারেন।', 'You can link one from Settings.')),
                            ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _bioCtrl,
                            maxLines: 3,
                            minLines: 2,
                            decoration: InputDecoration(
                              labelText: tr(context, 'বায়ো (ঐচ্ছিক)', 'Bio (optional)'),
                              hintText: tr(context, 'নিজের সম্পর্কে কিছু লিখুন…', 'Tell us a bit about yourself…'),
                              prefixIcon: const Icon(Icons.notes_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _SectionHeaderLabel(tr(context, 'হোম সিটি', 'Home city')),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_city, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  cityBn != null && cityEn != null
                                      ? tr(context, cityBn, cityEn)
                                      : tr(context, 'কোনো শহর নির্বাচিত হয়নি', 'No city selected'),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _busy ? null : _detectCityViaGps,
                                  icon: _busy
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.my_location, size: 18),
                                  label: Text(tr(context, 'GPS দিয়ে শনাক্ত', 'Auto-detect')),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickCityManually,
                                  icon: const Icon(Icons.list, size: 18),
                                  label: Text(tr(context, 'ম্যানুয়াল', 'Manual')),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _SectionHeaderLabel(tr(context, 'অ্যাপ', 'App')),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.settings_outlined, color: AppColors.primary),
                          title: Text(tr(context, 'সেটিংস', 'Settings'), style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(tr(context, 'থিম, ভাষা, ডেটা', 'Theme, language, data'), style: const TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                          title: Text(tr(context, 'প্রোফাইল রিসেট', 'Reset profile'), style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(tr(context, 'নাম, ইমেইল, বায়ো ও অবতার মুছবে', 'Clears name, email, bio and avatar'), style: const TextStyle(fontSize: 12)),
                          onTap: _resetProfile,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SectionHeaderLabel extends StatelessWidget {
  final String label;
  const _SectionHeaderLabel(this.label);
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: scheme.onSurfaceVariant, letterSpacing: 1.0),
      ),
    );
  }
}
