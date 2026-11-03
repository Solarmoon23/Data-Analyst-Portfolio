-- =============================================================
-- Hospital Readmissions in PA, WV and MD — CMS HRRP FY 2026 (MySQL 8)
-- Solar Shrestha-Greene
-- Tables: readmissions (readmissions_pa_wv_md.csv)
--         national_benchmarks (national_benchmarks.csv)
-- Excess readmission ratio (ERR) > 1 = more readmissions than expected
-- =============================================================

-- HOW TO LOAD: CREATE DATABASE hospital_readmissions; USE hospital_readmissions;
-- then Table Data Import Wizard for each CSV (table names as above).

USE hospital_readmissions;

-- Reported results only (CMS suppresses small or missing results)
CREATE OR REPLACE VIEW reported AS
SELECT *, CASE WHEN excess_ratio > 1 THEN 1 ELSE 0 END AS worse
FROM readmissions
WHERE excess_ratio IS NOT NULL;

-- -------------------------------------------------------------
-- Q1. How do the states compare?
-- -------------------------------------------------------------
SELECT state_name,
       COUNT(DISTINCT facility_id)     AS hospitals,
       COUNT(*)                        AS results,
       ROUND(100.0 * AVG(worse), 1)    AS pct_worse_than_expected,
       ROUND(AVG(excess_ratio), 3)     AS avg_ratio
FROM reported
GROUP BY state_name
ORDER BY pct_worse_than_expected DESC;

-- -------------------------------------------------------------
-- Q2. Which conditions are the problem in each state?
--     Rank conditions within each state (window function)
-- -------------------------------------------------------------
WITH by_condition AS (
    SELECT state, `condition`,
           COUNT(*)                     AS hospitals,
           ROUND(100.0 * AVG(worse), 0) AS pct_worse
    FROM reported
    GROUP BY state, `condition`
)
SELECT state, `condition`, hospitals, pct_worse,
       RANK() OVER (PARTITION BY state ORDER BY pct_worse DESC) AS rank_in_state
FROM by_condition
ORDER BY state, rank_in_state;

-- -------------------------------------------------------------
-- Q3. Best and worst hospitals (3+ reported conditions)
-- -------------------------------------------------------------
WITH hospital_scores AS (
    SELECT facility_id, hospital, city, state,
           COUNT(*)                   AS conditions,
           ROUND(AVG(excess_ratio), 3) AS avg_ratio,
           SUM(worse)                 AS conditions_worse,
           MAX(star_rating)           AS star_rating
    FROM reported
    GROUP BY facility_id, hospital, city, state
    HAVING COUNT(*) >= 3
)
SELECT hospital, city, state, conditions, avg_ratio, conditions_worse, star_rating,
       RANK()   OVER (ORDER BY avg_ratio)       AS overall_rank,
       NTILE(4) OVER (ORDER BY avg_ratio)       AS quartile     -- 1 = best 25%
FROM hospital_scores
ORDER BY avg_ratio;

-- -------------------------------------------------------------
-- Q4. Each hospital vs the national median for the same condition
-- -------------------------------------------------------------
SELECT r.hospital, r.state, r.`condition`,
       r.excess_ratio,
       n.national_median_ratio,
       ROUND(r.excess_ratio - n.national_median_ratio, 3) AS gap_vs_national
FROM reported r
JOIN national_benchmarks n ON n.`condition` = r.`condition`
ORDER BY gap_vs_national DESC
LIMIT 15;

-- -------------------------------------------------------------
-- Q5. Do star ratings line up with readmissions?
-- -------------------------------------------------------------
WITH hospital_avg AS (
    SELECT facility_id, MAX(star_rating) AS star_rating, AVG(excess_ratio) AS avg_ratio
    FROM reported
    GROUP BY facility_id
)
SELECT star_rating, COUNT(*) AS hospitals, ROUND(AVG(avg_ratio), 3) AS avg_ratio
FROM hospital_avg
WHERE star_rating IS NOT NULL
GROUP BY star_rating
ORDER BY star_rating;

-- -------------------------------------------------------------
-- Q6. Readmissions above expected, by state
--     (predicted rate - expected rate) x discharges, where reported
-- -------------------------------------------------------------
SELECT state,
       ROUND(SUM((predicted_rate_pct - expected_rate_pct) / 100 * discharges), 0) AS readmissions_above_expected
FROM reported
WHERE discharges IS NOT NULL
  AND predicted_rate_pct > expected_rate_pct
GROUP BY state
ORDER BY readmissions_above_expected DESC;
