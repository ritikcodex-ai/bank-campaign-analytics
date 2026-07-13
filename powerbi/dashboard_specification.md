# Phase 4 — Power BI Dashboard Build Specification
## Bank Term Deposit Campaign Effectiveness Analytics

**Project Code:** BCA-2025-001
**Document Type:** Dashboard Build Specification & DAX Library
**Analyst:** Ritik
**Status:** Ready to Build

---

## Data Sources to Load

In Power BI Desktop → Get Data → Text/CSV — load all four files from `data/processed/`:

| File | Rows | Purpose |
|---|---|---|
| `bank_analysis.csv` | 45,211 | Master fact table — powers all visuals |
| `campaign_roi_summary.csv` | 3 | ROI scenario comparison — Page 1 |
| `monthly_summary.csv` | 12 | Monthly trend — Page 1 |
| `segment_summary.csv` | 653 | Segment drill-through — Pages 2 & 3 |

**No relationships needed** — each table is self-contained.
`bank_analysis` is the primary table. Other tables support specific visuals only.

---

## Power Query — Column Type Verification

After loading `bank_analysis.csv`, verify these types in Power Query Editor:

| Column | Set Type To |
|---|---|
| age | Whole Number |
| balance | Whole Number |
| duration | Whole Number |
| campaign | Whole Number |
| pdays | Whole Number |
| previous | Whole Number |
| day | Whole Number |
| month_num | Whole Number |
| subscription_flag | Whole Number |
| valid_call_flag | Whole Number |
| job, marital, education, default | Text |
| housing, loan, contact, poutcome, y | Text |
| age_band, balance_tier | Text |
| contact_frequency_band, debt_burden_flag | Text |
| prior_contact_flag, call_quality_band | Text |

**Do not transform any values in Power Query.**
All business logic was applied in SQL. Power Query is for type verification only.

---

## Dashboard Architecture — 3 Pages

```
┌─────────────────────────────────────────────────────────────┐
│  Page 1 — Executive Command Centre                          │
│  Audience: Head of Retail Banking, CMO                      │
│  Question: "How is our campaign performing overall?"        │
├─────────────────────────────────────────────────────────────┤
│  Page 2 — Customer Intelligence                             │
│  Audience: Campaign Strategy Team                           │
│  Question: "Who should we be calling?"                      │
├─────────────────────────────────────────────────────────────┤
│  Page 3 — Campaign Optimiser                                │
│  Audience: Campaign Manager                                 │
│  Question: "How should we run the next campaign?"           │
└─────────────────────────────────────────────────────────────┘
```

---

## Colour Theme

Apply these hex values consistently across all pages.
In Power BI: View → Themes → Customise Current Theme

| Role | Hex | Use |
|---|---|---|
| Primary Green | `#1D9E75` | Positive outcomes, above average, subscriptions |
| Alert Red | `#E24B4A` | Negative, below average, non-subscriptions |
| Data Blue | `#378ADD` | Volume bars, neutral reference |
| Accent Purple | `#7F77DD` | Secondary segments, Persona C |
| Amber | `#EF9F27` | Mid-tier, caution signals |
| Dark Text | `#2C2C2C` | All titles and labels |
| Background | `#F7F7F5` | Canvas and card backgrounds |
| White | `#FFFFFF` | Card surfaces |

---

## DAX Measures Library

Create a dedicated measures table:
- Home → Enter Data → name it `_Measures` → Load
- Add all measures below to this table

---

### GROUP A — Core KPI Measures

