-- =============================================================================
-- SCRIPT 04: Customer Demographic Profiling
-- Project  : Bank Term Deposit Campaign Effectiveness Analytics
-- Analyst  : Ritik
-- Version  : 1.0
-- =============================================================================
-- PURPOSE:
--   Answer the campaign manager's question: "Who is our ideal customer?"
--   Profiles conversion rates across all demographic dimensions and
--   identifies the specific combinations that over-index on subscription.
--
-- KEY BUSINESS QUESTIONS ANSWERED:
--   Q1. Which age groups convert most strongly?
--   Q2. Which job types are the bank's best term deposit customers?
--   Q3. Does marital status or education level predict conversion?
--   Q4. How does debt burden (loans) affect subscription likelihood?
--   Q5. Which two-way demographic combinations are the highest converters?
-- =============================================================================

USE bank_campaign;


-- =============================================================================
-- SECTION A: Age Band Profiling
-- =============================================================================

-- -----------------------------------------------------------------------------
-- A1. Conversion rate by age band with segment lift
-- Lift = how much this segment over- or under-performs vs the overall average
-- A lift of 1.5 means this segment converts 50% better than average
-- -----------------------------------------------------------------------------
SELECT
    age_band,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(COUNT(*) * 100.0 / 45211, 2)                 AS pct_of_all_contacts,

    -- Segment lift vs overall average (11.7%)
    ROUND(AVG(subscription_flag) / 0.117, 2)           AS conversion_lift,

    CASE
        WHEN AVG(subscription_flag) > 0.15  THEN '🟢 High Priority'
        WHEN AVG(subscription_flag) >= 0.11 THEN '🟡 Average'
        ELSE                                     '🔴 Low Priority'
    END                                                 AS targeting_priority

FROM bank_analysis
GROUP BY age_band
ORDER BY age_band;


-- -----------------------------------------------------------------------------
-- A2. Fine-grained age conversion (5-year buckets)
-- More granular than age bands — useful for precise targeting
-- -----------------------------------------------------------------------------
SELECT
    FLOOR(age / 5) * 5                                  AS age_group_start,
    CONCAT(FLOOR(age/5)*5, '-', FLOOR(age/5)*5+4)      AS age_group,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct
FROM bank_analysis
GROUP BY age_group_start, age_group
HAVING COUNT(*) >= 100  -- Only show groups with sufficient sample size
ORDER BY age_group_start;


-- =============================================================================
-- SECTION B: Job Type Profiling
-- =============================================================================

-- -----------------------------------------------------------------------------
-- B1. Conversion by occupation with rank and lift
-- KEY INSIGHT: Students and retirees consistently over-index
-- -----------------------------------------------------------------------------
SELECT
    job,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(COUNT(*) * 100.0 / 45211, 2)                 AS pct_of_contacts,
    ROUND(AVG(subscription_flag) / 0.117, 2)           AS conversion_lift,
    RANK() OVER (ORDER BY AVG(subscription_flag) DESC) AS conversion_rank,

    CASE
        WHEN AVG(subscription_flag) > 0.15  THEN 'High Priority'
        WHEN AVG(subscription_flag) >= 0.10 THEN 'Average'
        ELSE                                     'Low Priority'
    END                                                 AS targeting_priority

FROM bank_analysis
GROUP BY job
ORDER BY conversion_rate_pct DESC;


-- =============================================================================
-- SECTION C: Marital Status & Education Profiling
-- =============================================================================

-- -----------------------------------------------------------------------------
-- C1. Marital status conversion analysis
-- -----------------------------------------------------------------------------
SELECT
    marital,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(COUNT(*) * 100.0 / 45211, 2)                 AS pct_of_contacts,
    ROUND(AVG(subscription_flag) / 0.117, 2)           AS conversion_lift
FROM bank_analysis
GROUP BY marital
ORDER BY conversion_rate_pct DESC;


-- -----------------------------------------------------------------------------
-- C2. Education level conversion analysis
-- Does higher education correlate with term deposit interest?
-- -----------------------------------------------------------------------------
SELECT
    education,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(COUNT(*) * 100.0 / 45211, 2)                 AS pct_of_contacts,
    ROUND(AVG(subscription_flag) / 0.117, 2)           AS conversion_lift
FROM bank_analysis
GROUP BY education
ORDER BY conversion_rate_pct DESC;


