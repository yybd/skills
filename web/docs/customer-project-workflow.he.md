# זרימת עבודה לפרויקט לקוח

כיצד ה-skills, האורקסטרטור וקבצי המפרט הספציפיים-לפרויקט משתלבים יחד לבניית אתר. קראו פעם אחת כדי להבין את המתודה; הכללים השוטפים נמצאים ב-`CLAUDE.md`.

## למה הסיסטם הזה (לעומת פרומט בשורה אחת)

שאלה הוגנת: אם פשוט תכתבו *"בוא נבנה דף הרשמה להלכה יומית בוואטסאפ"*, האם Claude Code לא יעשה את רוב זה לבד? ברובו כן — בערך 70–80% מזה. אז למה צריך סיסטם?

**ההשוואה האמיתית אינה "סיסטם מול פרומט קצר". היא: "סיסטם מול הפרומט הארוך-והמושלם שהייתם צריכים לכתוב מחדש — בלי טעות — בכל אתר ואתר."** הסיסטם הזה *הוא* אותו פרומט, שנכתב פעם אחת וכך שלא ישכח אף פרט.

מה מרוויחים לעומת פרומט חשוף:

| בלי הסיסטם | עם הסיסטם |
|------------|-----------|
| Claude מנחש stack | ה-intake **שואל** בכל פעם (landing←HTML, דינמי←Next, תוכן←Astro) |
| בונה ברצף עד הסוף | **עוצר לאישור שלכם** ב-intake, ב-blueprint, ובכיוון העיצוב |
| i18n/RTL מתווסף לרוב בדיעבד | i18n + RTL מחווטים מהקומיט הראשון — **לא נשכחים** |
| Desktop-first, מובייל בטלאי | safe-areas של iPhone/Android, ‏`svh/dvh`, יעדי מגע **כברירת מחדל** |
| מחרוזות מקודדות קשיח ב-markup | תוכן ב-`text/<lang>/`, ממשק בקטלוגים — **מופרד כברירת מחדל** |
| עלול להמציא המלצות/מספרים | **ללא תוכן מומצא** — פערים מסומנים כ-TODO |
| מראה ורמת-קפדנות שונים בכל פעם | **בסיס עקבי** לאורך כל אתר שתבנו |

שלושה דברים שזה נותן לכם במיוחד:
- **שליטה** — שלוש נקודות עצירה מפורשות (intake, blueprint, עיצוב) במקום הפקה אחת גדולה ולא-מבוקרת.
- **עקביות** — כל אתר שתשחררו עובר את אותו הבסיס, כך שהאיכות אינה תלויה במה שזכרתם להקליד באותו יום.
- **הסטנדרטים שלכם, מקודדים** — הדעות הספציפיות שלכם (RTL עברית-תחילה, mobile-first, ללא הוכחות מומצאות, תוכן מחוץ ל-markup) טבועים פנימה, לא נדונים מחדש בכל פעם.

**מתי זה *לא* שווה:** אתר חד-פעמי לזריקה, פרוטוטיפ מהיר, או דף סטטי בודד שלא תחזרו אליו. לאלה, פרומט קצר באמת מספיק. הסיסטם משתלם כשבונים *הרבה* אתרים ורוצים שכל אחד יתחיל מאותה רצפה גבוהה.

## המודל המנטלי

שלושה **skills** לשימוש חוזר מגדירים *מתודה* (אגנוסטיים לפרויקט). שלושה קבצי **פרויקט** מגדירים את *הלקוח הספציפי הזה*. האורקסטרטור קושר ביניהם.

```
לשימוש חוזר (להעתיק לכל פרויקט, בהמשך plugin)        ספציפי-לפרויקט (אחד לכל לקוח)
─────────────────────────────────────────────        ──────────────────────────────
.claude/skills/page-builder/        ← מבנה            CLAUDE.md   ← אורקסטרטור + intake
.claude/skills/frontend-design/     ← אסתטיקה          DESIGN.md   ← מפרט מותג וויזואל
.claude/skills/web-design-guidelines/ ← ביקורת          PRODUCT.md  ← קהל, טון, anti-refs
```

