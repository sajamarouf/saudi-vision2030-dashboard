# دليل بناء داشبورد رؤية 2030 — خطوة بخطوة

> الهدف: داشبورد Power BI من 5 صفحات بستايل الكروت البيضاء والأخضر (شوفي `design/preview/`)، مبني على بيانات رسمية موثّقة المصدر، بنموذج Star Schema ومقاييس DAX، جاهز للـ GitHub وللمقابلة.

---

## 0) المتطلبات

| الأداة | ملاحظة |
|---|---|
| Power BI Desktop | مجاني من Microsoft Store (ويندوز فقط). على ماك: Parallels أو جهاز ويندوز. |
| SQL Server 2022 Express | مجاني. ابحثي "SQL Server 2022 Express download" على موقع Microsoft → اختاري **Basic**. |
| SSMS (SQL Server Management Studio) | مجاني، لتشغيل السكربتات. |
| Git + حساب GitHub | لنشر المشروع على `github.com/sajamarouf`. |

**هيكل العمل:**

```
data/raw/*.csv  ──(مرجع فقط)
sql/01  جداول stg (خام) + dw (أبعاد)
sql/02  إدخال البيانات  (كل صف معه SourceID)
sql/03  Views: vw_FactKPI (UNPIVOT بـ CROSS APPLY) · vw_GDPLevels · vw_QA_FemaleIdentity
sql/04  فحوصات الجودة
      │
      ▼
Power Query: اتصال بالـ Views + الأنواع + بناء DimQuarter + أعمدة IsFlash / IsPreRevision
      │
      ▼
Power BI: علاقات + DAX + صفحات
```

> **ليش التقسيم هيك؟** SQL للمنطق الثقيل والقابل للمراجعة (unpivot، حسابات الحصص، فحوصات)، و Power Query للأشياء الخاصة بالتقرير (تقويم الأرباع، أعلام للـ tooltip). هاد نفس التقسيم الموجود بالشركات، واحكيه بالمقابلة.

---

## 1) إعداد قاعدة البيانات (SQL Server)

### 1.1 التثبيت
1. شغّلي مثبّت SQL Server Express → **Basic** → Accept → Install.
2. بالنهاية رح يعطيك **Connection string**، أهم شي اسم الـ instance، غالباً:
   `localhost\SQLEXPRESS`
3. نزّلي وثبّتي **SSMS**.

### 1.2 الاتصال
SSMS → نافذة **Connect to Server**:
- Server type: **Database Engine**
- Server name: `localhost\SQLEXPRESS`
- Authentication: **Windows Authentication**
- ✅ **Trust server certificate** (تحت Options أو بالشاشة الرئيسية بالإصدارات الجديدة)
- Connect

### 1.3 تشغيل السكربتات بالترتيب
لكل ملف: **File → Open → File…** → اختاري الملف → **Execute** (F5):

| الترتيب | الملف | شو بيعمل | المتوقع |
|---|---|---|---|
| 1 | `sql/01_create_database_and_tables.sql` | ينشئ قاعدة `Vision2030` و schemas `stg` و `dw` و 9 جداول | *Commands completed successfully* |
| 2 | `sql/02_insert_data.sql` | يدخل 38 ربع بطالة، 22 ربع مشاركة، 7 أرباع ناتج، الأهداف، 25 مصدر | *Commands completed successfully* |
| 3 | `sql/03_create_views.sql` | ينشئ الـ 3 Views | *Commands completed successfully* |
| 4 | `sql/04_quality_checks.sql` | 6 فحوصات + ملخص | **أول 6 نتائج فاضية**، والسابعة جدول 12 مؤشر |

السكربتات **قابلة لإعادة التشغيل**: إذا عدّلتي رقم بملف 02 شغّليه مرة ثانية وبعدين Refresh بـ Power BI.

