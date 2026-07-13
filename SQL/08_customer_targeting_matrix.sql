-- =============================================================================
-- SCRIPT 08: Customer Targeting Matrix
-- Project  : Bank Term Deposit Campaign Effectiveness Analytics
-- Analyst  : Ritik
-- Version  : 1.0
-- =============================================================================
-- PURPOSE:
--   Build a comprehensive customer targeting framework that answers:
--   "If we could only call X% of our database next campaign,
--    which customers should we call?"
--
--   This is the most forward-looking, decision-oriented script in the project.
--   It synthesises all previous analysis into a targeting priority score
--   and produces the "Ideal Customer Profile" for term deposit campaigns.
--
-- KEY BUSINESS QUESTIONS ANSWERED:
--   Q1. What does the ideal term deposit customer look like?
--   Q2. If we only targeted the top 20% of customers by conversion
--       probability, what % of all subscriptions would we capture?
--   Q3. Which segment combinations should be the campaign's priority list?
--   Q4. What is the projected ROI improvement from targeted vs broad outreach?
-- =============================================================================

USE bank_campaign;


-- =============================================================================
-- SECTION A: Composite Targeting Score
-- =============================================================================

-- -----------------------------------------------------------------------------
-- A1. Build a targeting score for each customer
-- Uses a point-based scoring system based on:
-- (+) Positive signals: previous success, high balance, right age, good job
-- (-) Negative signals: dual debt burden, defaulted credit, many prior calls
--
-- This is the kind of rule-based scoring a data analyst would build
-- BEFORE a data scientist builds a predictive model.
-- It is explainable, auditable, and immediately useful.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW customer_targeting_score AS
SELECT
    -- Original key attributes
    age, job, marital, education, `default`,
    balance, housing, loan, contact, `month`,
    duration, campaign, pdays, previous, poutcome, y,

    -- Derived attributes
    age_band, balance_tier, debt_burden_flag,
    prior_contact_flag, subscription_flag,

    -- ----------------------------------------------------------
    -- TARGETING SCORE COMPONENTS
    -- Each positive factor adds points; each negative deducts them.
    -- Scale: theoretical max ~+21, min ~-8
    -- ----------------------------------------------------------

    -- Previous campaign outcome (strongest single predictor)
    CASE poutcome
        WHEN 'success' THEN 8   -- Previously subscribed: massive positive signal
        WHEN 'failure' THEN 1   -- Declined before but not zero — slightly warm
        WHEN 'other'   THEN 2
        ELSE                0   -- Unknown / never contacted
    END
    +
    -- Balance tier (financial capacity)
    CASE balance_tier
        WHEN '5. Very High (20K+)'  THEN 5
        WHEN '4. High (5K-20K)'     THEN 3
        WHEN '3. Medium (1K-5K)'    THEN 2
        WHEN '2. Low (0-999)'       THEN 1
        WHEN '1. Negative (<0)'     THEN -2
        ELSE 0
    END
    +
    -- Age band (life stage receptiveness)
    CASE age_band
        WHEN '5. Retired (61+)'         THEN 3
        WHEN '1. Young (18-30)'          THEN 2   -- Students: high conversion
        WHEN '2. Early Career (31-40)'   THEN 1
        WHEN '3. Mid Career (41-50)'     THEN 0
        WHEN '4. Pre-Retirement (51-60)' THEN 1
        ELSE 0
    END
    +
    -- Job type
    CASE job
        WHEN 'retired'       THEN 3
        WHEN 'student'       THEN 3
        WHEN 'management'    THEN 2
        WHEN 'admin.'        THEN 1
        WHEN 'technician'    THEN 1
        WHEN 'self-employed' THEN 1
        WHEN 'unemployed'    THEN -1
        WHEN 'blue-collar'   THEN -1
        ELSE 0
    END
    +
    -- Debt burden (financial pressure)
    CASE debt_burden_flag
        WHEN 'Debt Free'          THEN 2
        WHEN 'Personal Loan Only' THEN 0
        WHEN 'Housing Loan Only'  THEN -1
        WHEN 'Dual Debt Burden'   THEN -3
        ELSE 0
    END
    +
    -- Credit default (risk flag)
    CASE `default`
        WHEN 'yes' THEN -3
        ELSE            0
    END
    +
    -- Campaign contact efficiency (have we already over-called this person?)
    CASE
        WHEN campaign = 1            THEN  1
        WHEN campaign BETWEEN 2 AND 3 THEN  0
        WHEN campaign BETWEEN 4 AND 5 THEN -1
        ELSE                              -3
    END                                                 AS targeting_score

