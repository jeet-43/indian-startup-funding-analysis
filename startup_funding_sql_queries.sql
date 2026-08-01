-- =====================================================
-- Indian Startup Funding Analysis - Business Questions
-- Database: SQLite (startup_funding.db)
-- Table: startup_funding
-- Business problem: see Business_Problem_Document.pdf
-- =====================================================


-- -----------------------------------------------------
-- LEVEL 1: Basic SELECT, WHERE, ORDER BY
-- -----------------------------------------------------

-- Q1: What does the data look like? (always start here)
SELECT * FROM startup_funding LIMIT 10;


-- Q2: How many total funding deals are in the dataset?
SELECT COUNT(*) AS total_deals
FROM startup_funding;


-- Q3: What is the total funding amount raised across all deals?
-- Note: amount_usd has missing values, SUM() automatically ignores NULLs
SELECT SUM(amount_usd) AS total_funding_usd
FROM startup_funding;


-- Q4: Show the 10 largest single funding deals
SELECT startup_name, city_clean, amount_usd, date
FROM startup_funding
WHERE amount_usd IS NOT NULL
ORDER BY amount_usd DESC
LIMIT 10;


-- -----------------------------------------------------
-- LEVEL 2: GROUP BY, aggregation functions
-- -----------------------------------------------------

-- Q5: Total funding by year. Is funding growing or shrinking?
SELECT
    year,
    COUNT(*) AS deal_count,
    SUM(amount_usd) AS total_funding_usd
FROM startup_funding
WHERE year IS NOT NULL
GROUP BY year
ORDER BY year;


-- Q6: Top 10 sectors by TOTAL FUNDING (money-based ranking)
SELECT
    industry_vertical_clean AS sector,
    SUM(amount_usd) AS total_funding_usd
FROM startup_funding
WHERE industry_vertical_clean IS NOT NULL
GROUP BY industry_vertical_clean
ORDER BY total_funding_usd DESC
LIMIT 10;


-- Q7: Top 10 sectors by DEAL COUNT (activity-based ranking)
-- Compare this result to Q6. The rankings often differ.
-- A sector can have many small deals (high count, lower total)
-- or a few huge deals (low count, high total). This is the
-- "broad activity vs. concentrated bets" question from the
-- business problem document.
SELECT
    industry_vertical_clean AS sector,
    COUNT(*) AS deal_count
FROM startup_funding
GROUP BY industry_vertical_clean
ORDER BY deal_count DESC
LIMIT 10;


-- Q8: City-wise funding concentration
-- Uses city_clean, which merges spelling duplicates like
-- Bangalore/Bengaluru and Gurgaon/Gurugram into one value.
SELECT
    city_clean AS city,
    COUNT(*) AS deal_count,
    SUM(amount_usd) AS total_funding_usd
FROM startup_funding
WHERE city_clean IS NOT NULL
GROUP BY city_clean
ORDER BY total_funding_usd DESC
LIMIT 10;


-- Q9: Which investors appear most often (most active investors)?
-- Note: investors_name can contain multiple investors separated by commas,
-- so this counts ROWS where an investor is mentioned, not unique deals per investor
SELECT
    investors_name,
    COUNT(*) AS deals_involved
FROM startup_funding
WHERE investors_name IS NOT NULL
GROUP BY investors_name
ORDER BY deals_involved DESC
LIMIT 10;


-- Q10: Average deal size by investment stage
-- Shows how ticket size differs from Seed to later stages
SELECT
    investment_type_clean AS stage,
    COUNT(*) AS deal_count,
    ROUND(AVG(amount_usd), 0) AS avg_deal_size_usd
FROM startup_funding
WHERE amount_usd IS NOT NULL
GROUP BY investment_type_clean
HAVING COUNT(*) >= 5   -- ignore stages with too few deals to be meaningful
ORDER BY avg_deal_size_usd DESC;


-- Q14: City x sector cross tab (deal count and funding)
-- This is the query behind the dashboard's "City Opportunity Map" page.
-- It answers the business problem's third question: which city/sector
-- combinations show high deal activity but comparatively low total
-- capital, relative to more saturated hubs.
SELECT
    city_clean AS city,
    industry_vertical_clean AS sector,
    COUNT(*) AS deal_count,
    SUM(amount_usd) AS total_funding_usd
FROM startup_funding
WHERE city_clean IN ('Bengaluru', 'Mumbai', 'New Delhi', 'Gurugram',
                      'Pune', 'Chennai', 'Noida', 'Hyderabad')
  AND industry_vertical_clean IN ('Consumer Internet', 'E-commerce', 'FinTech',
                                   'HealthTech', 'Technology', 'Transportation')
GROUP BY city_clean, industry_vertical_clean
ORDER BY city, sector;


-- -----------------------------------------------------
-- LEVEL 3: Window functions (RANK, growth percent)
-- -----------------------------------------------------

-- Q11: Rank sectors by funding WITHIN each year
-- This shows the number 1 sector for EACH year separately, not overall.
-- This is the query behind the dashboard's "Sector Momentum" page,
-- and it directly answers the business problem's first question:
-- which sectors show sustained momentum vs. one-off mega-round spikes.
SELECT *
FROM (
    SELECT
        year,
        industry_vertical_clean AS sector,
        SUM(amount_usd) AS total_funding_usd,
        RANK() OVER (
            PARTITION BY year
            ORDER BY SUM(amount_usd) DESC
        ) AS sector_rank
    FROM startup_funding
    WHERE year IS NOT NULL AND industry_vertical_clean IS NOT NULL
    GROUP BY year, industry_vertical_clean
)
WHERE sector_rank <= 3   -- top 3 sectors per year
ORDER BY year, sector_rank;


-- Q12: Month-over-month funding trend with growth percent
-- LAG() looks at the PREVIOUS row's value so we can calculate percent change
SELECT
    year_month,
    monthly_total,
    LAG(monthly_total) OVER (ORDER BY year_month) AS previous_month_total,
    ROUND(
        (monthly_total - LAG(monthly_total) OVER (ORDER BY year_month)) * 100.0
        / LAG(monthly_total) OVER (ORDER BY year_month),
        1
    ) AS mom_growth_percent
FROM (
    SELECT
        year_month,
        SUM(amount_usd) AS monthly_total
    FROM startup_funding
    WHERE year_month IS NOT NULL
    GROUP BY year_month
)
ORDER BY year_month;


-- Q13: Running (cumulative) total funding over time
SELECT
    year_month,
    SUM(amount_usd) AS monthly_total,
    SUM(SUM(amount_usd)) OVER (ORDER BY year_month) AS cumulative_total
FROM startup_funding
WHERE year_month IS NOT NULL
GROUP BY year_month
ORDER BY year_month;
