# Phase 2 — SQL Analytics: Completion Summary
## Bank Term Deposit Campaign Effectiveness Analytics

**Phase Status:** ✅ Complete
**Scripts Delivered:** 9 production SQL scripts + 1 index document
**Dataset Confirmed:** bank-full.csv · 45,211 records · 17 columns · 0 nulls

---

## Scripts Delivered

| # | Script | Business Question | Status |
|---|---|---|---|
| 00 | `00_sql_index.md` | Master index and execution guide | ✅ |
| 01 | `01_schema_setup.sql` | Schema, data load, derived columns | ✅ |
| 02 | `02_data_exploration.sql` | Dataset profile and distributions | ✅ |
| 03 | `03_conversion_analysis.sql` | Overall conversion + monthly trends | ✅ |
| 04 | `04_demographic_profiling.sql` | Age, job, marital, education analysis | ✅ |
| 05 | `05_balance_tier_analysis.sql` | Wealth segmentation + deposit value | ✅ |
| 06 | `06_campaign_diagnostics.sql` | Contact fatigue + call duration | ✅ |
| 07 | `07_previous_campaign_impact.sql` | Warm lead multiplier analysis | ✅ |
| 08 | `08_customer_targeting_matrix.sql` | Targeting score + customer personas | ✅ |
| 09 | `09_campaign_roi_model.sql` | ROI model + 3-scenario comparison | ✅ |

---

## ✅ VERIFIED FINDINGS — Real Numbers from bank-full.csv

### Headline KPIs
| Metric | Actual Value |
|---|---|
| Total contacts | 45,211 |
| Total subscriptions | 5,289 |
| Overall conversion rate | **11.70%** |
| Non-conversion rate | 88.30% |
| Zero-duration calls | 3 records (0.007%) — negligible |
| Estimated campaign cost (₹150/call) | **₹67.8 Lakh** |
| Estimated wasted spend | **₹59.9 Lakh** (non-converting calls) |
| Current cost per acquisition | **₹1,282** |

---

### Conversion by Job Type
| Job | Contacts | Subscriptions | Conversion Rate | Lift vs Avg |
|---|---|---|---|---|
| student | 938 | 269 | **28.68%** | 2.45× |
| retired | 2,264 | 516 | **22.79%** | 1.95× |
| unemployed | 1,303 | 202 | 15.50% | 1.32× |
| management | 9,458 | 1,301 | 13.76% | 1.18× |
| admin. | 5,171 | 631 | 12.20% | 1.04× |
| self-employed | 1,579 | 187 | 11.84% | 1.01× |
| technician | 7,597 | 840 | 11.06% | 0.95× |
| services | 4,154 | 369 | 8.88% | 0.76× |
| housemaid | 1,240 | 109 | 8.79% | 0.75× |
| entrepreneur | 1,487 | 123 | 8.27% | 0.71× |
| **blue-collar** | **9,732** | **708** | **7.27%** | **0.62×** |

> **Key insight:** Students (28.7%) and retirees (22.8%) convert at 2–2.5× the average. Blue-collar is the largest segment yet the lowest converter — the bank is over-investing here.

---

### Conversion by Age Band
| Age Band | Contacts | Subscriptions | Conversion Rate |
|---|---|---|---|
| Young (18–30) | 7,030 | 1,145 | 16.29% |
| Early Career (31–40) | 17,687 | 1,812 | 10.24% |
| Mid Career (41–50) | 11,239 | 1,019 | 9.07% |
| Pre-Retirement (51–60) | 8,067 | 811 | 10.05% |
| **Retired (61+)** | **1,188** | **502** | **42.26%** ⭐ |

> **Standout finding:** Retired customers (61+) convert at an extraordinary **42.26%** — nearly 4× the overall average. This is the single highest-converting demographic segment in the entire dataset.

---

### Conversion by Previous Campaign Outcome (Warm Lead Multiplier)
| poutcome | Contacts | Subscriptions | Conversion Rate | Lift vs Cold |
|---|---|---|---|---|
| **success** | 1,511 | 978 | **64.73%** | **7.07×** |
| other | 1,840 | 307 | 16.68% | 1.82× |
| failure | 4,901 | 618 | 12.61% | 1.38× |
| unknown (cold) | 36,959 | 3,386 | 9.16% | baseline |

> **Key insight:** Customers who subscribed in a previous campaign convert at **64.73%** — a **7× multiplier** over cold leads. These 1,511 customers should be the first call every campaign.

---

