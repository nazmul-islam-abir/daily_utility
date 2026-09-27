import 'package:flutter/material.dart';

/// Supported habit icon palette.
///
/// Kept as a `const` list of `IconData` values so the Flutter AOT compiler
/// can tree-shake the MaterialIcons font and embed only the glyphs the app
/// actually uses. Never construct `IconData` from a runtime int — that
/// defeats tree-shaking and produces the "non-constant invocations of
/// IconData" build error.
const List<IconData> kHabitIconChoices = <IconData>[
  Icons.spa_outlined,
  Icons.self_improvement,
  Icons.local_drink_outlined,
  Icons.directions_run,
  Icons.book_outlined,
  Icons.bedtime_outlined,
  Icons.fitness_center,
  Icons.brush_outlined,
  Icons.music_note_outlined,
  Icons.savings_outlined,
  Icons.restaurant_outlined,
  Icons.code,
  Icons.headphones,
  Icons.directions_bike,
  Icons.pool,
];

/// Map of `codePoint` → const `IconData` for the supported palette.
///
/// Built lazily from [kHabitIconChoices] so the values can never drift out
/// of sync. An unknown code point (e.g. a legacy saved habit whose icon
/// was removed from the palette) falls back to [Icons.spa_outlined].
final Map<int, IconData> _kHabitIconByCodePoint = <int, IconData>{
  for (final ic in kHabitIconChoices) ic.codePoint: ic,
};

/// Resolve a persisted `iconCodePoint` back to its const `IconData`.
///
/// Returns [Icons.spa_outlined] if the code point isn't in the current
/// palette (which is safe — it's always present in [kHabitIconChoices]).
IconData habitIconFromCode(int cp) =>
    _kHabitIconByCodePoint[cp] ?? Icons.spa_outlined;
