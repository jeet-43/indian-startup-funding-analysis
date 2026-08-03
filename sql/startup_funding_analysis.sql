-- Indian Startup Funding Analysis
-- MySQL queries answering the 6 key questions from the problem statement
-- Table: cleaned_startup_funding
-- Columns: Date, Startup_Name, Industry, SubVertical, City, Investors_Name,
--          Investment_Type, Amount_USD, Year, Month, YearMonth, Investment_Type_Clean

-- 1. Total funding trend by year and month

SELECT
    Year,
    Month,
    SUM(Amount_USD) AS total_funding,
    COUNT(*) AS total_deals
FROM cleaned_startup_funding
GROUP BY Year, Month
ORDER BY Year, Month;

-- 1a. Year over year funding growth

SELECT
    Year,
    SUM(Amount_USD) AS total_funding,
    LAG(SUM(Amount_USD)) OVER (ORDER BY Year) AS prev_year_funding,
    ROUND(
        (SUM(Amount_USD) - LAG(SUM(Amount_USD)) OVER (ORDER BY Year)) * 100.0
        / LAG(SUM(Amount_USD)) OVER (ORDER BY Year), 2
    ) AS yoy_growth_pct
FROM cleaned_startup_funding
GROUP BY Year
ORDER BY Year;

-- 1b. Month over month funding growth

SELECT
    YearMonth,
    SUM(Amount_USD) AS total_funding,
    LAG(SUM(Amount_USD)) OVER (ORDER BY YearMonth) AS prev_month_funding,
    ROUND(
        (SUM(Amount_USD) - LAG(SUM(Amount_USD)) OVER (ORDER BY YearMonth)) * 100.0
        / LAG(SUM(Amount_USD)) OVER (ORDER BY YearMonth), 2
    ) AS mom_growth_pct
FROM cleaned_startup_funding
GROUP BY YearMonth
ORDER BY YearMonth;

-- 1c. Running cumulative funding over time

SELECT
    YearMonth,
    SUM(Amount_USD) AS monthly_funding,
    SUM(SUM(Amount_USD)) OVER (ORDER BY YearMonth) AS cumulative_funding
FROM cleaned_startup_funding
GROUP BY YearMonth
ORDER BY YearMonth;

-- 2. Industries by total funding

SELECT
    Industry,
    SUM(Amount_USD) AS total_funding,
    COUNT(*) AS total_deals,
    ROUND(AVG(Amount_USD), 2) AS avg_deal_size
FROM cleaned_startup_funding
GROUP BY Industry
ORDER BY total_funding DESC;

-- 2a. Industry funding by year, to see shift over time

SELECT
    Year,
    Industry,
    SUM(Amount_USD) AS total_funding
FROM cleaned_startup_funding
GROUP BY Year, Industry
ORDER BY Year, total_funding DESC;

-- 2b. Top 5 industries each year, ranked

SELECT *
FROM (
    SELECT
        Year,
        Industry,
        SUM(Amount_USD) AS total_funding,
        RANK() OVER (PARTITION BY Year ORDER BY SUM(Amount_USD) DESC) AS industry_rank
    FROM cleaned_startup_funding
    GROUP BY Year, Industry
) ranked
WHERE industry_rank <= 5
ORDER BY Year, industry_rank;

-- 2c. Industry share of total funding per year (percentage)

SELECT
    Year,
    Industry,
    SUM(Amount_USD) AS industry_funding,
    ROUND(
        SUM(Amount_USD) * 100.0 / SUM(SUM(Amount_USD)) OVER (PARTITION BY Year), 2
    ) AS pct_share_of_year
FROM cleaned_startup_funding
GROUP BY Year, Industry
ORDER BY Year, pct_share_of_year DESC;

-- 3. Biggest city hubs by funding

SELECT
    City,
    SUM(Amount_USD) AS total_funding,
    COUNT(*) AS total_deals,
    ROUND(AVG(Amount_USD), 2) AS avg_deal_size
FROM cleaned_startup_funding
GROUP BY City
ORDER BY total_funding DESC;

-- 3a. City funding trend by year

SELECT
    City,
    Year,
    SUM(Amount_USD) AS total_funding
FROM cleaned_startup_funding
GROUP BY City, Year
ORDER BY City, Year;

-- 3b. Top city per industry

SELECT *
FROM (
    SELECT
        Industry,
        City,
        SUM(Amount_USD) AS total_funding,
        RANK() OVER (PARTITION BY Industry ORDER BY SUM(Amount_USD) DESC) AS city_rank
    FROM cleaned_startup_funding
    GROUP BY Industry, City
) ranked
WHERE city_rank = 1
ORDER BY total_funding DESC;

-- 4. Distribution across funding stages

SELECT
    Investment_Type_Clean,
    SUM(Amount_USD) AS total_funding,
    COUNT(*) AS total_deals,
    ROUND(SUM(Amount_USD) * 100.0 / SUM(SUM(Amount_USD)) OVER (), 2) AS pct_of_total_funding
FROM cleaned_startup_funding
GROUP BY Investment_Type_Clean
ORDER BY total_funding DESC;

-- 4a. Funding stage trend by year

SELECT
    Year,
    Investment_Type_Clean,
    SUM(Amount_USD) AS total_funding,
    COUNT(*) AS total_deals