### Conversion by Month
| Month | Contacts | Subscriptions | Conversion Rate |
|---|---|---|---|
| **mar** | 477 | 248 | **52.0%** ⭐ |
| **dec** | 214 | 100 | **46.7%** |
| **sep** | 579 | 269 | **46.5%** |
| **oct** | 738 | 323 | **43.8%** |
| apr | 2,932 | 577 | 19.7% |
| feb | 2,649 | 441 | 16.7% |
| aug | 6,247 | 688 | 11.0% |
| jan | 1,403 | 142 | 10.1% |
| nov | 3,970 | 403 | 10.2% |
| jun | 5,341 | 546 | 10.2% |
| jul | 6,895 | 627 | 9.1% |
| **may** | **13,766** | **925** | **6.7%** ❌ |

> **Critical finding:** May has the MOST contacts (13,766 = 30.4% of all calls) but the LOWEST conversion rate (6.7%). The bank is running its biggest effort in its worst month.

---

### Conversion by Contact Frequency (Campaign Fatigue)
| Calls Made | Contacts | Subscriptions | Conversion Rate |
|---|---|---|---|
| 1 Call | 17,544 | 2,561 | **14.60%** |
| 2–3 Calls | 18,026 | 2,019 | 11.20% |
| 4–5 Calls | 5,286 | 456 | 8.63% |
| **6+ Calls** | **4,355** | **253** | **5.81%** ❌ |

> **Fatigue confirmed:** Conversion drops from 14.6% on the first call to 5.8% after 6+ calls. Customers called 6+ times represent 9.6% of all contacts but convert at half the average rate.

---

### Conversion by Balance Tier
| Balance Tier | Contacts | Subscriptions | Conversion Rate |
|---|---|---|---|
| Very High (20K+) | 193 | 29 | 15.03% |
| High (5K–20K) | 2,652 | 412 | **15.54%** |
| Medium (1K–5K) | 11,786 | 1,807 | 15.33% |
| Low (0–999) | 23,300 | 2,539 | 10.90% |
| **Negative (<0)** | **7,280** | **502** | **6.90%** ❌ |

> **Insight:** Medium–High balance customers (₹1K–20K EUR) are the sweet spot — strong conversion rates AND large segment size. Negative balance customers convert at 6.9% — below average with low deposit value.

---

### Conversion by Debt Burden
| Debt Situation | Contacts | Subscriptions | Conversion Rate |
|---|---|---|---|
| **Debt Free** | 17,204 | 3,135 | **18.22%** ⭐ |
| Housing Loan Only | 20,763 | 1,670 | 8.04% |
| Personal Loan Only | 2,877 | 219 | 7.61% |
| **Dual Debt Burden** | **4,367** | **265** | **6.07%** ❌ |

> **Clearest negative signal in dataset:** Debt-free customers convert at 18.22% vs 6.07% for customers with both loans — a **3× difference**. Debt burden is the single strongest negative predictor.

---

### Call Duration: Subscribers vs Non-Subscribers
| Outcome | Avg Call Duration |
|---|---|
| **Subscribed (yes)** | **537 seconds (8.95 min)** |
| Did not subscribe (no) | 221 seconds (3.68 min) |
| **Difference** | **+316 seconds (+143%)** |

> Subscribers speak for **2.4× longer** on average. Longer calls signal genuine interest and engagement — a key diagnostic for agent training.

---

## The 5 Headline Numbers for Interviews

Memorise these. They answer 80% of interview questions about this project:

1. **11.70%** — overall campaign conversion rate (1 in 8.5 calls)
2. **64.73%** — conversion rate for warm leads (poutcome=success) — **7× multiplier**
3. **42.26%** — conversion rate for retired customers (61+) — highest demographic
4. **52.0%** — conversion rate in March — vs 6.7% in May (the bank's busiest month)
5. **18.22% vs 6.07%** — debt-free vs dual-debt conversion rate — **3× difference**

---

## SQL Techniques Used — Interview Checklist
- [x] `CREATE TABLE ... AS SELECT` — analysis table from raw
- [x] `CASE WHEN` — all derived column engineering (9 columns)
- [x] `GROUP BY` with `AVG()`, `SUM()`, `COUNT()` — all segmentation
- [x] `ROUND()` with `NULLIF()` — safe division
- [x] `RANK() OVER (ORDER BY ...)` — window function for ranking
- [x] `SUM() OVER (ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)` — cumulative sum
- [x] `WITH ... AS (CTE)` — Scripts 08 and 09
- [x] `CREATE OR REPLACE VIEW` — targeting score view
- [x] `CROSS JOIN` — sensitivity analysis in Script 09
- [x] `UNION ALL` — multi-scenario comparisons
- [x] `HAVING COUNT(*) >= N` — minimum sample size filters
- [x] `LOAD DATA LOCAL INFILE` — bulk CSV loading

---

*Phase 2 SQL Analytics — BCA-2025-001 | Verified against bank-full.csv (45,211 records)*
