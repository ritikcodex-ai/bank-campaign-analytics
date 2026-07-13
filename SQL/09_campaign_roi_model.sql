-- =============================================================================
-- SCRIPT 09: Campaign ROI Model & Targeting Efficiency Projection
-- Project  : Bank Term Deposit Campaign Effectiveness Analytics
-- Analyst  : Ritik
-- Version  : 1.0
-- =============================================================================
-- PURPOSE:
--   Quantify the financial impact of adopting a targeted outreach strategy
--   versus the bank's current broad-reach approach.
--
--   This is the "so what?" of the entire engagement.
--   All previous analysis has been building to this:
--   "If BankX follows our recommendations, here is the projected
--    improvement in cost-per-acquisition and campaign ROI."
--
-- KEY BUSINESS QUESTIONS ANSWERED:
--   Q1. What is the bank's current cost per term deposit acquired?
--   Q2. If we only called Priority 1 & 2 segments, what would the
--       conversion rate and CPA look like?
--   Q3. How many wasted calls (and ₹ spent) can be eliminated?
--   Q4. What is the ROI of implementing a targeted calling strategy?
--
-- ASSUMPTIONS (all conservative, all documented):
--   - Cost per call: ₹150 (agent time + infrastructure)
--   - Deposit margin: 1.5% annual net interest margin on term deposits
--   - Average term deposit size: 20% of customer average balance
--   - Term deposit tenure: 12 months
-- =============================================================================

USE bank_campaign;


-- =============================================================================
-- SECTION A: Current State ROI Baseline
-- =============================================================================

-- -----------------------------------------------------------------------------
-- A1. Current campaign economics — the baseline to beat
-- Every recommendation must be measured against these numbers.
-- -----------------------------------------------------------------------------
SELECT
    -- Volume metrics
    COUNT(*)                                            AS total_calls_made,
    SUM(subscription_flag)                              AS total_subscriptions,
    COUNT(*) - SUM(subscription_flag)                  AS wasted_calls,
    ROUND(AVG(subscription_flag) * 100, 2)             AS overall_conversion_rate_pct,

    -- Cost metrics (₹150 per call)
    COUNT(*) * 150                                      AS total_campaign_cost_inr,
    ROUND(COUNT(*) * 150 / 100000.0, 2)                AS total_campaign_cost_lakh_inr,
    (COUNT(*) - SUM(subscription_flag)) * 150          AS wasted_spend_inr,
    ROUND((COUNT(*) - SUM(subscription_flag)) * 150 / 100000.0, 2)
                                                        AS wasted_spend_lakh_inr,

    -- Efficiency metrics
    ROUND(COUNT(*) * 150.0 / NULLIF(SUM(subscription_flag), 0), 0)
                                                        AS cost_per_acquisition_inr,
    ROUND(COUNT(*) * 1.0 / NULLIF(SUM(subscription_flag), 0), 1)
                                                        AS calls_per_subscription,

    -- Revenue metrics (estimated term deposit value)
    -- Avg balance * 20% deposit rate * 1.5% margin * 12 months
    ROUND(SUM(subscription_flag) * AVG(balance) * 0.20 * 0.015, 0)
                                                        AS estimated_annual_revenue_eur,
    ROUND(SUM(subscription_flag) * AVG(balance) * 0.20 * 0.015
          / NULLIF(COUNT(*) * 150 / 84.0, 0) -- Convert INR to EUR at ~84 rate
    , 2)                                                AS campaign_roi_ratio

FROM bank_analysis;


-- =============================================================================
-- SECTION B: Projected State — Targeted Outreach Strategy
-- =============================================================================

-- -----------------------------------------------------------------------------
-- B1. What if we ONLY called customers with score >= 5 (B-tier and above)?
-- This is the "smart targeting" scenario.
-- Compares: volume reduction vs conversion gain vs cost saving.
-- -----------------------------------------------------------------------------
WITH current_state AS (
    SELECT
        COUNT(*)                                        AS total_calls,
        SUM(subscription_flag)                          AS subscriptions,
        ROUND(AVG(subscription_flag) * 100, 2)         AS conversion_rate_pct,
        COUNT(*) * 150                                  AS total_cost_inr,
        ROUND(COUNT(*) * 150.0 / NULLIF(SUM(subscription_flag), 0), 0)
                                                        AS cpa_inr
    FROM bank_analysis
),
targeted_state AS (
    SELECT
        COUNT(*)                                        AS total_calls,
        SUM(subscription_flag)                          AS subscriptions,
        ROUND(AVG(subscription_flag) * 100, 2)         AS conversion_rate_pct,
        COUNT(*) * 150                                  AS total_cost_inr,
        ROUND(COUNT(*) * 150.0 / NULLIF(SUM(subscription_flag), 0), 0)
                                                        AS cpa_inr
    FROM customer_targeting_score
    WHERE targeting_score >= 5  -- Only call B-tier and above
)
SELECT
    'Current: Broad Outreach'                           AS strategy,
    c.total_calls,
    c.subscriptions,
    c.conversion_rate_pct,
    c.total_cost_inr,
    ROUND(c.total_cost_inr / 100000.0, 2)              AS total_cost_lakh_inr,
    c.cpa_inr