```dax
// ── Total Contacts ──────────────────────────────────────────────────────────
Total Contacts =
COUNTROWS( bank_analysis )

// ── Total Subscriptions ─────────────────────────────────────────────────────
Total Subscriptions =
SUM( bank_analysis[subscription_flag] )

// ── Total Non-Subscriptions ─────────────────────────────────────────────────
Total Non-Subscriptions =
[Total Contacts] - [Total Subscriptions]

// ── Conversion Rate % ───────────────────────────────────────────────────────
Conversion Rate % =
DIVIDE( [Total Subscriptions], [Total Contacts], 0 ) * 100

// ── Non-Conversion Rate % ───────────────────────────────────────────────────
Non-Conversion Rate % =
100 - [Conversion Rate %]

// ── Overall Benchmark Rate ──────────────────────────────────────────────────
// Fixed baseline — used for lift calculations and reference lines
Overall Benchmark Rate =
CALCULATE(
    DIVIDE( SUM(bank_analysis[subscription_flag]), COUNTROWS(bank_analysis), 0 ),
    ALL( bank_analysis )
) * 100
```

---

### GROUP B — Cost & ROI Measures

```dax
// ── Total Campaign Cost (₹) ─────────────────────────────────────────────────
Total Campaign Cost INR =
[Total Contacts] * 150

// ── Total Campaign Cost (Lakh) ──────────────────────────────────────────────
Total Campaign Cost Lakh =
DIVIDE( [Total Campaign Cost INR], 100000 )

// ── Wasted Spend (₹ Lakh) ───────────────────────────────────────────────────
// Spend on calls that did NOT convert
Wasted Spend Lakh =
DIVIDE( [Total Non-Subscriptions] * 150, 100000 )

// ── Cost Per Acquisition ────────────────────────────────────────────────────
Cost Per Acquisition INR =
DIVIDE( [Total Campaign Cost INR], [Total Subscriptions], 0 )

// ── Calls Per Subscription ──────────────────────────────────────────────────
Calls Per Subscription =
DIVIDE( [Total Contacts], [Total Subscriptions], 0 )

// ── Wasted Spend % ──────────────────────────────────────────────────────────
Wasted Spend Pct =
DIVIDE( [Wasted Spend Lakh], [Total Campaign Cost Lakh], 0 ) * 100
```

---

### GROUP C — Segment Intelligence Measures

```dax
// ── Segment Conversion Rate ─────────────────────────────────────────────────
// Respects all slicer/filter context — use in all segment visuals
Segment Conversion Rate % =
DIVIDE(
    SUM( bank_analysis[subscription_flag] ),
    COUNTROWS( bank_analysis ),
    0
) * 100

// ── Segment Lift vs Overall ─────────────────────────────────────────────────
// How much better/worse is this segment vs the 11.70% overall average?
// Lift = 1.0 means average. Lift = 2.0 means 2× better.
Segment Lift =
DIVIDE(
    [Segment Conversion Rate %],
    [Overall Benchmark Rate],
    0
)

// ── Segment Lift Label ──────────────────────────────────────────────────────
// For use in card visuals showing lift as formatted text
Segment Lift Label =
VAR lift = [Segment Lift]
RETURN
    IF( lift >= 1,
        FORMAT(lift, "0.00") & "× above avg",
        FORMAT(lift, "0.00") & "× below avg"
    )

// ── Above / Below Average Flag ──────────────────────────────────────────────
// Used for conditional formatting rules
Above Average Flag =
IF( [Segment Conversion Rate %] >= [Overall Benchmark Rate], 1, 0 )

// ── Segment Share of Subscriptions ─────────────────────────────────────────
// What % of all subscriptions does the current filter context represent?
Segment Sub Share % =
DIVIDE(
    SUM( bank_analysis[subscription_flag] ),
    CALCULATE( SUM(bank_analysis[subscription_flag]), ALL(bank_analysis) ),
    0
) * 100

// ── Segment Share of Contacts ───────────────────────────────────────────────
Segment Contact Share % =
DIVIDE(
    COUNTROWS( bank_analysis ),
    CALCULATE( COUNTROWS(bank_analysis), ALL(bank_analysis) ),
    0
) * 100
```

---

### GROUP D — Campaign Diagnostics Measures

