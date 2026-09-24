# Daily Utility — Setup & What's Included

This is a `lib/`-only Flutter package right now — no `android/`, `ios/`, etc.
platform folders, because this sandbox has no Flutter SDK to generate them
safely. **You need to do one step before this runs:**

## 1. First-time setup

```bash
cd daily_utility
flutter create .          # generates android/, ios/, etc. — safe, does not touch lib/ or pubspec.yaml
flutter pub get
```

## 2. Add permissions

**`android/app/src/main/AndroidManifest.xml`** — add inside `<manifest>`, above `<application>`:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

**`ios/Runner/Info.plist`** — add:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Prayer times and Qibla direction need your location.</string>
```

## 3. Run

```bash
flutter analyze   # I don't have the Flutter SDK in this sandbox — please run this before trusting the build
flutter run
```

---

## What's implemented

- **Home** — YouTube-feed-style grid of section cards with live counts, tapping opens the section.
- **Todo** — priority, due date+time, recurring (daily/weekly/monthly — completing a recurring task logs it to history and rolls the live task to its next date), optional reminder (5/10/20/30/45/60 min before), completed history tab.
- **Notes** — text or checklist notes, pin-to-top, colour tags. Voice notes are modelled in the data layer but the recording UI isn't built (shows an honest "not available yet" state) — audio capture needs a mic plugin + platform permission wiring that's a separate chunk of work.
- **Finance** — income/expense, categories, balance, per-category spend breakdown.
- **Baki Khata** — people, running balance (receivable/payable), "gave"/"got" transaction log.
- **Loan** — principal/rate/instalment, payment history, remaining-balance progress bar, optional reminder for the next instalment.
- **Calculator** — organised into 5 categories (General, Education, Health, Finance, Bangladesh-specific) with ~20 working calculators: basic 4-function, percentage, discount, tip/bill-split, length & weight converters, GPA/CGPA, marks%, attendance, BMI, BMR, ideal weight, water intake, EMI, savings, simple interest, VAT, Bangladesh land unit converter (decimal/katha/bigha/acre), feet↔হাত, salary breakdown, and an illustrative electricity bill estimator. Health calculators carry an explicit "not medical advice" banner. This is a representative set, not literally every calculator named in the spec — the pattern (`ToolCard` + a small `StatefulWidget`) makes adding more a 20-line job.
- **Shopping List** — add with optional quantity, check off, clear-checked.
- **Date Tools** — age calculator, days-between-dates, event/birthday countdown, a real month calendar (Flutter's built-in `CalendarDatePicker`).
- **Reminders** — one aggregated, sorted view of every reminder set across Todo and Loan. (Medicine/bill/important-date reminders aren't a separate data model — create them as a Todo with recurrence; they'll show up here too.)
- **Prayer** — prayer times computed **fully offline** from latitude/longitude using `adhan_dart` (astronomical calculation, Karachi method + Hanafi madhab — common for Bangladesh). No internet download step needed at all, which is actually simpler than the cache-what-you-downloaded architecture in the spec — coordinates are cached in Hive so the last-used location persists. Includes a preset list of 8 Bangladeshi cities, an optional "use current location" (geolocator), Qibla bearing (numeric — no live compass sensor wired up), a daily tasbih counter, and optional reminders before each of the 5 waqts.

## Local database

Everything is Hive, fully offline, no server. Since this sandbox can't run
`build_runner`, every model has a **hand-written** `TypeAdapter` (in the same
file as the model) instead of a generated `.g.dart` — functionally
identical, just written in the standard generated-code shape by hand.

## Known gaps / next steps

- No platform folders yet (see step 1 above).
- Voice notes: data model only, no recording UI.
- Qibla: numeric bearing only, no live compass.
- Reminders only exist for Todo and Loan; medicine/bill reminders piggyback on Todo rather than getting their own screen.
- Not compiled/run anywhere — please `flutter analyze` before shipping.
