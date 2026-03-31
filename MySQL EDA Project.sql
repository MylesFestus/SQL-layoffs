-- Checking the data (Self data exploration)
-- Part One - Basic Understanding
-- 1.How many total layoff records are in the dataset?
-- 2.How many unique companies are represented?
-- 3.What is the date range of the layoffs?
-- 4.How many countries are included?
-- 5.How many industries are listed?
-- 6.Which columns have NULL values, and how many per column?

-- Let's dive in 
-- Part 1
-- Question 1
-- How many total layoff records are in the dataset?

SELECT
    SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
WHERE total_laid_off IS NOT null;


-- Question 2
-- How many unique companies are represented?
SELECT DISTINCT company FROM layoffs_staging2;

-- Question 3
-- What is the date range of the layoffs?
SELECT 
	MAX(date) AS earliest_layoff_date
    ,MIN(date) AS latest_layoff_date
FROM layoffs_staging2;


-- Question 4
-- How many countries are included?
SELECT
	COUNT(DISTINCT country) AS num_of_countries
FROM layoffs_staging2;


-- Question 5
-- How many industries are listed?
SELECT
	COUNT(DISTINCT industry) AS num_of_industry
FROM layoffs_staging2;


-- Question 6
-- Which columns have NULL values, and how many per column?
SELECT
    SUM(CASE WHEN company IS NULL THEN 1 ELSE 0 END) AS company_nulls,
    SUM(CASE WHEN location IS NULL THEN 1 ELSE 0 END) AS location_nulls,
    SUM(CASE WHEN industry IS NULL THEN 1 ELSE 0 END) AS industry_nulls,
    SUM(CASE WHEN total_laid_off IS NULL THEN 1 ELSE 0 END) AS total_laid_off_nulls,
    SUM(CASE WHEN percentage_laid_off IS NULL THEN 1 ELSE 0 END) AS percentage_laid_off_nulls,
    SUM(CASE WHEN date IS NULL THEN 1 ELSE 0 END) AS date_nulls,
    SUM(CASE WHEN stage IS NULL THEN 1 ELSE 0 END) AS stage_nulls,
    SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS country_nulls,
    SUM(CASE WHEN funds_raised_millions IS NULL THEN 1 ELSE 0 END) AS funds_raised_nulls
FROM layoffs_staging2;

-- Part 2
-- Overall Layoff Impact
-- High-level magnitude questions.
-- 7.What is the total number of employees laid off in 2022?
-- 8.What is the average number of layoffs per company?
-- 9.What is the maximum number of layoffs in a single event?
-- 10.How many companies laid off 100% of their workforce?
-- 11.What is the distribution of percentage_laid_off?


-- Part2
-- Question 7
-- What is the total number of employees laid off in 2022?
SELECT
	SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
WHERE YEAR(date) = '2022';

-- Question 8
-- What is the average number of layoffs per company?
SELECT company
	,ROUND(AVG(total_laid_off),2) AS avg_layoffs
FROM layoffs_staging2
GROUP BY company
ORDER BY avg_layoffs DESC; -- solve this again


-- Question 9
-- What is the maximum number of layoffs in a single event?
SELECT company,
    total_laid_off,
    `date`
FROM layoffs
WHERE total_laid_off = (
    SELECT MAX(total_laid_off)
    FROM layoffs_staging2
    WHERE total_laid_off IS NOT NULL
);


-- Question 10
-- How many companies laid off 100% of their workforce?
SELECT COUNT(company) AS total_company
FROM layoffs_staging2
WHERE percentage_laid_off = 1;


-- Question 11
-- 11.What is the distribution of percentage_laid_off?
-- method 1
SELECT
    MIN(percentage_laid_off) AS min_pct,
    MAX(percentage_laid_off) AS max_pct,
    AVG(percentage_laid_off) AS avg_pct
   -- PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY percentage_laid_off) AS median_pct
FROM layoffs_staging2
WHERE percentage_laid_off IS NOT NULL;

-- method 2 this is most useful for our data 
SELECT
    CASE
        WHEN percentage_laid_off = 1 THEN '100%'
        WHEN percentage_laid_off >= 0.75 THEN '75–99%'
        WHEN percentage_laid_off >= 0.50 THEN '50–74%'
        WHEN percentage_laid_off >= 0.25 THEN '25–49%'
        WHEN percentage_laid_off > 0 THEN '1–24%'
        ELSE '0%'
    END AS percentage_range,
    COUNT(company) AS company_count
FROM layoffs_staging2
WHERE percentage_laid_off IS NOT NULL
GROUP BY percentage_range
ORDER BY company_count DESC;


-- Part 3
-- Time-Based Analysis (Understand trends over time)
-- 12.How many layoffs occurred per month in 2022?
-- 13.Which month had the highest total layoffs?
-- 14.How many companies announced layoffs each month?
-- 15.What is the cumulative total of layoffs over time?
-- 16.Were layoffs increasing or decreasing toward the end of 2022?