FROM current_state c

UNION ALL

SELECT
    'Proposed: Targeted Outreach (Score ≥ 5)',
    t.total_calls,
    t.subscriptions,
    t.conversion_rate_pct,
    t.total_cost_inr,
    ROUND(t.total_cost_inr / 100000.0, 2),
    t.cpa_inr
FROM targeted_state t;


-- -----------------------------------------------------------------------------
-- B2. Sensitivity analysis — what if we used different score thresholds?
-- Shows the conversion rate and % of subscriptions captured at each threshold.
-- Helps the campaign team pick the right precision vs recall trade-off.
-- -----------------------------------------------------------------------------
SELECT
    score_threshold,
    customers_in_scope,
    pct_of_database,
    subscriptions_captured,
    pct_of_all_subscriptions,
    conversion_rate_pct,
    cost_lakh_inr,
    cpa_inr,
    calls_eliminated,
    spend_saved_lakh_inr
FROM (
    SELECT
        threshold_val                                   AS score_threshold,
        COUNT(*)                                        AS customers_in_scope,
        ROUND(COUNT(*) * 100.0 / 45211, 1)             AS pct_of_database,
        SUM(subscription_flag)                          AS subscriptions_captured,
        ROUND(SUM(subscription_flag) * 100.0
              / (SELECT SUM(subscription_flag) FROM bank_analysis), 1)
                                                        AS pct_of_all_subscriptions,
        ROUND(AVG(subscription_flag) * 100, 2)         AS conversion_rate_pct,
        ROUND(COUNT(*) * 150 / 100000.0, 2)            AS cost_lakh_inr,
        ROUND(COUNT(*) * 150.0 / NULLIF(SUM(subscription_flag),0), 0)
                                                        AS cpa_inr,
        45211 - COUNT(*)                                AS calls_eliminated,
        ROUND((45211 - COUNT(*)) * 150 / 100000.0, 2)  AS spend_saved_lakh_inr
    FROM customer_targeting_score
    CROSS JOIN (
        SELECT 0 AS threshold_val UNION SELECT 2 UNION SELECT 4
        UNION SELECT 6 UNION SELECT 8 UNION SELECT 10
    ) thresholds
    WHERE targeting_score >= threshold_val
    GROUP BY threshold_val
) sensitivity
ORDER BY score_threshold;


-- =============================================================================
-- SECTION C: Priority Segment ROI
-- =============================================================================

-- -----------------------------------------------------------------------------
-- C1. ROI by calling priority tier
-- Shows the cost efficiency of each segment tier.
-- The contrast between Tier 1 and Tier 4 CPA makes the case for targeting.
-- -----------------------------------------------------------------------------
SELECT
    CASE
        WHEN targeting_score >= 12 THEN 'Tier 1 — Premium (12+)'
        WHEN targeting_score >= 8  THEN 'Tier 2 — High (8-11)'
        WHEN targeting_score >= 5  THEN 'Tier 3 — Standard (5-7)'
        WHEN targeting_score >= 2  THEN 'Tier 4 — Low (2-4)'
        ELSE                            'Tier 5 — Minimal (0-1 or below)'
    END                                                 AS priority_tier,
    COUNT(*)                                            AS calls,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(COUNT(*) * 150 / 100000.0, 2)                AS spend_lakh_inr,
    ROUND(COUNT(*) * 150.0 / NULLIF(SUM(subscription_flag),0), 0)
                                                        AS cost_per_acquisition_inr,
    ROUND(COUNT(*) * 1.0  / NULLIF(SUM(subscription_flag),0), 1)
                                                        AS calls_per_subscription
FROM customer_targeting_score
GROUP BY priority_tier
ORDER BY MIN(targeting_score) DESC;


-- =============================================================================
-- SECTION D: Call Frequency ROI
-- =============================================================================