### 1.4 تأكدي بنفسك
```sql
USE Vision2030;
SELECT COUNT(*) AS rows, COUNT(DISTINCT IndicatorKey) AS indicators,
       MIN(QuarterKey) AS first_q, MAX(QuarterKey) AS last_q
FROM dw.vw_FactKPI;              -- المتوقع: 198 | 12 | 2017Q1 | 2026Q3

SELECT * FROM dw.vw_QA_FemaleIdentity;   -- 8 أرباع، GapPP كلها بين -0.23 و 0.19
SELECT * FROM dw.vw_GDPLevels;           -- NonOilSharePct ≈ 55.43 و 55.13
```

### 1.5 شرح أهم سطر SQL (للمقابلة)
```sql
FROM stg.LabourUnemployment AS u
CROSS APPLY (VALUES ('UR_SA_T', u.SaudiTotal),
                    ('UR_SA_M', u.SaudiMale), ...) AS v (IndicatorKey, Value)
WHERE v.Value IS NOT NULL
```
هاد **unpivot**: بيحوّل كل عمود (ذكور، إناث، إجمالي) لصف مستقل. استخدمت `CROSS APPLY (VALUES …)` بدل `UNPIVOT` لأنو أوضح وبيسمحلي أضيف أعمدة إضافية وأتحكم بالـ NULL.

### 1.6 فحص الهوية المحاسبية
`dw.vw_QA_FemaleIdentity` بتحسب البطالة الضمنية = (المشاركة − نسبة التشغيل) / المشاركة وبتقارنها بالرقم المنشور. لو الفرق أكبر من 0.35 نقطة معناها الأرقام من إصدارات مختلفة. النتيجة الحالية: كل الأرباع الثمانية ضمن ±0.23.

---

## 2) Power Query

### 2.1 الاتصال
1. Power BI Desktop → **Home → Transform data** (يفتح محرر Power Query فاضي).
2. **Home → Manage Parameters → New Parameter**:
   - `pServer` — Type: Text — Current value: `localhost\SQLEXPRESS`
   - `pDatabase` — Type: Text — Current value: `Vision2030`
3. **Home → New Source → Blank Query** → **Advanced Editor** → الصقي كتلة `Vision2030DB` من `powerquery/queries.pq` → Done → سمّي الاستعلام `Vision2030DB`.
   - اضغطي يمين عليه → شيلي ✔ من **Enable load** (مساعد بس، ما بيدخل النموذج).
   - أول مرة رح يسألك عن الصلاحيات: **Windows → Use my current credentials → Connect**. إذا طلع خطأ تشفير: **Encrypt connection** ✗ أو OK على تحذير الـ certificate.

### 2.2 باقي الاستعلامات
نفس الطريقة (Blank Query → Advanced Editor → لصق → إعادة تسمية)، **بهالترتيب** لأنو DimQuarter بيعتمد على FactKPI:

1. `FactKPI`
2. `DimQuarter`
3. `DimIndicator`
4. `DimTarget`
5. `DimSource`
6. `GDPLevels`
7. `GDPAnnual`
8. `QA_FemaleIdentity`

### 2.3 شو بيعمل Power Query بالضبط
| الاستعلام | الخطوات |
|---|---|
| FactKPI | يقرأ `dw.vw_FactKPI` → يحدد الأنواع → يضيف `IsFlash` و `IsPreRevision` |
| DimQuarter | **ما في جدول بالـ SQL**؛ يُبنى بالكامل بـ M: ياخذ أصغر وأكبر ربع من FactKPI، يولّد كل الأرباع بينهم (`{MinAbs .. MaxAbs}`)، ويضيف السنة، الربع، التسمية، تاريخ البداية، `QuarterIndex`، والفترة |
| DimSource | يضيف `IsPrimary` |
| QA_FemaleIdentity | يضيف عمود `Check` = Pass/Fail |

> **Query folding:** خطوات FactKPI البسيطة (الأنواع، الأعمدة الشرطية) بترجع لـ SQL Server وتنفّذ هناك. اضغطي يمين على آخر خطوة → **View Native Query** — إذا ظاهر SQL معناها folding شغّال. DimQuarter ما بيعمل folding لأنو مولّد بـ M، وهاد طبيعي.