```dax
// ── Average Call Duration (All) ─────────────────────────────────────────────
Avg Call Duration Seconds =
AVERAGEX(
    FILTER( bank_analysis, bank_analysis[duration] > 0 ),
    bank_analysis[duration]
)

// ── Avg Call Duration (Subscribers) ────────────────────────────────────────
Avg Duration Subscribers =
CALCULATE(
    AVERAGEX(
        FILTER( bank_analysis, bank_analysis[duration] > 0 ),
        bank_analysis[duration]
    ),
    bank_analysis[y] = "yes"
)

// ── Avg Call Duration (Non-Subscribers) ────────────────────────────────────
Avg Duration Non-Subscribers =
CALCULATE(
    AVERAGEX(
        FILTER( bank_analysis, bank_analysis[duration] > 0 ),
        bank_analysis[duration]
    ),
    bank_analysis[y] = "no"
)

// ── Duration Ratio ──────────────────────────────────────────────────────────
// Subscribers speak X× longer — use on Page 3 campaign diagnostics card
Duration Engagement Ratio =
DIVIDE( [Avg Duration Subscribers], [Avg Duration Non-Subscribers], 0 )

// ── Campaign Fatigue Rate ───────────────────────────────────────────────────
// Conversion rate for customers contacted 4+ times — the waste metric
Campaign Fatigue Rate % =
CALCULATE(
    DIVIDE( SUM(bank_analysis[subscription_flag]), COUNTROWS(bank_analysis), 0 ) * 100,
    bank_analysis[campaign] >= 4
)

// ── Excess Contacts (4+ calls) ──────────────────────────────────────────────
Excess Contacts =
CALCULATE(
    COUNTROWS( bank_analysis ),
    bank_analysis[campaign] >= 4
)

// ── Spend on Excess Contacts ────────────────────────────────────────────────
Excess Spend Lakh =
DIVIDE( [Excess Contacts] * 150, 100000 )
```

---

### GROUP E — Warm Lead Measures

```dax
// ── Warm Lead Count ─────────────────────────────────────────────────────────
Warm Lead Count =
CALCULATE(
    COUNTROWS( bank_analysis ),
    bank_analysis[poutcome] = "success"
)

// ── Warm Lead Conversion Rate ───────────────────────────────────────────────
Warm Lead Conversion Rate % =
CALCULATE(
    DIVIDE( SUM(bank_analysis[subscription_flag]), COUNTROWS(bank_analysis), 0 ) * 100,
    bank_analysis[poutcome] = "success"
)

// ── Cold Lead Conversion Rate ───────────────────────────────────────────────
Cold Lead Conversion Rate % =
CALCULATE(
    DIVIDE( SUM(bank_analysis[subscription_flag]), COUNTROWS(bank_analysis), 0 ) * 100,
    bank_analysis[poutcome] = "unknown"
)

// ── Warm Lead Multiplier ────────────────────────────────────────────────────
// The 7× headline number — warm leads outperform cold by this factor
Warm Lead Multiplier =
DIVIDE( [Warm Lead Conversion Rate %], [Cold Lead Conversion Rate %], 0 )
```

---

### GROUP F — Formatting & Display Measures

```dax
// ── Conversion Rate Formatted ───────────────────────────────────────────────
Conversion Rate Formatted =
FORMAT( [Conversion Rate %] / 100, "0.00%" )

// ── CPA Formatted ───────────────────────────────────────────────────────────
CPA Formatted =
"₹" & FORMAT( [Cost Per Acquisition INR], "#,##0" )

// ── Total Cost Formatted ────────────────────────────────────────────────────
Total Cost Formatted =
"₹" & FORMAT( [Total Campaign Cost Lakh], "0.00" ) & "L"

// ── KPI Status Label ────────────────────────────────────────────────────────
// Drives conditional colour on KPI cards
KPI Status =
IF( [Conversion Rate %] >= [Overall Benchmark Rate], "Above Average", "Below Average" )
```

---

## Page 1 — Executive Command Centre

