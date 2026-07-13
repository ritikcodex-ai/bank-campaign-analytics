# Phase 2 — SQL Analytics: Script Index & Execution Guide
## Bank Term Deposit Campaign Effectiveness Analytics

**Project Code:** BCA-2025-001
**Phase:** 2 of 5
**Total Scripts:** 9
**Status:** ✅ Complete

---

## Execution Order

> ⚠️ Scripts MUST be run in the order listed below.
> Script 09 depends on a VIEW created in Script 08.
> All scripts depend on the `bank_analysis` table created in Script 01.

---

## Script Reference

### `01_schema_setup.sql`
| Field | Detail |
|---|---|
| **Business Objective** | Create the database, load raw data, engineer all derived columns |
| **Run First** | Yes — all other scripts depend on `bank_analysis` table |
| **Key Output** | `bank_campaign` database, `bank_raw` table, `bank_analysis` table with 9 derived columns |
| **Derived Columns Created** | `subscription_flag`, `age_band`, `balance_tier`, `contact_frequency_band`, `prior_contact_flag`, `call_quality_band`, `month_num`, `debt_burden_flag`, `valid_call_flag` |
| **Verification Query** | `SELECT COUNT(*) FROM bank_analysis;` → Expected: 45,211 |

---

### `02_data_exploration.sql`
| Field | Detail |
|---|---|
| **Business Objective** | Understand the dataset before analysis — distributions, summary stats, data quality flags |
| **Business Question** | "What does our dataset actually contain, and are there any data issues we should know about?" |
| **Key Sections** | A: Dataset overview · B: Categorical distributions · C: Numeric distributions · D: Monthly volumes · E: Data quality flags |
| **Key Output** | Baseline statistics for all 17 columns, "unknown" prevalence by column, zero-duration call count |
| **Expected Insight** | 11.7% overall conversion rate; May has highest contact volume but not highest conversion; ~28.8% of contacts have unknown contact method |
| **Business Recommendation** | Use these numbers as the factual foundation for all stakeholder conversations |

---

### `03_conversion_analysis.sql`
| Field | Detail |
|---|---|
| **Business Objective** | Measure overall campaign conversion performance and identify timing patterns |
| **Business Question** | "How is our campaign performing month-by-month, and when are customers most receptive?" |
| **Key Sections** | A: Headline KPI card · B: Monthly trend · C: Day-of-month patterns · D: Channel comparison · E: Conversion funnel · F: Warm vs cold lead split |
| **Key Output** | Monthly conversion rates, contact channel efficiency, 4-stage funnel analysis, cost-per-acquisition baseline |
| **Expected Insight** | March, September, October, December show above-average conversion; cellular outperforms telephone; warm leads outperform cold leads |
| **Business Recommendation** | Concentrate campaign activity in high-conversion months; prioritise cellular channel; build warm lead calling list |

---

### `04_demographic_profiling.sql`
| Field | Detail |
|---|---|
| **Business Objective** | Identify which customer demographics predict term deposit subscription |
| **Business Question** | "Who is our ideal customer — which age, job, and life situation should we target?" |
| **Key Sections** | A: Age band profiling · B: Job type profiling · C: Marital and education · D: Debt burden impact · E: Multi-dimensional segments |
| **Key Output** | Conversion rate + lift index for every demographic dimension; top 15 age × job combinations |
| **Expected Insight** | Retired and student segments over-index; debt-free customers convert significantly better; dual debt burden is the clearest negative signal |
| **Business Recommendation** | Prioritise retired and management segments; deprioritise blue-collar customers with dual debt burden |

---

### `05_balance_tier_analysis.sql`
| Field | Detail |
|---|---|
| **Business Objective** | Quantify how account balance predicts term deposit conversion and deposit value |
| **Business Question** | "Do wealthier customers convert more, and does it translate to meaningfully larger deposits?" |
| **Key Sections** | A: Balance tier conversion · B: Balance × demographics · C: Negative balance deep-dive · D: Balance × debt burden · E: Deposit value opportunity model |
| **Key Output** | Conversion rate by 5 balance tiers, estimated total deposit value by tier, combined wealth + demographic matrix |
| **Expected Insight** | Very High balance (20K+ EUR) customers convert at materially higher rates and represent disproportionate deposit value; negative balance customers are poor targets on both conversion AND deposit value dimensions |
| **Business Recommendation** | Target balance ≥ 1,000 EUR customers as minimum threshold; High and Very High balance customers should be called in the first wave |

---

