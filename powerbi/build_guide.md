# Power BI Step-by-Step Build Guide
## Bank Term Deposit Campaign Effectiveness Analytics

**Read before opening Power BI Desktop.**
Follow this guide in sequence. Each step builds on the previous one.
Estimated total build time: 4–5 hours.

---

## PRE-BUILD CHECKLIST

Before opening Power BI:

- [ ] `bank_analysis.csv` exists in `data/processed/` (45,211 rows, 26 columns)
- [ ] `campaign_roi_summary.csv` exists in `data/processed/` (3 rows)
- [ ] `monthly_summary.csv` exists in `data/processed/` (12 rows)
- [ ] `segment_summary.csv` exists in `data/processed/` (653 rows)
- [ ] Power BI Desktop is installed (latest version)
- [ ] `dax_measures_library.dax` is open in a text editor alongside Power BI
- [ ] `dashboard_specification.md` is open for reference

---

## STEP 1 — NEW REPORT & CANVAS SETUP

1. Open Power BI Desktop → **Blank Report**
2. View → **Page View → Actual Size**
3. View → **Page View → Fit to Page**
4. File → **Options and Settings → Options → Report Settings**
   - Canvas background: `#F7F7F5`
5. Right-click Page 1 tab → **Rename** → `Executive Overview`
6. Add two more pages:
   - Right-click → Add Page → rename `Customer Intelligence`
   - Right-click → Add Page → rename `Campaign Optimiser`

---

## STEP 2 — LOAD DATA

### 2A. Load bank_analysis.csv

1. Home → **Get Data → Text/CSV**
2. Browse to `data/processed/bank_analysis.csv` → Open
3. In the preview dialog:
   - Delimiter: **Comma**
   - Data Type Detection: **Do not detect data types** ← important
4. Click **Transform Data** (NOT Load)
5. In Power Query Editor:
   - Home → **Advanced Editor**
   - Replace the entire script with Script 1 from `power_query_transformations.pq`
   - Update the file path in the `File.Contents()` line to your actual path
   - Click **Done**
6. Verify in the preview: 45,211 rows, 26 columns
7. Rename the query: right-click query name → rename to `bank_analysis`

### 2B. Load campaign_roi_summary.csv

1. Home → **New Source → Text/CSV**
2. Browse to `campaign_roi_summary.csv` → Transform Data
3. Advanced Editor → paste Script 2 → update path → Done
4. Rename query: `campaign_roi_summary`

### 2C. Load monthly_summary.csv

1. Same process → paste Script 3 → rename: `monthly_summary`

### 2D. Load segment_summary.csv

1. Same process → paste Script 4 → rename: `segment_summary`

### 2E. Apply & Close

1. Home → **Close & Apply**
2. Wait for all 4 tables to load
3. Verify in Fields pane: all 4 tables visible with correct column names

---

## STEP 3 — CREATE MEASURES TABLE

1. Home → **Enter Data**
2. In the table grid: leave it empty (no columns needed)
3. Name: `_Measures`
4. Click **Load**
5. The `_Measures` table now appears in Fields pane

### Add All DAX Measures

For each measure in `dax_measures_library.dax`:

1. Click the `_Measures` table in Fields pane to select it
2. **Table Tools → New Measure** (or Home → New Measure)
3. In the formula bar: paste the measure
4. Press **Enter** or click the ✓ checkmark
5. Repeat for all 46 measures

**Tip:** Work through groups A→G in order. Each group's measures may depend
on measures defined earlier in the same group (e.g., [Total Subscriptions]
is used inside [Conversion Rate %]).

---

## STEP 4 — APPLY COLOUR THEME

1. View → **Themes → Customise Current Theme**
2. Name: `BankX Analytics`
3. Set these colours:

