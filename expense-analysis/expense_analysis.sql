-- =============================================================
-- DCLC Expense & Job-Costing Analysis — 2026 (MySQL 8)
-- Solar Shrestha-Greene
-- Tables: purchases (purchases_clean.csv), trips (trips_raw.csv),
--         meals (meals_raw.csv), mileage_rates (mileage_rates.csv)
-- =============================================================

-- HOW TO LOAD THE DATA (MySQL Workbench):
-- 1. CREATE DATABASE dclc_expenses;  USE dclc_expenses;
-- 2. Right-click the schema > Table Data Import Wizard, once per CSV.
-- 3. Name the tables purchases, trips, meals and mileage_rates.

USE dclc_expenses;

-- -------------------------------------------------------------
-- 0. Overview
-- -------------------------------------------------------------
SELECT COUNT(*)              AS items,
       ROUND(SUM(amount), 2) AS total_spend,
       MIN(date)             AS first_purchase,
       MAX(date)             AS last_purchase
FROM purchases;

-- -------------------------------------------------------------
-- Q1. Where does the money go? (share of total + rank)
-- -------------------------------------------------------------
SELECT spend_category,
       COUNT(*)                                              AS items,
       ROUND(SUM(amount), 2)                                 AS spend,
       ROUND(100.0 * SUM(amount) / SUM(SUM(amount)) OVER (), 1) AS share_pct,
       RANK() OVER (ORDER BY SUM(amount) DESC)               AS spend_rank
FROM purchases
GROUP BY spend_category
ORDER BY spend DESC;

-- Q1b. One-off equipment purchases of $100 or more
SELECT date, amount, LEFT(description, 50) AS item
FROM purchases
WHERE spend_category = 'Equipment & tools'
  AND amount >= 100
ORDER BY amount DESC;

-- -------------------------------------------------------------
-- Q2. How does spending change through the year?
--     Running total and month-over-month change (window functions)
-- -------------------------------------------------------------
WITH monthly AS (
    SELECT month,
           COUNT(*)              AS items,
           ROUND(SUM(amount), 2) AS spend
    FROM purchases
    GROUP BY month
)
SELECT month,
       items,
       spend,
       ROUND(SUM(spend) OVER (ORDER BY month), 2)   AS running_total,
       ROUND(spend - LAG(spend) OVER (ORDER BY month), 2) AS change_vs_prior_month
FROM monthly
ORDER BY month;

-- Q2b. Share of the year's purchases made June–August
SELECT ROUND(100.0 * SUM(CASE WHEN month BETWEEN '2026-06' AND '2026-08' THEN amount ELSE 0 END)
             / SUM(amount), 1) AS summer_share_pct
FROM purchases;

-- -------------------------------------------------------------
-- Q3. Can spending be tied to a client? (job costing)
-- -------------------------------------------------------------
SELECT client,
       COUNT(*)                                              AS items,
       ROUND(SUM(amount), 2)                                 AS spend,
       ROUND(100.0 * SUM(amount) / SUM(SUM(amount)) OVER (), 1) AS share_pct
FROM purchases
GROUP BY client
ORDER BY spend DESC;

-- Q3b. Share of each category's spending with no client
SELECT spend_category,
       ROUND(100.0 * SUM(CASE WHEN client = 'Not recorded' THEN amount ELSE 0 END)
             / SUM(amount), 0) AS no_client_pct
FROM purchases
GROUP BY spend_category
ORDER BY no_client_pct DESC;

-- -------------------------------------------------------------
-- Q4. Trips: miles by destination and mileage value
--     (rate = the latest rate in effect on each trip date)
-- -------------------------------------------------------------
SELECT COALESCE(t.destination, 'Pine & Paw Lodge') AS destination,
       COUNT(*)                                     AS trips,
       ROUND(SUM(t.miles), 1)                       AS miles,
       ROUND(SUM(t.miles * (SELECT r.cents_per_mile
                            FROM mileage_rates r
                            WHERE r.effective_from <= t.date
                            ORDER BY r.effective_from DESC
                            LIMIT 1) / 100), 2)     AS mileage_value
FROM trips t
GROUP BY COALESCE(t.destination, 'Pine & Paw Lodge')
ORDER BY miles DESC;

-- Q4b. Meals: total and the logged deductible amount
SELECT COUNT(*)                                        AS meals,
       ROUND(SUM(amount), 2)                           AS total,
       ROUND(SUM(amount * deductible_pct / 100), 2)    AS deductible_at_logged_pct
FROM meals;

-- -------------------------------------------------------------
-- Q5. Data-quality checks
-- -------------------------------------------------------------
SELECT ROUND(100.0 * AVG(CASE WHEN client <> 'Not recorded' THEN 1 ELSE 0 END), 0) AS pct_with_client,
       ROUND(100.0 * AVG(CASE WHEN category <> 'Supplies'     THEN 1 ELSE 0 END), 0) AS pct_useful_category,
       ROUND(100.0 * AVG(has_receipt), 0)                                           AS pct_with_receipt,
       ROUND(100.0 * AVG(CASE WHEN vendor = vendor_raw         THEN 1 ELSE 0 END), 0) AS pct_vendor_consistent
FROM purchases;

-- Q5b. Repeated identical lines (same day, vendor, item and price)
SELECT date, vendor, LEFT(description, 50) AS item, amount, COUNT(*) AS lines
FROM purchases
GROUP BY date, vendor, description, amount
HAVING COUNT(*) > 1
ORDER BY lines DESC;