### 2.4 ⚠️ مشاكل شائعة
- **الأرقام العشرية غلط** (6.4 صارت 64) بسبب إعدادات عربية: **File → Options and settings → Options → Current File → Regional Settings → Locale for import: English (United States)**.
- **`Expression.Error: The import pServer matches no exports`**: الباراميتر مش منشأ أو اسمه مختلف (حساس لحالة الأحرف).
- **`DataSource.Error … SQLEXPRESS`**: تأكدي إنو خدمة SQL Server شغّالة: ابحثي بالويندوز عن **Services** → `SQL Server (SQLEXPRESS)` → Start.

ثم **Home → Close & Apply**.

---

## 3) نموذج البيانات (Model view)

ارسمي العلاقات (اسحبي العمود على العمود):

```
DimQuarter[QuarterKey]     1 ──→ *  FactKPI[QuarterKey]
DimIndicator[IndicatorKey] 1 ──→ *  FactKPI[IndicatorKey]
DimIndicator[IndicatorKey] 1 ──→ *  DimTarget[IndicatorKey]
```

- اتجاه الفلترة: **Single** في الثلاثة.
- `DimSource`, `GDPAnnual`, `GDPLevels`, `QA_FemaleIdentity` تبقى بدون علاقات (جداول مرجعية).
- **ترتيب التسميات:** اختاري `DimQuarter[QuarterLabel]` → Column tools → **Sort by column → QuarterIndex**.
- أخفي من Report view: `FactKPI[QuarterKey]`, `FactKPI[IndicatorKey]`, `DimTarget[IndicatorKey]`.

> **ليش الجدول الطويل (long format)؟** لأنو كل المؤشرات تشترك بنفس المقاييس (`KPI Value`, `YoY Change pp`, `Progress to Target`) — مقياس واحد يشتغل على 12 مؤشر بدل 12 نسخة. هاد سؤال مقابلات شائع، جاوبي فيه.

---

## 4) المقاييس (DAX)

1. **Home → Enter data** → سمّي الجدول `_Measures` → Load.
2. اختاري الجدول → **New measure** → الصقي كل مقياس من `powerbi/measures.dax` (مقياس لكل مرة؛ السطر الأول هو الاسم).
3. احذفي العمود الافتراضي `Column1` من `_Measures` — رح يصير أيقونة آلة حاسبة فوق.

### التنسيق (مهم جداً)
القيم مخزنة كنقاط مئوية (6.4 مش 0.064)، فـ:
- `KPI Value`, `Latest Value`, `QoQ/YoY Change pp`, `Gap…`, `Female UR…` → **Decimal number، منزلة واحدة**. أضيفي "%" بالـ Display units أو بالعنوان، **مش** صيغة Percentage.
- `Progress to Revised Target %` → **Percentage، بدون منازل** (لأنو كسر من 0 إلى 1).

---

## 5) التصميم (ستايل الكروت البيضاء والأخضر)

الشكل مبني بنفس الطريقة اللي بتشتغل فيها الشركات: **خلفية مصممة جاهزة لكل صفحة** (الكروت، الشريط الجانبي، شريط التنقل، العناوين الثابتة) و**الـ visuals فوقها شفافة**. هيك بتطلعي بزوايا دائرية وظلال وأيقونات ما بيقدر Power BI يرسمها لحاله.

| الملف | الاستخدام |
|---|---|
| `design/preview/page1-5.png` | شكل كل صفحة النهائي ببيانات حقيقية، هاد المرجع |
| `design/backgrounds/bg_page1-5.png` | خلفيات الصفحات (1920×1080) |
| `design/LAYOUT.md` | X / Y / W / H لكل visual بالبكسل |
| `powerbi/vision2030_theme.json` | ألوان + خلفية الـ visuals شفافة + بدون عناوين وحدود |
| `design/mockup.html` | المصدر؛ إذا عدّلتي نص أو كارد، بتعيدي توليد الصور منه |

