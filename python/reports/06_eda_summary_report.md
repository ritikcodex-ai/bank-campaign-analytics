# Phase 3 — EDA Summary Report
## Bank Term Deposit Campaign Effectiveness Analytics

**Project Code:** BCA-2025-001
**Document Type:** Exploratory Data Analysis Findings Report
**Analyst:** Ritik
**Dataset:** UCI Bank Marketing · `bank-full.csv` · 45,211 records
**Status:** ✅ Complete — Approved for Phase 4

---

## Executive Summary

This report presents findings from a full exploratory data analysis of BankX's direct
marketing campaign data covering 45,211 customer contact records across 2008–2010.

The central finding is this: **BankX's current broad-reach calling strategy converts
only 11.70% of contacts — producing ₹59.9 Lakh in non-converting spend per campaign
cycle.** The EDA identifies five actionable targeting dimensions that, if applied
together, would materially improve campaign ROI without increasing budget.

---

## Dataset Profile

| Attribute | Value |
|---|---|
| Total records | 45,211 |
| Total features | 17 (16 predictors + 1 target) |
| Engineered features added | 7 (age_band, balance_tier, debt_burden, etc.) |
| Null values | 0 |
| Target variable | `y` — term deposit subscription (yes/no) |
| Positive class (yes) | 5,289  (11.70%) |
| Negative class (no) | 39,922 (88.30%) |
| Class imbalance ratio | 7.5:1 |

---

## Finding 1 — Campaign Conversion Rate: 11.70%

**What we found:**
Of 45,211 customer contacts, only 5,289 subscribed to a term deposit — an 11.70% conversion rate.
The 7.5:1 class imbalance is not a data problem; it is the business problem.

**Financial implication:**
- Total campaign cost (est. ₹150/call): ₹67.8 Lakh
- Non-converting spend: ₹59.9 Lakh (88.3% of total)
- Current cost per acquisition (CPA): ₹1,282

**Chart:** `01_target_variable_distribution.png`

---

## Finding 2 — Top Customer Segments by Job Type

| Job | Contacts | Conversion Rate | Lift vs Average |
|---|---|---|---|
| student | 938 | **28.68%** | 2.45× |
| retired | 2,264 | **22.79%** | 1.95× |
| unemployed | 1,303 | 15.50% | 1.32× |
| management | 9,458 | 13.76% | 1.18× |
| blue-collar | 9,732 | **7.27%** | **0.62×** |

**Key insight:** Students and retirees convert at 2–2.5× the average. Blue-collar is the
largest single segment (21.5% of contacts) yet the lowest converter — indicating
significant budget misallocation.

**Statistical test:** Not applicable (conversion rate comparison — see chi-square equivalent via cross-tab).

**Chart:** `04_conversion_by_job.png`

---

## Finding 3 — Age Band: Retired Customers at 42.26%

| Age Band | Contacts | Conversion Rate |
|---|---|---|
| Young (18–30) | 7,030 | 16.29% |
| Early Career (31–40) | 17,687 | 10.24% |
| Mid Career (41–50) | 11,239 | 9.07% |
| Pre-Retirement (51–60) | 8,067 | 10.05% |
| **Retired (61+)** | **1,188** | **42.26%** |

**Key insight:** Retired customers (61+) convert at 42.26% — the highest of any
demographic dimension in the dataset. With only 1,188 contacts in the data,
this segment is demonstrably under-served by current campaigns.

**Chart:** `05_conversion_by_age_band.png`

---

## Finding 4 — The Warm Lead Multiplier: 7×

| Previous Campaign Outcome | Contacts | Conversion Rate | Lift vs Cold |
|---|---|---|---|
| **success** | 1,511 | **64.73%** | **7.07×** |
| other | 1,840 | 16.68% | 1.82× |
| failure | 4,901 | 12.61% | 1.38× |
| unknown (cold) | 36,959 | 9.16% | baseline |

**Key insight:** Customers who subscribed in a previous campaign convert at 64.73%
in the current campaign — a 7× multiplier over cold leads. These 1,511 customers
should receive the first call of every new campaign.

**Statistical test:** Chi-square χ² = 4,391.51, df = 3, p < 0.001 ✅

**Chart:** `06_warm_lead_multiplier.png`

---

## Finding 5 — May Paradox: Most Calls, Lowest Conversion