### Canvas Setup
- Canvas size: 1280 × 720 px (16:9)
- Background: `#F7F7F5`
- Page title text box: "BankX | Term Deposit Campaign — Executive Overview"
  Font: Segoe UI Semibold, 18pt, colour `#2C2C2C`
- Subtitle: "45,211 Customer Contacts · May 2008 – Nov 2010 · Direct Marketing Division"
  Font: Segoe UI, 11pt, colour `#6B6B6B`

---

### Visual 1 — KPI Card Row (5 cards across top)

Position: Y=80, full width, height 90px each
Card style: White background, thin border `#E0E0E0`, rounded corners

| Card | Measure | Label | Format |
|---|---|---|---|
| 1 | `Total Contacts` | Total Contacts | `#,##0` |
| 2 | `Total Subscriptions` | Subscriptions | `#,##0` |
| 3 | `Conversion Rate %` | Conversion Rate | `0.00%` — green if ≥11.7, red if < |
| 4 | `Cost Per Acquisition INR` | Cost Per Acquisition | `₹#,##0` |
| 5 | `Wasted Spend Lakh` | Wasted Spend | `₹0.00L` — always red |

**Conditional formatting on Card 3:**
- Value font colour: Rule → If value ≥ 11.7 → `#1D9E75` else `#E24B4A`

---

### Visual 2 — Monthly Conversion Rate vs Contact Volume

Type: **Line and Clustered Column Chart**
Table: `monthly_summary`

- Column (Y-axis left): `Total_Contacts` — colour `#378ADD`, opacity 30%
- Line (Y-axis right): `Conversion_Rate_Pct` — colour `#1D9E75`, line width 2.5pt
- X-axis: `month` sorted by `month_num`
- Secondary Y-axis: label "Conversion Rate (%)"
- Primary Y-axis: label "Number of Contacts"
- Data labels on line: ON, font 8pt
- Title: "Monthly Campaign Volume vs Conversion Rate"

**Conditional colour on data labels:**
- Green (`#1D9E75`) if value ≥ 11.7
- Red (`#E24B4A`) if value < 11.7

**Reference line:** Constant line at 11.7 on the line axis
- Label: "Overall avg: 11.7%", style: dashed, colour `#2C2C2C`

**Insight annotation text box** (position below chart):
> "⚠ May accounts for 30.4% of all contacts but converts at only 6.7% — the lowest of any month."

---

### Visual 3 — Campaign Conversion Funnel

Type: **Funnel Chart**
Table: `bank_analysis` (use measures)

Stages (create a small calculated table or use fixed values):

| Stage | Value |
|---|---|
| All Contacts | 45,211 |
| Valid Calls (duration > 0) | `CALCULATE(COUNTROWS(bank_analysis), bank_analysis[valid_call_flag]=1)` |
| Calls > 1 Minute | `CALCULATE(COUNTROWS(bank_analysis), bank_analysis[duration]>=60)` |
| Subscriptions | 5,289 |

- Colours: gradient from `#378ADD` (top) to `#1D9E75` (bottom)
- Data labels: ON with percentage
- Title: "Campaign Conversion Funnel"

---

### Visual 4 — ROI Scenario Comparison

Type: **Clustered Bar Chart**
Table: `campaign_roi_summary`

- Y-axis: `Scenario`
- X-axis: `Conversion_Rate_Pct`
- Data labels: ON, show value + "%" suffix
- Colour: Scenario A → `#E24B4A`, B → `#EF9F27`, C → `#1D9E75`
- Title: "Targeting Strategy Comparison — Conversion Rate by Scenario"

**Second visual alongside:** Clustered Bar of `Cost_Per_Acquisition`
- Title: "Cost Per Acquisition by Targeting Scenario"
- Same colour scheme
- Format: "₹#,##0"

**Callout text box:**
> "Scenario C (Warm Leads + High Balance): ₹476 CPA vs ₹1,282 current — 63% cost reduction"

---

### Visual 5 — Subscription vs Non-Subscription Donut

