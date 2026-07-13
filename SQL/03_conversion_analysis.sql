-- =============================================================================
-- SCRIPT 03: Conversion Rate Analysis
-- Project  : Bank Term Deposit Campaign Effectiveness Analytics
-- Analyst  : Ritik
-- Version  : 1.0
-- =============================================================================
-- PURPOSE:
--   Deep-dive into campaign conversion rates across time, contact channels,
--   and campaign-level aggregations. This script answers the CMO's core
--   question: "How is our campaign performing, and where are we winning?"
--
-- KEY BUSINESS QUESTIONS ANSWERED:
--   Q1. What is the overall conversion rate and how does it trend over months?
--   Q2. Are some months systematically better for conversions than others?
--   Q3. How does conversion rate vary by day of the month?
--   Q4. What is the cost implication of the current conversion rate?
--   Q5. How does conversion compare: valid calls vs all contacts?
-- =============================================================================

USE bank_campaign;


-- =============================================================================
-- SECTION A: Overall Campaign Conversion Summary
-- =============================================================================

-- -----------------------------------------------------------------------------
-- A1. The headline KPI card
-- This single query powers the "Executive Summary" KPI row in Power BI Page 1
-- -----------------------------------------------------------------------------
SELECT
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    COUNT(*) - SUM(subscription_flag)                  AS non_subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,

    -- What if we excluded zero-duration (no-connection) calls?
    SUM(CASE WHEN valid_call_flag = 1 THEN 1 ELSE 0 END)               AS valid_calls,
    SUM(CASE WHEN valid_call_flag = 1 THEN subscription_flag ELSE 0 END) AS subscriptions_from_valid_calls,
    ROUND(
        SUM(CASE WHEN valid_call_flag = 1 THEN subscription_flag ELSE 0 END) * 100.0
        / NULLIF(SUM(CASE WHEN valid_call_flag = 1 THEN 1 ELSE 0 END), 0)
    , 2)                                                AS valid_call_conversion_rate_pct,

    -- Cost model (conservative estimate: ~150 INR per call)
    ROUND(COUNT(*) * 150 / 100000.0, 2)                AS total_campaign_cost_lakh_inr,
    ROUND(
        (COUNT(*) - SUM(subscription_flag)) * 150 / 100000.0
    , 2)                                                AS wasted_spend_lakh_inr,
    ROUND(COUNT(*) * 150 / NULLIF(SUM(subscription_flag), 0), 0) AS cost_per_acquisition_inr

FROM bank_analysis;


-- =============================================================================
-- SECTION B: Monthly Conversion Trend
-- =============================================================================

-- -----------------------------------------------------------------------------
-- B1. Conversion rate and volume by month — sorted chronologically
-- INSIGHT: High volume months ≠ high conversion rate months
-- This is a key finding for campaign timing recommendations.
-- -----------------------------------------------------------------------------
SELECT
    UPPER(`month`)                                      AS month_name,
    month_num,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(COUNT(*) * 100.0 / 45211, 2)                 AS share_of_contacts_pct,

    -- Rolling insight: is conversion rate above or below overall average (11.7%)?
    CASE
        WHEN AVG(subscription_flag) * 100 >= 11.7 THEN 'Above Average'
        ELSE 'Below Average'
    END                                                 AS vs_overall_avg

FROM bank_analysis
GROUP BY `month`, month_num
ORDER BY month_num;


-- -----------------------------------------------------------------------------
-- B2. Best and worst months ranked by conversion rate
-- Useful for a single "top/bottom" insight callout in the report
-- -----------------------------------------------------------------------------
SELECT
    UPPER(`month`)                                      AS month_name,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    RANK() OVER (ORDER BY AVG(subscription_flag) DESC) AS conversion_rank
FROM bank_analysis
GROUP BY `month`, month_num
ORDER BY conversion_rate_pct DESC;


-- =============================================================================
-- SECTION C: Day-of-Month Conversion Patterns
-- =============================================================================

