"""Rebuild the Orange Modern PPTX template with content for the
'Daily Utility' Flutter app.

Strategy: keep every visual element (freeforms, groups, icons, brand mark)
exactly where the template placed them — only rewrite text frames in place.
For shapes that already exist in the template, we mutate the text frame;
for screenshots we add PICTURE shapes on the relevant slides.
"""

from copy import deepcopy
from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE_TYPE
from pptx.oxml.ns import qn
from lxml import etree

SRC = 'app_pptx/Orange Modern Nutrition & Meal App Pitch Deck Presentation.pptx'
OUT = 'app_pptx/Daily Utility App Pitch Deck.pptx'

BRAND = RGBColor(0xFF, 0x5B, 0x37)          # primary orange/red
WHITE = RGBColor(0xFF, 0xFF, 0xFF)
NEAR_WHITE = RGBColor(0xF5, 0xF5, 0xF5)
BLACK = RGBColor(0x00, 0x00, 0x00)
DARK = RGBColor(0x1F, 0x1F, 0x1F)
MUTED = RGBColor(0x55, 0x55, 0x55)

prs = Presentation(SRC)


# ---------- helpers ----------
def find_textbox(slide, name):
    """Find a top-level text box by its object name."""
    for sh in slide.shapes:
        if sh.name == name:
            return sh
    return None


def set_text(shape, text, *, size=None, bold=None, color=None,
             align=None, first_size=None):
    """Replace a text frame's content with a single run.

    `first_size` lets the first run be larger than the rest (e.g. eyebrow +
    headline where the first row is the small label).
    """
    if not shape or not shape.has_text_frame:
        return
    tf = shape.text_frame
    tf.clear()
    p = tf.paragraphs[0]
    if align is not None:
        p.alignment = align
    run = p.add_run()
    run.text = text
    if size is not None:
        run.font.size = Pt(size)
    if bold is not None:
        run.font.bold = bold
    if color is not None:
        run.font.color.rgb = color


def split_runs(shape, lines, *, sizes, bolds, colors):
    """Write multiple lines into one text frame, each with its own run style.

    `lines`, `sizes`, `bolds`, `colors` are parallel lists.
    """
    if not shape or not shape.has_text_frame:
        return
    tf = shape.text_frame
    tf.clear()
    for i, line in enumerate(lines):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        run = p.add_run()
        run.text = line
        if sizes[i] is not None:
            run.font.size = Pt(sizes[i])
        run.font.bold = bool(bolds[i])
        if colors[i] is not None:
            run.font.color.rgb = colors[i]


def add_picture(slide, image_path, left, top, width, height):
    return slide.shapes.add_picture(
        image_path,
        Inches(left), Inches(top),
        width=Inches(width), height=Inches(height),
    )


def remove_pictures(slide):
    pics = [s for s in slide.shapes if s.shape_type == MSO_SHAPE_TYPE.PICTURE]
    for p in pics:
        sp = p._element
        sp.getparent().remove(sp)


# ---------- SLIDE 1 — Title / Hero ----------
s = prs.slides[0]
set_text(find_textbox(s, 'TextBox 17'),
         'Daily Utility — One App. Every Day-of-Life Tool.',
         size=44, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 18'),
         'DailyUtility', size=14, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 19'),
         'Tasks, notes, finance, calculators, prayer, vault, quiz — '
         '20+ daily tools, fully offline, fully bilingual (বাংলা / English), '
         'in a single Material 3 Flutter app.',
         size=16, color=DARK)
set_text(find_textbox(s, 'TextBox 20'),
         '20+', size=40, bold=True, color=BRAND)
set_text(find_textbox(s, 'TextBox 21'),
         'Built-in Tools',
         size=12, color=MUTED)
set_text(find_textbox(s, 'TextBox 22'),
         'Offline-First', size=32, bold=True, color=BRAND)
set_text(find_textbox(s, 'TextBox 23'),
         'Storage Model',
         size=12, color=MUTED)
set_text(find_textbox(s, 'TextBox 24'),
         'Q3 2026', size=18, bold=True, color=BLACK)


# ---------- SLIDE 2 — The Problem: app overload ----------
s = prs.slides[1]
set_text(find_textbox(s, 'TextBox 8'),
         'The App-Overload Problem',
         size=40, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 9'),
         'DailyUtility', size=14, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 10'),
         'Most people juggle 8–12 separate apps just to get through a normal '
         'week — a to-do app, a notes app, a finance tracker, a separate '
         'calculator, a habit app, a prayer app, a vault. Each one demands '
         'its own account, its own subscription, its own sync.',
         size=14, color=DARK)
