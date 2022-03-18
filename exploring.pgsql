/* Getting the number of matches played per league each season, count of teams participating each season per league,
the total number of goals scored each season per league, average number of goals scored by team and per match.
Getting all available data in database: 11 league, 8 seasons, so 88 rows.
Can be filtered by adding WHERE clause like:
    WHERE league = '<Enter your desired league here>'
    WHERE season = '<Enter your desired season here>'
*/
SELECT 
	l.name AS league,
	m.season,
	COUNT(DISTINCT home_team_api_id) AS team_count,
	COUNT(*) AS match_count,
	SUM(home_team_goal + away_team_goal) AS goal_count,
	ROUND(SUM(home_team_goal + away_team_goal)/COUNT(DISTINCT home_team_api_id), 2) AS goals_per_team,
	ROUND(SUM(home_team_goal + away_team_goal)/COUNT(*),2) AS goals_per_match
FROM match AS m
INNER JOIN league AS l
ON m.league_id = l.id
GROUP BY league, season
ORDER BY goals_per_team DESC;


/* Getting the start & end date, number of match days, the time span of each league each season
*/
SELECT
	l.name AS league,
	m.season AS season,
	COUNT(m.date) AS match_days,
	MIN(m.date) AS start_date,
	MAX(m.date) AS end_date,
	(MAX(m.date) - MIN(m.date)) * INTERVAL '1 day' AS time_period
FROM match AS m
LEFT JOIN league AS l
ON m.league_id = l.id
GROUP BY league, season
ORDER BY season;


/* Getting the promoted or relegated teams any season, any league,
without having to calculate the points or standing.
Just by figuring out the teams in one season and not in the next for relegated,
and in one season but not in the former for promoted.
Here's an example of getting the promoted teams to 2015/2016 English Premier League.*/
SELECT 
	DISTINCT t.team_long_name AS teams1516
FROM match AS m
LEFT JOIN league AS l
ON m.league_id = l.id
LEFT JOIN team AS t
ON m.home_team_api_id = t.team_api_id
WHERE m.season = '2015/2016' 
	AND l.name = 'England Premier League'
EXCEPT 
	(SELECT 
		DISTINCT t.team_long_name AS teams1415
	FROM match AS m
	LEFT JOIN league AS l
	ON m.league_id = l.id
	LEFT JOIN team AS t
	ON m.home_team_api_id = t.team_api_id
	WHERE m.season = '2014/2015' 
		AND l.name = 'England Premier League');

/* Getting a team's track record in any season, match details such as: opponent, and whether it was
a home or away game, match result, the running total of goals scored and received,
and the goal difference, as well as running total of points.
You can specify the season in the WHERE clause in the ETC "team_track"
But to change the team, it's easier to use Find and Replace to replace all instances of "Liverpool"
with your desired team.
*/

WITH team_track AS 
    (
    SELECT
        m.date,
        m.stage,
        CASE WHEN m.home_team_api_id = t.team_api_id THEN t.team_long_name
            ELSE (
                SELECT team_long_name
                FROM team
                WHERE team_api_id = m.home_team_api_id
            ) END AS home_team,
        m.home_team_goal,
        m.away_team_goal,
        CASE WHEN m.away_team_api_id = t.team_api_id THEN t.team_long_name
            ELSE (
                SELECT team_long_name
                FROM team
                WHERE team_api_id = m.away_team_api_id
            ) END AS away_team
    FROM match AS m
    LEFT JOIN team AS t
    ON m.home_team_api_id = t.team_api_id OR m.away_team_api_id = t.team_api_id
    WHERE m.season = '2014/2015' AND t.team_long_name = 'Liverpool'
    )
