-- Data exploration using a relational database containing 5 tables:

	-- fortune500: data on top US companies in 2017
	-- stackoverflow: questions asked on Stack Overflow with certain tags
	-- company: information on companies related to tags in stackoverflow
	-- tag_company: links stackoverflow to company
	-- tag_type: type categories applied to tags in stackoverflow

-- Skills demonstrated: simple functions, aggregate functions, data filtering, joins, common table expressions (CTEs),
-- aliases, coalescing data, correlations, series generation, temporary tables, subqueries, truncation


-- Shows how many rows in the fortune500 table are missing a ticker symbol.
SELECT COUNT(*) - COUNT(ticker) AS missing
  FROM fortune500;

-- Number of rows that are missing a profits_change value.
SELECT COUNT(*) - COUNT(profits_change) AS missing
FROM fortune500;

-- Company names that appear in both the company and fortune500 tables.
SELECT company.name
  FROM company
       INNER JOIN fortune500
       ON company.ticker=fortune500.ticker;
	   
-- Companies that exist on both the Fortune 500 and company tables as well as their subsidiaries, ordered by rank.  	   
SELECT company_original.name, fortune500.title, fortune500.rank
  FROM company AS company_original
	LEFT JOIN company AS company_parent
       ON company_original.parent_id = company_parent.id 
       INNER JOIN fortune500 
       ON COALESCE(company_original.ticker, 
                   company_parent.ticker) = 
             fortune500.ticker
 ORDER BY rank; 
	   	   
-- The most common industry/sector found on the Fortune 500 list.
SELECT COALESCE(industry, sector, 'Unknown') AS industry2,
       COUNT(*) 
  FROM fortune500 
 GROUP BY industry2
 ORDER BY COUNT(*) DESC
 LIMIT 1;
	      	   
-- Fortune 500 companies that had positive changes in revenue in 2017.
SELECT COUNT(*)
  FROM fortune500
 WHERE revenues_change > 0;	   
	
-- Fortune 500 companies that had positive changes in profit in 2017.	
SELECT COUNT(*)
  FROM fortune500
 WHERE profits_change > 0;	   
	   
-- The average revenue per employee for Fortune 500 companies by sector.
SELECT sector, 
       AVG(revenues/employees::numeric) AS avg_rev_employee
  FROM fortune500
 GROUP BY sector
 ORDER BY avg_rev_employee;
	   	   
-- Exploring profits, the lowest, highest and average values as well as the standard deviation among Fortune 500 companies by sector.
SELECT sector,
		MIN(profits),
       AVG(profits),
       MAX(profits),
       stddev(profits)
  FROM fortune500
  GROUP BY sector;
  
-- Fortune 500 companies grouped into bins based on their employee count.
SELECT trunc(employees, -4) AS employee_bin,
       COUNT(*)
  FROM fortune500
 GROUP BY employee_bin
 ORDER BY employee_bin;
 
-- Finding the correlation between revenue and other financial attributes for Fortune 500 companies.
 SELECT CORR(revenues, profits) AS rev_profits,
       CORR(revenues, assets) AS rev_assets,
       CORR(revenues, equity) AS rev_equity 
  FROM fortune500;
  
-- Creating a temporary table featuring Fortune 500 profit numbers at the 80th percentile of each sector. 
DROP TABLE IF EXISTS profit80;

CREATE TEMP TABLE profit80 AS 
  SELECT sector,
         PERCENTILE_DISC(.8) WITHIN GROUP (ORDER BY profits) AS pct80
    FROM fortune500
   GROUP BY sector;
  
-- The number of tags of each type.
SELECT type, COUNT(*) AS count
  FROM tag_type
 GROUP BY type
 ORDER BY count DESC;
 
-- Using joins to view company name, tag and tag type.
SELECT company.name, tag_type.tag, tag_type.type
  FROM company
       INNER JOIN tag_company
       ON company.id = tag_company.company_id
       INNER JOIN tag_type
       ON tag_company.tag = tag_type.tag
  WHERE TYPE='cloud';
  
-- The maximum question count of each tag in the stackoverflow table. Among those max values, the minimum, maximum, average and standard deviation.
SELECT stddev(maxval),
       MIN(maxval),
       MAX(maxval),
       AVG(maxval)
  FROM (SELECT MAX(question_count) AS maxval
          FROM stackoverflow
         GROUP BY tag) AS max_results;  
  
-- Creating bins for question counts with the dropbox tag from the stackoverflow table. 
-- Finding the count of days where the question count fell between the lower and upper limits created.
  SELECT MIN(question_count), 
       MAX(question_count)
  FROM stackoverflow
 WHERE tag = 'dropbox';  
  
WITH bins AS (
      SELECT generate_series(2200, 3050, 50) AS lower,
             generate_series(2250, 3100, 50) AS upper),
     dropbox AS (
      SELECT question_count 
        FROM stackoverflow
       WHERE tag='dropbox') 

SELECT lower, upper, COUNT(question_count) 
  FROM bins  
       LEFT JOIN dropbox 
         ON question_count >= lower 
        AND question_count < upper
 GROUP BY lower, upper
 ORDER BY lower;
   
-- For each tag, using temp tables to help look at the question count on the first date and
-- last date where data became available as well as the difference between the two.
DROP TABLE IF EXISTS startdates;

CREATE TEMP TABLE startdates AS
SELECT tag, MIN(date) AS mindate
  FROM stackoverflow
 GROUP BY tag;
 
 SELECT startdates.tag, 
	   so_min.question_count AS min_date_question_count,
       so_max.question_count AS max_date_question_count,
       so_max.question_count - so_min.question_count AS change
  FROM startdates
       INNER JOIN stackoverflow AS so_min
          ON startdates.tag = so_min.tag
         AND startdates.mindate = so_min.date
       INNER JOIN stackoverflow AS so_max
          ON startdates.tag = so_max.tag
         AND so_max.date = '2018-09-25';