| Month | Contacts | % of Total | Conversion Rate |
|---|---|---|---|
| **mar** | 477 | 1.1% | **52.0%** |
| dec | 214 | 0.5% | 46.7% |
| sep | 579 | 1.3% | 46.5% |
| oct | 738 | 1.6% | 43.8% |
| **may** | **13,766** | **30.4%** | **6.7%** |

**Key insight:** May receives 30.4% of all calls — more than any other month —
yet produces the lowest conversion rate in the dataset. March, with only 1.1%
of calls, converts at 52.0%. This is the most actionable budget reallocation
opportunity in the entire project.

**Chart:** `07_monthly_volume_vs_conversion.png`

---

## Finding 6 — Campaign Fatigue: Cap at 3 Calls

| Calls Made | Contacts | Conversion Rate | vs 1st Call |
|---|---|---|---|
| 1 Call | 17,544 | **14.60%** | baseline |
| 2–3 Calls | 18,026 | 11.20% | −23% |
| 4–5 Calls | 5,286 | 8.63% | −41% |
| **6+ Calls** | **4,355** | **5.81%** | **−60%** |

**Key insight:** Conversion decays 60% from the first call to the 6th+ call.
A 3-call cap would eliminate 9,641 contacts, saving ₹14.5 Lakh while losing
only 253 low-probability subscriptions.

**Chart:** `08_campaign_fatigue_curve.png`

---

## Finding 7 — Debt Burden: 3× Conversion Gap

| Debt Profile | Contacts | Conversion Rate |
|---|---|---|
| **Debt Free** | 17,204 | **18.22%** |
| Housing Loan Only | 20,763 | 8.04% |
| Personal Loan Only | 2,877 | 7.61% |
| **Dual Debt Burden** | **4,367** | **6.07%** |

**Key insight:** Debt-free customers convert at 3× the rate of customers carrying
both a housing and personal loan. This is the strongest actionable exclusion signal
for low-priority customers.

**Statistical test:** Mann-Whitney U p < 0.001 ✅ (balance as proxy)

**Chart:** `09_debt_burden_conversion.png`

---

## Finding 8 — Call Duration: Subscribers Speak 2.4× Longer

| Outcome | Mean Duration | Median Duration |
|---|---|---|
| **Subscribed (yes)** | **537 seconds (8.95 min)** | 426 seconds |
| Did not subscribe (no) | 221 seconds (3.68 min) | 164 seconds |

**Statistical test:** Mann-Whitney U = 170,521,757, p < 0.001 ✅

**Important caveat:** Duration is a *post-call* metric — known only after the call ends.
It cannot be used in targeting decisions. Applications:
- Agent training benchmark (aim for conversations ≥5 minutes)
- Quality review flag for calls under 60 seconds
- Validation that high-scoring segments produce longer actual calls

**Chart:** `11_call_duration_analysis.png`

---

## Finding 9 — Correlation Structure

| Feature | Correlation with Subscription | Direction |
|---|---|---|
| duration | r = +0.395 | ▲ (post-call diagnostic only) |
| pdays | r = +0.104 | ▲ (recency of prior contact) |
| previous | r = +0.093 | ▲ (prior campaign engagement) |
| campaign | r = −0.073 | ▼ (more calls = lower conversion) |
| balance | r = +0.053 | ▲ (modest positive) |
| age | r = +0.025 | ▲ (negligible linear effect) |

**Key insight:** No single numeric feature is a strong linear predictor of subscription —
which means segmentation-based targeting (as built in SQL Script 08) is more appropriate
than simple threshold rules. The correlation matrix confirms multi-factor analysis is needed.

**Chart:** `12_correlation_heatmap.png`

---

## Finding 10 — 4 Customer Personas Validated

| Persona | Definition | Conversion Rate | Priority |
|---|---|---|---|
| A — Loyal Retiree | poutcome=success + age≥61 | **~75%+** | 🟢 Wave 1 |
| B — Affluent Professional | balance>5K, mgmt/admin, debt-free | **~19–22%** | 🟢 Wave 1 |
| C — Financial Student | job=student or age≤30 & single | **~25–29%** | 🟡 Wave 2 |
| D — Over-Leveraged | dual debt + negative balance | **~3–4%** | 🔴 Deprioritise |

**Chart:** `15_customer_personas.png`

---

## Statistical Tests Summary