-- Part 3
-- Question 12
-- How many layoffs occurred per month in 2022?
SELECT 
	YEAR(`date`) AS year,
	MONTH(`date`) AS month,
	SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
WHERE YEAR(date) = '2022'
GROUP BY year, month
ORDER BY year, month;


-- Question 13
-- Which month had the highest total layoffs?
SELECT 
	YEAR(`date`) AS year,
	MONTH(`date`) AS month,
	SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
WHERE YEAR(date) = '2022'
GROUP BY year, month
ORDER BY total_layoffs DESC
LIMIT 5;

-- Question 14
-- How many companies announced layoffs each month?
SELECT 
	DATE_FORMAT(`date`, '%Y-%m') AS month,              -- Group by month
	COUNT(DISTINCT company) AS total_companies          -- Count unique companies
FROM layoffs_staging2                                   -- Each company is counted once per month, even if it had multiple layoff events
WHERE `date` IS NOT NULL
GROUP BY DATE_FORMAT(`date`, '%Y-%m')
ORDER BY month;

-- Question 15
-- What is the cumulative total of layoffs over time?
-- Approach using as rolling_total

WITH ROLLING_TOTAL AS 
(
SELECT SUBSTRING(date,1,7) as dates, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY dates
ORDER BY dates ASC
)
SELECT dates, SUM(total_laid_off) OVER (ORDER BY dates ASC) as rolling_total_layoffs
FROM ROLLING_TOTAL
ORDER BY dates ASC;

-- Question 16
-- Were layoffs increasing or decreasing toward the end of 2022?
WITH ROLLING_TOTAL AS 
(
SELECT SUBSTRING(date,1,7) as dates, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
WHERE YEAR(`date`) = '2022'
GROUP BY dates
)
SELECT dates, SUM(total_laid_off) OVER (ORDER BY dates ASC) as rolling_total_layoffs
FROM ROLLING_TOTAL;

-- Part 3
-- Company-Level Analysis
-- Identify major players.
-- 17.Which companies had the highest total layoffs?
-- 18.Which companies had multiple layoff events?
-- 19.What is the average layoff size per company?
-- 20.Which companies laid off the highest percentage of employees?
-- 21.How many startups vs. large companies conducted layoffs?

-- Question 17
-- Which companies had the highest total layoffs?
SELECT
    company,
    SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY company
ORDER BY total_layoffs DESC;


-- Question 18
-- Which companies had multiple layoff events?
SELECT
    company,
    COUNT(company) AS layoff_events
FROM layoffs_staging2
GROUP BY company
HAVING COUNT(company) > 1
ORDER BY layoff_events DESC;

-- Question 19
-- What is the average layoff size per company?
SELECT
    company,
    ROUND(AVG(total_laid_off),2) AS avg_layoffs
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY company
ORDER BY avg_layoffs DESC;

-- Question 20
-- Which companies laid off the highest percentage of employees?
SELECT 
	company
    ,MAX(percentage_laid_off) AS max_percentage_lay_off
FROM layoffs_staging2
WHERE percentage_laid_off IS NOT NULL
GROUP BY company
ORDER BY  max_percentage_lay_off DESC;

-- total number of companies with max_percentage_lay_offs
SELECT 
    COUNT(percentage_laid_off) AS total_percentage_lay_off
FROM layoffs_staging2
WHERE percentage_laid_off IS NOT NULL 
	AND percentage_laid_off = 1;

-- Question 21
-- How many startups vs. large companies conducted layoffs?
SELECT
    company_type,
    COUNT(company) AS num_companies
FROM (
    SELECT company,
        CASE
            WHEN SUM(total_laid_off) < 100 THEN 'Startup'
            ELSE 'Large Company'
        END AS company_type
    FROM layoffs_staging2
    WHERE total_laid_off IS NOT NULL
    GROUP BY company
) t
GROUP BY company_type;

-- Part 4
-- Industry Analysis
-- See which sectors were hit hardest.
-- 22.Which industries had the highest total layoffs?
-- 23.Which industry had the highest average layoffs per company?
-- 24.How many companies laid off employees in each industry?
-- 25.Which industries had the most companies laying off 100% of staff?
-- 26.How did layoffs in Tech compare to non-Tech industries?


-- Question 22
-- Which industries had the highest total layoffs?
SELECT industry,
	COUNT(industry) AS layoff_events,
	SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
	AND industry IS NOT NULL
GROUP BY industry
ORDER BY total_layoffs DESC;


-- Question 23
-- Which industry had the highest average layoffs per company?
SELECT company, industry, 
	ROUND(AVG(total_laid_off),2) AS avg_layoff
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
	AND industry IS NOT NULL
GROUP BY company, industry
ORDER BY avg_layoff DESC;


-- Question 24
-- How many companies laid off employees in each industry?
SELECT 
	industry,
    COUNT(DISTINCT company) AS num_company_with_layoffs
FROM layoffs_staging2
WHERE industry IS NOT NULL
GROUP BY industry
ORDER BY num_company_with_layoffs DESC;