FROM bank_analysis;


-- -----------------------------------------------------------------------------
-- A2. Score distribution and conversion rate by score band
-- Validates that higher scores actually predict higher conversion.
-- This is the "model validation" step for a rule-based scorer.
-- -----------------------------------------------------------------------------
SELECT
    CASE
        WHEN targeting_score >= 12 THEN 'A+ (Score 12+)'
        WHEN targeting_score >= 8  THEN 'A  (Score 8-11)'
        WHEN targeting_score >= 5  THEN 'B  (Score 5-7)'
        WHEN targeting_score >= 2  THEN 'C  (Score 2-4)'
        WHEN targeting_score >= 0  THEN 'D  (Score 0-1)'
        ELSE                            'E  (Score <0)'
    END                                                 AS score_band,
    COUNT(*)                                            AS customer_count,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(AVG(subscription_flag) / 0.117, 2)           AS lift_vs_average,
    ROUND(COUNT(*) * 100.0 / 45211, 2)                 AS pct_of_database
FROM customer_targeting_score
GROUP BY score_band
ORDER BY score_band;


-- =============================================================================
-- SECTION B: Ideal Customer Profile
-- =============================================================================

-- -----------------------------------------------------------------------------
-- B1. Top converting customer segments — the "Ideal Customer Profile" (ICP)
-- Combines all dimensions to find the highest-value segment combinations.
-- These become the named customer personas in the recommendations report.
-- -----------------------------------------------------------------------------
WITH all_segments AS (
    SELECT
        age_band,
        job,
        balance_tier,
        poutcome,
        debt_burden_flag,
        COUNT(*)                                        AS segment_size,
        SUM(subscription_flag)                          AS subscriptions,
        ROUND(AVG(subscription_flag) * 100, 2)         AS conversion_rate_pct,
        ROUND(AVG(balance), 0)                          AS avg_balance_eur
    FROM bank_analysis
    GROUP BY age_band, job, balance_tier, poutcome, debt_burden_flag
    HAVING COUNT(*) >= 30
)
SELECT
    age_band,
    job,
    balance_tier,
    poutcome,
    debt_burden_flag,
    segment_size,
    subscriptions,
    conversion_rate_pct,
    avg_balance_eur,
    RANK() OVER (ORDER BY conversion_rate_pct DESC)     AS icp_rank
FROM all_segments
ORDER BY conversion_rate_pct DESC
LIMIT 20;


-- =============================================================================
-- SECTION C: Targeting Efficiency Analysis
-- "If we only called our best customers, how much would we capture?"
-- =============================================================================