| Setting | Hex |
|---|---|
| First datacolour | `#1D9E75` |
| Second datacolour | `#E24B4A` |
| Third datacolour | `#378ADD` |
| Fourth datacolour | `#7F77DD` |
| Fifth datacolour | `#EF9F27` |
| Background | `#F7F7F5` |
| Second background | `#FFFFFF` |
| Foreground | `#2C2C2C` |
| Second foreground | `#6B6B6B` |

4. Click **Apply** → **Save current theme**
5. Save the .json file as `powerbi/bankx_theme.json`

---

## STEP 5 — PAGE 1: EXECUTIVE OVERVIEW

Navigate to the **Executive Overview** page.

### 5A. Page Header

1. Insert → **Text Box**
2. Type: `BankX | Term Deposit Campaign — Executive Overview`
3. Font: Segoe UI, 18pt, Bold, colour `#2C2C2C`
4. Position: X=20, Y=10, Width=1240, Height=35

5. Insert → **Text Box** (second line)
6. Type: `45,211 Customer Contacts  ·  May 2008 – Nov 2010  ·  Direct Marketing Division`
7. Font: Segoe UI, 11pt, colour `#6B6B6B`
8. Position: X=20, Y=48, Width=1240, Height=22

---

### 5B. KPI Card Row (5 cards)

Add 5 **Card** visuals across the top:

**Card 1 — Total Contacts**
- Visualizations pane → **Card**
- Fields: drag `Total Contacts` from `_Measures`
- Format → Callout value → Font: Segoe UI Bold 28pt, colour `#2C2C2C`
- Format → Category label → Text: "Total Contacts", Font 10pt, `#6B6B6B`
- Format → General → Background ON, colour `#FFFFFF`, transparency 0%
- Format → General → Border ON, colour `#E0E0E0`, rounded corners ON
- Position: X=20, Y=80, W=225, H=90

**Card 2 — Total Subscriptions**
- Measure: `Total Subscriptions`
- Label: "Subscriptions"
- Callout value colour: `#1D9E75`
- Same size and style as Card 1
- Position: X=255, Y=80

**Card 3 — Conversion Rate %**
- Measure: `Conversion Rate %`
- Label: "Conversion Rate"
- Format: Callout value → `0.00` with `%` suffix (or use `Conversion Rate Formatted`)
- Conditional formatting on callout value colour:
  - Format → Callout value → Font colour → Conditional formatting
  - Format style: Rules
  - Rule: If value ≥ 11.7 → `#1D9E75` else → `#E24B4A`
- Position: X=490, Y=80

**Card 4 — Cost Per Acquisition**
- Measure: `Cost Per Acquisition INR`
- Label: "Cost Per Acquisition"
- Format: `₹#,##0` (or use `CPA Formatted`)
- Callout colour: `#2C2C2C`
- Position: X=725, Y=80

**Card 5 — Wasted Spend**
- Measure: `Wasted Spend Lakh`
- Label: "Wasted Spend (₹ Lakh)"
- Format: `₹0.00L` (or use `Wasted Spend Formatted`)
- Callout colour: `#E24B4A` (always red — this is the cost of inaction)
- Position: X=960, Y=80

---

### 5C. Monthly Volume vs Conversion Rate (Line & Column Chart)

1. Visualizations → **Line and Clustered Column Chart**
2. Data fields:
   - X-axis: `monthly_summary[month]`
   - Column Y-axis: `monthly_summary[Total_Contacts]`
   - Line Y-axis: `monthly_summary[Conversion_Rate_Pct]`
3. Format → Columns → Colour: `#378ADD`, Transparency: 70%
4. Format → Lines → Colour: `#1D9E75`, Stroke width: 2.5pt
5. Format → Lines → Show marker: ON, marker size: 8
6. Format → Data labels → ON for line series only, font 8pt
7. Format → X-axis → Sort: by `month_num` (Ascending)
   - Right-click `month` column in Fields → Sort by column → `month_num`
8. Add reference line:
   - Analytics pane → Constant line → Value: 11.7
   - Label: "Overall avg: 11.7%", Style: Dashed, Colour: `#2C2C2C`