**כלל אצבע:**
- מתודה תמיד-שימושית → **skill** (אגנוסטי לפרויקט, ללא פרטי לקוח).
- הוראות ספציפיות ללקוח → **CLAUDE.md** בפרויקט.
- החלטות מותג/ויזואל → **DESIGN.md**.
- קהל/טון/מסרים → **PRODUCT.md**.

אם אי-פעם תמצאו פרטים ספציפיים-ללקוח דולפים לתוך skill — הוציאו אותם משם. ה-skills חייבים להישאר ניידים כדי שניתן יהיה להעתיק אותם בין פרויקטים ובסופו של דבר לארוז אותם כ-plugin של Claude Code.

## מבנה תיקיות לפרויקט לקוח

```
~/Developer/web/<customer>/
├── CLAUDE.md            ← אורקסטרטור (intake + workflow + routing)
├── DESIGN.md            ← מפרט מותג וויזואל
├── PRODUCT.md           ← קהל, טון, anti-references
├── docs/web/
│   ├── customer-project-workflow.md      ← הקובץ הזה (אנגלית)
│   └── customer-project-workflow.he.md   ← גרסה עברית
├── .claude/skills/
│   ├── page-builder/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── page-archetypes.md
│   │       ├── i18n-rtl.md
│   │       ├── responsive-mobile.md
│   │       ├── content-architecture.md
│   │       ├── seo-metadata.md
│   │       ├── forms-conversion.md
│   │       ├── performance.md
│   │       ├── sections/{hero-patterns, trust-signals, cta-hierarchy}.md
│   │       └── checklists/pre-delivery.md
│   ├── frontend-design/
│   │   ├── SKILL.md
│   │   └── references/techniques.md
│   └── web-design-guidelines/SKILL.md
└── src/                 ← האתר עצמו
    ├── text/<lang>/*.md ← טקסט תוכן, תיקייה לכל שפה
    ├── media/           ← תמונות / וידאו (AVIF/WebP תחילה, SVG לאייקונים)
    └── data/            ← אופציונלי: נתונים מובְנים
```

> מיקום ה-skill קריטי: Claude Code מזהה skills רק תחת `.claude/skills/<name>/SKILL.md` (פרויקט) או `~/.claude/skills/<name>/SKILL.md` (אישי). skill שממוקם ישירות ב-`.claude/<name>/` **לא** מזוהה.

## ה-skills בפירוט

### `page-builder` — מבנה (מה נמצא בדף ובאיזה סדר)
רץ ראשון. קובע את שלד הדף לפני כל עיצוב ויזואלי. ה-`SKILL.md` שלו מנהל את התהליך ומושך references לפי הצורך:

- **`references/page-archetypes.md`** — סדרי סקשנים מוכחים לכל סוג דף (landing, homepage, product, content/article, docs, contact, pricing), **וכן דפי מערכת ומצב (404, שגיאה, ריק, טעינה)** + כיצד לבחור ביניהם.
- **`references/sections/hero-patterns.md`** — וריאציות hero (centered, split, inline-form, background-media, editorial, interactive) ומדריך בחירה.
- **`references/sections/trust-signals.md`** — מיפוי ספק→הוכחה, סוגי הוכחה לפי דירוג, וכללי מיקום.
- **`references/sections/cta-hierarchy.md`** — "כלל האחד" ל-CTA ראשי, ניסוח, והיכן לחזור עליו.
- **`references/i18n-rtl.md`** — ארכיטקטורת ריבוי-שפות + כללי RTL-first, עם ספריות לכל stack והנחיות טיפוגרפיה עברית.
- **`references/responsive-mobile.md`** — מתודת mobile-first, breakpoints, ארגונומיית מגע, safe areas, ותקלות iPhone/Android ב-Safari/Chrome.
- **`references/content-architecture.md`** — הפרדת טקסט-תוכן/טקסט-ממשק, מבנה `text/<lang>/*.md`, מנוע הרינדור הסטטי לכל stack, תיקיית הנכסים `media/` ‏(AVIF/WebP), ותיקיית `data/` האופציונלית.
- **`references/seo-metadata.md`** — title/meta לכל דף, canonical, ‏`hreflang`, כרטיסי שיתוף Open Graph/Twitter (התצוגה המקדימה בוואטסאפ/פייסבוק), JSON-LD/Schema.org, sitemap/robots, וסט ה-favicon/manifest/site-chrome.
- **`references/forms-conversion.md`** — כשהמטרה היא שליחת טופס: נתיב השליחה, markup נגיש ותומך-RTL, אימות, הגנת ספאם, ארבעת המצבים, וחובות הפרטיות/PII (הסכמה, מדיניות פרטיות, מינימיזציה).
- **`references/performance.md`** — יעדי Core Web Vitals קונקרטיים ואסטרטגיית טעינת פונטים עברית-תחילה (self-host, subset כולל ניקוד, ‏`font-display`, preload), בנוסף למסירת תמונות/CSS/JS.
- **`references/checklists/pre-delivery.md`** — שער QA מבני סופי (מטרה, hero, אמון, CTAs, תוכן, ארכיטקטורת-תוכן, i18n/RTL, רספונסיביות, SEO, טפסים, ביצועים, בסיסים).