Type: **Donut Chart**
Table: `bank_analysis`

- Values: `Total Subscriptions` and `Total Non-Subscriptions`
- Colours: Green `#1D9E75` / Red `#E24B4A`
- Legend: OFF (use data labels instead)
- Detail labels: Category + Percent
- Inner radius: 60%
- Title: "Overall Outcome Split"

---

## Page 2 — Customer Intelligence

### Canvas Setup
- Same dimensions and background as Page 1
- Page title: "BankX | Customer Intelligence — Who Converts?"
- Subtitle: "Conversion rate analysis by demographic profile · All filters apply globally"

---

### Slicer Panel (left column, stacked vertically)

Add 4 slicers in a vertical panel on the left (width ~200px):

| Slicer | Field | Style |
|---|---|---|
| Age Band | `age_band` | Dropdown |
| Job Type | `job` | Dropdown |
| Education | `education` | Dropdown |
| Debt Profile | `debt_burden_flag` | Dropdown |

All slicers: Select All by default, sync across page.

---

### Visual 6 — Conversion by Job Type (Horizontal Bar)

Type: **Bar Chart (Horizontal)**
Table: `bank_analysis`
- Y-axis: `job`
- X-axis: `Segment Conversion Rate %` (measure)
- Sort: Descending by conversion rate
- Data labels: ON, format "0.0%"
- Title: "Conversion Rate by Occupation"

**Conditional formatting — bar colour:**
Rule: If `Above Average Flag` = 1 → `#1D9E75` else `#E24B4A`

**Reference line:** 11.7 (constant)
- Label: "Overall avg", dashed, `#2C2C2C`

**Tooltips** (add tooltip fields):
- `Total Contacts`
- `Total Subscriptions`
- `Segment Lift Label`

---

### Visual 7 — Conversion by Age Band (Column Chart)

Type: **Clustered Column Chart**
Table: `bank_analysis`
- X-axis: `age_band` (sorted by value, not alphabetically)
- Y-axis: `Segment Conversion Rate %`
- Data labels: ON, "0.0%"
- Title: "Conversion Rate by Age Band"

**Conditional colour:**
- Retired (61+) bar: manually set to `#1D9E75` (will stand out)
- Others: apply rule — ≥11.7 green, <11.7 red

**Callout card** positioned next to chart:
- Measure: `Warm Lead Multiplier`
- Label: "Retired (61+) Conversion"
- Static value: 42.26%
- Background: `#E1F5EE`, text `#0F6E56`

---

### Visual 8 — Conversion by Education × Marital (Matrix)

Type: **Matrix**
Table: `bank_analysis`
- Rows: `education`
- Columns: `marital`
- Values: `Segment Conversion Rate %`
- Format: "0.0%"
- Conditional formatting on values: Colour scale — Red (0%) → White (11.7%) → Green (30%+)
- Title: "Conversion Rate: Education × Marital Status"

---

### Visual 9 — Debt Burden Impact (Column Chart)

Type: **Clustered Column Chart**
Table: `bank_analysis`
- X-axis: `debt_burden_flag`
  Sort order: Debt Free → Housing Loan Only → Personal Loan Only → Dual Debt Burden
- Y-axis: `Segment Conversion Rate %`
- Data labels: ON
- Colours: Debt Free `#1D9E75`, Housing Only `#EF9F27`, Personal Only `#EF9F27`, Dual Debt `#E24B4A`
- Reference line: 11.7
- Title: "Impact of Debt Burden on Conversion Rate"

**Annotation text box:**
> "Debt-Free customers convert at 3× the rate of Dual-Debt customers (18.2% vs 6.1%)"

---

### Visual 10 — Balance Tier Conversion (Column Chart)

Type: **Clustered Column Chart**
Table: `bank_analysis`
- X-axis: `balance_tier` (sort by value)
- Y-axis: `Segment Conversion Rate %`
- Data labels: ON, "0.0%"
- Conditional colour: ≥11.7 green, <11.7 red
- Reference line: 11.7
- Title: "Conversion Rate by Account Balance Tier"

