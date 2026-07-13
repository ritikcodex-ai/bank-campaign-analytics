-- =============================================================================
-- SCRIPT 06: Campaign Execution Diagnostics
-- Project  : Bank Term Deposit Campaign Effectiveness Analytics
-- Analyst  : Ritik
-- Version  : 1.0
-- =============================================================================
-- PURPOSE:
--   Diagnose HOW the campaign is being run, not just who it's targeting.
--   This script reveals whether the bank's calling tactics — how often,
--   how long, and when — are working for or against them.
--
-- KEY BUSINESS QUESTIONS ANSWERED:
--   Q1. Is the bank calling some customers too many times? (Campaign fatigue)
--   Q2. What is the optimal number of calls per customer per campaign?
--   Q3. How does call duration correlate with conversion? (Engagement quality)
--   Q4. Is there a "sweet spot" of call duration that signals high intent?
--
-- IMPORTANT CAVEAT:
--   Call duration is analysed here DIAGNOSTICALLY only.
--   It cannot be used to decide who to call, because we only
--   know duration after the call ends. See inline notes.
-- =============================================================================

USE bank_campaign;


-- =============================================================================
-- SECTION A: Campaign Contact Frequency (Fatigue Analysis)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- A1. Conversion rate by number of calls made in current campaign
-- This is the campaign fatigue curve — the single most actionable finding
-- for the campaign manager.
-- EXPECTED FINDING: Strong conversion on call 1, drops sharply after call 3-4
-- -----------------------------------------------------------------------------
SELECT
    campaign                                            AS calls_made,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(COUNT(*) * 100.0 / 45211, 2)                 AS pct_of_all_contacts,

    -- Visual indicator bar for quick reading (every * = 1%)
    RPAD('', ROUND(AVG(subscription_flag) * 100), '*') AS rate_visual

FROM bank_analysis
WHERE campaign <= 15  -- Focus on meaningful sample sizes; 15+ calls are tiny fringe
GROUP BY campaign
ORDER BY campaign;


-- -----------------------------------------------------------------------------
-- A2. Aggregated fatigue buckets — cleaner for the dashboard
-- Groups contact counts into strategic bands.
-- -----------------------------------------------------------------------------
SELECT
    contact_frequency_band,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(COUNT(*) * 100.0 / 45211, 2)                 AS pct_of_contacts,
    ROUND(AVG(subscription_flag) / 0.117, 2)           AS lift_vs_average,
    ROUND(AVG(campaign), 1)                             AS avg_calls_in_band

FROM bank_analysis
GROUP BY contact_frequency_band
ORDER BY contact_frequency_band;


-- -----------------------------------------------------------------------------
-- A3. Budget waste from over-contacting
-- How much is the bank spending on calls 4+ when conversion is negligible?
-- Quantifies the financial case for a "stop after 3 calls" policy.
-- -----------------------------------------------------------------------------
WITH fatigue_model AS (
    SELECT
        CASE
            WHEN campaign <= 3 THEN 'Optimal (1-3 calls)'
            ELSE                    'Excess (4+ calls)'
        END                                             AS call_strategy,
        COUNT(*)                                        AS total_calls,
        SUM(subscription_flag)                          AS subscriptions,
        ROUND(AVG(subscription_flag) * 100, 2)         AS conversion_rate_pct
    FROM bank_analysis
    GROUP BY call_strategy
)
SELECT
    call_strategy,
    total_calls,
    subscriptions,
    conversion_rate_pct,
    -- Cost at 150 INR per call
    ROUND(total_calls * 150 / 100000.0, 2)             AS spend_lakh_inr,
    -- Cost per subscription in each band
    ROUND(total_calls * 150.0 / NULLIF(subscriptions, 0), 0) AS cost_per_subscription_inr
FROM fatigue_model
ORDER BY call_strategy;


-- =============================================================================
-- SECTION B: Call Duration Analysis (Engagement Quality Diagnostics)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- B1. Average call duration for subscribers vs non-subscribers
-- This is the engagement quality diagnostic.
-- A large gap tells us that QUALITY of conversation matters, not just volume.
-- ⚠️ REMINDER: duration is a diagnostic metric, not a targeting metric.
-- -----------------------------------------------------------------------------
SELECT
    y                                                   AS subscription_outcome,
    COUNT(*)                                            AS total_records,
    ROUND(AVG(duration), 0)                             AS avg_duration_seconds,
    ROUND(AVG(duration) / 60.0, 2)                     AS avg_duration_minutes,
    MIN(duration)                                       AS min_duration_seconds,
    MAX(duration)                                       AS max_duration_seconds,
    ROUND(STDDEV(duration), 0)                          AS std_dev_seconds