9. Title: "Monthly Campaign Volume vs Conversion Rate"
10. Position: X=20, Y=185, W=620, H=280

Add insight text box below chart:
- "⚠ May: 30.4% of all calls but only 6.7% conversion — the lowest of any month"
- Font: 9pt, colour `#E24B4A`, italic

---

### 5D. Conversion Funnel

1. Visualizations → **Funnel**

First, create a static funnel table:
- Home → **Enter Data**
- Two columns: `Stage` (text) and `Value` (number)

| Stage | Value |
|---|---|
| All Contacts | 45211 |
| Valid Calls (duration > 0) | 45208 |
| Calls > 1 Minute | 36673 |
| Subscriptions | 5289 |

- Name: `funnel_data` → Load

2. Funnel visual:
   - Category: `funnel_data[Stage]`
   - Values: `funnel_data[Value]`
3. Format → Data labels: ON (percentage + value)
4. Format → Colours: gradient from `#378ADD` → `#1D9E75`
5. Title: "Campaign Conversion Funnel"
6. Position: X=655, Y=185, W=300, H=280

---

### 5E. ROI Scenario Comparison (Two Bar Charts)

**Chart 1 — Conversion Rate by Scenario**
1. Visualizations → **Clustered Bar Chart**
2. Y-axis: `campaign_roi_summary[Scenario]`
3. X-axis: `campaign_roi_summary[Conversion_Rate_Pct]`
4. Format → Bars → Apply colour per category: ON
   - Scenario A: `#E24B4A`
   - Scenario B: `#EF9F27`
   - Scenario C: `#1D9E75`
5. Format → Data labels: ON, format "0.0%"
6. Title: "Conversion Rate by Targeting Scenario"
7. Position: X=970, Y=185, W=290, H=130

**Chart 2 — CPA by Scenario**
1. Duplicate Chart 1 (Ctrl+C, Ctrl+V)
2. Change X-axis to: `campaign_roi_summary[Cost_Per_Acquisition]`
3. Format → Data labels: format "₹#,##0"
4. Title: "Cost Per Acquisition by Scenario"
5. Position: X=970, Y=325, W=290, H=130

**Callout text box:**
- Text: `Scenario C: ₹476 CPA vs ₹1,282 current — 63% cost reduction`
- Font: 9pt Bold, colour `#1D9E75`
- Position: X=970, Y=460, W=290, H=35

---

### 5F. Outcome Donut Chart

1. Visualizations → **Donut Chart**
2. Legend: `bank_analysis[y]`
3. Values: `Total Contacts` measure
4. Format → Slices → Subscribed (yes): `#1D9E75`, Not subscribed (no): `#E24B4A`
5. Format → Detail labels: Category + Percent
6. Format → Inner radius: 60%
7. Title: "Overall Outcome Split"
8. Position: X=655, Y=470, W=300, H=200

---

## STEP 6 — PAGE 2: CUSTOMER INTELLIGENCE

Navigate to **Customer Intelligence** page.

### 6A. Copy Page Header from Page 1

1. Go to Page 1 → Select both header text boxes → Ctrl+C
2. Go to Page 2 → Ctrl+V
3. Edit title text to: `BankX | Customer Intelligence — Who Converts?`
4. Edit subtitle to: `Conversion rate by demographic profile · All slicers apply globally`

---

### 6B. Slicer Panel (left column)

Add 4 **Slicer** visuals stacked vertically on the left side:

**Slicer 1 — Age Band**
1. Visualizations → **Slicer**
2. Field: `bank_analysis[age_band]`
3. Format → Slicer settings → Style: Dropdown
4. Format → Header → Text: "Filter by Age Band"
5. Format → Background: `#FFFFFF`, border `#E0E0E0`
6. Position: X=10, Y=80, W=190, H=60
7. Default: Select All

**Slicer 2 — Job Type**
- Field: `bank_analysis[job]`, Style: Dropdown
- Header: "Filter by Job Type"
- Position: X=10, Y=150, W=190, H=60

