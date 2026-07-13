-- =============================================================================
-- SCRIPT 01: Schema Setup & Data Preparation
-- Project  : Bank Term Deposit Campaign Effectiveness Analytics
-- Analyst  : Ritik
-- Version  : 1.1 (Revised — Import Wizard compatible)
-- =============================================================================
-- PURPOSE:
--   Create the database schema, define the raw staging table, and engineer
--   all derived columns used across subsequent analysis scripts.
--
-- HOW TO USE THIS SCRIPT (3 steps):
--
--   STEP 1 — Run SECTION 1 and SECTION 2 of this script in MySQL Workbench
--             to create the database and the bank_raw table.
--
--   STEP 2 — Import bank-full.csv using the Table Data Import Wizard:
--             • Right-click bank_raw in the schema panel → Table Data Import Wizard
--             • Select bank-full.csv
--             • Field separator: ; (semicolon)
--             • Confirm column mapping matches the table definition below
--             • Click Finish — all 45,211 rows will load automatically
--
--   STEP 3 — Run SECTION 3 onwards to build bank_analysis and verify setup.
--
-- RUN ORDER: This script runs FIRST. All other scripts depend on bank_analysis.
-- =============================================================================


-- =============================================================================
-- SECTION 1: Database Creation
-- =============================================================================

DROP DATABASE IF EXISTS bank_campaign;
CREATE DATABASE bank_campaign
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE bank_campaign;


-- =============================================================================
-- SECTION 2: Raw Staging Table
-- -----------------------------------------------------------------------------
-- Mirrors the CSV structure exactly — column names and types match bank-full.csv
-- The Import Wizard will map the CSV headers to these columns automatically.
-- Do NOT rename or reorder columns here.
-- =============================================================================

DROP TABLE IF EXISTS bank_raw;

CREATE TABLE bank_raw (

    -- -------------------------------------------------------------------------
    -- Client demographic attributes
    -- -------------------------------------------------------------------------
    age          INT            COMMENT 'Age of the customer (years)',
    job          VARCHAR(50)    COMMENT 'Type of job — 12 categories incl. unknown',
    marital      VARCHAR(20)    COMMENT 'Marital status: married / single / divorced',
    education    VARCHAR(20)    COMMENT 'Education: primary / secondary / tertiary / unknown',
    `default`    VARCHAR(5)     COMMENT 'Has credit in default? yes / no',
    balance      INT            COMMENT 'Average yearly balance in euros (can be negative)',
    housing      VARCHAR(5)     COMMENT 'Has housing loan? yes / no',
    loan         VARCHAR(5)     COMMENT 'Has personal loan? yes / no',

    -- -------------------------------------------------------------------------
    -- Last contact attributes
    -- -------------------------------------------------------------------------
    contact      VARCHAR(20)    COMMENT 'Contact type: cellular / telephone / unknown',
    `month`      VARCHAR(5)     COMMENT 'Month of last contact: jan–dec',
    `day`        INT            COMMENT 'Day of month of last contact: 1–31',
    duration     INT            COMMENT 'Last call duration in seconds',

    -- -------------------------------------------------------------------------
    -- Campaign attributes
    -- -------------------------------------------------------------------------
    campaign     INT            COMMENT 'Number of contacts made in current campaign',
    pdays        INT            COMMENT 'Days since last contact from previous campaign (-1 = never)',
    previous     INT            COMMENT 'Number of contacts before this campaign',
    poutcome     VARCHAR(20)    COMMENT 'Previous campaign outcome: failure / other / success / unknown',

    -- -------------------------------------------------------------------------
    -- Target variable
    -- -------------------------------------------------------------------------
    y            VARCHAR(5)     COMMENT 'Subscribed to term deposit? yes / no'

);

-- =============================================================================
-- ⏸ PAUSE HERE
-- -----------------------------------------------------------------------------
-- Run Sections 1 & 2 above first to create the table.
-- Then import bank-full.csv via the Table Data Import Wizard into bank_raw.
-- Once the import is complete (45,211 rows), continue from Section 3 below.
-- =============================================================================


-- =============================================================================
-- SECTION 3: Import Verification
-- -----------------------------------------------------------------------------
-- Run this immediately after the Import Wizard completes.
-- Expected result: 45,211 rows, y = yes: 5,289, y = no: 39,922
-- =============================================================================

SELECT
    COUNT(*)                        AS total_rows_imported,
    SUM(y = 'yes')                  AS subscriptions,
    SUM(y = 'no')                   AS non_subscriptions,
    ROUND(SUM(y = 'yes') * 100.0
          / COUNT(*), 2)            AS conversion_rate_pct
FROM bank_raw;

