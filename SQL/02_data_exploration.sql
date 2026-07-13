-- =============================================================================
-- SCRIPT 02: Data Exploration & Distribution Analysis
-- Project  : Bank Term Deposit Campaign Effectiveness Analytics
-- Analyst  : Ritik
-- Version  : 1.0
-- =============================================================================
-- PURPOSE:
--   Perform a thorough exploration of the dataset to understand:
--   - Record volumes and target variable distribution
--   - Distribution of every key variable
--   - Summary statistics for numeric columns
--   - "Unknown" category prevalence by column
--
-- BUSINESS VALUE:
--   These queries form the factual foundation of the Data Quality Audit
--   and inform all subsequent analysis decisions. Every number here
--   should be cited in the GitHub README and referenced in interviews.
--
-- RUN ORDER: After 01_schema_setup.sql
-- =============================================================================

USE bank_campaign;


-- =============================================================================
-- SECTION A: Dataset Overview
-- =============================================================================

-- -----------------------------------------------------------------------------
-- A1. Campaign summary — the headline numbers
-- This is the first thing you present to a stakeholder.
-- -----------------------------------------------------------------------------
SELECT
    COUNT(*)                                            AS total_contacts,
    SUM(subscription_flag)                              AS total_subscriptions,
    COUNT(*) - SUM(subscription_flag)                  AS total_non_subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)             AS conversion_rate_pct,
    ROUND((1 - AVG(subscription_flag)) * 100, 2)       AS non_conversion_rate_pct,
    COUNT(DISTINCT job)                                 AS unique_job_categories,
    COUNT(DISTINCT `month`)                             AS months_in_data,
    MIN(age)                                            AS youngest_customer,
    MAX(age)                                            AS oldest_customer,
    ROUND(AVG(age), 1)                                  AS avg_customer_age,
    ROUND(AVG(balance), 0)                              AS avg_account_balance_eur,
    MIN(balance)                                        AS min_balance_eur,
    MAX(balance)                                        AS max_balance_eur
FROM bank_analysis;


-- -----------------------------------------------------------------------------
-- A2. Numeric column summary statistics
-- Provides mean, median proxy, min, max, and standard deviation for
-- every numeric column — the equivalent of df.describe() in pandas.
-- -----------------------------------------------------------------------------
SELECT
    'age'                               AS column_name,
    MIN(age)                            AS min_val,
    MAX(age)                            AS max_val,
    ROUND(AVG(age), 2)                  AS mean_val,
    ROUND(STDDEV(age), 2)               AS std_dev
FROM bank_analysis
UNION ALL
SELECT 'balance', MIN(balance), MAX(balance),
       ROUND(AVG(balance), 2), ROUND(STDDEV(balance), 2) FROM bank_analysis
UNION ALL
SELECT 'duration', MIN(duration), MAX(duration),
       ROUND(AVG(duration), 2), ROUND(STDDEV(duration), 2) FROM bank_analysis
UNION ALL
SELECT 'campaign', MIN(campaign), MAX(campaign),
       ROUND(AVG(campaign), 2), ROUND(STDDEV(campaign), 2) FROM bank_analysis
UNION ALL
SELECT 'previous', MIN(previous), MAX(previous),
       ROUND(AVG(previous), 2), ROUND(STDDEV(previous), 2) FROM bank_analysis;


-- =============================================================================
-- SECTION B: Categorical Column Distributions
-- =============================================================================

-- -----------------------------------------------------------------------------
-- B1. Job type distribution — how many customers per occupation
-- -----------------------------------------------------------------------------
SELECT
    job,
    COUNT(*)                                        AS total_contacts,
    SUM(subscription_flag)                          AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)         AS conversion_rate_pct,
    ROUND(COUNT(*) * 100.0 / 45211, 2)             AS pct_of_total
FROM bank_analysis
GROUP BY job
ORDER BY total_contacts DESC;


-- -----------------------------------------------------------------------------
-- B2. Marital status distribution
-- -----------------------------------------------------------------------------
SELECT
    marital,
    COUNT(*)                                        AS total_contacts,
    SUM(subscription_flag)                          AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)         AS conversion_rate_pct,
    ROUND(COUNT(*) * 100.0 / 45211, 2)             AS pct_of_total
FROM bank_analysis
GROUP BY marital
ORDER BY total_contacts DESC;


-- -----------------------------------------------------------------------------
-- B3. Education level distribution
-- -----------------------------------------------------------------------------
SELECT
    education,
    COUNT(*)                                        AS total_contacts,
    SUM(subscription_flag)                          AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)         AS conversion_rate_pct,
    ROUND(COUNT(*) * 100.0 / 45211, 2)             AS pct_of_total
FROM bank_analysis
GROUP BY education
ORDER BY total_contacts DESC;


-- -----------------------------------------------------------------------------
-- B4. Contact method distribution
-- NOTE: 28.8% "unknown" contacts — an important data quality flag
-- -----------------------------------------------------------------------------
SELECT
    contact,
    COUNT(*)                                        AS total_contacts,
    SUM(subscription_flag)                          AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)         AS conversion_rate_pct,
    ROUND(COUNT(*) * 100.0 / 45211, 2)             AS pct_of_total
FROM bank_analysis
GROUP BY contact
ORDER BY total_contacts DESC;


-- -----------------------------------------------------------------------------
-- B5. Previous campaign outcome distribution
-- KEY FINDING: poutcome='success' customers are our warmest leads
-- -----------------------------------------------------------------------------
SELECT
    poutcome,
    COUNT(*)                                        AS total_contacts,
    SUM(subscription_flag)                          AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)         AS conversion_rate_pct,
    ROUND(COUNT(*) * 100.0 / 45211, 2)             AS pct_of_total