---

### Visual 11 — Customer Persona Cards (4 KPI Cards)

Position: bottom row of Page 2
Create 4 cards in a 2×2 or 1×4 layout

For each persona, create a **dedicated measure:**

```dax
// Persona A — Loyal Retiree
Persona A Conversion % =
CALCULATE(
    DIVIDE( SUM(bank_analysis[subscription_flag]), COUNTROWS(bank_analysis), 0 ) * 100,
    bank_analysis[poutcome] = "success",
    bank_analysis[age] >= 61
)

// Persona B — Affluent Professional
Persona B Conversion % =
CALCULATE(
    DIVIDE( SUM(bank_analysis[subscription_flag]), COUNTROWS(bank_analysis), 0 ) * 100,
    bank_analysis[balance] > 5000,
    bank_analysis[job] IN { "management", "admin." },
    bank_analysis[housing] = "no",
    bank_analysis[loan] = "no"
)

// Persona C — Financial Student
Persona C Conversion % =
CALCULATE(
    DIVIDE( SUM(bank_analysis[subscription_flag]), COUNTROWS(bank_analysis), 0 ) * 100,
    bank_analysis[job] = "student"
        || ( bank_analysis[age] <= 30 && bank_analysis[marital] = "single" )
)

// Persona D — Over-Leveraged
Persona D Conversion % =
CALCULATE(
    DIVIDE( SUM(bank_analysis[subscription_flag]), COUNTROWS(bank_analysis), 0 ) * 100,
    bank_analysis[housing] = "yes",
    bank_analysis[loan] = "yes",
    bank_analysis[balance] < 0
)
```

Card labels: "Persona A: Loyal Retiree", "Persona B: Affluent Professional",
"Persona C: Financial Student", "Persona D: Over-Leveraged (Avoid)"

Card colours: A=green background, B=blue, C=purple, D=red

---

## Page 3 — Campaign Optimiser

### Canvas Setup
- Page title: "BankX | Campaign Optimiser — How Should We Run the Next Campaign?"
- Subtitle: "Timing · Frequency · Channel · Warm Lead Strategy"

---

### Visual 12 — Campaign Fatigue Curve (Line Chart)

Type: **Line Chart**
Table: `bank_analysis`
- X-axis: `campaign` (filter to 1–10 for clarity)
- Y-axis: `Segment Conversion Rate %`
- Markers: ON
- Line colour: `#378ADD`
- Reference line: 11.7 (overall avg), dashed
- Reference line: X=3 (recommended cap), red dashed
  Label: "3-Call Cap Recommendation"
- Title: "Campaign Fatigue: Conversion Rate by Number of Calls"

**Shaded region** (create using a reference band if available, else annotate):
- Shade X > 3 with light red background
- Text box: "Waste Zone — 4+ calls"

**KPI cards alongside:**
- `Excess Contacts` — label "Contacts Above 3-Call Cap"
- `Excess Spend Lakh` — label "Spend on Excess Contacts (₹ Lakh)"

---

### Visual 13 — Conversion by Contact Frequency Band (Column)

Type: **Clustered Column Chart**
Table: `bank_analysis`
- X-axis: `contact_frequency_band`
- Y-axis: `Segment Conversion Rate %`
- Data labels: ON
- Colours: 1 Call `#1D9E75`, 2-3 `#EF9F27`, 4-5 `#E24B4A`, 6+ `#8B0000`
- Reference line: 11.7
- Title: "Conversion by Contact Frequency Band"

---

### Visual 14 — Monthly Conversion Rate (Bar, sorted best to worst)

Type: **Horizontal Bar Chart**
Table: `monthly_summary`
- Y-axis: `month` sorted descending by `Conversion_Rate_Pct`
- X-axis: `Conversion_Rate_Pct`
- Data labels: ON, "0.0%"
- Conditional colour: ≥11.7 green, <11.7 red
- Reference line: 11.7
- Title: "Best & Worst Months by Conversion Rate"