### `frontend-design` — אסתטיקה (איך זה נראה)
רץ שני. מתחייב לכיוון ויזואלי נועז ומגובש (טיפוגרפיה, צבע, מושן, קומפוזיציה) לפי `DESIGN.md`, ומיישם markup ברמת production. אגנוסטי לפרויקט; החלטות המותג מגיעות מ-`DESIGN.md`. ה-`references/techniques.md` שלו מכיל דפוסים קונקרטיים לארבעת הווקטורים (זיווגי פונטים כולל חיתוכים עבריים, themes, מושן staggered, רקעים שכבתיים, AI-slop checklist, ו-template תואם-baseline) — כנקודות התחלה לשינוי, לא כברירות מחדל.

### `web-design-guidelines` — ביקורת (האם זה תקין)
רץ אחרון. מושך את ה-Web Interface Guidelines העדכניים וסוקר את הקבצים שנבנו לעמידה בנגישות, ביצועים ו-UX, ומדווח ממצאים בפורמט `file:line`.

## כיצד נטענים קבצי המפרט

- **`CLAUDE.md` נטען אוטומטית** על ידי Claude Code (הוא ה-project memory בשורש הריפו) — תמיד בהקשר.
- **`DESIGN.md` ו-`PRODUCT.md` *אינם* נטענים אוטומטית.** הם קבצים רגילים, נקראים רק כשהתהליך דורש זאת. ההדק הוא ההוראה שבתוך `CLAUDE.md` ("Read all three before building anything"), המכובדת ב-intake ובשלב הרלוונטי: `page-builder` מתייעץ עם `PRODUCT.md` (קהל, טון, אילו הוכחות צריך); `frontend-design` מתייעץ עם `DESIGN.md` (מותג, צבע, טיפוגרפיה, מושן).
- משמעות מעשית: שמרו על משמעת קריאה — בתחילת כל בנייה, קראו את `DESIGN.md` ו-`PRODUCT.md` לפני הפקת מבנה או ויזואלים. (לא מוגדר hook; הטעינה מודרכת על ידי `CLAUDE.md`.)

## זרימת ה-skills (לכל דף או אתר)

1. **הIntake (CLAUDE.md).** לפני הבנייה, אַשרו: מה אנחנו בונים, ה-stack (נשאל בכל פעם — landing page ← HTML/CSS/JS, דינמי ← Next.js+React, עתיר-תוכן ← Astro), השפות + ברירת המחדל, ומקור המותג. תֵעדו את התשובות לתוך בלוק "This Project" ולתוך קבצי המפרט.
2. **מבנה (`page-builder`).** בחרו את הארכיטיפ, סדר הסקשנים, תבנית ה-hero, מיקום אותות האמון, והיררכיית ה-CTA. מבנה ה-i18n/RTL נקבע כאן. הפיקו blueprint ואַשרו אותו.
3. **אסתטיקה (`frontend-design`).** התחייבו לכיוון נועז לפי `DESIGN.md`; יישמו UI ברמת production ב-stack הנבחר.
4. **בנייה.** יישמו עם i18n + RTL מוטמעים מההתחלה (קטלוגי תרגום, CSS לוגי, `lang`/`dir` נכונים). בדקו בדפדפן כולל מעבר RTL ומסך קטן.
5. **ביקורת (`web-design-guidelines`).** הריצו את סקירת הנגישות/ביצועים/UX; תקנו ממצאים.
6. **טרום-מסירה.** הריצו את `page-builder/references/checklists/pre-delivery.md`; דַווחו על TODO-ים שנותרו בתוכן.

