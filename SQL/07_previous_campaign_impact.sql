-- =============================================================================
-- SCRIPT 07: Previous Campaign Impact & Warm Lead Analysis
-- Project  : Bank Term Deposit Campaign Effectiveness Analytics
-- Analyst  : Ritik
-- Version  : 1.0
-- =============================================================================
-- PURPOSE:
--   Measure how prior campaign history predicts current campaign success.
--   The central finding here is the "warm lead multiplier" — how much
--   better customers who previously subscribed (poutcome='success')
--   perform compared to cold leads (poutcome='unknown').
--
-- KEY BUSINESS QUESTIONS ANSWERED:
--   Q1. How much does a previous successful campaign multiply conversion?
--   Q2. Does the recency of prior contact affect current conversion rate?
--   Q3. Is it worth re-contacting customers who previously said no?
--   Q4. How should the campaign team prioritise their calling list?
-- =============================================================================

USE bank_campaign;


-- =============================================================================
-- SECTION A: Previous Campaign Outcome Impact
-- =============================================================================

-- -----------------------------------------------------------------------------
-- A1. Conversion rate by poutcome — the warm lead multiplier
-- This is typically the single most striking number in the entire project.
-- poutcome='success' customers can convert at 5-10x the cold lead rate.
-- -----------------------------------------------------------------------------
SELECT
    poutcome                                            AS prev_campaign_outcome,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(COUNT(*) * 100.0 / 45211, 2)                 AS pct_of_all_contacts,

    -- Lift vs the 'unknown' baseline (customers never previously contacted)
    ROUND(
        AVG(subscription_flag) /
        MIN(CASE WHEN poutcome = 'unknown' THEN AVG(subscription_flag) END)
            OVER ()
    , 2)                                                AS lift_vs_unknown_baseline,

    -- Lift vs overall average
    ROUND(AVG(subscription_flag) / 0.117, 2)           AS lift_vs_overall_avg

FROM bank_analysis
GROUP BY poutcome
ORDER BY conversion_rate_pct DESC;


-- -----------------------------------------------------------------------------
-- A2. Simplified: poutcome='success' vs everyone else
-- Isolates the warm lead premium in a single, memorable comparison
-- -----------------------------------------------------------------------------
SELECT
    CASE
        WHEN poutcome = 'success' THEN 'Previous Success (Warm Lead)'
        ELSE 'No Previous Success (Cold/Failed/Unknown)'
    END                                                 AS lead_warmth,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(AVG(subscription_flag) / 0.117, 2)           AS lift_vs_overall
FROM bank_analysis
GROUP BY lead_warmth
ORDER BY conversion_rate_pct DESC;


-- =============================================================================
-- SECTION B: Contact Recency Analysis
-- =============================================================================

-- -----------------------------------------------------------------------------
-- B1. Days since last contact (pdays) vs current conversion rate
-- Does recency of prior contact matter? Does a more recent prior contact
-- produce a stronger warm lead effect?
-- pdays = -1 means never previously contacted
-- -----------------------------------------------------------------------------
SELECT
    prior_contact_flag,
    CASE
        WHEN pdays = -1              THEN '1. Never Contacted'
        WHEN pdays BETWEEN 0 AND 90  THEN '2. Recent (0-90 days)'
        WHEN pdays BETWEEN 91 AND 180 THEN '3. Moderate (91-180 days)'
        ELSE                              '4. Distant (181+ days)'
    END                                                 AS recency_bucket,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(AVG(pdays), 0)                               AS avg_days_since_contact
FROM bank_analysis
GROUP BY prior_contact_flag, recency_bucket
ORDER BY recency_bucket;


-- -----------------------------------------------------------------------------
-- B2. Among previously contacted customers only:
-- Does the NUMBER of prior contacts predict current success?
-- -----------------------------------------------------------------------------
SELECT
    CASE
        WHEN previous = 0            THEN '0 Prior Contacts'
        WHEN previous BETWEEN 1 AND 2 THEN '1-2 Prior Contacts'
        WHEN previous BETWEEN 3 AND 5 THEN '3-5 Prior Contacts'
        ELSE                              '6+ Prior Contacts'
    END                                                 AS prior_contact_volume,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct
FROM bank_analysis
WHERE pdays != -1  -- Only customers with prior campaign history
GROUP BY prior_contact_volume
ORDER BY prior_contact_volume;


-- =============================================================================
-- SECTION C: Warm Lead Profiling
-- =============================================================================

-- -----------------------------------------------------------------------------
-- C1. Who are the warm leads? Demographic profile of poutcome='success'
-- Understanding this segment helps build the "ideal warm lead" persona
-- -----------------------------------------------------------------------------
SELECT
    age_band,
    COUNT(*)                                            AS warm_lead_count,
    SUM(subscription_flag)                              AS current_subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(AVG(balance), 0)                              AS avg_balance_eur
FROM bank_analysis
WHERE poutcome = 'success'
GROUP BY age_band
ORDER BY conversion_rate_pct DESC;

-- Job profile of warm leads
SELECT
    job,
    COUNT(*)                                            AS warm_lead_count,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct
FROM bank_analysis
WHERE poutcome = 'success'
GROUP BY job
HAVING COUNT(*) >= 10
ORDER BY conversion_rate_pct DESC;


-- -----------------------------------------------------------------------------
-- C2. poutcome='failure' customers — worth re-contacting?
-- Did customers who said no last time come around this time?
-- -----------------------------------------------------------------------------
SELECT
    'Re-contact of Failed Leads'                        AS segment,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(AVG(subscription_flag) / 0.117, 2)           AS lift_vs_overall
FROM bank_analysis
WHERE poutcome = 'failure';


-- =============================================================================
-- SECTION D: Combined Warm Lead + Current Campaign Analysis
-- =============================================================================

-- -----------------------------------------------------------------------------
-- D1. Warm lead × Contact frequency: How many times should warm leads be called?
-- If warm leads already have a high base rate, do we need to call them often?
-- Hypothesis: warm leads may convert on the FIRST call, making repeat
-- contacts wasteful.
-- -----------------------------------------------------------------------------
SELECT
    poutcome                                            AS prev_outcome,
    contact_frequency_band,
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct
FROM bank_analysis
WHERE poutcome IN ('success', 'failure')
GROUP BY poutcome, contact_frequency_band
ORDER BY poutcome, contact_frequency_band;


-- -----------------------------------------------------------------------------
-- D2. Priority calling queue recommendation
-- Ranks customer segments by conversion rate for prioritised outreach.
-- This is the output that becomes the "Campaign Optimizer" page in Power BI.
-- Combines: poutcome + age_band + balance_tier into a priority score.
-- -----------------------------------------------------------------------------
WITH segment_scores AS (
    SELECT
        poutcome,
        age_band,
        balance_tier,
        COUNT(*)                                        AS segment_size,
        SUM(subscription_flag)                          AS subscriptions,
        ROUND(AVG(subscription_flag) * 100, 2)         AS conversion_rate_pct
    FROM bank_analysis
    GROUP BY poutcome, age_band, balance_tier
    HAVING COUNT(*) >= 100
)
SELECT
    poutcome,
    age_band,
    balance_tier,
    segment_size,
    subscriptions,
    conversion_rate_pct,
    RANK() OVER (ORDER BY conversion_rate_pct DESC)     AS priority_rank,
    CASE
        WHEN conversion_rate_pct >= 30 THEN 'Priority 1 — Call First'
        WHEN conversion_rate_pct >= 20 THEN 'Priority 2 — Call Second'
        WHEN conversion_rate_pct >= 11.7 THEN 'Priority 3 — Standard'
        ELSE                                 'Priority 4 — Deprioritise'
    END                                                 AS calling_priority
FROM segment_scores
ORDER BY conversion_rate_pct DESC
LIMIT 20;


-- =============================================================================
-- END OF SCRIPT 07
-- KEY FINDINGS TO DOCUMENT:
--   - poutcome='success' customers convert at dramatically higher rates
--   - This is the single strongest predictor of current campaign success
--   - Failed leads (poutcome='failure') still perform above unknown baseline
--   - Warm leads should be called FIRST, and capped at 1-2 contacts
--   - Recommendation: Build a "priority calling list" for each campaign cycle
-- Next: Run 08_customer_targeting_matrix.sql
-- =============================================================================