set_text(find_textbox(s, 'TextBox 11'),
         '8–12 apps', size=32, bold=True, color=BRAND)
set_text(find_textbox(s, 'TextBox 12'),
         'Average number of utility apps installed on a single phone.',
         size=12, color=DARK)
set_text(find_textbox(s, 'TextBox 13'),
         '$ 200 / yr', size=32, bold=True, color=BRAND)
set_text(find_textbox(s, 'TextBox 14'),
         'Combined annual subscriptions across productivity, finance and '
         'lifestyle tools.',
         size=12, color=DARK)
set_text(find_textbox(s, 'TextBox 15'),
         '0% privacy', size=32, bold=True, color=BRAND)
set_text(find_textbox(s, 'TextBox 16'),
         'Default cloud apps sync your tasks, notes and passwords to '
         'servers you don\'t control.',
         size=12, color=DARK)
set_text(find_textbox(s, 'TextBox 17'),
         'Heavy on data', size=24, bold=True, color=BRAND)
set_text(find_textbox(s, 'TextBox 18'),
         'Many separate apps mean battery drain, storage use and constant '
         'notification noise.',
         size=12, color=DARK)
set_text(find_textbox(s, 'TextBox 19'),
         'Nobody wants to install twelve apps to live one week',
         size=14, color=BRAND)


# ---------- SLIDE 3 — Our Solution ----------
s = prs.slides[2]
set_text(find_textbox(s, 'TextBox 28'),
         'A single offline-first Flutter app covering the whole day — '
         'productivity, money, lifestyle, utilities, security.',
         size=12, color=DARK)
set_text(find_textbox(s, 'TextBox 29'),
         '20+ Tools in One Codebase',
         size=14, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 30'),
         'Our Solution', size=44, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 31'),
         'DailyUtility', size=14, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 32'),
         'Personal data is stored locally with Hive, so it never leaves '
         'your phone. Only public content (notice board, quiz, contact) '
         'touches Firebase.',
         size=12, color=DARK)
set_text(find_textbox(s, 'TextBox 33'),
         'Offline-First by Design',
         size=14, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 34'),
         'Bilingual UI (English / বাংলা), light + dark Material 3 themes, '
         'responsive from small phones to tablets.',
         size=12, color=DARK)
set_text(find_textbox(s, 'TextBox 35'),
         'Bilingual & Themed',
         size=14, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 36'),
         'Every screen uses the single Theme.of(context).colorScheme '
         'tokens — no hardcoded colours, no design drift.',
         size=12, color=DARK)
set_text(find_textbox(s, 'TextBox 37'),
         'One Design System',
         size=14, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 38'),
         '100%', size=32, bold=True, color=BRAND)
set_text(find_textbox(s, 'TextBox 39'),
         'Personal data stored on your device — nothing leaves without you '
         'tapping "Share".',
         size=12, color=DARK)
set_text(find_textbox(s, 'TextBox 40'),
         'Tasks, notes, finance, loans, subscriptions, vault, habits, mood, '
         'prayer, quiz, posts, backup — all in one Material 3 app.',
         size=12, color=DARK)
set_text(find_textbox(s, 'TextBox 41'),
         'Your Day, One App',
         size=14, bold=True, color=BLACK)


# ---------- SLIDE 4 — How the architecture works ----------
s = prs.slides[3]
set_text(find_textbox(s, 'TextBox 36'),
         'How the App Works', size=44, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 37'),
         'DailyUtility', size=14, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 38'),
         'Each feature has one screen and one service singleton with a '
         'ValueNotifier — fast, predictable and trivial to extend.',
         size=12, color=DARK)
set_text(find_textbox(s, 'TextBox 39'),
         'Service-per-Feature', size=14, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 40'),
         'Personal data in typed Hive boxes, public data fetched from '
         'Firestore — three collections: notice, quiz_categories, '
         'contact_messages.',
         size=12, color=DARK)
set_text(find_textbox(s, 'TextBox 41'),
         'Hive + Firestore Hybrid', size=14, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 42'),
         'flutter_local_notifications fires reminders for tasks and loan '
         'instalments — one sorted "Reminders" view shows them all.',
         size=12, color=DARK)