-- If total_rows_imported = 45211 → proceed to Section 4.
-- If the count is wrong, re-run the Import Wizard and ensure:
--   • Field separator is set to ; (semicolon, not comma)
--   • "First row contains column names" is checked


-- =============================================================================
-- SECTION 4: Analysis Table with Engineered Features
-- -----------------------------------------------------------------------------
-- Creates bank_analysis — the working table used by ALL subsequent scripts.
-- Adds 9 derived columns on top of the 17 original columns.
-- Never query bank_raw directly after this point.
-- =============================================================================

DROP TABLE IF EXISTS bank_analysis;

CREATE TABLE bank_analysis AS
SELECT

    -- =========================================================================
    -- Original 17 columns — preserved exactly as imported
    -- =========================================================================
    age,
    job,
    marital,
    education,
    `default`,
    balance,
    housing,
    loan,
    contact,
    `month`,
    `day`,
    duration,
    campaign,
    pdays,
    previous,
    poutcome,
    y,

    -- =========================================================================
    -- DERIVED COLUMN 1: subscription_flag
    -- =========================================================================
    -- Binary integer version of the target variable.
    -- Enables AVG(subscription_flag) to return the conversion rate as a decimal.
    -- Used in every aggregation query across all scripts.
    -- =========================================================================
    CASE WHEN y = 'yes' THEN 1 ELSE 0 END
        AS subscription_flag,

    -- =========================================================================
    -- DERIVED COLUMN 2: age_band
    -- =========================================================================
    -- 5 life-stage segments based on age.
    -- Prefixed with numbers so ORDER BY age_band sorts correctly in dashboards.
    -- Business rationale: financial behaviour varies significantly by life stage.
    -- Verified finding: Retired (61+) converts at 42.26% — highest segment.
    -- =========================================================================
    CASE
        WHEN age BETWEEN 18 AND 30 THEN '1. Young (18-30)'
        WHEN age BETWEEN 31 AND 40 THEN '2. Early Career (31-40)'
        WHEN age BETWEEN 41 AND 50 THEN '3. Mid Career (41-50)'
        WHEN age BETWEEN 51 AND 60 THEN '4. Pre-Retirement (51-60)'
        ELSE                             '5. Retired (61+)'
    END
        AS age_band,

    -- =========================================================================
    -- DERIVED COLUMN 3: balance_tier
    -- =========================================================================
    -- 5 wealth proxy segments based on average annual account balance.
    -- Verified finding: Medium–High balance (1K–20K EUR) converts at ~15%,
    -- vs 6.9% for negative balance customers.
    -- =========================================================================
    CASE
        WHEN balance < 0     THEN '1. Negative (<0)'
        WHEN balance < 1000  THEN '2. Low (0-999)'
        WHEN balance < 5000  THEN '3. Medium (1K-5K)'
        WHEN balance < 20000 THEN '4. High (5K-20K)'
        ELSE                      '5. Very High (20K+)'
    END
        AS balance_tier,

    -- =========================================================================
    -- DERIVED COLUMN 4: contact_frequency_band
    -- =========================================================================
    -- Groups call count per campaign into 4 strategic buckets.
    -- Verified finding: conversion drops from 14.6% (1 call) to 5.8% (6+ calls).
    -- Used in campaign fatigue analysis (Script 06).
    -- =========================================================================
    CASE
        WHEN campaign = 1             THEN '1. Single Contact'
        WHEN campaign BETWEEN 2 AND 3 THEN '2. Light (2-3 calls)'
        WHEN campaign BETWEEN 4 AND 5 THEN '3. Moderate (4-5 calls)'
        ELSE                               '4. Heavy (6+ calls)'
    END
        AS contact_frequency_band,

    -- =========================================================================
    -- DERIVED COLUMN 5: prior_contact_flag
    -- =========================================================================
    -- Classifies whether this customer was ever contacted in a prior campaign.
    -- pdays = -1 is the dataset's sentinel value meaning "never contacted before."
    -- Used to identify warm vs cold leads (Script 07).
    -- =========================================================================
    CASE
        WHEN pdays = -1 THEN 'Cold Lead (No Prior Contact)'
        ELSE                 'Warm Lead (Prior Campaign)'
    END
        AS prior_contact_flag,

    -- =========================================================================
    -- DERIVED COLUMN 6: call_quality_band
    -- =========================================================================
    -- Classifies call duration into 5 engagement quality buckets.
    -- ⚠ DIAGNOSTIC USE ONLY — duration is only known after the call ends.
    --   It cannot be used in targeting logic (we don't know it before calling).
    -- Verified finding: subscribers average 537 sec vs 221 sec for non-subscribers.
    -- =========================================================================
    CASE
        WHEN duration = 0   THEN '0. No Connection (0 sec)'
        WHEN duration < 60  THEN '1. Very Short (<1 min)'
        WHEN duration < 300 THEN '2. Short (1-5 min)'
        WHEN duration < 600 THEN '3. Medium (5-10 min)'
        ELSE                     '4. Long (10+ min)'
    END
        AS call_quality_band,

    -- =========================================================================
    -- DERIVED COLUMN 7: month_num
    -- =========================================================================
    -- Converts abbreviated month names to integers for correct chronological
    -- sorting. Without this, GROUP BY month sorts alphabetically: apr, aug, dec…
    -- instead of jan, feb, mar…
    -- =========================================================================
    CASE `month`
        WHEN 'jan' THEN  1  WHEN 'feb' THEN  2  WHEN 'mar' THEN  3
        WHEN 'apr' THEN  4  WHEN 'may' THEN  5  WHEN 'jun' THEN  6
        WHEN 'jul' THEN  7  WHEN 'aug' THEN  8  WHEN 'sep' THEN  9
        WHEN 'oct' THEN 10  WHEN 'nov' THEN 11  WHEN 'dec' THEN 12
    END
        AS month_num,

    -- =========================================================================
    -- DERIVED COLUMN 8: debt_burden_flag
    -- =========================================================================
    -- Classifies customers by their combined loan obligations.
    -- Verified finding: Debt Free → 18.22% conversion vs Dual Debt → 6.07%.
    -- The single clearest negative predictor in the dataset (3× difference).
    -- =========================================================================
    CASE
        WHEN housing = 'yes' AND loan = 'yes' THEN 'Dual Debt Burden'
        WHEN housing = 'yes'                  THEN 'Housing Loan Only'
        WHEN loan    = 'yes'                  THEN 'Personal Loan Only'
        ELSE                                       'Debt Free'
    END
        AS debt_burden_flag,

    -- =========================================================================
    -- DERIVED COLUMN 9: valid_call_flag
    -- =========================================================================
    -- Marks records where an actual conversation took place (duration > 0).
    -- Only 3 zero-duration records exist in bank-full.csv (0.007%) —
    -- negligible, but flagged correctly for analytical completeness.
    -- =========================================================================
    CASE WHEN duration > 0 THEN 1 ELSE 0 END
        AS valid_call_flag

FROM bank_raw;


-- =============================================================================
-- SECTION 5: Performance Indexes
-- =============================================================================
-- Speeds up GROUP BY and WHERE filtering across all 60+ analysis queries.
-- Run once after bank_analysis is created.
-- =============================================================================

CREATE INDEX idx_y          ON bank_analysis (y);
CREATE INDEX idx_age_band   ON bank_analysis (age_band);
CREATE INDEX idx_job        ON bank_analysis (job);
CREATE INDEX idx_month_num  ON bank_analysis (month_num);
CREATE INDEX idx_poutcome   ON bank_analysis (poutcome);
CREATE INDEX idx_balance    ON bank_analysis (balance_tier);
CREATE INDEX idx_campaign   ON bank_analysis (campaign);


-- =============================================================================
-- SECTION 6: Final Verification
-- =============================================================================
-- Run all three checks. If all pass, Phase 2 SQL scripts are ready to run.
-- =============================================================================

-- CHECK 1: Row count and headline KPIs
-- Expected: 45,211 rows | 5,289 subscriptions | 11.70% conversion rate
SELECT
    COUNT(*)                                       AS total_records,
    SUM(subscription_flag)                         AS total_subscriptions,
    COUNT(*) - SUM(subscription_flag)              AS total_non_subscriptions,
    ROUND(AVG(subscription_flag) * 100, 2)         AS overall_conversion_rate_pct
FROM bank_analysis;

-- CHECK 2: Derived column spot-check — age bands
-- Expected: 5 rows with Retired (61+) having the smallest count (~1,188)
SELECT
    age_band,
    COUNT(*)                                       AS records,
    ROUND(AVG(subscription_flag) * 100, 2)         AS conversion_rate_pct
FROM bank_analysis
GROUP BY age_band
ORDER BY age_band;

-- CHECK 3: Target variable distribution
-- Expected: no = 39,922 (88.30%) | yes = 5,289 (11.70%)
SELECT
    y,
    COUNT(*)                                       AS count,
    ROUND(COUNT(*) * 100.0 / 45211, 2)             AS pct
FROM bank_analysis
GROUP BY y
ORDER BY y DESC;

-- =============================================================================
-- ✅ ALL CHECKS PASSED? → Proceed to 02_data_exploration.sql
-- =============================================================================
