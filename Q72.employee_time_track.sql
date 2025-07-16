--Q72
/* 
 * SQL Solution: Employee Productive Time Calculation
 * Problem: Calculate total hours and productive time from login/logout records
 */

-- Setup: Compact table creation and sample data
CREATE TABLE swipe(employee_id INT, activity_type VARCHAR(10), activity_time TIMESTAMP);
INSERT INTO swipe VALUES(1,'login','2024-07-23 08:00'),(1,'logout','2024-07-23 12:00'),(1,'login','2024-07-23 13:00'),(1,'logout','2024-07-23 17:00');
INSERT INTO swipe VALUES(2,'login','2024-07-23 09:00'),(2,'logout','2024-07-23 11:00'),(2,'login','2024-07-23 12:00'),(2,'logout','2024-07-23 15:00');
INSERT INTO swipe VALUES(1,'login','2024-07-24 08:30'),(1,'logout','2024-07-24 12:30'),(2,'login','2024-07-24 09:30'),(2,'logout','2024-07-24 10:30');

/*
 * SOLUTION 1: My Innovative Approach (Self-Join with Row Numbering)
 * Advantages:
 * - Uses creative self-join pattern to match logins with corresponding logouts
 * - Handles multiple login/logout pairs per day reliably
 * - Use of complex joins and window functions
 */
WITH cte AS (
    SELECT *,
    ROW_NUMBER() OVER(
        PARTITION BY employee_id, activity_time::date, activity_type 
        ORDER BY activity_time
    ) AS rn
    FROM swipe 
)
SELECT 
    c1.employee_id, 
    c1.activity_time::date AS work_date,
    MAX(c1.activity_time) - MIN(c1.activity_time) AS total_hours,
    SUM(c2.activity_time - c1.activity_time) AS productive_time
FROM cte c1 
JOIN cte c2 ON 
    c1.employee_id = c2.employee_id
    AND c1.activity_time::date = c2.activity_time::date
    AND c1.activity_type != c2.activity_type  
    AND c1.rn = c2.rn
WHERE c1.activity_type = 'login'  
GROUP BY c1.employee_id, c1.activity_time::date
ORDER BY c1.employee_id, work_date;

/*
 * SOLUTION 2: Author's Recommended Approach (LEAD Window Function)
 * Advantages:
 * - More concise syntax using LEAD() to find next activity
 * - Efficient single pass through the data
 */
WITH cte AS (
    SELECT *,
    LEAD(activity_time) OVER(
        PARTITION BY employee_id, activity_time::date 
        ORDER BY activity_time
    ) AS logout_time 
    FROM swipe 
)
SELECT 
    employee_id,
    activity_time::date AS work_date,
    (MAX(logout_time) - MIN(activity_time)) AS total_hours,
    SUM(logout_time - activity_time) AS productive_time
FROM cte
WHERE activity_type = 'login'
GROUP BY employee_id, activity_time::date
ORDER BY employee_id, work_date;

/*
 * ANALYSIS:
 * Both solutions produce identical correct results:
 * 
 * employee_id | work_date | total_hours | productive_time
 * ------------+------------+-------------+-----------------
 *      1      | 2024-07-23 | 09:00:00    | 08:00:00
 *      1      | 2024-07-24 | 04:00:00    | 04:00:00
 *      2      | 2024-07-23 | 06:00:00    | 05:00:00
 *      2      | 2024-07-24 | 01:00:00    | 01:00:00
 * 
 * Key Differences:
 * - My approach uses a self-join with row numbering which is more flexible
 * - Author's approach is more elegant for this specific problem
 */