### `06_campaign_diagnostics.sql`
| Field | Detail |
|---|---|
| **Business Objective** | Diagnose campaign execution tactics — frequency, duration, and timing efficiency |
| **Business Question** | "Is the bank calling too many times? What does a high-quality call look like?" |
| **Key Sections** | A: Contact frequency fatigue curve · B: Budget waste from over-contacting · C: Call duration analysis · D: Month × frequency interaction |
| **Key Output** | Conversion rate by exact call count (1 to 15+), budget waste model for 4+ calls, duration distribution by outcome |
| **Expected Insight** | Conversion drops sharply after 3rd call; subscribers have significantly longer average call durations; excess calls (4+) represent material wasted spend |
| **Business Recommendation** | Implement a 3-call cap policy per customer per campaign; train agents to sustain longer conversations with high-signal customers |

---

### `07_previous_campaign_impact.sql`
| Field | Detail |
|---|---|
| **Business Objective** | Measure the "warm lead multiplier" — how prior campaign success predicts current conversion |
| **Business Question** | "Are customers who subscribed before more likely to subscribe again, and by how much?" |
| **Key Sections** | A: poutcome conversion comparison · B: Contact recency analysis · C: Warm lead demographics · D: Warm lead × frequency interaction · E: Priority calling queue |
| **Key Output** | Conversion rate by poutcome category, warm lead lift multiplier, priority calling queue by combined segment |
| **Expected Insight** | poutcome='success' customers convert at 5–8× the overall average; even failed leads outperform unknown (cold) leads; warm leads should be called first and capped at 1–2 contacts |
| **Business Recommendation** | Build a dedicated "Warm Lead Priority List" at the start of every campaign — these are the bank's highest-ROI contacts by far |

---

### `08_customer_targeting_matrix.sql`
| Field | Detail |
|---|---|
| **Business Objective** | Build a rule-based targeting score and identify the four named customer personas |
| **Business Question** | "If we could only contact our best prospects, who would they be?" |
| **Key Sections** | A: Composite targeting score (9-factor model) · B: Score validation · C: ICP top segments · D: Concentration analysis · E: 4 named customer personas |
| **Key Output** | `customer_targeting_score` VIEW, score band validation table, 4 named personas (Loyal Retiree, Affluent Professional, Financial Student, Over-Leveraged) |
| **Expected Insight** | Rule-based scores successfully rank segments by conversion rate; top 20% of scored customers capture a disproportionate share of all subscriptions |
| **Business Recommendation** | Use the targeting score as a campaign pre-filter; call Score A+ and A customers in Wave 1, B in Wave 2, C and below only if budget remains |
| **⚠️ Dependency** | This script creates the `customer_targeting_score` VIEW required by Script 09 |

---

### `09_campaign_roi_model.sql`
| Field | Detail |
|---|---|
| **Business Objective** | Quantify the financial return of targeted vs broad outreach — the "so what?" of the entire project |
| **Business Question** | "How much money is the bank wasting, and what is the financial case for changing strategy?" |
| **Key Sections** | A: Current state ROI baseline · B: Projected targeted state · C: Sensitivity analysis (6 thresholds) · D: Call cap ROI · E: Three-scenario executive comparison |
| **Key Output** | Current CPA (~₹1,282), targeted CPA (run to find), spend saved by targeting, 3-scenario comparison table for executive presentation |
| **Expected Insight** | Implementing targeted outreach (score ≥5 + 3-call cap) can significantly reduce cost-per-acquisition while retaining the majority of subscription volume |
| **Business Recommendation** | See Phase 5 Executive Recommendations Report for full narrative |
| **⚠️ Dependency** | Requires `customer_targeting_score` VIEW from Script 08 |

---

## Key Metrics Reference

| Metric | Definition | Script |
|---|---|---|
| Overall Conversion Rate | `AVG(subscription_flag) × 100` | 03 |
| Segment Lift | `Segment Conv. Rate / 11.7` | 04, 05, 07 |
| Cost Per Acquisition (CPA) | `Total Calls × ₹150 / Subscriptions` | 03, 09 |
| Campaign Fatigue Rate | Conversion rate by call count | 06 |
| Warm Lead Multiplier | `poutcome='success' rate / overall rate` | 07 |
| Targeting Score | 9-factor weighted rule model (max ~21) | 08 |
| Wasted Spend | `(Calls - Subscriptions) × ₹150` | 09 |
| Deposit Value Opportunity | `Subscriptions × Avg Balance × 20% × 1.5%` | 05, 09 |

---

## Interview Quick Reference

When asked "walk me through your SQL," use this flow:

> "I started with schema setup and data preparation in Script 01, where I also engineered 9 derived columns — things like age bands, balance tiers, and a debt burden flag. Script 02 gave me the baseline dataset profile. Scripts 03 through 07 each answered a specific business question: overall conversion trends, demographic profiling, wealth segmentation, campaign fatigue, and previous campaign impact. In Script 08, I built a composite targeting score using a 9-factor rule model that ranked customers by conversion likelihood. And in Script 09, I quantified the ROI of adopting that targeting strategy versus the bank's current broad-reach approach — showing the projected reduction in cost-per-acquisition."

---

*Phase 2 — SQL Analytics | BCA-2025-001 | Analyst: Ritik*
