-- =============================================================
-- Facebook Engagement Analysis — 2026 (MySQL 8)
-- Solar Shrestha-Greene
-- Table: facebook_posts  (imported from facebook_posts_clean.csv)
-- =============================================================

-- HOW TO LOAD THE DATA (MySQL Workbench):
-- 1. Create a schema:  CREATE DATABASE facebook_analysis;  USE facebook_analysis;
-- 2. Right-click the schema > Table Data Import Wizard > choose facebook_posts_clean.csv
-- 3. Name the table facebook_posts and finish the wizard.

USE facebook_analysis;

-- Only original page posts (no group cross-posts, no shares of other pages' posts)
CREATE OR REPLACE VIEW original_posts AS
SELECT *
FROM facebook_posts
WHERE is_crosspost = 0
  AND is_share = 0;

-- -------------------------------------------------------------
-- 0. Overview by page
-- -------------------------------------------------------------
SELECT page,
       COUNT(*)                          AS posts,
       SUM(views)                        AS total_views,
       ROUND(AVG(views), 0)              AS avg_views,
       ROUND(100.0 * SUM(interactions) / SUM(views), 2) AS engagement_rate_pct
FROM original_posts
GROUP BY page
ORDER BY total_views DESC;

-- -------------------------------------------------------------
-- Q1. Which post type gets the highest engagement rate?
-- -------------------------------------------------------------
SELECT post_type,
       COUNT(*)                                        AS posts,
       ROUND(AVG(views), 0)                            AS avg_views,
       ROUND(100.0 * SUM(interactions) / SUM(views), 2)  AS engagement_rate_pct,
       ROUND(100.0 * SUM(clicks) / SUM(views), 2)        AS click_rate_pct
FROM original_posts
GROUP BY post_type
HAVING COUNT(*) >= 3
ORDER BY engagement_rate_pct DESC;

-- -------------------------------------------------------------
-- Q2. Which day of the week works best?
-- -------------------------------------------------------------
SELECT day_of_week,
       COUNT(*)                                        AS posts,
       ROUND(AVG(views), 0)                            AS avg_views,
       ROUND(100.0 * SUM(interactions) / SUM(views), 2)  AS engagement_rate_pct
FROM original_posts
GROUP BY day_of_week
ORDER BY FIELD(day_of_week, 'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday');

-- -------------------------------------------------------------
-- Q3. Which time of day works best?
-- -------------------------------------------------------------
SELECT time_of_day,
       COUNT(*)                                        AS posts,
       ROUND(AVG(views), 0)                            AS avg_views,
       ROUND(100.0 * SUM(interactions) / SUM(views), 2)  AS engagement_rate_pct
FROM original_posts
GROUP BY time_of_day
HAVING COUNT(*) >= 5
ORDER BY engagement_rate_pct DESC;

-- -------------------------------------------------------------
-- Q4. Which month / season is strongest?
-- -------------------------------------------------------------
SELECT month, month_name,
       COUNT(*)                                        AS posts,
       SUM(views)                                      AS total_views,
       ROUND(100.0 * SUM(interactions) / SUM(views), 2)  AS engagement_rate_pct
FROM original_posts
GROUP BY month, month_name
ORDER BY month;

SELECT season,
       COUNT(*)                                        AS posts,
       SUM(views)                                      AS total_views,
       ROUND(100.0 * SUM(interactions) / SUM(views), 2)  AS engagement_rate_pct
FROM original_posts
GROUP BY season
ORDER BY engagement_rate_pct DESC;

-- -------------------------------------------------------------
-- Bonus A. Do calls to action ("book", "call", "discount"...) help?
-- -------------------------------------------------------------
SELECT CASE WHEN has_cta IN (1, 'True') THEN 'With call to action' ELSE 'No call to action' END AS cta,
       COUNT(*)                                        AS posts,
       ROUND(AVG(views), 0)                            AS avg_views,
       ROUND(100.0 * SUM(clicks) / SUM(views), 2)        AS click_rate_pct
FROM original_posts
GROUP BY cta;

-- -------------------------------------------------------------
-- Bonus B. Original posts vs. shares of other pages (all posts)
-- -------------------------------------------------------------
SELECT CASE WHEN is_share = 1 THEN 'Shared from others' ELSE 'Original' END AS origin,
       COUNT(*)                                        AS posts,
       ROUND(AVG(views), 0)                            AS avg_views,
       SUM(interactions)                               AS total_interactions
FROM facebook_posts
WHERE is_crosspost = 0
GROUP BY origin;

-- -------------------------------------------------------------
-- Bonus C. Top 10 posts by views (window function: rank within page)
-- -------------------------------------------------------------
SELECT *
FROM (
    SELECT page, publish_time, post_type, views, interactions,
           ROUND(engagement_rate * 100, 2) AS engagement_rate_pct,
           LEFT(caption, 60)               AS caption_start,
           RANK() OVER (PARTITION BY page ORDER BY views DESC) AS rank_in_page
    FROM original_posts
) ranked
WHERE rank_in_page <= 5
ORDER BY page, rank_in_page;

-- -------------------------------------------------------------
-- Bonus D. Monthly trend with running total of views (window function)
-- -------------------------------------------------------------
SELECT month, month_name,
       SUM(views)                                   AS views,
       SUM(SUM(views)) OVER (ORDER BY month)        AS running_total_views,
       SUM(views) - LAG(SUM(views)) OVER (ORDER BY month) AS change_vs_last_month
FROM original_posts
GROUP BY month, month_name
ORDER BY month;