-- -----------------------------------------------------------------------------
-- C1. Concentration analysis: what % of subscriptions come from top segments?
-- Classic 80/20 analysis — do a few segments drive most conversions?
--
-- Uses a CTE + window function to compute cumulative subscription share.
-- This is exactly the kind of SQL that comes up in DA interviews.
-- -----------------------------------------------------------------------------
WITH segment_conversion AS (
    SELECT
        age_band,
        balance_tier,
        poutcome,
        COUNT(*)                                        AS contacts,
        SUM(subscription_flag)                          AS subscriptions,
        ROUND(AVG(subscription_flag) * 100, 2)         AS conversion_rate_pct
    FROM bank_analysis
    GROUP BY age_band, balance_tier, poutcome
    HAVING COUNT(*) >= 100
),
ranked_segments AS (
    SELECT *,
        RANK() OVER (ORDER BY conversion_rate_pct DESC) AS rank_by_conversion,
        SUM(subscriptions)  OVER (ORDER BY conversion_rate_pct DESC
                                  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                                                        AS cumulative_subscriptions,
        SUM(contacts) OVER (ORDER BY conversion_rate_pct DESC
                            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                                                        AS cumulative_contacts
    FROM segment_conversion
)
SELECT
    rank_by_conversion,
    age_band,
    balance_tier,
    poutcome,
    contacts,
    subscriptions,
    conversion_rate_pct,
    cumulative_subscriptions,
    ROUND(cumulative_subscriptions * 100.0 / (SELECT SUM(subscription_flag) FROM bank_analysis), 1)
                                                        AS pct_of_all_subscriptions,
    ROUND(cumulative_contacts * 100.0 / 45211, 1)      AS pct_of_database_contacted
FROM ranked_segments
ORDER BY rank_by_conversion
LIMIT 25;


-- =============================================================================
-- SECTION D: Named Customer Personas
-- =============================================================================

-- -----------------------------------------------------------------------------
-- D1. Persona A — "The Loyal Retiree" (poutcome=success, retired)
-- Previously subscribed, now retired, likely has pension savings to deploy
-- -----------------------------------------------------------------------------
SELECT
    'Persona A: The Loyal Retiree'                      AS persona_name,
    COUNT(*)                                            AS customer_count,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(AVG(balance), 0)                              AS avg_balance_eur,
    ROUND(AVG(age), 0)                                  AS avg_age
FROM bank_analysis
WHERE poutcome = 'success'
  AND (job = 'retired' OR age_band = '5. Retired (61+)');


-- -----------------------------------------------------------------------------
-- D2. Persona B — "The Affluent Professional" (high balance, mgmt/admin, debt-free)
-- Mid-career, professionally stable, has savings, no major debts
-- -----------------------------------------------------------------------------
SELECT
    'Persona B: The Affluent Professional'              AS persona_name,
    COUNT(*)                                            AS customer_count,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(AVG(balance), 0)                              AS avg_balance_eur,
    ROUND(AVG(age), 0)                                  AS avg_age
FROM bank_analysis
WHERE balance_tier IN ('4. High (5K-20K)', '5. Very High (20K+)')
  AND job IN ('management', 'admin.', 'technician', 'self-employed')
  AND debt_burden_flag = 'Debt Free';


-- -----------------------------------------------------------------------------
-- D3. Persona C — "The Financial Student" (young, student job, single)
-- Low balance but very high conversion rate — receptive to financial products
-- This is a surprise segment that most campaigns overlook
-- -----------------------------------------------------------------------------
SELECT
    'Persona C: The Financial Student'                  AS persona_name,
    COUNT(*)                                            AS customer_count,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(AVG(balance), 0)                              AS avg_balance_eur,
    ROUND(AVG(age), 0)                                  AS avg_age
FROM bank_analysis
WHERE job = 'student'
  OR (age_band = '1. Young (18-30)' AND marital = 'single');


-- -----------------------------------------------------------------------------
-- D4. Persona D — "The Over-Leveraged Contact" (dual debt, negative/low balance)
-- The segment to actively deprioritise — low conversion, low deposit value
-- -----------------------------------------------------------------------------
SELECT
    'Persona D: The Over-Leveraged (Avoid)'             AS persona_name,
    COUNT(*)                                            AS customer_count,
    SUM(subscription_flag)                              AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND(AVG(balance), 0)                              AS avg_balance_eur
FROM bank_analysis
WHERE debt_burden_flag = 'Dual Debt Burden'
  AND balance_tier IN ('1. Negative (<0)', '2. Low (0-999)');


-- =============================================================================
-- END OF SCRIPT 08
-- KEY OUTPUTS:
--   - Rule-based targeting score validated against actual conversion rates
--   - Top 20 segment combinations by conversion rate
--   - 4 named customer personas for the recommendations report
--   - Concentration analysis showing % of subscriptions in top segments
-- Next: Run 09_campaign_roi_model.sql
-- =============================================================================
