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
- **Notices** — Firestore-backed notice board (`notice` collection). Admin pushes `title` / `para` / `imgurl` / `linkurl`; users read.
- **Quiz** — Firestore-backed multi-category quiz. Each category is one Firestore document; its `questions` array holds the playable 4-option MCQs. Adding a category or questions in the Firestore console is enough — no app update needed.
- **Contact us** — settings → "যোগাযোগ / Contact us". Form writes a new document to the `contact_messages` Firestore collection. The admin reads submissions from the Firebase console and replies by email.

## Firebase (Firestore)

Three collections are touched by the app at runtime (see `firestore.rules`):

| Collection         | Read    | Write (create) | Write (update/delete) |
|--------------------|---------|----------------|-----------------------|
| `notice`           | public  | admin only     | admin only            |
| `quiz_categories`  | public  | admin only     | admin only            |
| `contact_messages` | admin   | public         | admin only            |

### `notice/{docId}`

| Field      | Type   | Required | Notes |
|------------|--------|----------|-------|
| `title`    | string | yes      | Notice headline |
| `para`     | string | yes      | Body text |
| `imgurl`   | string | no       | Optional image URL |
| `linkurl`  | string | no       | Optional "Read more" link |
| `isPinned` | bool   | no       | Pinned to top |

### `quiz_categories/{docId}`

Each document = one quiz category. The `questions` array lives **inside the
category document**, so a single read fetches the whole category. Drop in a new
document and the hub picks it up on next refresh.

| Field       | Type     | Required | Notes |
|-------------|----------|----------|-------|
| `name`      | string   | yes      | Display title (e.g. `"Physics"`) |
| `subtitle`  | string   | no       | Shown under title (e.g. `"10 quick questions"`) |
| `icon`      | string   | no       | One of: `science`, `physics`/`phy`, `chemistry`/`chem`, `biology`/`bio`, `math`, `history`, `geography`/`geo`, `gk`, `art`, `language`, `sports`, `music`, `movies`, `tech` |
| `color`     | string   | no       | Hex like `0xFF14B8A6` or `#14B8A6` (alpha stripped). Defaults to brand quiz colour. |
| `order`     | number   | no       | Ascending sort key |
| `questions` | array    | yes      | See shape below |

#### `questions[]` entry

```json
{
  "q":       "What is the SI unit of force?",
  "options": ["Joule", "Newton", "Watt", "Pascal"],
  "answer":  1,
  "hint":    "Named after the father of mechanics."
}
```

- `q` — question text
- `options` — exactly **4** strings
- `answer` — **0-based** index of the correct option in `options`
- `hint` — optional, shown to the user when they get the answer wrong

#### Worked example

Collection `quiz_categories`, document id `phy`:

```json
{
  "name": "Physics",
  "subtitle": "10 quick questions",
  "icon": "science",
  "color": "#14B8A6",
  "order": 1,
  "questions": [
    {
      "q": "What is the SI unit of force?",
      "options": ["Joule", "Newton", "Watt", "Pascal"],
      "answer": 1,
      "hint": "Named after the father of mechanics."
    },
    {
      "q": "Which particle has no electric charge?",
      "options": ["Proton", "Electron", "Neutron", "Photon"],
      "answer": 2
    }
  ]
}
```

To add a new category: create another document in `quiz_categories` (e.g. `gk`)
with the same shape. The next refresh will show it in the hub automatically.

### `contact_messages/{docId}`

Each document = one user-submitted message from the in-app "Contact us"
form (Settings → যোগাযোগ). End users create; admin reads from the
Firebase console and replies by email.

| Field        | Type      | Required | Notes |
|--------------|-----------|----------|-------|
| `name`       | string    | yes      | Sender's name |
| `email`      | string    | yes      | Sender's email (used to reply) |
| `message`    | string    | yes      | Issue / suggestion body |
| `createdAt`  | timestamp | server   | Server-set when document is created |
| `appVersion` | string    | no       | App version at submission |
| `platform`   | string    | no       | OS / platform info |
| `locale`     | string    | no       | UI locale (e.g. `bn` / `en`) |

#### How submissions reach you

The app does **not** auto-send email. When a user taps "Send", a new
document is created in `contact_messages`. You read them from
Firebase console → Firestore → `contact_messages`, then reply directly
to the `email` field. If you want auto-forwarding to your Gmail,
configure an email trigger (Firebase Extension "Trigger Email" works
well for this) — point it at `contact_messages` and use the
`email` field as the recipient, `name` as greeting, and `message` as body.

#### How to add a Firebase Extension trigger (optional, 1 minute)

1. Firebase console → Firestore → `contact_messages` → look for the
   lightning-bolt icon / "Extensions" → "Trigger Email"
2. Install, set:
   - Collection: `contact_messages`
   - To: `{{email.value}}` (uses the sender's email — so they get the copy too)
   - Reply-To: `nazmulislamabir1500@gmail.com`
   - From: a Gmail address you've authenticated with SMTP
   - Message: `Hello {{name.value}}, thanks for contacting DailyUtility. — Admin`
   - Body: `{{message.value}}`
3. Publish → every new contact message is auto-emailed to both you and the user.

## Local database

Everything except notices/quizzes is Hive, fully offline, no server. Since this
sandbox can't run `build_runner`, every model has a **hand-written** `TypeAdapter`
(in the same file as the model) instead of a generated `.g.dart` — functionally
identical, just written in the standard generated-code shape by hand.

## Known gaps / next steps

- No platform folders yet (see step 1 above).
- Voice notes: data model only, no recording UI.
- Qibla: numeric bearing only, no live compass.
- Reminders only exist for Todo and Loan; medicine/bill reminders piggyback on Todo rather than getting their own screen.
- Not compiled/run anywhere — please `flutter analyze` before shipping.