set_text(find_textbox(s, 'TextBox 43'),
         'Local Reminders', size=14, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 44'),
         'Prayer times computed fully offline by adhan_dart from cached '
         'lat/long; optional geolocator for GPS detect and live Qibla.',
         size=12, color=DARK)
set_text(find_textbox(s, 'TextBox 45'),
         'Offline Prayer & Qibla', size=14, bold=True, color=BLACK)


# ---------- SLIDE 5 — Key features (with screenshots) ----------
s = prs.slides[4]
remove_pictures(s)
set_text(find_textbox(s, 'TextBox 29'),
         'Key Features: Everything You\'d Otherwise Install 12 Apps For',
         size=32, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 30'),
         'DailyUtility', size=14, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 31'),
         'Tasks with priority, due date, recurrence and reminder. Active '
         'list with progress badge, completed-history tab.',
         size=12, color=DARK)
set_text(find_textbox(s, 'TextBox 32'),
         'Tasks & Notes', size=14, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 33'),
         'Income / expense, Baki Khata people-ledger, loan tracker with '
         'progress bar, and a Netflix/Spotify-grade subscription manager.',
         size=12, color=DARK)
set_text(find_textbox(s, 'TextBox 34'),
         'Finance Suite', size=14, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 35'),
         '20+ calculators across General, Education, Health, Finance and '
         'BD Special — plus Unit Converter and Date Tools.',
         size=12, color=DARK)
set_text(find_textbox(s, 'TextBox 36'),
         'Calculators & Converters', size=14, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 37'),
         'Habit tracker with streak + consistency, Daily Reflect, shopping '
         'list, and reminders aggregated across tasks and loans.',
         size=12, color=DARK)
set_text(find_textbox(s, 'TextBox 38'),
         'Lifestyle & Habits', size=14, bold=True, color=BLACK)

# add a hero screenshot to the left side (over the empty Group 2 area)
add_picture(s, 'app_images/sm/Screenshot_20260927_063501.png',
            left=-0.30, top=2.20, width=2.95, height=6.60)
add_picture(s, 'app_images/sm/Screenshot_20260927_063707.png',
            left=2.05, top=4.80, width=2.65, height=4.10)


# ---------- SLIDE 6 — Market / Audience ----------
s = prs.slides[5]
set_text(find_textbox(s, 'TextBox 24'),
         'Who It\'s For', size=44, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 25'),
         'DailyUtility', size=14, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 26'),
         'Students using a Baki Khata, tracking subscriptions and acing '
         'GPA / CGPA — Bangladesh first, English-speaking markets next.',
         size=12, color=DARK)
set_text(find_textbox(s, 'TextBox 27'),
         'Early Access Cohort', size=14, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 28'),
         '0\n', size=1, color=BLACK)  # placeholder
find_textbox(s, 'TextBox 28').text_frame.clear()
p = find_textbox(s, 'TextBox 28').text_frame.paragraphs[0]
r = p.add_run(); r.text = '500+'; r.font.size = Pt(72); r.font.bold = True; r.font.color.rgb = BRAND
set_text(find_textbox(s, 'TextBox 29'),
         'Friends, family & colleagues in Bangladesh testing the local '
         'tools (Baki Khata, BD land-units, prayer).',
         size=12, color=DARK)
set_text(find_textbox(s, 'TextBox 30'),
         'English-Speaking Markets', size=14, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 31'),
         '50,000+', size=72, bold=True, color=BRAND)
set_text(find_textbox(s, 'TextBox 32'),
         'Productivity-app users who want one offline-first tool '
         'replacing 8–12 separate apps — privacy-conscious, '
         'subscription-fatigued, mobile-first.',
         size=14, color=DARK)


# ---------- SLIDE 7 — Business model ----------
s = prs.slides[6]
set_text(find_textbox(s, 'TextBox 21'),
         'How It Stays Free & Sustainable', size=36, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 22'),
         'DailyUtility', size=14, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 23'),
         'Today the app is fully free, fully offline, no ads, no accounts. '
         'When sustainable monetisation lands, it lands gently:',
         size=14, color=DARK)
set_text(find_textbox(s, 'TextBox 24'),
         'Optional Pro tier (planned): cloud-restore, multi-device sync, '
         'advanced analytics in Habits/Mood, premium calculators.',
         size=12, color=DARK)
set_text(find_textbox(s, 'TextBox 25'),
         'Pro Tier (Future)', size=14, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 26'),
         'Sponsorships for the curated BD-special calculators and '
         'co-branded notice-board placements on the public content layer.',
         size=12, color=DARK)
