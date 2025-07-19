--Q78.
-- cricket_match_analysis.sql
-- Comprehensive analysis of player participation in cricket matches
-- Provides two distinct methods to calculate match appearances

-- =============================================
-- SECTION 1: TABLE CREATION AND DATA INSERTION
-- =============================================

CREATE TABLE cricket_match (
    matchid INTEGER NOT NULL,
    ballnumber INTEGER NOT NULL,
    innings INTEGER NOT NULL,
    overs NUMERIC(3,1) NOT NULL,
    outcome VARCHAR(10) NOT NULL,
    batter VARCHAR(50) NOT NULL,
    bowler VARCHAR(50) NOT NULL,
    score INTEGER NOT NULL,
    PRIMARY KEY (matchid, ballnumber)
);

-- Insert match data
INSERT INTO cricket_match VALUES
(1,1,1,0.1,'0','Mohammed Shami','Devon Conway',0),
(1,2,1,0.2,'1lb','Mohammed Shami','Devon Conway',1),
-- [Additional 98 rows inserted...]
(4,24,2,15.6,'2','Shivam Dube','Alzarri Joseph',2);

-- =============================================
-- SECTION 2: ANALYSIS QUERIES
-- =============================================

-- METHOD 1: Using multiple CTEs with joins
-- Advantages: Clear separation of logic, easy to modify individual components
WITH total_matches AS (
    SELECT player, COUNT(*) AS total_matches_played 
    FROM (
        SELECT DISTINCT matchid, batter AS player FROM cricket_match
        UNION 
        SELECT DISTINCT matchid, bowler AS player FROM cricket_match
    ) AS all_players
    GROUP BY player
),
batting_matches AS (
    SELECT batter, COUNT(DISTINCT matchid) AS batting_count 
    FROM cricket_match
    GROUP BY batter
),
bowling_matches AS (
    SELECT bowler, COUNT(DISTINCT matchid) AS bowling_count 
    FROM cricket_match
    GROUP BY bowler
)
SELECT 
    t.player,
    t.total_matches_played,
    COALESCE(b.batting_count, 0) AS batting_matches,
    COALESCE(w.bowling_count, 0) AS bowling_matches
FROM total_matches t
LEFT JOIN batting_matches b ON t.player = b.batter
LEFT JOIN bowling_matches w ON t.player = w.bowler
ORDER BY t.player;

-- METHOD 2: Using unified CTE with NULL placeholders
-- Advantages: More compact, single table scan
WITH player_activities AS (
    SELECT batter AS player, matchid AS batting_matchid, NULL AS bowling_matchid 
    FROM cricket_match
    UNION ALL
    SELECT bowler, NULL, matchid 
    FROM cricket_match
)
SELECT 
    player,
    COUNT(DISTINCT COALESCE(batting_matchid, bowling_matchid)) AS total_matches_played,
    COUNT(DISTINCT batting_matchid) AS batting_matches,
    COUNT(DISTINCT bowling_matchid) AS bowling_matches
FROM player_activities
GROUP BY player
ORDER BY player;

-- =============================================
-- SECTION 3: VALIDATION QUERY
-- =============================================

-- Quick verification of data load
SELECT COUNT(*) AS total_balls_recorded FROM cricket_match;