**Insight annotation:**
> "March (52.0%) converts at 7.8× the rate of May (6.7%). Shift budget to Q4."

---

### Visual 15 — Warm Lead Analysis (Two Cards + Bar)

**Card 1:** `Warm Lead Count` — "Priority Warm Leads Available"
**Card 2:** `Warm Lead Conversion Rate %` — "Warm Lead Conversion Rate" (green background)
**Card 3:** `Warm Lead Multiplier` — "Multiplier vs Cold Leads" — format "0.0×"

**Bar chart alongside:**
Type: Clustered Bar
- Y-axis: `poutcome`
- X-axis: `Segment Conversion Rate %`
- Colours: success `#1D9E75`, other `#378ADD`, failure `#EF9F27`, unknown `#E24B4A`
- Data labels: ON
- Title: "Conversion Rate by Previous Campaign Outcome"

---

### Visual 16 — Call Duration Diagnostic (Two KPI Cards + Bar)

**Card 1:** `Avg Duration Subscribers` — format "#,##0 sec" — green
**Card 2:** `Avg Duration Non-Subscribers` — format "#,##0 sec" — red
**Card 3:** `Duration Engagement Ratio` — "Subscribers Speak" — format "0.0×" — dark

**Bar chart:**
- Y-axis: `call_quality_band`
- X-axis: `Segment Conversion Rate %`
- Data labels: ON
- Title: "Conversion Rate by Call Quality Band"

**Disclaimer text box** (important):
> "⚠ Duration is a post-call metric — it cannot be used for targeting decisions.
>    Use these figures for agent training and quality benchmarking only."

---

### Visual 17 — Contact Channel Performance

Type: **Clustered Column Chart**
Table: `bank_analysis`
- X-axis: `contact`
- Y-axis: `Segment Conversion Rate %`
- Data labels: ON
- Colours: cellular `#1D9E75`, telephone `#EF9F27`, unknown `#E24B4A`
- Title: "Conversion Rate by Contact Channel"

---

## Page Navigation

Add navigation buttons at the top of every page:

| Button | Action | Style |
|---|---|---|
| "📊 Executive Overview" | Page navigation → Page 1 | Active = filled green, inactive = outline |
| "👥 Customer Intelligence" | Page navigation → Page 2 | Same style |
| "⚙ Campaign Optimiser" | Page navigation → Page 3 | Same style |

Steps to add:
Insert → Buttons → Navigator → Page Navigator
Or manually: Insert → Buttons → Blank → Action: Page Navigation → set target page

---

## Tooltips

For every visual, add these standard tooltip fields:
- `Total Contacts`
- `Total Subscriptions`
- `Segment Conversion Rate %`
- `Segment Lift Label`
- `Cost Per Acquisition INR`

---

## Final Polish Checklist

Before publishing:

- [ ] All chart titles set in Segoe UI Semibold 12pt, colour `#2C2C2C`
- [ ] All axis labels: Segoe UI 9pt, colour `#6B6B6B`
- [ ] All data labels: Segoe UI 9pt, bold
- [ ] All cards: white background, border `#E0E0E0`, 4px corner radius
- [ ] No gridlines on bar/column charts (turn off in Format → Gridlines)
- [ ] Reference lines added on all conversion charts (11.7% baseline)
- [ ] Page navigation buttons working on all 3 pages
- [ ] All slicers on Page 2 synced
- [ ] Tooltips configured on all visuals
- [ ] Report-level filter: exclude `valid_call_flag = 0` from all pages
  (Format → Filters → Add `valid_call_flag` = 1 as report-level filter)
- [ ] Title banner consistent across all 3 pages
- [ ] Screenshot each page at 1280×720 for GitHub README

---

*Phase 4 Dashboard Specification — BCA-2025-001 | Analyst: Ritik*
