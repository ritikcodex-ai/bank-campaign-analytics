# 🏦 Bank Term Deposit Campaign Effectiveness Analytics
### A Consulting-Grade Data Analytics Portfolio Project

<p align="left">
  <img src="https://img.shields.io/badge/MySQL-8.0-4479A1?style=flat&logo=mysql&logoColor=white"/>
  <img src="https://img.shields.io/badge/Python-3.x-3776AB?style=flat&logo=python&logoColor=white"/>
  <img src="https://img.shields.io/badge/Power%20BI-PL--300-F2C811?style=flat&logo=powerbi&logoColor=black"/>
  <img src="https://img.shields.io/badge/pandas-1.5+-150458?style=flat&logo=pandas&logoColor=white"/>
  <img src="https://img.shields.io/badge/Status-Complete-1D9E75?style=flat"/>
</p>

---

## 📌 The Business Problem

**BankX**, a mid-size retail bank, runs periodic direct marketing campaigns to promote **term deposit subscriptions** via outbound telephone calls.

Over multiple campaigns, BankX contacted **45,211 customers** and achieved a conversion rate of only **11.70%** — meaning **88.3% of all calls produced no subscription**.

At an estimated ₹150 per call, this translates to:

| Metric | Value |
|---|---|
| Total campaign spend | ₹67.8 Lakh |
| Spend on non-converting calls | **₹59.9 Lakh** |
| Current cost per acquisition | **₹1,282** |

The Head of Retail Banking asked three questions this engagement was designed to answer:

> 1. Which customers are genuinely likely to subscribe — and which are wasting our budget?
> 2. Are our calling tactics (frequency, timing, channel) hurting or helping conversion?
> 3. If we redesigned our targeting strategy today, what would our projected ROI look like?

---

## 🎯 Project Approach

This is not a dashboard project. It is a **campaign intelligence engagement** structured as a real consulting delivery — starting with a client brief, ending with quantified business recommendations.

```
Business Problem → SQL Analysis → Python EDA → Power BI Dashboard → Recommendations
```

Every analytical output answers a specific business question. Every chart exists to support a decision.

---

## 📂 Repository Structure

```
bank-campaign-analytics/
│
├── data/
│   ├── raw/                          # bank-full.csv (not committed — download from Kaggle)
│   └── processed/                    # Exported MySQL tables for Power BI
│       ├── bank_analysis.csv         # 45,211 rows × 26 cols — master fact table
│       ├── campaign_roi_summary.csv  # 3-scenario ROI comparison
│       ├── monthly_summary.csv       # 12-month aggregated trend
│       └── segment_summary.csv       # 653 customer segment combinations
│
├── sql/
│   ├── 00_sql_index.md               # Script index & execution guide
│   ├── 01_schema_setup.sql           # Database, table, 9 derived columns
│   ├── 02_data_exploration.sql       # Dataset profile & distributions
│   ├── 03_conversion_analysis.sql    # Overall conversion + monthly trends
│   ├── 04_demographic_profiling.sql  # Age, job, education, marital analysis
│   ├── 05_balance_tier_analysis.sql  # Wealth segmentation + deposit value
│   ├── 06_campaign_diagnostics.sql   # Contact fatigue + call duration
│   ├── 07_previous_campaign_impact.sql # Warm lead multiplier analysis
│   ├── 08_customer_targeting_matrix.sql # Targeting score + 4 personas
│   └── 09_campaign_roi_model.sql     # 3-scenario ROI projection
│
├── notebooks/
│   ├── bank_campaign_eda.ipynb       # Full EDA notebook (38 cells, 18 sections)
│   └── bank_campaign_eda.py          # Standalone Python script
│
├── powerbi/
│   ├── bank_campaign_dashboard.pbix  # 3-page Power BI dashboard
│   ├── dax_measures_library.dax      # 46 DAX measures, fully documented
│   ├── dashboard_specification.md    # Visual spec & build guide
│   └── power_query_transformations.pq
│
├── docs/
│   ├── 01_business_problem_statement.md
│   ├── 02_project_scope.md
│   ├── 03_data_dictionary.md
│   ├── 04_data_quality_audit.md
│   ├── 05_phase2_completion_summary.md
│   ├── 06_eda_summary_report.md
│   └── 07_executive_recommendations.md
│
├── reports/
│   └── executive_summary.md
│
├── assets/screenshots/               # EDA charts + dashboard previews
├── .gitignore
└── README.md
```