SELECT
    stage,
    home_team,
    home_team_goal AS home_goals,
    away_team_goal AS away_goals,
    away_team,
    SUM(CASE WHEN home_team = 'Liverpool' THEN home_team_goal
    ELSE away_team_goal END) OVER(ORDER BY stage ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
    AS scored,
    SUM(CASE WHEN home_team = 'Liverpool' THEN away_team_goal
    ELSE home_team_goal END) OVER(ORDER BY stage ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
    AS received,
    (SUM(CASE WHEN home_team = 'Liverpool' THEN home_team_goal
    ELSE away_team_goal END) OVER(ORDER BY stage ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW))-
    (SUM(CASE WHEN home_team = 'Liverpool' THEN away_team_goal
    ELSE home_team_goal END) OVER(ORDER BY stage ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)) AS goal_diff,
    SUM(CASE
    WHEN home_team = 'Liverpool' AND home_team_goal > away_team_goal THEN 3
    WHEN home_team != 'Liverpool' AND home_team_goal > away_team_goal THEN 0
    WHEN home_team = 'Liverpool' AND home_team_goal < away_team_goal THEN 0
    WHEN home_team != 'Liverpool' AND home_team_goal < away_team_goal THEN 3
    ELSE 1 END) OVER(ORDER BY stage ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
    AS points
FROM team_track
ORDER BY stage;


/* Getting the league standing. The query results in the final league standing
after all matches have been played, but you can add "AND stage <=[weak]" to both home & away CTEs
in the WHERE clause to get the league standing after each team has played specified number of matches.
For more realistic (historically correct, considering postponed matches) you can add
"AND date <= 'YYYY-MM-DD' :: date" to both the home & away CTEs in the WHERE clause 
to get the standing at a specific date.
*/
WITH home AS (
    SELECT
    t.team_long_name AS team,
    COUNT(*) AS played,
    SUM(home_team_goal) AS scored_home,
    SUM(away_team_goal) AS received_home,
    SUM(CASE WHEN home_team_goal > away_team_goal THEN 1
         ELSE 0 END) AS home_wins,
    SUM(CASE WHEN home_team_goal = away_team_goal THEN 1
         ELSE 0 END) AS home_draws,
    SUM(CASE WHEN home_team_goal < away_team_goal THEN 1
         ELSE 0 END) AS home_losses,
    SUM(CASE WHEN home_team_goal > away_team_goal THEN 3
         WHEN home_team_goal < away_team_goal THEN 0
         ELSE 1 END) AS home_points
FROM match AS m
LEFT JOIN league AS l
ON m.league_id = l.id
LEFT JOIN team AS t
ON m.home_team_api_id = t.team_api_id
WHERE m.season = '2015/2016' AND l.name = 'England Premier League'
GROUP BY t.team_long_name
),
away AS (
    SELECT
        t.team_long_name AS team,
        COUNT(*) AS played,
        SUM(away_team_goal) AS scored_away,
        SUM(home_team_goal) AS received_away,
        SUM(CASE WHEN home_team_goal < away_team_goal THEN 1
            ELSE 0 END) AS away_wins,
        SUM(CASE WHEN home_team_goal = away_team_goal THEN 1
            ELSE 0 END) AS away_draws,
        SUM(CASE WHEN home_team_goal > away_team_goal THEN 1
            ELSE 0 END) AS away_losses,
        SUM(CASE WHEN home_team_goal < away_team_goal THEN 3
            WHEN home_team_goal > away_team_goal THEN 0
            ELSE 1 END) AS away_points
    FROM match AS m
    LEFT JOIN league AS l
    ON m.league_id = l.id
    LEFT JOIN team AS t
    ON m.away_team_api_id = t.team_api_id
    WHERE m.season = '2015/2016' AND l.name = 'England Premier League'
    GROUP BY t.team_long_name
)
SELECT
    home.team,
    home.played + away.played AS MP,
    home.home_wins + away.away_wins AS W,
    home.home_draws + away.away_draws AS D,
    home.home_losses + away.away_losses AS L,
    home.scored_home + away.scored_away AS GF,
    home.received_home + away.received_away AS GA,
    (home.scored_home + away.scored_away) - (home.received_home + away.received_away) AS GD,
    home.home_points + away.away_points AS Pts
FROM home
INNER JOIN away
ON home.team = away.team
ORDER BY Pts DESC, GD DESC, team;