FROM bank_analysis
WHERE duration > 0  -- Exclude zero-duration (no connection) calls
GROUP BY y
ORDER BY y DESC;


-- -----------------------------------------------------------------------------
-- B2. Conversion rate by call quality band
-- Shows the relationship between call length and outcome.
-- EXPECTED FINDING: Medium and long calls (5+ min) have dramatically
-- higher conversion rates than short calls.
-- -----------------------------------------------------------------------------
SELECT
    call_quality_band,
    COUNT(*)                                            AS total_calls,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(AVG(duration), 0)                             AS avg_duration_seconds,
    ROUND(COUNT(*) * 100.0 / 45211, 2)                 AS pct_of_contacts

FROM bank_analysis
GROUP BY call_quality_band
ORDER BY call_quality_band;


-- -----------------------------------------------------------------------------
-- B3. Duration distribution for subscribers only
-- What does a "successful call" look like in terms of duration?
-- Tells us what the sales team should aim for in terms of conversation depth.
-- -----------------------------------------------------------------------------
SELECT
    call_quality_band,
    COUNT(*)                                            AS subscriber_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_subscribers,
    ROUND(AVG(duration) / 60, 2)                       AS avg_duration_minutes
FROM bank_analysis
WHERE subscription_flag = 1 AND duration > 0
GROUP BY call_quality_band
ORDER BY call_quality_band;


-- =============================================================================
-- SECTION C: Timing Optimisation
-- =============================================================================

-- -----------------------------------------------------------------------------
-- C1. Conversion rate by month — which months yield best ROI on calling effort?
-- Re-presented here in campaign context (linked to timing recommendations)
-- -----------------------------------------------------------------------------
SELECT
    UPPER(`month`)                                      AS month_name,
    month_num,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(AVG(campaign), 1)                             AS avg_calls_per_customer,

    -- Cost efficiency: how many calls does it take to get one subscription?
    ROUND(COUNT(*) * 1.0 / NULLIF(SUM(subscription_flag), 0), 1)
                                                        AS calls_per_subscription

FROM bank_analysis
GROUP BY `month`, month_num
ORDER BY conversion_rate_pct DESC;


-- -----------------------------------------------------------------------------
-- C2. Contact frequency × Month — does timing change the fatigue curve?
-- Are customers called fewer times in high-conversion months?
-- -----------------------------------------------------------------------------
SELECT
    UPPER(`month`)                                      AS month_name,
    month_num,
    ROUND(AVG(campaign), 2)                             AS avg_calls_per_customer,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    SUM(CASE WHEN campaign >= 4 THEN 1 ELSE 0 END)     AS customers_over_contacted,
    ROUND(
        SUM(CASE WHEN campaign >= 4 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
    , 1)                                                AS pct_over_contacted
FROM bank_analysis
GROUP BY `month`, month_num
ORDER BY month_num;


-- =============================================================================
-- SECTION D: Combined Fatigue + Demographic Signal
-- =============================================================================

-- -----------------------------------------------------------------------------
-- D1. For each age band: what is the optimal call frequency?
-- Does the fatigue curve differ by customer life stage?
-- Helps personalise calling strategy by segment.
-- -----------------------------------------------------------------------------
SELECT
    age_band,
    contact_frequency_band,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct
FROM bank_analysis
GROUP BY age_band, contact_frequency_band
HAVING COUNT(*) >= 100
ORDER BY age_band, contact_frequency_band;


-- =============================================================================
-- END OF SCRIPT 06
-- KEY FINDINGS TO DOCUMENT:
--   - Conversion drops sharply after 3 calls (campaign fatigue)
--   - Calls 4+ are largely wasted spend — policy recommendation: cap at 3
--   - Subscribers have significantly longer average call durations
--   - March, September, October, December are highest conversion months
--   - Budget recommendation: shift spend from over-contacted customers to
--     untapped high-propensity segments
-- Next: Run 07_previous_campaign_impact.sql
-- =============================================================================