### 5.1 إعداد الصفحة
1. **View → Themes → Browse for themes** → `powerbi/vision2030_theme.json`.
2. **Format page (فرشاة الرسم بدون ما تختاري أي visual):**
   - **Canvas settings → Type: 16:9** (1280 × 720).
   - **Canvas background → Image → Browse** → `design/backgrounds/bg_page1.png`
     - **Image fit: Fit** ← مهم، مش Normal
     - **Transparency: 0%**
   - **Wallpaper → Color:** `#ECEDEB`.
3. كرري لكل صفحة بالخلفية الخاصة فيها، وسمّي الصفحات: Overview, Labour Market, Women, Diversification, Data & Method.

### 5.2 قاعدة كل visual
الثيم بيعمل هاد تلقائياً، بس تأكدي:
- **General → Effects → Background: Off**، **Visual border: Off**، **Shadow: Off**.
- **Title: Off** (العنوان موجود بالخلفية).
- **Properties → Position / Size:** من `LAYOUT.md`، بس **ضيفي 14 على X و Y، واطرحي 28 من W و H** عشان الـ visual يقعد جوا الكارد. وإذا الكارد فيه عنوان بالخلفية، ضيفي ~45 كمان على Y واطرحيهم من H.
  مثال: الأعمدة بالصفحة 1، الكارد `314, 136, 674, 362` ← الـ visual: `X 328, Y 194, W 646, H 290`.

### 5.3 الألوان
| الدور | اللون |
|---|---|
| أساسي (Non-oil، النساء، السعوديين) | `#0E7C4A` |
| مقارنة (Oil، الرجال، employment ratio) | `#B5832A` (ذهبي) |
| أعمدة عادية | `#A9D4BC` |
| خلفية الكرت الأخضر | `#0E7C4A` → `#0B5F39` |
| خطوط الأهداف (متقطعة) | `#B5832A` |
| سلبي / تراجع | `#B42318` |

اخترت الأخضر والذهبي لأنهم بيتميزوا عن بعض لعمى الألوان كمان (فحصتهم بأداة تحقق: ΔE 8.7 وأكثر)، بينما الأخضر والرمادي كان فاشل.

---

## 6) بناء الصفحات visual بـ visual

> قبل كل صفحة افتحي صورتها من `design/preview/` جنبك.

### الصفحة 1 — Overview

| الكارد | الـ Visual | الإعداد |
|---|---|---|
| **Saudi Unemployment** (الكرت الأخضر) | **Card (new)** | Value = `Saudi Unemployment Latest`. لون الرقم **أبيض** حجم 28، بدون label. Position فوق المستطيل الأخضر: تقريباً `X 98, Y 222, W 170, H 46`. |
| ↳ نص الربع | **Card** صغير | `Latest Quarter Label` (فلتر Visual: UR_SA_T)، أبيض، 9pt، فوق "Latest ·" |
| ↳ Gap | **Card** صغير | `Gap to Revised Target pp`، صيغة `"+"0.0" pp"`، أبيض 9pt، يمين أسفل الكرت الأخضر |
| ↳ شريط التقدم | **Gauge** أو **Bar chart** | `Progress to Revised Target %` (فلتر UR_SA_T). Bar chart أفقي: لون `#0E7C4A`، Max = 1، خلفية الشريط `#E3F1E8`. |
| **Female participation** | **Card (new)** + **Card** صغير | `Female LFPR Latest` (24pt) + `YoY Arrow` ولونه من `YoY Color` |
| **Non-oil activities growth** | **Clustered column chart** | X = `DimQuarter[QuarterLabel]`، Y = `Non-Oil Growth`، فلتر الصفحة: Year ≥ 2025. **Columns → Color → fx → Format style: Field value → `Column Color Latest`** (آخر ربع أخضر غامق، الباقي فاتح). **Columns → Border radius / Corner radius: 10** (بالإصدارات الجديدة من Power BI؛ إذا مش موجود، عادي). **Data labels:** بس لآخر عمود (Series → Apply settings to: per point… أو اتركيها Off). |
| **Unemployment trend** | **Area chart** | X = QuarterLabel، Y = `KPI Value` (فلتر UR_SA_T)، المحاور مخفية (الثيم بيخفيها)، **Constant line** Y = 5 ذهبي متقطع. فوقها **Card** = `Change Since Start pp` (الرقم −6.2). |
| **Vision 2030 scorecard** | **Table** | `DimIndicator[IndicatorName]`، `Latest Value`، `Latest Quarter Label`، `Target 2030 Original`، `Target 2030 Revised`، `Target Status`. فلتر Visual: IndicatorKey بـ (UR_SA_T, LFPR_SA_F, GDP_YOY_NONOIL). |
| **Non-oil share** | **Card** + **Bar chart** | `Non-Oil Share of Real GDP %` + شريط بنفس طريقة شريط التقدم (Max 100) |
| أعلى | **Slicer** | `DimQuarter[QuarterStart]` → Style: **Between**، مكانه فوق الشيب اللي فيه أيقونة التقويم |
| شريط التنقل | **Page navigator** | Insert → Buttons → Navigator → Page navigator. Shape: Pill. Default fill: شفاف 100%. Selected: أبيض، نص `#16201B` Bold. ركّبيه على الـ tabs بالخلفية. |