> **Note on raw data:** `bank-full.csv` is not committed due to file size. Download from [Kaggle](https://www.kaggle.com/datasets/henriqueyamahata/bank-marketing) and place in `data/raw/`.

---

## 🔍 Key Findings

### Finding 1 — Campaign Converts Only 1 in 8.5 Calls
Overall conversion rate: **11.70%** across 45,211 contacts. The 7.5:1 class imbalance (no:yes) quantifies the scale of the inefficiency.

---

### Finding 2 — Retired Customers Convert at 42.26% (4× Average)
Customers aged 61+ represent only 2.6% of contacts but convert at nearly four times the average — the most under-served high-value segment in the database.

| Age Band | Contacts | Conversion Rate |
|---|---|---|
| Young (18–30) | 7,030 | 16.3% |
| Early Career (31–40) | 17,687 | 10.2% |
| Mid Career (41–50) | 11,239 | 9.1% |
| Pre-Retirement (51–60) | 8,067 | 10.1% |
| **Retired (61+)** | **1,188** | **42.3% ⭐** |

---

### Finding 3 — The 7× Warm Lead Multiplier
Customers who subscribed in a previous campaign convert at **64.73%** — seven times the cold lead baseline of 9.16%.

| Previous Outcome | Contacts | Conversion Rate | Lift |
|---|---|---|---|
| **success** | 1,511 | **64.73%** | **7.07×** |
| other | 1,840 | 16.68% | 1.82× |
| failure | 4,901 | 12.61% | 1.38× |
| unknown (cold) | 36,959 | 9.16% | baseline |

---

### Finding 4 — The May Paradox
May receives **30.4% of all contacts** but produces the **lowest conversion rate** (6.7%). March converts at **52.0%** with only 1.1% of total volume.

| Month | Contacts | Conversion Rate |
|---|---|---|
| **March** | 477 | **52.0%** ⭐ |
| December | 214 | 46.7% |
| September | 579 | 46.5% |
| October | 738 | 43.8% |
| **May** | **13,766** | **6.7%** ❌ |

---

### Finding 5 — Campaign Fatigue After 3 Calls
Conversion decays 60% from the first call (14.6%) to 6+ calls (5.8%). A 3-call cap saves ₹14.5 Lakh while retaining 95%+ of subscription volume.

---

### Finding 6 — Debt-Free Customers Convert at 3× the Dual-Debt Rate
18.22% vs 6.07% — the strongest single negative predictor in the dataset.

---

### Finding 7 — Subscribers Speak 2.4× Longer
537 seconds vs 221 seconds average call duration. Statistically significant (p < 0.001). Used for agent training diagnostics only — not for targeting.

---

## 💡 Business Recommendations

| # | Recommendation | Expected Impact |
|---|---|---|
| 1 | Call warm leads (poutcome=success) first every campaign | ~978 subs at ₹231 CPA |
| 2 | Implement 3-call cap per customer per campaign | Save ₹14.5 Lakh per campaign |
| 3 | Shift 30% of May budget to Sep/Oct/Dec | Same spend, higher conversion |
| 4 | Minimum ≥1,000 EUR balance threshold for Wave 1 | Remove low-probability cold contacts |
| 5 | Tiered wave strategy: Warm → Retired/Students → Broad | Improve blended CPA from ₹1,282 to ~₹858 |

---

## 📊 ROI Projection — 3 Targeting Scenarios

| Scenario | Calls | Conversion | CPA | Spend Saved |
|---|---|---|---|---|
| A — Current (Broad Outreach) | 45,211 | 11.70% | ₹1,282 | — |
| B — Targeted + 3-Call Cap | ~28,000 | ~17.5% | ~₹858 | ~₹25.7L |
| C — Premium (Warm + High Balance) | ~4,163 | ~31.5% | ~₹476 | ~₹61.5L |

---

## 🗂️ Technical Stack

| Tool | Purpose |
|---|---|
| **MySQL 8.0** | Database, schema design, all data transformation & segmentation |
| **Python 3.x** | EDA, statistical analysis, 15 analytical charts |
| **pandas · matplotlib · seaborn · scipy** | Data manipulation, visualisation, hypothesis testing |
| **Power BI Desktop** | 3-page interactive dashboard, 46 DAX measures |
| **Excel** | Supporting analysis |

---

## 🚀 How to Reproduce

### Step 1 — Get the Data
Download `bank-full.csv` from [Kaggle](https://www.kaggle.com/datasets/henriqueyamahata/bank-marketing) → place in `data/raw/`.

### Step 2 — Run SQL Scripts
Open MySQL Workbench → run scripts `01` through `09` in order. See `sql/00_sql_index.md`.

### Step 3 — Run Python EDA
```bash
pip install pandas matplotlib seaborn scipy numpy nbformat
jupyter notebook notebooks/bank_campaign_eda.ipynb
```

### Step 4 — Build Power BI Dashboard
Load CSVs from `data/processed/` → follow `powerbi/build_guide.md` → add DAX measures from `powerbi/dax_measures_library.dax`.

---

## 📋 Dataset Information

| Attribute | Value |
|---|---|
| Source | UCI Machine Learning Repository |
| Kaggle | [henriqueyamahata/bank-marketing](https://www.kaggle.com/datasets/henriqueyamahata/bank-marketing) |
| Records | 45,211 |
| Features | 17 (16 predictors + 1 target) |
| Engineered features | 9 |
| Time period | May 2008 – November 2010 |
| Null values | 0 |

---

## 👤 About

**Analyst:** Ritik | BCA — Asian School of Business, Noida (2026)
**Certifications:** Microsoft PL-300 (Power BI Data Analyst)
**Stack:** SQL · Python · Power BI · Excel
**GitHub:** [github.com/ritikcodex-ai](https://github.com/ritikcodex-ai)

---

*"The best analysis is the one that changes a decision."*