-- -----------------------------------------------------------------------------
-- C1. Conversion rate by day of month
-- Are there specific days when customers are more receptive?
-- Groups into week-of-month buckets for cleaner insights.
-- -----------------------------------------------------------------------------
SELECT
    CASE
        WHEN `day` BETWEEN 1  AND 7  THEN 'Week 1 (Days 1-7)'
        WHEN `day` BETWEEN 8  AND 14 THEN 'Week 2 (Days 8-14)'
        WHEN `day` BETWEEN 15 AND 21 THEN 'Week 3 (Days 15-21)'
        ELSE                               'Week 4 (Days 22-31)'
    END                                                 AS week_of_month,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct
FROM bank_analysis
GROUP BY week_of_month
ORDER BY MIN(`day`);


-- =============================================================================
-- SECTION D: Conversion by Contact Channel
-- =============================================================================

-- -----------------------------------------------------------------------------
-- D1. Cellular vs telephone vs unknown — which channel converts best?
-- This directly informs how the bank should prioritise its outreach channels.
-- -----------------------------------------------------------------------------
SELECT
    contact                                             AS contact_channel,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(COUNT(*) * 100.0 / 45211, 2)                 AS share_of_contacts_pct,

    -- How many times better/worse than the "unknown" channel?
    ROUND(
        AVG(subscription_flag) /
        NULLIF(
            AVG(AVG(subscription_flag)) OVER (), 0
        ) , 2
    )                                                   AS conversion_index

FROM bank_analysis
GROUP BY contact
ORDER BY conversion_rate_pct DESC;


-- =============================================================================
-- SECTION E: Conversion Funnel Analysis
-- =============================================================================

-- -----------------------------------------------------------------------------
-- E1. Conversion funnel stages
-- Maps the journey from all contacts → valid calls → subscriptions.
-- This is the "funnel" visual on Power BI Page 1.
-- -----------------------------------------------------------------------------
SELECT
    'Stage 1: All Contacts'                             AS funnel_stage,
    COUNT(*)                                            AS record_count,
    ROUND(COUNT(*) * 100.0 / 45211, 1)                AS pct_of_total
FROM bank_analysis

UNION ALL

SELECT
    'Stage 2: Valid Calls (duration > 0)',
    SUM(valid_call_flag),
    ROUND(SUM(valid_call_flag) * 100.0 / 45211, 1)
FROM bank_analysis

UNION ALL

SELECT
    'Stage 3: Calls >1 Minute (duration >= 60)',
    SUM(CASE WHEN duration >= 60 THEN 1 ELSE 0 END),
    ROUND(SUM(CASE WHEN duration >= 60 THEN 1 ELSE 0 END) * 100.0 / 45211, 1)
FROM bank_analysis

UNION ALL

SELECT
    'Stage 4: Subscriptions (y = yes)',
    SUM(subscription_flag),
    ROUND(AVG(subscription_flag) * 100, 1)
FROM bank_analysis;


-- =============================================================================
-- SECTION F: Year-over-Year Style Comparison (using poutcome as proxy)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- F1. How does current campaign performance differ for customers with
--     vs without prior campaign history?
-- Measures the "warm lead multiplier" — how much better warm leads perform.
-- -----------------------------------------------------------------------------
SELECT
    prior_contact_flag,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(
        AVG(subscription_flag) /
        MIN(AVG(subscription_flag)) OVER ()
    , 2)                                                AS lift_vs_lowest_segment
FROM bank_analysis
GROUP BY prior_contact_flag
ORDER BY conversion_rate_pct DESC;


-- =============================================================================
-- END OF SCRIPT 03
-- KEY FINDINGS TO DOCUMENT:
--   - Overall conversion rate: ~11.7%
--   - Best months for conversion: March, September, October, December
--   - Cellular contact channel outperforms telephone significantly
--   - Warm leads (prior contact) convert at notably higher rates
-- Next: Run 04_demographic_profiling.sql
-- =============================================================================