### الصفحة 2 — Labour Market
| الكارد | الـ Visual |
|---|---|
| 4 كروت فوق | **Card (new)** لكل وحدة: `Saudi Unemployment Latest`؛ `Latest Value` بفلتر UR_KSA_T؛ `Latest Value` بفلتر LFPR_SA_T؛ `Gap to Revised Target pp` (فلتر UR_SA_T). وجنب كل وحدة Card صغير فيه `YoY Arrow`. |
| الرسم الكبير | **Line chart**: X = QuarterLabel، Y = `KPI Value` (فلتر UR_SA_T). **Analytics → Constant line** عند 7 و 5، لون `#B5832A`، Style: Dashed، Data label: Right. **Error bars/Shade:** استخدمي **Shape (Rectangle)** رمادي `#F3F4F2` ورا الخط لحد 2022 Q4 (أو X-axis constant line عند Q1 2023). |
| Reading this chart | النص موجود بالخلفية. ضيفي تحته **Slicer** على `DimQuarter[Period]`، Style: Tile. |

### الصفحة 3 — Women
| الكارد | الـ Visual |
|---|---|
| Labour force participation by sex | **Line chart**: Y = `Female LFPR` و `Male LFPR`، فلتر Year ≥ 2021. Constant lines 30 و 40. Series colors: Women `#0E7C4A`، Men `#B5832A`. |
| Fewer unemployed… | **Line chart**: Y = `Female UR` و `Female EPR`، فلتر Year ≥ 2023 Q4. **Line → Show missing values: Off** عشان الفجوة بـ Q2 2025 تبين (الرقم مش منشور). |
| Denominator effect | **Card** أبيض فوق الكرت الأخضر = `Female UR at Peak Participation` (فلتر الصفحة على الربع 2026Q1)، وتحته Card صغير `Denominator Effect pp`. |
| Progress to 40% | **Card** = `Progress to Revised Target %` (فلتر LFPR_SA_F) + شريط Bar chart. |

### الصفحة 4 — Diversification
| الكارد | الـ Visual |
|---|---|
| 3 كروت | `Non-Oil Growth Latest`، `Latest Value` (GDP_YOY_OIL)، `Latest Value` (GDP_YOY_T) + `Data Note` بخط صغير. |
| Non-oil beat oil | **Card** = `Quarters Non-Oil Beat Oil`. |
| Real growth by activity | **Clustered column**: X = QuarterLabel، Y = `Non-Oil Growth` و `Oil Growth`، فلتر Year ≥ 2025. Colors: Non-oil `#0E7C4A`، Oil `#B5832A`. Tooltip: `Estimate Type`, `Data Note`. |
| Annual growth | **Matrix** أو **Table** من `GDPAnnual` + Card `Non-Oil Share of Real GDP %` + شريط. |