-- -----------------------------------------------------------------------------
-- D1. ROI impact of capping calls at 3 per customer
-- The campaign fatigue finding translated into financial terms.
-- How much could the bank save by implementing a "3-call cap" policy?
-- -----------------------------------------------------------------------------
SELECT
    CASE
        WHEN campaign <= 3 THEN 'Within Cap (1-3 calls) — Keep'
        ELSE                    'Excess Calls (4+) — Eliminate'
    END                                                 AS call_policy,
    COUNT(*)                                            AS total_call_records,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(COUNT(*) * 150 / 100000.0, 2)                AS spend_lakh_inr,
    ROUND(COUNT(*) * 150.0 / NULLIF(SUM(subscription_flag),0), 0)
                                                        AS cost_per_acquisition_inr
FROM bank_analysis
GROUP BY call_policy
ORDER BY call_policy;


-- =============================================================================
-- SECTION E: Executive Summary — The Final Impact Statement
-- =============================================================================

-- -----------------------------------------------------------------------------
-- E1. Three-scenario comparison:
--   Scenario A: Current state (broad reach, no cap)
--   Scenario B: Targeted outreach only (score >= 5) + 3-call cap
--   Scenario C: Warm leads only (poutcome = success) + high balance (4+5 tier)
-- This is the slide that goes to the Head of Retail Banking.
-- -----------------------------------------------------------------------------
SELECT scenario, calls, subscriptions, conversion_rate_pct,
       cost_lakh_inr, cpa_inr, calls_saved, spend_saved_lakh_inr
FROM (

    -- Scenario A: Current State
    SELECT
        'A — Current: Broad Outreach (No Targeting)'    AS scenario,
        COUNT(*)                                        AS calls,
        SUM(subscription_flag)                          AS subscriptions,
        ROUND(AVG(subscription_flag)*100,2)             AS conversion_rate_pct,
        ROUND(COUNT(*)*150/100000.0,2)                  AS cost_lakh_inr,
        ROUND(COUNT(*)*150.0/NULLIF(SUM(subscription_flag),0),0) AS cpa_inr,
        0                                               AS calls_saved,
        0.00                                            AS spend_saved_lakh_inr
    FROM bank_analysis

    UNION ALL

    -- Scenario B: Targeted + call cap
    SELECT
        'B — Proposed: Targeted Outreach (Score ≥5, Cap 3 Calls)',
        COUNT(*),
        SUM(subscription_flag),
        ROUND(AVG(subscription_flag)*100,2),
        ROUND(COUNT(*)*150/100000.0,2),
        ROUND(COUNT(*)*150.0/NULLIF(SUM(subscription_flag),0),0),
        45211 - COUNT(*),
        ROUND((45211-COUNT(*))*150/100000.0,2)
    FROM customer_targeting_score
    WHERE targeting_score >= 5 AND campaign <= 3

    UNION ALL

    -- Scenario C: Warm leads + high balance only
    SELECT
        'C — Premium: Warm Leads + High Balance Only',
        COUNT(*),
        SUM(subscription_flag),
        ROUND(AVG(subscription_flag)*100,2),
        ROUND(COUNT(*)*150/100000.0,2),
        ROUND(COUNT(*)*150.0/NULLIF(SUM(subscription_flag),0),0),
        45211 - COUNT(*),
        ROUND((45211-COUNT(*))*150/100000.0,2)
    FROM bank_analysis
    WHERE poutcome = 'success'
       OR balance_tier IN ('4. High (5K-20K)','5. Very High (20K+)')

) scenarios
ORDER BY scenario;


-- =============================================================================
-- END OF SCRIPT 09 — END OF PHASE 2 SQL
-- =============================================================================
-- PHASE 2 COMPLETE. ALL 9 SCRIPTS DELIVERED.
--
-- MASTER FINDINGS SUMMARY (populate from your actual query results):
--
-- 1. OVERALL CONVERSION:      ~11.7% (1 in 8.5 calls converts)
-- 2. WARM LEAD MULTIPLIER:    poutcome='success' converts at ~5-8x baseline
-- 3. CAMPAIGN FATIGUE:        Conversion drops sharply after call 3
-- 4. BEST SEGMENTS:           Retired + High Balance + Debt Free
-- 5. BEST MONTHS:             March, September, October, December
-- 6. TARGETING OPPORTUNITY:   Targeting score ≥5 retains ~X% of subscriptions
--                             while eliminating ~Y% of wasted calls
-- 7. CPA IMPROVEMENT:         Current ~₹1,282 → Targeted ~₹X (run to find)
-- 8. WASTED SPEND:            ~₹59.9L in non-converting calls vs current approach
-- =============================================================================
