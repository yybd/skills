# מדריך משפחת סקילי Apple

מדריך לכל הסקילים שנבנו לפיתוח והוצאת אפליקציות macOS/iOS — מה כל אחד עושה,
מי הבעלים של מה, התלויות ביניהם, ודוגמאות שימוש.

עודכן: 2026-06-03 · מיקום הסקילים: `~/.claude/skills/`

---

## סקירה — 8 הסקילים

| סקיל | במשפט אחד | סוג |
|------|-----------|-----|
| **ship-apple-app** | Playbook מתזמן: מ-bundle ID ועד submit ל-App Store | מתזמן |
| **apple-credentials** | בעלים יחיד של תעודות + credentials (יצירה, p12., notary, API key) | בעלים |
| **code-signing-provisioning** | מודל חתימה, profiles, אבחון, פענוח שגיאות חתימה | אבחון |
| **app-store-review-compliance** | תאימות למדריך הביקורת של אפל (מונע דחיות) | בדיקה+תיקון |
| **apple-hig-design-review** | סקירת עיצוב/נגישות מול ה-HIG (המלצות מדורגות) | ייעוץ |
| **app-store-metadata** | מטא-דאטה רב-לשוני דרך fastlane + אימות מול דרישות אפל | בנייה+בדיקה |
| **app-icon-generator** | יצירת AppIcon set לכל הפלטפורמות מתמונה אחת | יצירה |
| **localization-i18n** | לוקליזציה בתוך האפליקציה: מחרוזות, טקסט קשיח, שלמות תרגום, RTL | בדיקה+תיקון |
| **notarize-and-distribute** | הפצה ישירה: DMG → חתימה → notarization → אימות | ביצוע |
| **app-store-reviews-responder** | מעקב אחר ביקורות משתמשים וניסוח תשובות | אחרי שחרור |
| **aso-keywords** | אופטימיזציית מילות מפתח (ASO) לגילוי בחיפוש | אחרי שחרור |

---

## מי הבעלים של מה (מקור אמת יחיד)

העיקרון: כל נושא שייך לסקיל אחד; השאר **שואבים** ממנו (ואם לא מותקן — fallback מקומי).

| נושא | בעלים | מי שואב ממנו |
|------|-------|--------------|
| תעודות, יצירה, `.p12`, app-specific password, notary profile, API key | **apple-credentials** | code-signing, notarize-and-distribute, ship-apple-app, app-store-metadata |
| מודל חתימה, provisioning profiles, שגיאות חתימה, אבחון | **code-signing-provisioning** | ship-apple-app |
| כללי ביקורת + demo mode + privacy manifest + entitlements מוצדקים | **app-store-review-compliance** | ship-apple-app |
| מטא-דאטה + צילומי מסך (גודל) | **app-store-metadata** | ship-apple-app |
| התאמת גודל צילומי מסך | **apple-app-store-screenshots** (מובנה) | app-store-metadata |
| לוקליזציה בתוך האפליקציה (מחרוזות, תרגום, RTL) | **localization-i18n** | — |
| אייקונים | **app-icon-generator** | — |
| ביקורות משתמשים + תשובות | **app-store-reviews-responder** | — |
| מילות מפתח / ASO | **aso-keywords** | (קורא מ-app-store-metadata) |
| עיצוב/נגישות | **apple-hig-design-review** | ship-apple-app (אופציונלי) |

---

## מפת תלויות

```
                          ┌─────────────────┐
                          │  ship-apple-app │  (מתזמן את כל מסלול ה-App Store)
                          └────────┬────────┘
        ┌──────────────┬───────────┼───────────┬──────────────┐
        ▼              ▼           ▼            ▼              ▼
 apple-credentials  code-signing  compliance  hig-review   app-store-metadata
        ▲              │                                        │
        │              │ (שואב תעודות)                          ▼
        └──────────────┘                              apple-app-store-screenshots
        ▲
        │ (שואב תעודות + notary)
 notarize-and-distribute   ← מסלול נפרד: הפצה ישירה (DMG), לא App Store

 app-icon-generator   ← עצמאי, ללא תלויות
```