-- -----------------------------------------------------------------------------
-- C3. Education × Marital status cross-tab
-- Two-way breakdown to identify the education + marital combination
-- that produces the highest conversion rate
-- -----------------------------------------------------------------------------
SELECT
    education,
    marital,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct
FROM bank_analysis
GROUP BY education, marital
HAVING COUNT(*) >= 200  -- Minimum sample size for reliable rates
ORDER BY conversion_rate_pct DESC
LIMIT 10;


-- =============================================================================
-- SECTION D: Debt Burden Impact
-- =============================================================================

-- -----------------------------------------------------------------------------
-- D1. Impact of housing loan + personal loan on conversion
-- Does debt burden reduce a customer's capacity to save?
-- -----------------------------------------------------------------------------
SELECT
    debt_burden_flag,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(COUNT(*) * 100.0 / 45211, 2)                 AS pct_of_contacts,
    ROUND(AVG(subscription_flag) / 0.117, 2)           AS conversion_lift
FROM bank_analysis
GROUP BY debt_burden_flag
ORDER BY conversion_rate_pct DESC;


-- -----------------------------------------------------------------------------
-- D2. Housing loan vs no housing loan — isolated effect
-- -----------------------------------------------------------------------------
SELECT
    housing                                             AS has_housing_loan,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct
FROM bank_analysis
GROUP BY housing
ORDER BY conversion_rate_pct DESC;


-- -----------------------------------------------------------------------------
-- D3. Personal loan vs no personal loan — isolated effect
-- -----------------------------------------------------------------------------
SELECT
    loan                                                AS has_personal_loan,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct
FROM bank_analysis
GROUP BY loan
ORDER BY conversion_rate_pct DESC;


-- =============================================================================
-- SECTION E: Multi-Dimensional Demographic Segments
-- =============================================================================

-- -----------------------------------------------------------------------------
-- E1. Age band × Job type — the most powerful two-way segment
-- Identifies which life stage + occupation combinations are highest value
-- Uses CTE to cleanly calculate segment lift vs overall average
-- -----------------------------------------------------------------------------
WITH segment_rates AS (
    SELECT
        age_band,
        job,
        COUNT(*)                                        AS total_contacts,
        SUM(subscription_flag)                          AS subscriptions,
        ROUND(AVG(subscription_flag) * 100, 2)         AS conversion_rate_pct
    FROM bank_analysis
    GROUP BY age_band, job
    HAVING COUNT(*) >= 150  -- Minimum sample size filter
)
SELECT
    age_band,
    job,
    total_contacts,
    subscriptions,
    conversion_rate_pct,
    ROUND(conversion_rate_pct / 11.7, 2)               AS lift_vs_average,
    RANK() OVER (ORDER BY conversion_rate_pct DESC)     AS overall_rank
FROM segment_rates
ORDER BY conversion_rate_pct DESC
LIMIT 15;


-- -----------------------------------------------------------------------------
-- E2. Job × Education — professional profile targeting
-- Which occupational + education combination has the highest conversion?
-- -----------------------------------------------------------------------------
SELECT
    job,
    education,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(AVG(subscription_flag) / 0.117, 2)           AS lift_vs_average
FROM bank_analysis
GROUP BY job, education
HAVING COUNT(*) >= 200
ORDER BY conversion_rate_pct DESC
LIMIT 15;


-- -----------------------------------------------------------------------------
-- E3. Debt-free customers by job type
-- Customers with no housing loan AND no personal loan — maximally free capital
-- These customers have the highest disposable income for savings products
-- -----------------------------------------------------------------------------
SELECT
    job,
    COUNT(*)                                            AS debt_free_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(AVG(subscription_flag) / 0.117, 2)           AS lift_vs_average
FROM bank_analysis
WHERE housing = 'no' AND loan = 'no'
GROUP BY job
HAVING COUNT(*) >= 100
ORDER BY conversion_rate_pct DESC;


-- =============================================================================
-- END OF SCRIPT 04
-- KEY FINDINGS TO DOCUMENT:
--   - Retired customers and students show highest conversion lift
--   - Single customers convert better than married
--   - Debt-free customers (no housing, no loan) convert significantly better
--   - Tertiary education customers over-index vs primary educated
--   - Dual debt burden (housing + personal loan) is the clearest negative signal
-- Next: Run 05_balance_tier_analysis.sql
-- =============================================================================