### الصفحة 5 — Data & Method
| الكارد | الـ Visual |
|---|---|
| Sources | **Table**: `DimSource[Publisher]`, `Title`, `SourceType`, `Url` (Data category = Web URL، **Format → URL icon: On**). Conditional formatting على SourceType: primary أخضر، secondary ذهبي. |
| Methodology | النص موجود بالخلفية، ما بدها visual. ممكن تضيفي **Table** `QA_FemaleIdentity` تحت. |

### بعد ما تخلصي
- **View → Selection pane**: سمّي كل visual اسم واضح.
- جرّبي الـ slicer وتأكدي إنو الكروت اللي فيها `Latest` **ما بتتغير** (لأنها مبنية على `ALL ( DimQuarter )`، وهيك مقصود).
- **File → Options → Report settings → Visual options:** ✗ *Use the modern visual header* إذا بدك تخفي الأيقونات فوق الـ visuals بوضع القراءة.

---

## 7) النشر

### صور و PDF
- **File → Export → Export to PDF** → `powerbi/Vision2030_Dashboard.pdf`.
- لقطة شاشة لكل صفحة (Win + Shift + S) → احفظيها في `docs/screenshots/`.

### GitHub
```bash
cd saudi-vision2030-dashboard
git init
git add .
git commit -m "Saudi Vision 2030 analytics dashboard: data pipeline, model, DAX, docs"
git branch -M main
git remote add origin https://github.com/sajamarouf/saudi-vision2030-dashboard.git
git push -u origin main
```
(أنشئي الـ repo فاضي على GitHub أولاً بدون README.)
ارفعي ملف `.pbix` كمان (ما فيه كلمات سر، الاتصال Windows Authentication). إذا حجمه فوق 50MB استخدمي Git LFS: `git lfs track "*.pbix"`.

### Publish to web (اختياري)
يحتاج حساب عمل/جامعة، مش Gmail. بديل: الـ PDF + الصور بالـ README.

---

## 8) نقاط حديث المقابلة (صادقة)

1. **"ليش ما رسمتي خط بطالة واحد من 2017 لـ 2026؟"** — لأنو GASTAT راجعت السلسلة على أساس تعداد 2022؛ قبل 2023 الأرقام من الأساس القديم. فصلتهم بعمود `SeriesVintage` وعلّمتهم بالرسم.
2. **Flash vs final:** تقدير Q3 2025 السريع كان نمو 5.0% والنهائي 4.8%. الداشبورد يحمل `EstimateType` لكل رقم.
3. **أثر المقام (Denominator effect):** انخفاض بطالة النساء جزء منه خروج من سوق العمل. استنتجته من معادلة محاسبية بسيطة، وتحققت منها على 8 أرباع (الفارق ≤ 0.25 نقطة).
4. **الأهداف تحركت:** هدف البطالة 7% → 5%، ومشاركة المرأة 30% → 40%. الداشبورد يعرض الهدفين لأنو "حققنا الهدف" يعتمد على أي هدف.

## 9) حدود المشروع (اذكريها بنفسك قبل ما يسألوك)

- بعض الأرقام من مصادر ثانوية (Argaam, Gulf News, EnterpriseAM) تنقل عن GASTAT. الخطوة التالية: تنزيل ملفات Excel الرسمية من stats.gov.sa وتعديل `sql/02_insert_data.sql` (عمود `SourceType` بـ `dw.DimSource` بيوضح أي مصدر ثانوي).
- بطالة السعوديين 2025Q2 (6.8%) **مشتقة** من مقارنة سنوية منشورة، مش منقولة مباشرة.
- 2026Q2 للناتج: الإجمالي وغير النفطي معدّلين، النفطي والحكومي لسا تقدير سريع.
- حصة غير النفطي من الناتج متوفرة لربعين فقط (Q3 2024 و Q3 2025).
- البيانات ربعية، ونسب فقط (GASTAT ما تنشر أعداد LFS).