עקרון ה-fallback: אם סקיל שואב לא מוצא את הבעלים (למשל `apple-credentials` לא
מותקן), הוא מבצע גרסה מקומית מצומצמת בעצמו (בד"כ הדרכה דרך Xcode) וממשיך.

---

## שני המסלולים העיקריים

### מסלול א' — App Store / Mac App Store
```
ship-apple-app מתזמן:
1. זהות        → apple-credentials (Apple Distribution) + code-signing-provisioning
2. רשומת אפליקציה → App Store Connect (אתר)
3. תאימות       → app-store-review-compliance
4. עיצוב        → apple-hig-design-review (אופציונלי)
5. מטא-דאטה     → app-store-metadata (+ app-icon-generator לאייקון)
6. build/archive/upload
7. השלמה באתר   → age rating, pricing, App Privacy
8. submit
```

### מסלול ב' — הפצה ישירה (DMG, מחוץ ל-App Store)
```
1. תעודה        → apple-credentials (Developer ID Application)
2. credential   → apple-credentials (notary profile מ-app-specific password)
3. ארוז+חתום+notarize+staple+אמת → notarize-and-distribute
```

---

## דוגמאות שימוש (משפטים שמפעילים כל סקיל)

**ship-apple-app**
- "איך אני מעלה את האפליקציה ל-App Store מאפס?"
- "תעבור איתי על כל תהליך השליחה צעד-צעד"

**apple-credentials**
- "איזו תעודה אני צריך כדי להעלות ל-App Store?"
- "תבדוק אילו תעודות ו-credentials יש לי"
- "אני צריך לייצא את התעודה ל-`.p12` בשביל GitHub Actions"
- "תקים לי פרופיל notary מ-app-specific password"

**code-signing-provisioning**
- "קיבלתי 'Provisioning profile doesn't include signing certificate' — מה לעשות?"
- "תאבחן לי את הגדרות החתימה בפרויקט"

**app-store-review-compliance**
- "למה אפל דחתה את האפליקציה? Guideline 2.1"
- "תבדוק את הפרויקט מול מדריך הביקורת לפני שאני שולח"

**apple-hig-design-review**
- "תעשה סקירת עיצוב — האם ה-UI מרגיש native?"
- "תבדוק נגישות (VoiceOver / Dynamic Type)"

**app-store-metadata**
- "תכין מטא-דאטה ל-App Store בעברית ואנגלית"
- "תאמת שכל הטקסטים בתוך מגבלות התווים של אפל"

**app-icon-generator**
- "תייצר אייקון לאפליקציה בכל הגדלים מהתמונה הזו"
- "אין לי אייקון — תיצור לי אחד התחלתי"

**notarize-and-distribute**
- "תבנה DMG, תחתום ותעשה notarization"
- "המשתמשים מקבלים 'app is damaged' — תתקן"

---

## תרחישי קצה-לקצה

### "שלחתי לאפל ונדחיתי על 2.1 (demo mode)"
→ `app-store-review-compliance` מאבחן את חוסר ה-demo, מתקן/מנסח demo mode +
review notes. (זה התרחיש האמיתי שממנו התחלנו.)

### "אני רוצה להוציא גרסה חדשה ל-DMG"
→ `apple-credentials` (לוודא Developer ID + notary profile) → `notarize-and-distribute`
(build → sign → notarize → verify).

### "מתחיל אפליקציה חדשה לגמרי"
→ `ship-apple-app` כ-Playbook, שמתזמן: `apple-credentials` (זהות) →
`app-icon-generator` (אייקון) → `app-store-review-compliance` (תאימות) →
`app-store-metadata` (רישום) → build → submit.

---

## סקילים מתוכננים (Roadmap)

סקילים שטרם נבנו — מתוכננים להוספה עתידית למשפחה:

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
- **פלטפורמות:** הכול תומך macOS + iOS; הפצה ישירה (DMG) רלוונטית רק ל-macOS.
- **בטיחות:** כל פעולה חיצונית (העלאה, notarization, store-creds, fastlane match)
  דורשת אישור לפני ביצוע.