**Slicer 3 — Education**
- Field: `bank_analysis[education]`, Style: Dropdown
- Header: "Filter by Education"
- Position: X=10, Y=220, W=190, H=60

**Slicer 4 — Debt Profile**
- Field: `bank_analysis[debt_burden_flag]`, Style: Dropdown
- Header: "Filter by Debt Profile"
- Position: X=10, Y=290, W=190, H=60

**Sync slicers across pages:**
1. View → **Sync Slicers**
2. For each slicer: check both "Sync" and "Visible" for Page 2 only
   (These filters are page 2 specific — don't sync to Page 1 or 3)

---

### 6C. Conversion by Job Type (Horizontal Bar)

1. Visualizations → **Bar Chart (Clustered)**
2. Y-axis: `bank_analysis[job]`
3. X-axis: `Segment Conversion Rate %`
4. Sort: Descending by X-axis value
   - Click the `...` menu on the visual → Sort axis → Segment Conversion Rate % → Descending
5. Format → Bars → Conditional formatting → Field value → `Above Average Flag`
   - If value = 1 → `#1D9E75`, if value = 0 → `#E24B4A`
6. Format → Data labels: ON, format "0.0%", font 9pt bold
7. Tooltips: add `Total Contacts`, `Total Subscriptions`, `Segment Lift Label`
8. Analytics → Constant line: Value 11.7, label "Overall avg: 11.7%", dashed
9. Title: "Conversion Rate by Occupation"
10. Position: X=210, Y=80, W=400, H=290

---

### 6D. Conversion by Age Band (Column Chart)

1. Visualizations → **Clustered Column Chart**
2. X-axis: `bank_analysis[age_band]`
3. Y-axis: `Segment Conversion Rate %`
4. Sort: by age_band (ascending — prefix numbers handle this)
5. Conditional colour: same rule as 6C
6. Data labels: ON, "0.0%"
7. Reference line: 11.7
8. Title: "Conversion Rate by Age Band"
9. Position: X=620, Y=80, W=380, H=290

**Callout card next to chart:**
- Add a **Card** visual
- Measure: `Persona A Conversion %` (proxy for retired segment)
- Label: "Retired Customers (61+)"
- Background: `#E1F5EE`, text: `#0F6E56`
- Position: X=1010, Y=80, W=240, H=90

---

### 6E. Education × Marital Matrix

1. Visualizations → **Matrix**
2. Rows: `bank_analysis[education]`
3. Columns: `bank_analysis[marital]`
4. Values: `Segment Conversion Rate %`
5. Format → Cell elements → Background colour → Conditional formatting:
   - Format style: Gradient
   - Min value: 0%, colour `#E24B4A`
   - Mid value: 11.7%, colour `#FFFFFF`
   - Max value: 30%, colour `#1D9E75`
6. Format → Values → Font: 9pt bold
7. Title: "Conversion Rate (%): Education × Marital Status"
8. Position: X=210, Y=380, W=380, H=200

---

### 6F. Debt Burden Impact (Column Chart)

1. Visualizations → **Clustered Column Chart**
2. X-axis: `bank_analysis[debt_burden_flag]`
3. Y-axis: `Segment Conversion Rate %`
4. Manual bar colours:
   - "Debt Free": `#1D9E75`
   - "Housing Loan Only": `#EF9F27`
   - "Personal Loan Only": `#EF9F27`
   - "Dual Debt Burden": `#E24B4A`
5. Data labels: ON, "0.0%"
6. Reference line: 11.7
7. Title: "Impact of Debt Burden on Conversion Rate"
8. Position: X=620, Y=380, W=380, H=200

Annotation text box below:
- "Debt-Free → 18.2%  |  Dual Debt → 6.1%  |  3× difference"
- Font 9pt, colour `#2C2C2C`

---

### 6G. Balance Tier Conversion (Column Chart)

1. Visualizations → **Clustered Column Chart**
2. X-axis: `bank_analysis[balance_tier]`
3. Y-axis: `Segment Conversion Rate %`
4. Conditional colour: ≥11.7 green, <11.7 red
5. Data labels: ON, "0.0%"
6. Reference line: 11.7
7. Title: "Conversion Rate by Account Balance Tier"
8. Position: X=210, Y=590, W=380, H=110

---

### 6H. Customer Persona Cards (4 cards, bottom row)

Add 4 **Card** visuals in a 2×2 grid:

| Card | Measure | Label | Background |
|---|---|---|---|
| Persona A | `Persona A Conversion %` | "Persona A: Loyal Retiree" | `#E1F5EE` |
| Persona B | `Persona B Conversion %` | "Persona B: Affluent Professional" | `#E6F1FB` |
| Persona C | `Persona C Conversion %` | "Persona C: Financial Student" | `#EEEDFE` |
| Persona D | `Persona D Conversion %` | "Persona D: Over-Leveraged (Avoid)" | `#FCEBEB` |

Position: X=620, Y=590, W=630, H=120 (distribute 4 cards evenly across this area)

Add small text box below persona cards:
"🟢 Personas A & B = Wave 1 priority calls  ·  🟡 Persona C = Wave 2  ·  🔴 Persona D = Deprioritise"

---

## STEP 7 — PAGE 3: CAMPAIGN OPTIMISER

Navigate to **Campaign Optimiser** page.

### 7A. Page Header (copy and edit from Page 1)

Title: `BankX | Campaign Optimiser — How to Run the Next Campaign`
Subtitle: `Timing · Contact Frequency · Warm Lead Strategy · Channel Performance`

---

### 7B. Campaign Fatigue Curve (Line Chart)

1. Visualizations → **Line Chart**
2. X-axis: `bank_analysis[campaign]`
3. Y-axis: `Segment Conversion Rate %`
4. Visual-level filter: campaign ≤ 10 (right-click `campaign` in Filters pane)
5. Format → Lines → Colour: `#378ADD`, width 2.5pt
6. Format → Markers: ON, size 8, colour `#378ADD`
7. Format → Data labels: ON, 8pt
8. Analytics → Constant line (X-axis): Value 3.5, colour `#E24B4A`, dashed
   Label: "3-Call Cap Recommendation"
9. Analytics → Constant line (Y-axis): Value 11.7, dashed, label "Overall avg"
10. Title: "Campaign Fatigue: Conversion Drops 60% from Call 1 to Call 6+"
11. Position: X=20, Y=80, W=450, H=250

**Three diagnostic cards alongside:**

Card: `Excess Contacts` — "Contacts Above 3-Call Cap" — colour `#E24B4A`
Card: `Excess Spend Lakh` — "Wasted Spend on Excess Calls (₹L)" — colour `#E24B4A`
Card: `Subscriptions Lost at 3 Call Cap` — "Subscriptions in Excess Calls" — `#EF9F27`

Position cards: X=480, Y=80, distribute 3 cards vertically down to Y=250

---

### 7C. Contact Frequency Band (Column Chart)

1. Visualizations → **Clustered Column Chart**
2. X-axis: `bank_analysis[contact_frequency_band]`
3. Y-axis: `Segment Conversion Rate %`
4. Manual bar colours:
   - "1. Single Contact": `#1D9E75`
   - "2. Light (2-3 calls)": `#EF9F27`
   - "3. Moderate (4-5 calls)": `#E24B4A`
   - "4. Heavy (6+ calls)": `#8B0000`
5. Data labels: ON, "0.0%"
6. Reference line: 11.7
7. Title: "Conversion by Contact Frequency Band"
8. Position: X=660, Y=80, W=350, H=250

**Savings callout text box:**
"Implementing a 3-call cap saves ₹14.5 Lakh while retaining 95% of subscription volume"
Font 9pt, background `#FFF8E1`, border `#EF9F27`
Position: X=1020, Y=80, W=240, H=80

---

### 7D. Monthly Conversion Rate Ranked (Horizontal Bar)

1. Visualizations → **Clustered Bar Chart**
2. Y-axis: `monthly_summary[month]`
3. X-axis: `monthly_summary[Conversion_Rate_Pct]`
4. Sort: Descending by Conversion_Rate_Pct
5. Conditional colour on bars:
   - Format → Data colours → Conditional formatting → Rules
   - Rule: If value ≥ 11.7 → `#1D9E75` else → `#E24B4A`
6. Data labels: ON, "0.0%"
7. Analytics → Constant line: 11.7, dashed
8. Title: "Best & Worst Months by Conversion Rate (Best → Worst)"
9. Position: X=20, Y=345, W=320, H=340

**Annotation text box:**
"March (52.0%) converts at 7.8× the rate of May (6.7%)"
Font 9pt bold, colour `#1D9E75`

---

### 7E. Warm Lead Analysis

**Three KPI Cards (horizontal row):**

Card 1: `Warm Lead Count` — "Priority Warm Leads in Database"
Card 2: `Warm Lead Conversion Rate %` — "Warm Lead Conversion Rate" — background `#E1F5EE`
Card 3: `Warm Lead Multiplier Formatted` — "Multiplier vs Cold Leads" — background `#E1F5EE`

Position: X=355, Y=345, W=650, H=75

**Bar chart — poutcome conversion:**
1. Visualizations → **Clustered Bar Chart**
2. Y-axis: `bank_analysis[poutcome]`
3. X-axis: `Segment Conversion Rate %`
4. Sort: Descending
5. Manual colours: success `#1D9E75`, other `#378ADD`, failure `#EF9F27`, unknown `#E24B4A`
6. Data labels: ON, "0.0%"
7. Reference line: 11.7
8. Title: "Conversion Rate by Previous Campaign Outcome"
9. Position: X=355, Y=428, W=320, H=260

---

### 7F. Call Duration Diagnostic

**Two KPI Cards:**

Card 1: `Avg Duration Subscribers` — "Avg Duration: Subscribers (sec)" — `#1D9E75`
Card 2: `Avg Duration Non-Subscribers` — "Avg Duration: Non-Subscribers (sec)" — `#E24B4A`
Card 3: `Duration Ratio Formatted` — "Subscribers Speak" — `#2C2C2C`

Position: X=685, Y=345, W=575, H=75

**Disclaimer text box (mandatory):**
"⚠ Duration is a post-call metric only. Do not use for targeting decisions.
   Apply these findings to agent training and call quality benchmarking."
Font 8pt italic, colour `#E24B4A`, background `#FFF0F0`
Position: X=685, Y=428, W=295, H=60

**Call quality band bar chart:**
1. Y-axis: `bank_analysis[call_quality_band]`
2. X-axis: `Segment Conversion Rate %`
3. Sort: Descending
4. Conditional colour: ≥11.7 green, <11.7 red
5. Data labels: ON
6. Title: "Conversion by Call Quality Band (Diagnostic)"
7. Position: X=685, Y=495, W=575, H=195

---

### 7G. Contact Channel Performance

1. Visualizations → **Clustered Column Chart**
2. X-axis: `bank_analysis[contact]`
3. Y-axis: `Segment Conversion Rate %`
4. Manual colours: cellular `#1D9E75`, telephone `#EF9F27`, unknown `#E24B4A`
5. Data labels: ON, "0.0%"
6. Reference line: 11.7
7. Title: "Conversion Rate by Contact Channel"
8. Position: X=355, Y=600, W=320, H=90

---

## STEP 8 — PAGE NAVIGATION BUTTONS

Add navigation buttons to the top-right of EVERY page:

1. Insert → **Buttons → Navigator → Page Navigator**
   Power BI will auto-create buttons for all 3 pages.
2. Format → Style:
   - Default state: Fill colour `#F7F7F5`, border `#E0E0E0`, text `#6B6B6B`
   - Selected state: Fill `#1D9E75`, text `#FFFFFF`
   - Hover state: Fill `#E1F5EE`, text `#0F6E56`
3. Position: X=1060, Y=10, W=200, H=55
4. Copy the navigation group → paste on Pages 2 and 3

---

## STEP 9 — REPORT-LEVEL FILTER

This filter applies to ALL pages and ensures zero-duration calls are excluded
from conversion calculations (only 3 records, but correct practice):

1. Click on empty canvas (no visual selected)
2. Filters pane → **Add data to filters → Add filter**
3. Field: `bank_analysis[valid_call_flag]`
4. Filter type: Basic filtering
5. Value: **1** (checked)
6. Apply filter → mark as "Not available for end user to change"

---

## STEP 10 — FINAL REVIEW & SCREENSHOTS

### Quality checklist:
- [ ] All 5 KPI cards on Page 1 showing correct values
- [ ] Monthly chart sorted Jan→Dec (not alphabetically)
- [ ] All bar/column charts sorted by value (not alphabetically)
- [ ] All reference lines at 11.7% visible
- [ ] Slicers on Page 2 working (test by selecting "retired" in job slicer)
- [ ] All persona cards showing unique values (not all showing 11.7%)
- [ ] Fatigue curve showing decay from 14.6% to ~5.8%
- [ ] Warm lead multiplier card showing ~7.07
- [ ] Navigation buttons working on all 3 pages
- [ ] Duration disclaimer text box visible on Page 3
- [ ] Report-level filter active (visible in Filters pane)

### Screenshot each page:
1. Go to each page
2. File → **Export → Export to PDF** (for full report)
   OR: Use Windows Snipping Tool / Mac Screenshot for individual pages
3. Save screenshots to `assets/screenshots/`:
   - `powerbi_page1_executive.png`
   - `powerbi_page2_customer.png`
   - `powerbi_page3_optimiser.png`
4. These go into the GitHub README

### Save the report:
- File → **Save As** → `powerbi/bank_campaign_dashboard.pbix`

---

## WHAT TO SAY IN INTERVIEWS ABOUT THE DASHBOARD

**Q: Walk me through your Power BI dashboard.**

> "The dashboard has three pages, each designed for a specific audience.
> Page 1 is the Executive Command Centre — it shows the campaign's headline KPIs,
> a monthly trend chart that reveals the May paradox where 30% of calls produce
> the lowest conversion rate, a conversion funnel, and a three-scenario ROI comparison
> showing what happens if we apply targeted outreach.
>
> Page 2 is Customer Intelligence — it answers 'who should we call?'
> It has four slicers so the campaign manager can self-serve any demographic cut,
> and it shows conversion rates across job type, age band, debt burden, and balance tier.
> The four customer personas at the bottom give a named, memorable summary of the key findings.
>
> Page 3 is the Campaign Optimiser — it answers 'how should we run the next campaign?'
> It shows the fatigue curve, warm lead multiplier, best months to call, and call
> channel performance. Every recommendation on this page is directly actionable
> by the campaign team without needing a data analyst in the room."

**Q: How many DAX measures did you write?**

> "46 measures across seven groups — core KPIs, cost and ROI calculations,
> segment intelligence, campaign diagnostics, warm lead analysis, customer personas,
> and display formatting. The most important design decision was using ALL() in the
> benchmark rate measure so segment lift always compares against the true overall average,
> not the filtered view."

**Q: Why did you use CSV exports from MySQL rather than connecting Power BI directly to the database?**

> "This is a portfolio project running on a local MySQL instance, so a live
> DirectQuery connection isn't practical for sharing. In a production environment,
> I would use DirectQuery or a scheduled refresh to keep the dashboard live.
> The important principle is the same either way: all data transformation and
> business logic lives in the SQL layer — Power BI only handles visualisation."

---

*Phase 4 Build Guide — BCA-2025-001 | Analyst: Ritik*