FROM bank_analysis
GROUP BY poutcome
ORDER BY conversion_rate_pct DESC;


-- -----------------------------------------------------------------------------
-- B6. Housing and personal loan distribution
-- -----------------------------------------------------------------------------
SELECT
    housing                                         AS has_housing_loan,
    loan                                            AS has_personal_loan,
    COUNT(*)                                        AS total_contacts,
    SUM(subscription_flag)                          AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)         AS conversion_rate_pct
FROM bank_analysis
GROUP BY housing, loan
ORDER BY conversion_rate_pct DESC;


-- =============================================================================
-- SECTION C: Numeric Column Distributions (Bucketed)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- C1. Age band distribution — customer life-stage breakdown
-- -----------------------------------------------------------------------------
SELECT
    age_band,
    COUNT(*)                                        AS total_contacts,
    SUM(subscription_flag)                          AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)         AS conversion_rate_pct,
    ROUND(COUNT(*) * 100.0 / 45211, 2)             AS pct_of_total
FROM bank_analysis
GROUP BY age_band
ORDER BY age_band;


-- -----------------------------------------------------------------------------
-- C2. Balance tier distribution — wealth segmentation
-- -----------------------------------------------------------------------------
SELECT
    balance_tier,
    COUNT(*)                                        AS total_contacts,
    SUM(subscription_flag)                          AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)         AS conversion_rate_pct,
    ROUND(COUNT(*) * 100.0 / 45211, 2)             AS pct_of_total
FROM bank_analysis
GROUP BY balance_tier
ORDER BY balance_tier;


-- -----------------------------------------------------------------------------
-- C3. Campaign contact frequency distribution
-- KEY FINDING: Diminishing returns after 3rd call
-- -----------------------------------------------------------------------------
SELECT
    contact_frequency_band,
    COUNT(*)                                        AS total_contacts,
    SUM(subscription_flag)                          AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)         AS conversion_rate_pct,
    ROUND(COUNT(*) * 100.0 / 45211, 2)             AS pct_of_total
FROM bank_analysis
GROUP BY contact_frequency_band
ORDER BY contact_frequency_band;


-- -----------------------------------------------------------------------------
-- C4. Call quality band distribution
-- How many calls fell into each duration bucket?
-- -----------------------------------------------------------------------------
SELECT
    call_quality_band,
    COUNT(*)                                        AS total_calls,
    SUM(subscription_flag)                          AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)         AS conversion_rate_pct,
    ROUND(COUNT(*) * 100.0 / 45211, 2)             AS pct_of_total
FROM bank_analysis
GROUP BY call_quality_band
ORDER BY call_quality_band;


-- =============================================================================
-- SECTION D: Monthly Volume Overview
-- =============================================================================

-- -----------------------------------------------------------------------------
-- D1. Contact volume and conversion by month
-- Note: months are sorted chronologically using month_num
-- KEY OBSERVATION: May has highest volume but not highest conversion rate
-- -----------------------------------------------------------------------------
SELECT
    UPPER(`month`)                                  AS month_name,
    month_num,
    COUNT(*)                                        AS total_contacts,
    SUM(subscription_flag)                          AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)         AS conversion_rate_pct,
    ROUND(COUNT(*) * 100.0 / 45211, 2)             AS pct_of_all_contacts
FROM bank_analysis
GROUP BY `month`, month_num
ORDER BY month_num;


-- =============================================================================
-- SECTION E: Data Quality Flags
-- =============================================================================

-- -----------------------------------------------------------------------------
-- E1. "Unknown" value prevalence across all categorical columns
-- Cross-column quality summary
-- -----------------------------------------------------------------------------
SELECT 'job'      AS column_name, COUNT(*) AS unknown_count, ROUND(COUNT(*)*100.0/45211,2) AS pct FROM bank_analysis WHERE job='unknown'
UNION ALL
SELECT 'education', COUNT(*), ROUND(COUNT(*)*100.0/45211,2) FROM bank_analysis WHERE education='unknown'
UNION ALL
SELECT 'contact',   COUNT(*), ROUND(COUNT(*)*100.0/45211,2) FROM bank_analysis WHERE contact='unknown'
UNION ALL
SELECT 'poutcome',  COUNT(*), ROUND(COUNT(*)*100.0/45211,2) FROM bank_analysis WHERE poutcome='unknown';


-- -----------------------------------------------------------------------------
-- E2. Zero-duration calls (no actual conversation)
-- These contacts technically "happened" but had no sales interaction
-- -----------------------------------------------------------------------------
SELECT
    valid_call_flag,
    CASE valid_call_flag WHEN 1 THEN 'Valid Call (duration > 0)'
                         ELSE 'No Connection (duration = 0)' END  AS call_status,
    COUNT(*)                                                        AS record_count,
    SUM(subscription_flag)                                          AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)                         AS conversion_rate_pct
FROM bank_analysis
GROUP BY valid_call_flag
ORDER BY valid_call_flag DESC;


-- -----------------------------------------------------------------------------
-- E3. Default credit holders (risk flag)
-- Small population but relevant for responsible targeting
-- -----------------------------------------------------------------------------
SELECT
    `default`                                       AS credit_in_default,
    COUNT(*)                                        AS total_contacts,
    SUM(subscription_flag)                          AS subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)         AS conversion_rate_pct
FROM bank_analysis
GROUP BY `default`
ORDER BY `default`;


-- =============================================================================
-- END OF SCRIPT 02
-- Key numbers to note from this script:
--   - Overall conversion rate: ~11.7%
--   - poutcome='success' conversion rate: (check output — typically ~65%)
--   - May has highest contact volume but not highest conversion rate
--   - ~3.4% of calls had duration=0 (no actual conversation)
-- Next: Run 03_conversion_analysis.sql
-- =============================================================================