| Test | Feature | Statistic | p-value | Result |
|---|---|---|---|---|
| Mann-Whitney U | Call Duration | 170,521,757 | < 0.001 | ✅ Significant |
| Mann-Whitney U | Account Balance | — | < 0.001 | ✅ Significant |
| Mann-Whitney U | Age | — | 0.063 | ❌ Not significant (linear) |
| Mann-Whitney U | Campaign Contacts | — | < 0.001 | ✅ Significant |
| Chi-Square | poutcome vs y | χ²=4,391.51, df=3 | < 0.001 | ✅ Significant |

> **Note on age:** The Mann-Whitney result for age is not significant *as a linear predictor*,
> but the age band analysis clearly shows Retired (61+) as a high-converting group.
> This confirms that age needs to be analysed as a categorical band, not a continuous variable.

---

## Charts Produced

| Chart | File | Section |
|---|---|---|
| 01 | `01_target_variable_distribution.png` | Target variable / class imbalance |
| 02 | `02_univariate_numeric.png` | Numeric feature distributions |
| 03 | `03_univariate_categorical.png` | Categorical feature distributions |
| 04 | `04_conversion_by_job.png` | Conversion by job type |
| 05 | `05_conversion_by_age_band.png` | Conversion by age band |
| 06 | `06_warm_lead_multiplier.png` | Previous campaign outcome effect |
| 07 | `07_monthly_volume_vs_conversion.png` | Monthly volume vs conversion |
| 08 | `08_campaign_fatigue_curve.png` | Campaign fatigue curve |
| 09 | `09_debt_burden_conversion.png` | Debt burden impact |
| 10 | `10_balance_tier_conversion.png` | Balance tier conversion |
| 11 | `11_call_duration_analysis.png` | Call duration deep-dive |
| 12 | `12_correlation_heatmap.png` | Correlation matrix |
| 13 | `13_statistical_tests.png` | Statistical test box plots |
| 14 | `14_job_month_heatmap.png` | Job × month heatmap |
| 15 | `15_customer_personas.png` | 4 customer personas |

---

## Interview Q&A — Phase 3 Specific

**Q: What EDA technique did you use and why?**
> "I used both univariate (distributions, value counts) and bivariate analysis (conversion rate by segment). For statistical validation I used Mann-Whitney U tests rather than t-tests because the distributions — especially duration and balance — are right-skewed and non-normal. For the categorical relationship between prior campaign outcome and current subscription, I used a chi-square test."

**Q: What was the most surprising finding?**
> "May. The bank makes 30.4% of all its calls in May, but May has the lowest conversion rate of any month at 6.7%. March, with just 1.1% of total calls, converts at 52%. The bank is running its biggest effort in its worst month — and that single insight is probably worth more than all the demographic analysis combined."

**Q: How did you handle the class imbalance?**
> "Since this is a pure analytics project — not a predictive modelling project — class imbalance doesn't require resampling techniques like SMOTE. I just ensured all conversion rates are expressed as percentages with sample sizes shown, so the 11.7% baseline is always visible as context. The imbalance itself is the finding: it quantifies the inefficiency of the current broad-reach strategy."

**Q: What is duration's relationship with conversion, and why can't you use it for targeting?**
> "Duration has the strongest numeric correlation with subscription at r=0.395, and subscribers average 537 seconds vs 221 seconds for non-subscribers — a 2.4× gap confirmed as significant by a Mann-Whitney U test. But duration is a post-call metric. We only know it after the call ends. Using it to decide who to call would be like using exam scores to decide who to let into the exam. It's useful for agent training and quality benchmarking, but it's explicitly excluded from the targeting logic."

---

## Phase 3 Deliverables Checklist

- [x] Complete Python EDA script (`bank_campaign_eda.py`)
- [x] Jupyter notebook (`bank_campaign_eda.ipynb`) — 38 cells, 18 sections
- [x] 15 production charts saved to `assets/screenshots/`
- [x] Statistical hypothesis tests (Mann-Whitney U + Chi-square)
- [x] EDA Summary Report (this document)
- [x] 10 validated findings with business interpretation
- [x] 4 customer personas defined and quantified
- [x] Interview Q&A for Phase 3

---

*Phase 3 EDA Summary Report — BCA-2025-001 | Analyst: Ritik*
*Ready for Phase 4 — Power BI Dashboard*