-- Question 25
-- Which industries had the most companies laying off 100% of staff?
SELECT industry,
	COUNT(DISTINCT company) AS companies_laid_off_100_pct
FROM layoffs_staging2
WHERE percentage_laid_off = 1
	AND industry IS NOT NULL
GROUP BY industry
ORDER BY companies_laid_off_100_pct DESC;


-- Question 26
-- How did layoffs in Tech compare to non-Tech industries?
SELECT  CASE
		WHEN industry LIKE '%tech%'
			OR industry LIKE '%software%'
            OR industry LIKE '%IT%'
        THEN 'Tech'
		ELSE 'Non-Tech'
	END AS business_unit
    ,COUNT(total_laid_off) AS total_laid_offs
FROM layoffs_staging2
GROUP BY business_unit;


-- Part 5
-- Geographic Analysis
-- Explore regional impact.
-- 27.Which countries had the highest total layoffs?
-- 28.Which country had the most layoff events?
-- 29.What is the average layoff size per country?
-- 30.How do layoffs in the U.S. compare to the rest of the world?
-- 31.Which regions experienced layoffs across the most industries
    

-- Question 27
-- Which countries had the highest total layoffs?
SELECT country
	,COUNT(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY country
ORDER BY total_laid_off DESC;

-- Question 28
-- Which country had the most layoff events?














-- total layoffs per country, industry and year
WITH Country_Industry_Year AS 
(
  SELECT country, industry, YEAR(date) AS years, SUM(total_laid_off) AS total_laid_off
  FROM layoffs_staging2
  GROUP BY country, industry, YEAR(date)
)
, Country_Industry_Year_Rank AS (
  SELECT country, industry, years, total_laid_off, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
  FROM Country_Industry_Year
)
SELECT country, industry, years, total_laid_off, ranking
FROM Country_Industry_Year_Rank
WHERE ranking <= 5
AND years IS NOT NULL
ORDER BY years ASC, total_laid_off DESC;






SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY country, date
ORDER BY total_layoffs DESC;

-- total layoffs per year
SELECT YEAR (date)
    ,SUM(total_laid_off) AS total_layoffs
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
GROUP BY date
ORDER BY total_layoffs DESC;

SELECT * FROM layoffs_staging2;

-- company with more than 20 funds_raised_millions and still went under (100% layoff) 
SELECT  company, industry, country, funds_raised_millions
FROM layoffs_staging2
WHERE funds_raised_millions > 20
AND percentage_laid_off = 1
ORDER BY funds_raised_millions;

-- total layoffs per year
WITH Country_Year AS 
(
  SELECT country, YEAR(date) AS years, SUM(total_laid_off) AS total_laid_off
  FROM layoffs_staging2
  GROUP BY country, YEAR(date)
)
, Country_Year_Rank AS (
  SELECT country, years, total_laid_off, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
  FROM Country_Year
)
SELECT country, years, total_laid_off, ranking
FROM Country_Year_Rank
WHERE ranking <= 10
AND years IS NOT NULL
ORDER BY years ASC, total_laid_off DESC;


-- total layoffs per country, industry and year
WITH Country_Industry_Year AS 
(
  SELECT country, industry, YEAR(date) AS years, SUM(total_laid_off) AS total_laid_off
  FROM layoffs_staging2
  GROUP BY country, industry, YEAR(date)
)
, Country_Industry_Year_Rank AS (
  SELECT country, industry, years, total_laid_off, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
  FROM Country_Industry_Year
)
SELECT country, industry, years, total_laid_off, ranking
FROM Country_Industry_Year_Rank
WHERE ranking <= 5
AND years IS NOT NULL
ORDER BY years ASC, total_laid_off DESC;
















-- Funding & Company Stage
-- Great for startup analysis.
-- 32.What company stages (Seed, Series A, Series B, etc.) had the most layoffs?
-- 33.Do later-stage companies lay off more employees on average?
-- 34.What is the relationship between funds raised and number of layoffs?
-- 35.Which companies raised the most money but still had large layoffs?
-- 36.Are early-stage startups more likely to shut down completely?


-- Outliers & Risk Signals
-- Find interesting stories.
-- 37.Which single layoff events were extreme outliers?
-- 38.Are there companies with high funding but high layoff percentages?
-- 39.Which industries show the highest volatility in layoff size?
-- 40.Are there countries where most layoffs are full shutdowns?


-- Data Quality & Cleaning Checks
-- Important before visualization.
-- 41.Are there duplicate records for the same company and date?
-- 42.Are there inconsistent country or industry names?
-- 43.Are there unrealistic values in percentage_laid_off?
-- 44.Which records are missing both total_laid_off and percentage_laid_off?



-- Advanced / Window Function Ideas
-- For more advanced SQL practice.
-- 45.Rank companies by total layoffs within each industry
-- 46.Calculate month-over-month layoff growth rate
-- 47.Identify the first layoff event per company
-- 48.Find companies whose layoffs increased over time
-- 49.Compute running totals by country and month
-- 50.Identify industries contributing the most to cumulative layoffs