## סיכום הזרימה (ומתי כל קובץ מפרט נכתב)

```
אתה: "בוא נבנה X"
   ↓
Intake (4 שאלות)   → 📝 CLAUDE.md מתעדכן + מחליטים על מקור המותג   ← כאן ההחלטה על DESIGN.md
   ↓
page-builder       → blueprint, אתה מאשר                          → 📝 PRODUCT.md (כשעולה קהל/טון)
   ↓
frontend-design    → דו-שיח עיצוב, אתה מאשר כיוון                  → 📝 DESIGN.md נמלא בפועל   ← כאן המילוי
   ↓
בנייה              → קורא DESIGN.md + PRODUCT.md, כותב תוכן ל-text/<lang>/
   ↓
ביקורת (web-design-guidelines) + טרום-מסירה
```

שתי נקודות מפתח:
- **`DESIGN.md` מתמלא בדו-שיח, לא מראש** — התבנית מגיעה עם `TODO`-ים; היא *נמלאת* בשלב `frontend-design` כשאתה מאשר כיוון ויזואלי. (אם כבר יש לך מותג — היא נמלאת ב-intake במקום זאת.)
- **אתה מאשר לפני שכל שלב ממשיך** — intake, blueprint, וכיוון העיצוב הם שלוש נקודות עצירה.

## סטנדרטים בסיסיים (לכל פרויקט)

- **הi18n כברירת מחדל** — תמיכה רב-שפתית מחווטת מהקומיט הראשון, ללא מחרוזות מקודדות קשיח, ספרייה מתאימה לכל stack.
- **הRTL כאזרח-ראשון** — CSS logical properties, מירור נקי, טיפוגרפיה עברית אמיתית (ניקוד היכן שצריך).
- **Mobile-first ורספונסיביות** — קודם פריסת הטלפון, נבדק על viewports אמיתיים של iPhone + Android (safe areas, ‏`svh/dvh`, יעדי מגע 44/48px, שדות קלט 16px). ראו `page-builder/references/responsive-mobile.md`.
- **תוכן מחוץ ל-markup** — טקסט-תוכן ב-`text/<lang>/*.md` (מנוע סטטי מרנדר אותו), מחרוזות ממשק בקטלוגים, נתונים מובְנים ב-`data/` אופציונלי. ראו `page-builder/references/content-architecture.md`.
- **ללא תוכן מומצא** — רק הוכחות ומקורות אמיתיים; סַמנו פערים כ-TODO.
- **נגישות וביצועים הם דרישות**, מגודרים על ידי ביקורת ה-`web-design-guidelines`.

## פתיחת פרויקט לקוח חדש

1. צרו את התיקייה והעתיקו את `CLAUDE.md`, `DESIGN.md`, `PRODUCT.md` ואת `.claude/skills/` מפרויקט קיים (או, לאחר האריזה, התקינו את ה-plugin).
2. עדכנו את בלוק "This Project" ב-`CLAUDE.md`.
3. מלאו את `DESIGN.md` ו-`PRODUCT.md` (או השאירו TODO-ים ופִתרו אותם במהלך ה-intake).
4. הריצו את ה-intake והמשיכו דרך שלבי ה-workflow.

## לקראת plugin

שלושת ה-skills בתוספת מסמך זה מתוכננים להיארז כ-plugin של Claude Code כך שפרויקטים חדשים יקבלו אותם ללא העתקת קבצים. שִמרו את ה-skills נקיים מפרטים ספציפיים-ללקוח כדי שהחילוץ העתידי יהיה נקי: רק `CLAUDE.md` / `DESIGN.md` / `PRODUCT.md` צריכים להשתנות בין לקוחות.
