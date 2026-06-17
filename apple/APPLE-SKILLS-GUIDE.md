# מדריך משפחת סקילי האפליקציות

מדריך לכל הסקילים שנבנו לפיתוח והוצאת אפליקציות — רובם ל-macOS/iOS (App Store
והפצה ישירה), פלוס סקיל-אח ל-Google Play. מה כל אחד עושה, מי הבעלים של מה,
התלויות ביניהם, ודוגמאות שימוש.

עודכן: 2026-06-17 · מיקום הסקילים: `~/.claude/skills/` · **16 סקילים**

> **זרימת סטודיו (BD TECH):** 16 הסקילים כאן הם **מכניקה גנרית** (ידע אפל/גוגל) ופועלים בכל פרויקט.
> ב-BD TECH הם מונעים משכבת ה-Hub: מקור האמת לכל קופי הוא הפרופיל (`<slug>/profile.md`), הקופי
> **מורם** ממנו (לא מומצא), והמדיה (`appstore-media`) נכתבת אל ה-Hub. לתזמור מקצה-לקצה
> (פרופיל → מדיה → חנויות → אתר → שליחה), שכבת ה-Hub, ואיפה כל סקיל רץ — ראה
> `~/Developer/app-hub/APP-LIFECYCLE.md` (ה-Hub של הסטודיו).

---

## סקירה — 16 הסקילים (לפי תפקיד)

**מתזמן**

| סקיל | במשפט אחד |
|------|-----------|
| **ship-apple-app** | Playbook שמתזמן את כל מסלול ה-App Store: מ-bundle ID ועד submit |

**זהות וחתימה**

| סקיל | במשפט אחד |
|------|-----------|
| **apple-credentials** | בעלים יחיד של תעודות + credentials (יצירה, `.p12`, notary, API key) |
| **code-signing-provisioning** | מודל חתימה, provisioning profiles, אבחון ופענוח שגיאות |

**איכות, תאימות ולוקליזציה**

| סקיל | במשפט אחד |
|------|-----------|
| **app-store-review-compliance** | תאימות למדריך הביקורת של אפל (מונע דחיות) + demo mode לבודק |
| **apple-bug-flow-review** | QA פונקציונלי: מאתר באגי לוגיקה/קוד + שברים בזרימת המשתמש (סריקה סטטית + analyzer + sanitizers + XCUITest) |
| **apple-hig-design-review** | סקירת עיצוב/נגישות מול ה-HIG (המלצות מדורגות) |
| **localization-i18n** | לוקליזציה בתוך האפליקציה: מחרוזות, טקסט קשיח, שלמות תרגום, RTL |

**שם וזהות (מקור אמת)**

