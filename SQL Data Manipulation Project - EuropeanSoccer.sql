-- Data manipulation using the European Soccer Database containing 12,800 matches from 11 countries played between 2011 and 2015.

-- Main tables: country, match, league, and team. 
-- Any other tables used below were custom and created by filtering one of the 4 main tables.

-- Skills demonstrated: CASE statements, subqueries (simple, scalar, correlated), and window functions.


----------------------------------------------------------------------------------


-- Identifying how many home matches FC Schalke 04 and FC Bayern Munich had.

SELECT 
	CASE WHEN hometeam_id = 10189 THEN 'FC Schalke 04'
        WHEN hometeam_id = 9823 THEN 'FC Bayern Munich'
         ELSE 'Other' END AS home_team,
	COUNT(id) AS total_matches
FROM matches_germany
GROUP BY home_team;

-- Identifying home wins, losses and ties among Spain's matches.

SELECT date,
	CASE WHEN home_goal > away_goal THEN 'Home win'
        WHEN home_goal < away_goal THEN 'Home loss' 
        ELSE 'Tie' END as outcome
FROM matches_spain;

-- Determining the total number of matches won by the home team in each country during the 2012/2013, 2013/2014, and 2014/2015 seasons.

SELECT 
	c.name as country,

	SUM(CASE WHEN m.season = '2012/2013' AND m.home_goal > m.away_goal 
        THEN 1 ELSE 0 END) as matches_2012_2013,

 	SUM(CASE WHEN m.season = '2013/2014' AND m.home_goal > m.away_goal 
        THEN 1 else 0 END) as matches_2013_2014,

	SUM(CASE WHEN m.season = '2014/2015' AND m.home_goal > m.away_goal 
        THEN 1 ELSE 0 END) as matches_2014_2015

FROM country as c
LEFT JOIN match as m
ON c.id = m.country_id
GROUP BY c.name;

-- Filtering for matches during the 2013/2014 season, with total goals scored exceeding three times the average.

SELECT 
    date,
	home_goal,
	away_goal
FROM matches_2013_2014
WHERE (home_goal + away_goal) > 
       (SELECT 3 * AVG(home_goal + away_goal)
        FROM matches_2013_2014); 

-- Returning number of matches where total goals scored were equal to or greater than 10, per country.

SELECT
    c.name as country_name,
    COUNT(*) as matches
FROM country as c
INNER JOIN 
(SELECT country_id, id 
           FROM match
           WHERE (home_goal + away_goal) >=10) as sub
ON c.id = sub.country_id
GROUP BY country_name;

-- Filtering for only matches with the highest total goals scored for each country each season.

SELECT main.country_id,
    main.date,
    main.home_goal,
    main.away_goal
FROM match as main
WHERE (home_goal + away_goal) = 
        (SELECT MAX(sub.home_goal + sub.away_goal)
         FROM match as sub
         WHERE main.country_id = sub.country_id
               AND main.season = sub.season);

-- Using an OVER clause to create column with the overall average of total goals scored for easy comparison.

SELECT 
	m.id, 
    c.name as country, 
    m.season,
	m.home_goal,
	m.away_goal,
	AVG(m.home_goal + m.away_goal) OVER() as overall_avg
FROM match as m
LEFT JOIN country as c ON m.country_id = c.id;

-- Looking at team Legia Warszawa (team ID 8673) and their opponents, finding the average number of home and away goals,
-- partitioned by season and month.

SELECT 
	date,
	season,
	home_goal,
	away_goal,
	CASE WHEN hometeam_id = 8673 THEN 'home' 
         ELSE 'away' END as warsaw_location,
    AVG(home_goal) OVER(PARTITION BY season, 
         	EXTRACT(month FROM date)) as season_mo_home,
    AVG(away_goal) OVER(PARTITION BY season, 
            EXTRACT(month FROM date)) as season_mo_away
FROM match
WHERE 
	hometeam_id = 8673
    OR awayteam_id = 8673
ORDER BY (home_goal + away_goal) DESC;