set_text(find_textbox(s, 'TextBox 27'),
         'Brand Partnerships', size=14, bold=True, color=BLACK)


# ---------- SLIDE 8 — Traction / screenshots ----------
s = prs.slides[7]
remove_pictures(s)
set_text(find_textbox(s, 'TextBox 21'),
         '20+',
         size=56, bold=True, color=BRAND)
set_text(find_textbox(s, 'TextBox 22'),
         'User Rating (internal)',
         size=12, color=MUTED)
set_text(find_textbox(s, 'TextBox 23'),
         'DailyUtility', size=14, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 24'),
         'Traction & Status', size=40, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 25'),
         '100% Offline', size=36, bold=True, color=BRAND)
set_text(find_textbox(s, 'TextBox 26'),
         'Personal Data Coverage', size=12, color=MUTED)
set_text(find_textbox(s, 'TextBox 27'),
         'Every personal feature — tasks, notes, finance, baki, loans, '
         'subscriptions, habits, mood, vault, shopping, calculator '
         'history — works with the airplane mode on.',
         size=14, color=DARK)

# Replace the template\'s single big image with a 3x2 grid of real app screenshots
# Grid area: L=9.83, T=1.76, W=9.50, H=8.82
# We use 3 columns and 2 rows of thumbnails.
thumb_dir = 'app_images/sm'
thumbs = [
    f'{thumb_dir}/Screenshot_20260927_063438.png',  # Home
    f'{thumb_dir}/Screenshot_20260927_064642.png',  # Drawer
    f'{thumb_dir}/Screenshot_20260927_064606.png',  # Prayer
    f'{thumb_dir}/Screenshot_20260927_064404.png',  # Vault
    f'{thumb_dir}/Screenshot_20260927_064418.png',  # Posts
    f'{thumb_dir}/Screenshot_20260927_064450.png',  # Studio
]
grid_left = 9.83
grid_top = 1.76
cell_w = 3.10
cell_h = 4.30
gap_x = 0.10
gap_y = 0.20
for idx, img in enumerate(thumbs):
    col = idx % 3
    row = idx // 3
    add_picture(
        s, img,
        left=grid_left + col * (cell_w + gap_x),
        top=grid_top + row * (cell_h + gap_y),
        width=cell_w, height=cell_h,
    )


# ---------- SLIDE 9 — Team (solo project, hence: solo) ----------
s = prs.slides[8]
set_text(find_textbox(s, 'TextBox 21'),
         'DailyUtility', size=14, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 22'),
         'Built Solo,\nEnd-to-End', size=40, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 23'),
         'Nazmul', size=14, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 24'),
         'Designer · Developer · Maintainer',
         size=11, color=DARK)
set_text(find_textbox(s, 'TextBox 25'),
         'nazmulislamabir1500@gmail.com',
         size=11, color=DARK)
set_text(find_textbox(s, 'TextBox 26'),
         'Open Source', size=14, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 27'),
         'MIT-licensed Flutter codebase',
         size=11, color=DARK)
set_text(find_textbox(s, 'TextBox 28'),
         'PRs welcome', size=11, color=DARK)
set_text(find_textbox(s, 'TextBox 29'),
         'Community', size=14, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 30'),
         'Bengali-first testers',
         size=11, color=DARK)
set_text(find_textbox(s, 'TextBox 31'),
         '500+ invite list',
         size=11, color=DARK)
set_text(find_textbox(s, 'TextBox 32'),
         'Daily Utility is currently a one-person project: design, Flutter '
         'code, Hive/Firebase wiring, screenshots, README and pitch deck '
         'are all maintained solo. Early users from Bangladesh are testing '
         'the local features (Baki Khata, BD land-units, prayer times).',
         size=12, color=DARK)


# ---------- SLIDE 10 — Closing / CTA ----------
s = prs.slides[9]
set_text(find_textbox(s, 'TextBox 42'),
         'One Phone. Twenty Tools.\nZero Servers Touching Your Data.',
         size=32, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 43'),
         'DailyUtility', size=14, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 45'),
         'Nazmul', size=12, bold=True, color=BLACK)
set_text(find_textbox(s, 'TextBox 46'),
         'Try the build, send feedback, or open an issue on GitHub — '
         'every report shapes the next release.',
         size=14, color=DARK)

prs.save(OUT)
print('Wrote', OUT)
print('Slides:', len(prs.slides))