| סקיל | במשפט אחד |
|------|-----------|
| **app-identity** | קובע את שם האפליקציה (תצוגה במכשיר + App Store + סאבטייטל) בשיח עם המפתח (לא לבד), כותב את שם-התצוגה ל-build/Info.plist, ובעלים של ה-README כמקור-אמת (זהות + רשימת פיצ'רים). רץ **מוקדם** — לפני metadata/media |

**רשימה ונכסים (App Store)**

| סקיל | במשפט אחד |
|------|-----------|
| **app-store-metadata** | בעלים של קובצי הרשימה: טקסט רב-לשוני + קבצי צילומי מסך, אימות, העלאה ב-`deliver` |
| **appstore-media** | ייצור צילומי מסך + סרטוני App Preview מ-XCUITest demo flow |
| **apple-app-store-screenshots** | התאמת תמונה בודדת קיימת לגודל פיקסלים מדויק |
| **app-icon-generator** | יצירת AppIcon set לכל הפלטפורמות מתמונה אחת |
| **aso-keywords** | אופטימיזציית name/subtitle/keywords לגילוי בחיפוש |

**הפצה ישירה (macOS, מחוץ ל-App Store)**

| סקיל | במשפט אחד |
|------|-----------|
| **notarize-and-distribute** | DMG → חתימת Developer ID → notarization → staple → אימות |

**אחרי שחרור**

| סקיל | במשפט אחד |
|------|-----------|
| **app-store-reviews-responder** | מעקב אחר ביקורות משתמשים וניסוח תשובות |

**אנדרואיד (סקיל-אח)**

| סקיל | במשפט אחד |
|------|-----------|
| **play-store-metadata** | מטא-דאטה ל-Google Play דרך fastlane `supply` — המקבילה של `app-store-metadata` |

---

## מי הבעלים של מה (מקור אמת יחיד)

העיקרון: כל נושא שייך לסקיל אחד; השאר **שואבים** ממנו (ואם לא מותקן — fallback
מקומי מצומצם, בד"כ הדרכה דרך Xcode).

| נושא | בעלים | מי שואב / מזין |
|------|-------|----------------|
| **שם תצוגה במכשיר** (PRODUCT_NAME/CFBundleDisplayName) + **בחירת** שם/סאבטייטל לחנות + **README מקור-אמת** (זהות + רשימת פיצ'רים) | **app-identity** | app-store-metadata, aso-keywords, appstore-media, ו-app-profile (Hub) שואבים מה-README; רץ מוקדם, לפני metadata/media |
| תעודות, יצירה, `.p12`, app-specific password, notary profile, API key | **apple-credentials** | code-signing, notarize-and-distribute, ship-apple-app, app-store-metadata, app-store-reviews-responder |
| מודל חתימה, provisioning profiles, שגיאות חתימה, אבחון | **code-signing-provisioning** | ship-apple-app |
| כללי ביקורת + demo mode לבודק + privacy manifest + entitlements מוצדקים | **app-store-review-compliance** | ship-apple-app, appstore-media (להבחנה בין שני סוגי ה-demo mode) |
| באגי נכונות/חוסן + QA של זרימת המשתמש (האם זה עובד?) | **apple-bug-flow-review** | ship-apple-app (אופציונלי, לפני archive); מנצל את ה-demo mode וה-a11y IDs של appstore-media ל-smoke flows |
| עיצוב/נגישות (HIG) | **apple-hig-design-review** | ship-apple-app (אופציונלי) |
| לוקליזציה בתוך האפליקציה (מחרוזות, תרגום, RTL) | **localization-i18n** | ship-apple-app (לפני metadata) |
| קובצי רשימת ה-App Store (טקסט + קבצי צילומי מסך) + העלאה ב-`deliver` | **app-store-metadata** | ship-apple-app; **מוזן** מ-appstore-media, apple-app-store-screenshots, aso-keywords |
| **ייצור** צילומי מסך + סרטונים (demo-flow) | **appstore-media** | קורא את הפרופיל; כותב מדיה ל-`<slug>/media/apple/` ב-Hub (דרך `-o`); מזין את app-store-metadata |
| **התאמת גודל** של תמונה בודדת קיימת | **apple-app-store-screenshots** | בשימוש app-store-metadata, appstore-media |
| מילות מפתח / ASO (אפל) | **aso-keywords** | קורא וממזין את app-store-metadata |
| אייקונים | **app-icon-generator** | עצמאי (בשימוש ב-ship phase 5) |
| הפצה ישירה (DMG/notarize) | **notarize-and-distribute** | שואב מ-apple-credentials |
| ביקורות משתמשים + תשובות | **app-store-reviews-responder** | שואב מ-apple-credentials (API key) |
| רשימת Google Play (אנדרואיד) | **play-store-metadata** | אח מקביל ל-app-store-metadata |

### שלישיית צילומי המסך (החלוקה החשובה ביותר)
שלושה סקילים נוגעים בצילומי מסך — אל תבלבל ביניהם:
- **appstore-media** = **ייצור** (לכידה מהאפליקציה הרצה דרך XCUITest demo flow; גם סרטוני App Preview).
- **apple-app-store-screenshots** = **התאמה** (תמונה אחת שכבר קיימת → גודל פיקסלים מדויק).
- **app-store-metadata** = **ארגון/העלאה** (הכנסת הקבצים ל-`metadata/`, אימות מגבלות, `deliver`).

### שלישיית האיכות (אל תבלבל בין שלושת סקילי ה"סקירה")
שלושה סקילים סוקרים את האפליקציה לפני שחרור, כל אחד שאלה אחרת:
- **apple-bug-flow-review** = **האם זה עובד / נכון?** (קריסות, races, leaks, אובדן נתונים, שברים בזרימה — QA פונקציונלי).
- **app-store-review-compliance** = **האם אפל תאשר?** (כללי מדריך הביקורת — privacy strings, IAP, demo mode, entitlements).
- **apple-hig-design-review** = **האם זה מרגיש נייטיב ונגיש?** (ליטוש עיצוב/UX/נגישות מול ה-HIG).

חפיפה נפתרת לפי בעלות: UX שחוסם זרימה שייך ל-bug-flow; ליטוש אסתטי ל-HIG; כלל-דחייה ל-compliance; פרצת אבטחה נדחית לסקיל `security-review`.

### שכבת הסטודיו (Hub) — מאיפה מגיע הקופי
ב**זרימת BD TECH** ה-workers של החנויות מונעים משכבת ה-Hub, ומקור הקופי הוא הפרופיל — לא המצאה:
- `app-identity` `[בכל פרויקט]` → ה-`README.md` של הרפו = מקור-האמת לזהות (שם תצוגה/חנות/סאבטייטל) ולרשימת הפיצ'רים. רץ **לפני** `app-profile`.
- `app-profile` `[Hub]` → `<slug>/profile.md` = מקור האמת לכל קופי; **שואב מה-README** של `app-identity` (שמות + דירוג פיצ'רים) ואז מעשיר בקוד + מחקר שוק.
- `store-metadata-writer` `[Hub]` → מרים את הקופי מהפרופיל ומריץ את `app-store-metadata` /
  `play-store-metadata` / `aso-keywords` (הם הבעלים של הקבצים / האימות / ה-ASO — **לא** של חיבור הקופי).
- `add-app-to-site` `[bd-tech]` → האתר.
- `appstore-media` → קורא את הפרופיל וכותב מדיה ל-`<slug>/media/apple/` ב-Hub.

**כלל:** כשקיים פרופיל, אל תחבר קופי-חנות מאפס ב-workers — הרם מהפרופיל (או תן ל-`store-metadata-writer`
לתזמר). בלי פרופיל (פרויקט עצמאי) ה-workers כותבים מול המשתמש כרגיל. פירוט מלא: `APP-LIFECYCLE.md`.

---

## מפת תלויות

```
                          ┌─────────────────┐
                          │  ship-apple-app │  (מתזמן את כל מסלול ה-App Store)
                          └────────┬────────┘
   ┌───────────┬───────────┬───────┼────────┬───────────────┬─────────────┐
   ▼           ▼           ▼       ▼        ▼               ▼             ▼
apple-creds  code-sign  compliance hig  localization-i18n  app-store-metadata
   ▲           │                                                ▲   ▲   ▲
   │           │ (שואב תעודות)                                   │   │   │
   └───────────┘                          appstore-media ────────┘   │   │
   ▲                                       apple-app-store-screenshots┘   │
   │ (שואב תעודות + notary)                aso-keywords ──────────────────┘
notarize-and-distribute   ← מסלול נפרד: הפצה ישירה (DMG), לא App Store
app-store-reviews-responder ← אחרי שחרור (שואב API key מ-apple-credentials)
app-icon-generator   ← עצמאי, ללא תלויות
```

**מקור האמת — `app-identity` קובע שם וכותב README; סקילי הרשימה/מדיה שואבים ממנו:**

```
app-identity  ─▶  README.md  ─┬─▶  aso-keywords        (שם/סאבטייטל → מילות מפתח)
(רץ מוקדם —   (זהות +      ├─▶  app-store-metadata   (name / subtitle / description)
 לפני          פיצ'רים     ├─▶  appstore-media       (screen story / captions)
 metadata)     מדורגים)    └─▶  app-profile [Hub] ─▶ profile.md ─▶ store-metadata-writer
play-store-metadata  ← מקביל ל-app-store-metadata; בקרוס-פלטפורם שואב מאותו README
```

עקרון ה-fallback: אם סקיל שואב לא מוצא את הבעלים (למשל `apple-credentials` לא
מותקן), הוא מבצע גרסה מקומית מצומצמת בעצמו וממשיך.

---

## שני המסלולים העיקריים

### מסלול א' — App Store / Mac App Store
```
ship-apple-app מתזמן:
1. זהות         → apple-credentials (Apple Distribution) + code-signing-provisioning
2. רשומת אפליקציה → App Store Connect (אתר)
3. תאימות        → app-store-review-compliance
4. עיצוב         → apple-hig-design-review (אופציונלי)
5. לוקליזציה     → localization-i18n (אם ה-UI לא מתורגם במלואו)
6. שם+נכסים+רשימה → app-identity (שם תצוגה ב-build/Info.plist + בחירת שם/סאבטייטל + README מקור-אמת)
                   → aso-keywords (מילות מפתח) → appstore-media (ייצור צילומי מסך/סרטונים)
                   → apple-app-store-screenshots (התאמת תמונה בודדת) → app-store-metadata
                   (ארגון+אימות+deliver) → app-icon-generator (אייקון)
7. build/archive/upload
8. השלמה באתר    → age rating, pricing, App Privacy
9. submit
```

### מסלול ב' — הפצה ישירה (DMG, מחוץ ל-App Store, macOS בלבד)
```
1. תעודה        → apple-credentials (Developer ID Application)
2. credential   → apple-credentials (notary profile מ-app-specific password)
3. ארוז+חתום+notarize+staple+אמת → notarize-and-distribute
```

### מסלול ג' — Google Play (אנדרואיד)
```
play-store-metadata: scaffold → מילוי טקסט רב-לשוני + גרפיקה → אימות →
fastlane supply (העלאה) → השלמה ב-Play Console (Data safety, content rating, pricing)
```

---

## דוגמאות שימוש (משפטים שמפעילים כל סקיל)

**ship-apple-app** — "איך אני מעלה את האפליקציה ל-App Store מאפס?" · "תעבור איתי על כל תהליך השליחה צעד-צעד"

**apple-credentials** — "איזו תעודה אני צריך כדי להעלות ל-App Store?" · "תבדוק אילו תעודות יש לי" · "תייצא את התעודה ל-`.p12` בשביל GitHub Actions" · "תקים פרופיל notary"

**code-signing-provisioning** — "קיבלתי 'Provisioning profile doesn't include signing certificate' — מה לעשות?" · "תאבחן את הגדרות החתימה בפרויקט"

**app-store-review-compliance** — "למה אפל דחתה את האפליקציה? Guideline 2.1" · "תבדוק את הפרויקט מול מדריך הביקורת לפני שליחה"

**apple-bug-flow-review** — "בדוק באגים לפני שליחה" · "תעשה QA על האפליקציה" · "למה זה קורס / מאבד נתונים / נתקע?" · "בדוק שזרימות המשתמש באמת עובדות" · "בדיקת זרימת המשתמש"

**apple-hig-design-review** — "תעשה סקירת עיצוב — האם ה-UI מרגיש native?" · "תבדוק נגישות (VoiceOver / Dynamic Type)"

**localization-i18n** — "תוסיף תמיכה בעברית לאפליקציה" · "תמצא מחרוזות קשיחות שלא עברו לוקליזציה" · "האם כל השפות שלמות?"

**app-identity** — "איך לקרוא לאפליקציה?" · "תשנה את השם שמופיע מתחת לאייקון / בשורת התפריטים" · "תעדכן את שם ה-App Store והסאבטייטל" · "תכתוב/תרענן את ה-README ורשימת הפיצ'רים"

**app-store-metadata** — "תכין מטא-דאטה ל-App Store בעברית ואנגלית" · "תאמת שכל הטקסטים בתוך מגבלות התווים"

**appstore-media** — "תכין צילומי מסך לאפליקציה" · "אני צריך סרטון App Preview" · "demo flow שמייצר צילומי מסך בכל השפות"

**apple-app-store-screenshots** — "תהפוך את התמונה הזו לגודל הנכון ל-App Store" · "אפל דחתה את צילום המסך — תתקן את הגודל"

**app-icon-generator** — "תייצר אייקון בכל הגדלים מהתמונה הזו" · "אין לי אייקון — תיצור אחד התחלתי"

**aso-keywords** — "תשפר את הדירוג בחיפוש" · "תבדוק את שדה ה-keywords"

**notarize-and-distribute** — "תבנה DMG, תחתום ותעשה notarization" · "המשתמשים מקבלים 'app is damaged' — תתקן"

**app-store-reviews-responder** — "תראה לי את הביקורות האחרונות" · "תנסח תשובה לביקורת השלילית הזו"

**play-store-metadata** — "תכין רשימה ל-Google Play" · "תקים fastlane supply" · "תתרגם את התיאור ל-Play בעברית ואנגלית"

---

## תרחישי קצה-לקצה

### "שלחתי לאפל ונדחיתי על 2.1 (demo mode)"
→ `app-store-review-compliance` מאבחן את חוסר ה-demo path לבודק, מתקן/מנסח demo
mode + review notes. (שים לב: זה ה-demo mode של **הבודק**, לא ה-demo mode השיווקי
של `appstore-media` ללכידת צילומי מסך.)

### "אני צריך צילומי מסך וסרטון לעמוד ה-App Store"
→ `appstore-media` (ייצור מ-demo flow בכל השפות) → `app-store-metadata` (ארגון
והעלאה). לתמונה בודדת לתיקון גודל בלבד: `apple-app-store-screenshots`.

### "אני רוצה להוציא גרסה חדשה ל-DMG"
→ `apple-credentials` (Developer ID + notary profile) → `notarize-and-distribute`.

### "מתחיל אפליקציה חדשה לגמרי"
→ `ship-apple-app` כ-Playbook שמתזמן: `apple-credentials` → `app-icon-generator`
→ `app-store-review-compliance` → `localization-i18n` → `app-store-metadata`
(+ `appstore-media` / `aso-keywords`) → build → submit.

### "אני מוציא את אותה אפליקציה גם לאנדרואיד"
→ ב-BD TECH: `store-metadata-writer` מתזמר את שתי החנויות מאותו פרופיל (עקבי בין App Store
ל-Play), ומריץ את `app-store-metadata` ו-`play-store-metadata`. עצמאי (בלי פרופיל): הרץ את שניהם —
כתוב את הקופי הבסיסי פעם אחת והתאם לכל חנות (ל-Play אין שדה keywords — הגילוי דרך הטקסט הגלוי).

---

## סקילים מתוכננים (Roadmap)

סקילים שטרם נבנו — מתוכננים להוספה עתידית:

**הפצה ובנייה**
- **app-hosting-updates** — העלאת DMG ל-R2/CDN + Sparkle appcast לעדכונים אוטומטיים (ההמשך של `notarize-and-distribute`).
- **storekit-iap** — הקמת מוצרי IAP, StoreKit config, בדיקות sandbox, Restore.
- **testflight-beta** — העלאה ל-TestFlight, ניהול בודקים, beta notes.
- **release-notes-versioning** — העלאת build/version אוטומטית + "What's New" רב-לשוני מ-git.
- **ci-cd-apple** — GitHub Actions / Xcode Cloud ל-build+test+sign+notarize.
- **swift-deprecation-migrator** — Swift 6 concurrency, העלאת min-OS, APIs מיושנים.

## הערות

- **הפעלה:** הסקילים נטענים אוטומטית לפי ההקשר (ה-description שלהם). אפשר גם
  לבקש במפורש ("תשתמש בסקיל X").
- **מיקום:** `~/.claude/skills/<name>/` — גלובלי, זמין בכל פרויקט.
- **קבצי `.skill`:** עותקים ארוזים לשיתוף/התקנה נמצאים בתיקיית הפרויקט
  (`~/Developer/xcode/OfficeTabsApps/*.skill`).
- **פלטפורמות:** רוב הסקילים ל-macOS + iOS; `play-store-metadata` הוא לאנדרואיד/
  Google Play; הפצה ישירה (DMG) רלוונטית רק ל-macOS.
- **בטיחות:** כל פעולה חיצונית (העלאה, notarization, store-creds, fastlane match)
  דורשת אישור לפני ביצוע.
