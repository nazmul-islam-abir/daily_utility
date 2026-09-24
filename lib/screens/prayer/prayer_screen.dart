import 'dart:math' as math;
import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:intl/intl.dart';

import '../../data/bd_cities.dart';
import '../../services/hive_service.dart';
import '../../services/locale_service.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

const Map<String, PrayerName> kPrayerNames = {
  'fajr': PrayerName('ফজর', 'Fajr'),
  'sunrise': PrayerName('সূর্যোদয়', 'Sunrise'),
  'dhuhr': PrayerName('যোহর', 'Dhuhr'),
  'asr': PrayerName('আসর', 'Asr'),
  'maghrib': PrayerName('মাগরিব', 'Maghrib'),
  'isha': PrayerName('এশা', 'Isha'),
};

class PrayerName {
  final String bn;
  final String en;
  const PrayerName(this.bn, this.en);
}

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  double _lat = 23.8103;
  double _lng = 90.4125;
  String _locationLabelBn = 'ঢাকা';
  String _locationLabelEn = 'Dhaka';
  PrayerTimes? _times;
  double? _qiblaDegrees;
  int? _reminderMinutes;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
    _recompute();
  }

  void _loadSavedLocation() {
    final settings = HiveService.settings;
    final lat = settings.get('prayer_lat') as double?;
    final lng = settings.get('prayer_lng') as double?;
    final labelBn = settings.get('prayer_location_label_bn') as String?;
    final labelEn = settings.get('prayer_location_label_en') as String?;
    final reminder = settings.get('prayer_reminder_minutes') as int?;
    if (lat != null && lng != null) {
      _lat = lat;
      _lng = lng;
      _locationLabelBn = labelBn ?? 'সংরক্ষিত অবস্থান';
      _locationLabelEn = labelEn ?? 'Saved location';
    }
    _reminderMinutes = reminder;
  }

  void _recompute() {
    final coordinates = Coordinates(_lat, _lng);
    final params = CalculationMethodParameters.karachi()..madhab = Madhab.hanafi;
    setState(() {
      _times = PrayerTimes(
        coordinates: coordinates,
        date: DateTime.now(),
        calculationParameters: params,
        precision: false,
      );
      _qiblaDegrees = Qibla.qibla(coordinates);
    });
    if (_reminderMinutes != null) _scheduleReminders(_reminderMinutes!);
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    final res = await LocationService.instance.getCurrent();
    if (!mounted) {
      setState(() => _locating = false);
      return;
    }
    if (res.position != null) {
      _lat = res.position!.latitude;
      _lng = res.position!.longitude;
      _locationLabelBn = 'বর্তমান জিপিএস অবস্থান';
      _locationLabelEn = 'Current GPS location';

      await HiveService.settings.put('prayer_lat', _lat);
      await HiveService.settings.put('prayer_lng', _lng);
      await HiveService.settings.put('prayer_location_label_bn', _locationLabelBn);
      await HiveService.settings.put('prayer_location_label_en', _locationLabelEn);
      _recompute();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(tr(context, 'অবস্থান সফলভাবে আপডেট করা হয়েছে', 'Location updated successfully')),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else if (res.failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocationService.describe(context, res.failure!)),
        ),
      );
      if (res.failure == LocationFailure.permissionDeniedForever) {
        await LocationService.instance.openSettings();
      }
    }
    if (mounted) setState(() => _locating = false);
  }

  Future<void> _pickCity() async {
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
              child: Text(
                tr(ctx, 'শহর নির্বাচন করুন', 'Select a city'),
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: kBdCities.entries.map((e) {
                  final isSelected = _locationLabelBn == e.value.bn;
                  return ListTile(
                    selected: isSelected,
                    leading: Icon(Icons.location_city, color: isSelected ? AppColors.prayer : null),
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
    if (chosen == null) return;
    final def = kBdCities[chosen]!;
    setState(() {
      _lat = def.lat;
      _lng = def.lng;
      _locationLabelBn = def.bn;
      _locationLabelEn = def.en;
    });
    await HiveService.settings.put('prayer_lat', _lat);
    await HiveService.settings.put('prayer_lng', _lng);
    await HiveService.settings.put('prayer_city_key', chosen);
    await HiveService.settings.put('prayer_location_label_bn', def.bn);
    await HiveService.settings.put('prayer_location_label_en', def.en);
    _recompute();
  }

  Future<void> _openReminderSheet() async {
    int? selected = _reminderMinutes;
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr(ctx, 'নামাজের রিমাইন্ডার', 'Prayer reminder'), style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                tr(ctx, 'আজকের বাকি প্রতিটি ওয়াক্তের আগে জানিয়ে দেবে (ঐচ্ছিক)।', 'Notifies you before each remaining prayer today (optional).'),
                style: TextStyle(fontSize: 13, color: Theme.of(ctx).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              ReminderPicker(value: selected, onChanged: (v) => setSheetState(() => selected = v)),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await HiveService.settings.put('prayer_reminder_minutes', selected);
                    setState(() => _reminderMinutes = selected);
                    if (selected != null) {
                      await _scheduleReminders(selected!);
                    } else {
                      await _cancelReminders();
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(tr(ctx, 'সংরক্ষণ করুন', 'Save')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scheduleReminders(int minutes) async {
    final t = _times;
    if (t == null) return;
    final entries = <String, DateTime>{
      'fajr': t.fajr,
      'dhuhr': t.dhuhr,
      'asr': t.asr,
      'maghrib': t.maghrib,
      'isha': t.isha,
    };
    final bn = LocaleService.isBangla;
    for (final e in entries.entries) {
      final time = e.value.toLocal();
      final name = kPrayerNames[e.key]!;
      final displayName = bn ? name.bn : name.en;
      await NotificationService.scheduleReminder(
        idKey: 'prayer_${e.key}',
        title: bn ? '$displayName নামাজ' : '$displayName prayer',
        body: bn ? '${DateFormat('hh:mm a').format(time)}-এ $displayName-এর সময় হবে' : '$displayName at ${DateFormat('hh:mm a').format(time)}',
        fireAt: time.subtract(Duration(minutes: minutes)),
      );
    }
  }

  Future<void> _cancelReminders() async {
    for (final key in kPrayerNames.keys.where((k) => k != 'sunrise')) {
      await NotificationService.cancel(NotificationService.idFromString('prayer_$key'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = _times;
    final now = DateTime.now();
    final rows = t == null
        ? <_PrayerRow>[]
        : [
            _PrayerRow('fajr', t.fajr.toLocal()),
            _PrayerRow('sunrise', t.sunrise.toLocal()),
            _PrayerRow('dhuhr', t.dhuhr.toLocal()),
            _PrayerRow('asr', t.asr.toLocal()),
            _PrayerRow('maghrib', t.maghrib.toLocal()),
            _PrayerRow('isha', t.isha.toLocal()),
          ];
    _PrayerRow? next;
    for (final r in rows) {
      if (r.time.isAfter(now)) {
        next = r;
        break;
      }
    }

    final locationLabel = tr(context, _locationLabelBn, _locationLabelEn);
    final nextName = next == null ? null : tr(context, kPrayerNames[next.key]!.bn, kPrayerNames[next.key]!.en);
    final coordStr = '${_lat.toStringAsFixed(4)}° N, ${_lng.toStringAsFixed(4)}° E';

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'নামাজ ও কিবলা', 'Prayer & Qibla')),
        actions: [
          IconButton(
            icon: Icon(_reminderMinutes != null ? Icons.notifications_active : Icons.notifications_outlined),
            color: _reminderMinutes != null ? AppColors.prayer : null,
            tooltip: tr(context, 'রিমাইন্ডার', 'Reminder'),
            onPressed: _openReminderSheet,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // Top Hero Card with Prayer Time & GPS Coordinates
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.prayer, Color(0xFF047857)],
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.prayer.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$locationLabel ($coordStr)',
                          style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(DateFormat('d MMMM y').format(now), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (next != null) ...[
                    Text(
                      tr(context, 'পরবর্তী: $nextName', 'Next: $nextName'),
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('hh:mm a').format(next.time),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ] else
                    Text(
                      tr(context, 'আজকের সব ওয়াক্ত শেষ', 'All prayer times for today are over'),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Location Controls (GPS Auto Detect + Manual City Selection)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _locating ? null : _useCurrentLocation,
                    icon: _locating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location, size: 18, color: AppColors.prayer),
                    label: Text(
                      tr(context, 'GPS অবস্থান', 'GPS Detect'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickCity,
                    icon: const Icon(Icons.location_city, size: 18, color: AppColors.prayer),
                    label: Text(
                      tr(context, 'শহর নির্বাচন', 'Pick City'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Live Qibla Compass Section
            if (_qiblaDegrees != null) ...[
              _SectionHeaderLabel(tr(context, 'লাইভ কিবলা কম্পাস', 'Live Qibla Compass')),
              _LiveQiblaCompass(
                qiblaDegrees: _qiblaDegrees!,
                lat: _lat,
                lng: _lng,
              ),
              const SizedBox(height: 16),
            ],

            // Prayer Times Schedule Card
            _SectionHeaderLabel(tr(context, 'আজকের নামাজের সময়সূচি', "Today's Prayer Schedule")),
            Card(
              child: Column(
                children: rows.map((r) {
                  final passed = r.time.isBefore(now);
                  final isNext = next?.key == r.key;
                  final name = tr(context, kPrayerNames[r.key]!.bn, kPrayerNames[r.key]!.en);
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isNext ? AppColors.prayer.withValues(alpha: 0.15) : scheme.surfaceContainerHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isNext ? Icons.access_time_filled : (passed ? Icons.check_circle_outline : Icons.access_time),
                        size: 18,
                        color: isNext ? AppColors.prayer : (passed ? scheme.onSurfaceVariant.withValues(alpha: 0.5) : scheme.onSurface),
                      ),
                    ),
                    title: Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isNext ? FontWeight.w900 : FontWeight.w700,
                        color: isNext ? AppColors.prayer : scheme.onSurface,
                      ),
                    ),
                    trailing: Text(
                      DateFormat('hh:mm a').format(r.time),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: isNext ? FontWeight.w900 : FontWeight.w700,
                        color: isNext ? AppColors.prayer : (passed ? scheme.onSurfaceVariant.withValues(alpha: 0.6) : scheme.onSurface),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Tasbih Counter Card
            _SectionHeaderLabel(tr(context, 'তাসবিহ কাউন্টার', 'Tasbih Counter')),
            const _TasbihCounter(),
          ],
        ),
      ),
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
        style: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

/// Real-time Interactive Qibla Compass pointing towards Mecca (21.4225° N, 39.8262° E).
/// Rotates dynamically using device magnetometer hardware sensor.
class _LiveQiblaCompass extends StatelessWidget {
  final double qiblaDegrees;
  final double lat;
  final double lng;

  const _LiveQiblaCompass({
    required this.qiblaDegrees,
    required this.lat,
    required this.lng,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(context, tr(context, 'কম্পাস সেন্সরে সমস্যা', 'Compass sensor error'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final heading = snapshot.data?.heading;

        // If device has no hardware magnetometer/compass sensor
        if (heading == null) {
          return _buildNoSensorCard(context);
        }

        // Heading normalized 0..360
        final headingNormalized = (heading < 0 ? heading + 360 : heading) % 360;

        // Difference between phone pointing direction and Qibla bearing
        double diff = (qiblaDegrees - headingNormalized) % 360;
        if (diff > 180) diff -= 360;
        if (diff < -180) diff += 360;

        final isAligned = diff.abs() <= 5.0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Alignment Badge Header
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAligned ? AppColors.success.withValues(alpha: 0.15) : scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAligned ? Icons.check_circle : Icons.explore,
                        size: 16,
                        color: isAligned ? AppColors.success : scheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isAligned
                            ? tr(context, 'কিবলামুখী (সঠিক দিক)', 'Aligned with Qibla')
                            : tr(context, 'কিবলার দিক চিহ্নিত করুন', 'Align with Qibla'),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: isAligned ? AppColors.success : scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Rotating Compass Dial
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Compass Background Dial — Rotates opposite to device heading
                      Transform.rotate(
                        angle: -headingNormalized * (math.pi / 180),
                        child: Container(
                          width: 210,
                          height: 210,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.surfaceContainerLow,
                            boxShadow: [
                              BoxShadow(
                                color: scheme.shadow.withValues(alpha: 0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Cardinal Points
                              const Positioned(top: 8, child: Text('N', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.danger))),
                              const Positioned(bottom: 8, child: Text('S', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800))),
                              const Positioned(right: 12, child: Text('E', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800))),
                              const Positioned(left: 12, child: Text('W', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800))),

                              // Qibla Target Point on Compass Ring
                              Transform.rotate(
                                angle: qiblaDegrees * (math.pi / 180),
                                child: const Positioned(
                                  top: 14,
                                  child: Icon(Icons.location_on, color: AppColors.prayer, size: 22),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Qibla Pointer Needle — Points dynamically to Qibla
                      Transform.rotate(
                        angle: diff * (math.pi / 180),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Kaaba Indicator / Pointer Arrow
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isAligned ? AppColors.success : AppColors.prayer,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isAligned ? AppColors.success : AppColors.prayer).withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Text('🕋', style: TextStyle(fontSize: 16)),
                            ),
                            Container(
                              width: 4,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isAligned ? AppColors.success : AppColors.prayer,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: scheme.onSurfaceVariant,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Angles Information
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _angleStat(
                      context,
                      label: tr(context, 'কিবলা কোণ', 'Qibla Bearing'),
                      value: '${qiblaDegrees.toStringAsFixed(1)}°',
                      color: AppColors.prayer,
                    ),
                    Container(width: 1, height: 28, color: scheme.outlineVariant),
                    _angleStat(
                      context,
                      label: tr(context, 'হেডিং (উত্তর)', 'Heading'),
                      value: '${headingNormalized.toStringAsFixed(0)}°',
                      color: scheme.onSurface,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _angleStat(BuildContext context, {required String label, required String value, required Color color}) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildNoSensorCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.explore_off_outlined, color: AppColors.warning, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, 'কিবলার কোণ: ${qiblaDegrees.toStringAsFixed(1)}° (উত্তর থেকে)', 'Qibla angle: ${qiblaDegrees.toStringAsFixed(1)}° from North'),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr(context, 'এই ডিভাইসে লাইভ ম্যাগনেটোমিটার সেন্সর পাওয়া যায়নি।', 'Hardware compass sensor not detected on this device.'),
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message, style: TextStyle(color: scheme.error)),
      ),
    );
  }
}

class _PrayerRow {
  final String key;
  final DateTime time;
  _PrayerRow(this.key, this.time);
}

class _TasbihCounter extends StatefulWidget {
  const _TasbihCounter();
  @override
  State<_TasbihCounter> createState() => _TasbihCounterState();
}

class _TasbihCounterState extends State<_TasbihCounter> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    final box = HiveService.tasbih;
    final savedDate = box.get('date') as String?;
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (savedDate == todayKey) {
      _count = (box.get('count') as int?) ?? 0;
    } else {
      _count = 0;
      box.put('date', todayKey);
      box.put('count', 0);
    }
  }

  void _increment() {
    setState(() => _count++);
    HiveService.tasbih.put('count', _count);
    HiveService.tasbih.put('date', DateFormat('yyyy-MM-dd').format(DateTime.now()));
  }

  void _reset() {
    setState(() => _count = 0);
    HiveService.tasbih.put('count', 0);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('$_count', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.prayer)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.prayer,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(64, 56),
                    ),
                    onPressed: _increment,
                    child: Text(tr(context, 'গণনা করুন (+১)', 'Count (+1)'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(64, 56)),
                  onPressed: _reset,
                  child: Text(tr(context, 'রিসেট', 'Reset')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
