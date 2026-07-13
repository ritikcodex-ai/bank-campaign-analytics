-- =============================================================================
-- SCRIPT 05: Balance Tier & Wealth Segmentation Analysis
-- Project  : Bank Term Deposit Campaign Effectiveness Analytics
-- Analyst  : Ritik
-- Version  : 1.0
-- =============================================================================
-- PURPOSE:
--   Analyse how a customer's account balance predicts term deposit conversion.
--   Balance is the most direct proxy for a customer's financial capacity
--   to lock money in a fixed-tenure product.
--
-- KEY BUSINESS QUESTIONS ANSWERED:
--   Q1. Do higher-balance customers convert at significantly higher rates?
--   Q2. What is the conversion rate among customers with negative balances?
--   Q3. Does balance interact with demographic profile to identify
--       the highest-value customer segments?
--   Q4. What is the total deposit value opportunity by balance tier?
-- =============================================================================

USE bank_campaign;


-- =============================================================================
-- SECTION A: Core Balance Tier Conversion Analysis
-- =============================================================================

-- -----------------------------------------------------------------------------
-- A1. Conversion by balance tier — the core wealth segmentation table
-- This is one of the most important outputs of the entire project.
-- -----------------------------------------------------------------------------
SELECT
    balance_tier,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(COUNT(*) * 100.0 / 45211, 2)                 AS pct_of_all_contacts,
    ROUND(AVG(subscription_flag) / 0.117, 2)           AS conversion_lift,
    ROUND(AVG(balance), 0)                              AS avg_balance_eur,

    -- Priority flag for targeting
    CASE
        WHEN AVG(subscription_flag) > 0.17  THEN 'Tier 1 — Highest Priority'
        WHEN AVG(subscription_flag) >= 0.11 THEN 'Tier 2 — Average'
        ELSE                                     'Tier 3 — Deprioritise'
    END                                                 AS targeting_tier

FROM bank_analysis
GROUP BY balance_tier
ORDER BY balance_tier;


-- -----------------------------------------------------------------------------
-- A2. Balance statistics by subscription outcome
-- Do subscribers have materially higher average balances than non-subscribers?
-- The gap tells us how strong balance is as a predictor.
-- -----------------------------------------------------------------------------
SELECT
    y                                                   AS subscription_outcome,
    COUNT(*)                                            AS customer_count,
    ROUND(AVG(balance), 0)                              AS avg_balance_eur,
    MIN(balance)                                        AS min_balance_eur,
    MAX(balance)                                        AS max_balance_eur,
    ROUND(STDDEV(balance), 0)                           AS std_dev_balance
FROM bank_analysis
GROUP BY y
ORDER BY y DESC;


-- =============================================================================
-- SECTION B: Balance × Demographics Cross-Analysis
-- =============================================================================

-- -----------------------------------------------------------------------------
-- B1. Balance tier × Age band — wealth by life stage
-- Which life-stage + wealth combinations convert best?
-- -----------------------------------------------------------------------------
SELECT
    age_band,
    balance_tier,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(AVG(subscription_flag) / 0.117, 2)           AS lift_vs_average
FROM bank_analysis
GROUP BY age_band, balance_tier
HAVING COUNT(*) >= 100
ORDER BY conversion_rate_pct DESC
LIMIT 15;


-- -----------------------------------------------------------------------------
-- B2. Balance tier × Job type — who has wealth AND converts?
-- Identifies the specific high-wealth occupations that are most receptive
-- -----------------------------------------------------------------------------
SELECT
    balance_tier,
    job,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(AVG(subscription_flag) / 0.117, 2)           AS lift_vs_average
FROM bank_analysis
WHERE balance_tier IN ('4. High (5K-20K)', '5. Very High (20K+)')
GROUP BY balance_tier, job
HAVING COUNT(*) >= 50
ORDER BY balance_tier, conversion_rate_pct DESC;


-- =============================================================================
-- SECTION C: Negative Balance Deep-Dive
-- =============================================================================

-- -----------------------------------------------------------------------------
-- C1. Negative balance customers — who are they and should we call them?
-- These customers have overdraft balances. Their conversion rate, combined
-- with the cost-per-call, tells us whether they're worth targeting.
-- -----------------------------------------------------------------------------
SELECT
    'Negative Balance Customers'                        AS segment,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(AVG(balance), 0)                              AS avg_balance_eur,

    -- Job breakdown within negative balance customers
    GROUP_CONCAT(
        DISTINCT job ORDER BY job SEPARATOR ', '
    )                                                   AS jobs_present
FROM bank_analysis
WHERE balance < 0;

-- Detailed job breakdown for negative balance customers
SELECT
    job,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(AVG(balance), 0)                              AS avg_balance_eur
FROM bank_analysis
WHERE balance < 0
GROUP BY job
ORDER BY total_contacts DESC;


-- =============================================================================
-- SECTION D: Balance Tier × Debt Burden
-- =============================================================================

-- -----------------------------------------------------------------------------
-- D1. Do high-balance customers with loans still convert well?
-- Tests whether financial capacity (balance) overrides debt obligation (loans)
-- when it comes to term deposit interest.
-- -----------------------------------------------------------------------------
SELECT
    balance_tier,
    debt_burden_flag,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct
FROM bank_analysis
WHERE balance_tier IN ('4. High (5K-20K)', '5. Very High (20K+)')
GROUP BY balance_tier, debt_burden_flag
HAVING COUNT(*) >= 30
ORDER BY balance_tier, conversion_rate_pct DESC;


-- =============================================================================
-- SECTION E: Deposit Value Opportunity Model
-- =============================================================================

-- -----------------------------------------------------------------------------
-- E1. Estimated deposit value opportunity by balance tier
-- Assumes customers deposit ~20% of their account balance into term deposit
-- (conservative assumption). Shows where the largest $ opportunity lies.
-- This is the "business impact" quantification that impresses interviewers.
-- -----------------------------------------------------------------------------
SELECT
    balance_tier,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(AVG(balance), 0)                              AS avg_balance_eur,

    -- Estimated average deposit size = 20% of average balance
    ROUND(AVG(balance) * 0.20, 0)                      AS est_avg_deposit_eur,

    -- Total estimated deposit value from this tier
    ROUND(SUM(subscription_flag) * AVG(balance) * 0.20 / 1000000, 2)
                                                        AS est_total_deposit_value_mn_eur,

    -- Cumulative share of deposit value across tiers
    ROUND(
        SUM(subscription_flag) * AVG(balance) * 0.20 * 100.0 /
        SUM(SUM(subscription_flag) * AVG(balance) * 0.20) OVER ()
    , 1)                                                AS pct_of_total_deposit_value

FROM bank_analysis
WHERE balance > 0  -- Exclude negative balance customers from opportunity sizing
GROUP BY balance_tier
ORDER BY balance_tier;


-- =============================================================================
-- END OF SCRIPT 05
-- KEY FINDINGS TO DOCUMENT:
--   - Higher balance tiers convert at meaningfully higher rates
--   - Very High balance (20K+) customers are the single most valuable segment
--   - Even among high-balance customers, debt-free ones convert better
--   - Negative balance customers have low conversion AND low deposit potential
-- Next: Run 06_campaign_diagnostics.sql
-- =============================================================================
