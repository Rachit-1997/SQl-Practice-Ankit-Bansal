-- Q67
--  contest_leaderboard_practice.sql
--  Purpose
--  -------
--  * Re‑create a minimal schema and seed data for the HackerRank “Contest Leaderboard”
--    problem so the query can be run locally.
--  * Provide **two** solutions for the daily‑summary question:
--      1.  Reference solution attributed to Ankit Bansal
--      2.  My own attempt (included as an alternative)
--
--  How to use
--  ----------
--  psql (PostgreSQL):
--      \i contest_leaderboard_practice.sql
-- ============================================================================

-- --------------------------------------------------------------------
-- 1. SCHEMA

CREATE TABLE Hackers (
    hacker_id   INT PRIMARY KEY,
    name        VARCHAR(100)
);

CREATE TABLE Submissions (
    submission_date DATE   NOT NULL,
    submission_id   INT    NOT NULL,
    hacker_id       INT    NOT NULL REFERENCES Hackers(hacker_id),
    score           INT    NOT NULL,
    PRIMARY KEY (submission_id)
);

-- --------------------------------------------------------------------
-- 2. SEED DATA
-- --------------------------------------------------------------------
INSERT INTO Hackers (hacker_id, name) VALUES
    (20703, 'Hacker20703'),
    (53473, 'Hacker53473'),
    (79722, 'Hacker79722'),
    (36396, 'Hacker36396'),
    (15758, 'Hacker15758');

INSERT INTO Submissions (submission_date, submission_id, hacker_id, score) VALUES
    ('2016-03-01',  8494, 20703,  0),
    ('2016-03-01', 22403, 53473, 15),
    ('2016-03-01', 23965, 79722, 60),
    ('2016-03-01', 30173, 36396, 70),

    ('2016-03-02', 34928, 20703,  0),
    ('2016-03-02', 38740, 15758, 60),
    ('2016-03-02', 42769, 79722, 25),
    ('2016-03-02', 44364, 79722, 60),

    ('2016-03-03', 45440, 20703,  0);

-- --------------------------------------------------------------------
-- 3. REFERENCE SOLUTION (PostgreSQL syntax - Ankit Bansal)
-- --------------------------------------------------------------------
-- Description:
--   For each contest date:
--     * Count of hackers who submitted on every contest day since the first.
--     * Hacker with the maximum number of submissions (tie → lowest ID).

WITH cte AS (
    SELECT submission_date,
           hacker_id,
           COUNT(*) AS no_of_submissions,
           DENSE_RANK() OVER (ORDER BY submission_date) AS day_number
    FROM Submissions
    GROUP BY submission_date, hacker_id
),
cte2 AS (
    SELECT *,
           COUNT(*) OVER (PARTITION BY hacker_id ORDER BY submission_date) AS till_date_submissions,
           CASE
               WHEN COUNT(*) OVER (PARTITION BY hacker_id ORDER BY submission_date) = day_number THEN 1
               ELSE 0
           END AS unique_flag
    FROM cte
),
cte3 AS (
    SELECT *,
           SUM(unique_flag) OVER (PARTITION BY submission_date) AS unique_count,
           ROW_NUMBER() OVER (PARTITION BY submission_date ORDER BY no_of_submissions DESC, hacker_id) AS rn
    FROM cte2
)
SELECT submission_date,
       unique_count,
       hacker_id,
       (SELECT name FROM Hackers h WHERE h.hacker_id = cte3.hacker_id) AS name
FROM   cte3
WHERE  rn = 1
ORDER BY submission_date;

-- --------------------------------------------------------------------
-- 4. MY ALTERNATIVE ATTEMPT (for practice record)
-- --------------------------------------------------------------------
-- Description:
--   Alternative approach that uses date difference logic to find streaks
--   and joins that back with the top-submitter logic.
--   Kept to track problem-solving progress and experimentation.

WITH tem AS (
    SELECT hacker_id,
           MIN(submission_date) AS initial,
           MAX(submission_date) AS finall
    FROM (
        SELECT hacker_id,
               submission_date,
               LAG(submission_date) OVER (PARTITION BY hacker_id ORDER BY submission_date) AS prev,
               submission_date - LAG(submission_date) OVER (PARTITION BY hacker_id ORDER BY submission_date) AS diff
        FROM   Submissions
    ) sub
    WHERE NOT (prev IS NULL AND EXTRACT(DAY FROM submission_date) <> 1)
      AND (diff IS NULL OR diff = 1)
    GROUP BY hacker_id
),
tem2 AS (
    SELECT DISTINCT s.submission_date, s.hacker_id
    FROM   Submissions s
    JOIN   tem t ON t.hacker_id = s.hacker_id
                AND s.submission_date BETWEEN t.initial AND t.finall
),
cte AS (
    SELECT submission_date, hacker_id
    FROM (
        SELECT submission_date,
               hacker_id,
               ROW_NUMBER() OVER (PARTITION BY submission_date ORDER BY COUNT(*) DESC, hacker_id) AS rn
        FROM   Submissions
        GROUP BY submission_date, hacker_id
    ) x
    WHERE rn = 1
)
SELECT t.submission_date,
       c.hacker_id,
       COUNT(DISTINCT t.hacker_id) AS unique_cnt
FROM   tem2 t
JOIN   cte  c ON c.submission_date = t.submission_date
GROUP BY t.submission_date, c.hacker_id
ORDER BY t.submission_date;

-- --------------------------------------------------------------------
-- 5. NOTES
-- --------------------------------------------------------------------
-- * The first query is aligned with HackerRank's official solution.
-- * The second query reflects hands-on thinking and iterative debugging.
-- * This file serves as a self-evaluation milestone of SQL learning progression.
-- ============================================================================
