import 'package:flutter/foundation.dart';

/// Global "data version" notifier. Every time the underlying Hive boxes are
/// replaced (e.g. after a restore from a backup file, or a "clear all data"
/// action), this counter is bumped so that any screen watching it can
/// rebuild itself and re-read fresh values from Hive.
class DataRefreshService {
  DataRefreshService._();
  static final DataRefreshService instance = DataRefreshService._();

  final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  /// Bump the version. Call this after operations that wholesale replace
  /// the contents of one or more Hive boxes (restore, clear, etc.) to
  /// guarantee listeners refresh.
  void bump() {
    notifier.value = notifier.value + 1;
  }
}