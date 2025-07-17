--Q73.
-- subscription_active_users_analysis.sql
/*
Analysis of Active Subscriptions as of 2020-12-31
Identifies customers with active subscriptions by checking:
1. Most recent event isn't cancellation ('C')
2. Subscription period extends beyond 2020-12-31
*/

-- Setup: Create and populate table
DROP TABLE IF EXISTS subscription_history;
CREATE TABLE subscription_history (
    customer_id INT,
    marketplace VARCHAR(10),
    event_date DATE,
    event CHAR(1),
    subscription_period INT
);

-- Single INSERT statement with all values
INSERT INTO subscription_history VALUES
    (1, 'India', '2020-01-05', 'S', 6),
    (1, 'India', '2020-12-05', 'R', 1),
    (1, 'India', '2021-02-05', 'C', null),
    (2, 'India', '2020-02-15', 'S', 12),
    (2, 'India', '2020-11-20', 'C', null),
    (3, 'USA', '2019-12-01', 'S', 12),
    (3, 'USA', '2020-12-01', 'R', 12),
    (4, 'USA', '2020-01-10', 'S', 6),
    (4, 'USA', '2020-09-10', 'R', 3),
    (4, 'USA', '2020-12-25', 'C', null),
    (5, 'UK', '2020-06-20', 'S', 12),
    (5, 'UK', '2020-11-20', 'C', null),
    (6, 'UK', '2020-07-05', 'S', 6),
    (6, 'UK', '2021-03-05', 'R', 6),
    (7, 'Canada', '2020-08-15', 'S', 12),
    (8, 'Canada', '2020-09-10', 'S', 12),
    (8, 'Canada', '2020-12-10', 'C', null),
    (9, 'Canada', '2020-11-10', 'S', 1);

-- =============================================
-- APPROACH 1: Recommended solution using ROW_NUMBER()
-- =============================================
WITH ranked_subscriptions AS (
    SELECT 
        customer_id,
        marketplace,
        event_date,
        event,
        subscription_period,
        ROW_NUMBER() OVER(
            PARTITION BY marketplace, customer_id 
            ORDER BY event_date DESC
        ) AS event_rank
    FROM subscription_history
    WHERE event_date <= '2020-12-31'
)
SELECT 
    customer_id,
    marketplace,
    event_date AS last_event_date,
    event AS last_event_type,
    subscription_period,
    (event_date + (subscription_period * INTERVAL '1 month'))::date AS subscription_end_date
FROM ranked_subscriptions
WHERE event_rank = 1
    AND event != 'C'
    AND (event_date + (subscription_period * INTERVAL '1 month'))::date >= '2020-12-31'
ORDER BY marketplace, customer_id;

-- =============================================
-- APPROACH 2: Alternative solution using LAST_VALUE()
-- =============================================
WITH last_events AS (
    SELECT 
        customer_id,
        marketplace,
        event_date,
        event,
        subscription_period,
        LAST_VALUE(event_date) OVER(
            PARTITION BY marketplace, customer_id 
            ORDER BY event_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS last_event_date,
        LAST_VALUE(event) OVER(
            PARTITION BY marketplace, customer_id 
            ORDER BY event_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS last_event_type
    FROM subscription_history
    WHERE event_date <= '2020-12-31'
)
SELECT 
    customer_id,
    marketplace,
    last_event_date,
    last_event_type,
    subscription_period,
    (event_date + (subscription_period * INTERVAL '1 month'))::date AS subscription_end_date
FROM last_events
WHERE event_date = last_event_date
    AND last_event_type != 'C'
    AND (event_date + (subscription_period * INTERVAL '1 month'))::date >= '2020-12-31'
ORDER BY marketplace, customer_id;

 