FROM cleaned_startup_funding
GROUP BY Year, Investment_Type_Clean
ORDER BY Year, total_funding DESC;

-- 5. Top investors by number of deals

SELECT
    Investors_Name,
    COUNT(*) AS total_deals
FROM cleaned_startup_funding
GROUP BY Investors_Name
ORDER BY total_deals DESC
LIMIT 10;

-- 5a. Top investors by total amount invested

SELECT
    Investors_Name,
    SUM(Amount_USD) AS total_amount
FROM cleaned_startup_funding
GROUP BY Investors_Name
ORDER BY total_amount DESC
LIMIT 10;

-- 5b. Top investors by industry focus

SELECT
    Investors_Name,
    Industry,
    COUNT(*) AS total_deals,
    SUM(Amount_USD) AS total_amount
FROM cleaned_startup_funding
GROUP BY Investors_Name, Industry
ORDER BY total_deals DESC
LIMIT 20;

-- 6. Average and median deal size by industry

WITH ranked_industry AS (
    SELECT
        Industry,
        Amount_USD,
        ROW_NUMBER() OVER (PARTITION BY Industry ORDER BY Amount_USD) AS row_num,
        COUNT(*) OVER (PARTITION BY Industry) AS row_count
    FROM cleaned_startup_funding
    WHERE Amount_USD IS NOT NULL
)
SELECT
    Industry,
    ROUND(AVG(Amount_USD), 2) AS median_deal_size
FROM ranked_industry
WHERE row_num IN (FLOOR((row_count + 1) / 2), CEIL((row_count + 1) / 2))
GROUP BY Industry;

-- 6a. Average deal size by industry, separate query for side by side comparison

SELECT
    Industry,
    ROUND(AVG(Amount_USD), 2) AS avg_deal_size
FROM cleaned_startup_funding
WHERE Amount_USD IS NOT NULL
GROUP BY Industry
ORDER BY avg_deal_size DESC;

-- 6b. Average and median deal size by funding stage

WITH ranked_stage AS (
    SELECT
        Investment_Type_Clean,
        Amount_USD,
        ROW_NUMBER() OVER (PARTITION BY Investment_Type_Clean ORDER BY Amount_USD) AS row_num,
        COUNT(*) OVER (PARTITION BY Investment_Type_Clean) AS row_count
    FROM cleaned_startup_funding
    WHERE Amount_USD IS NOT NULL
)
SELECT
    Investment_Type_Clean,
    ROUND(AVG(Amount_USD), 2) AS median_deal_size
FROM ranked_stage
WHERE row_num IN (FLOOR((row_count + 1) / 2), CEIL((row_count + 1) / 2))
GROUP BY Investment_Type_Clean;

SELECT
    Investment_Type_Clean,
    ROUND(AVG(Amount_USD), 2) AS avg_deal_size
FROM cleaned_startup_funding
WHERE Amount_USD IS NOT NULL
GROUP BY Investment_Type_Clean
ORDER BY avg_deal_size DESC;

-- Extra analytical queries beyond the 6 core questions

-- Overall disclosed vs undisclosed deal percentage

SELECT
    SUM(CASE WHEN Amount_USD IS NOT NULL THEN 1 ELSE 0 END) AS disclosed_deals,
    SUM(CASE WHEN Amount_USD IS NULL THEN 1 ELSE 0 END) AS undisclosed_deals,
    ROUND(
        SUM(CASE WHEN Amount_USD IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2
    ) AS disclosed_pct
FROM cleaned_startup_funding;

-- Top 10 largest single funding rounds

SELECT
    Startup_Name,
    Industry,
    City,
    Investors_Name,
    Investment_Type_Clean,
    Amount_USD,
    Date
FROM cleaned_startup_funding
WHERE Amount_USD IS NOT NULL
ORDER BY Amount_USD DESC
LIMIT 10;

-- Startups that raised more than one round, with total raised

SELECT
    Startup_Name,
    COUNT(*) AS total_rounds,
    SUM(Amount_USD) AS total_raised
FROM cleaned_startup_funding
GROUP BY Startup_Name
HAVING COUNT(*) > 1
ORDER BY total_raised DESC;

-- Top subverticals by funding within top industries

SELECT
    Industry,
    SubVertical,
    SUM(Amount_USD) AS total_funding,
    COUNT(*) AS total_deals
FROM cleaned_startup_funding
WHERE Industry IN (
    SELECT Industry FROM (
        SELECT Industry, SUM(Amount_USD) AS total
        FROM cleaned_startup_funding
        GROUP BY Industry
        ORDER BY total DESC
        LIMIT 5
    ) top_industries
)
GROUP BY Industry, SubVertical
ORDER BY Industry, total_funding DESC;

-- City and industry combined view, top 15 pairs by funding

SELECT
    City,
    Industry,
    SUM(Amount_USD) AS total_funding,
    COUNT(*) AS total_deals
FROM cleaned_startup_funding
GROUP BY City, Industry
ORDER BY total_funding DESC
LIMIT 15;

-- Number of unique investors and unique startups per year

SELECT
    Year,
    COUNT(DISTINCT Startup_Name) AS unique_startups,
    COUNT(DISTINCT Investors_Name) AS unique_investors,
    COUNT(*) AS total_deals
FROM cleaned_startup_funding
GROUP BY Year
ORDER BY Year;
