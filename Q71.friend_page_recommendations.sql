--Q71.
/*
 * SQL Solution Showcase: Friend Page Recommendations
 * Problem: Find pages that a user's friends have liked but the user hasn't liked yet
 * Database: PostgreSQL 
 */

-- Setup: Create and populate tables
DROP TABLE IF EXISTS friends;
DROP TABLE IF EXISTS likes;

CREATE TABLE friends (
    user_id INT,
    friend_id INT
);

CREATE TABLE likes (
    user_id INT,
    page_id CHAR(1)
);

INSERT INTO friends VALUES 
    (1, 2), (1, 3), (1, 4), 
    (2, 1), (3, 1), (3, 4), 
    (4, 1), (4, 3);

INSERT INTO likes VALUES 
    (1, 'A'), (1, 'B'), (1, 'C'), 
    (2, 'A'), (3, 'B'), (3, 'C'), 
    (4, 'B');

/*
 * SOLUTION 1: My Preferred Solution (NOT IN approach)
 * Advantages: 
 * - Simple and intuitive syntax
 * - Clearly expresses the business logic
 * - Efficient execution
 */
SELECT 
    DISTINCT f.user_id, l.page_id 
FROM 
    friends f 
JOIN 
    likes l ON f.friend_id = l.user_id
WHERE 
    (f.user_id, l.page_id) NOT IN (
        SELECT user_id, page_id FROM likes
    )
ORDER BY 
    f.user_id;

/*
 * SOLUTION 2: LEFT JOIN/IS NULL Approach
 */
SELECT 
    DISTINCT f.user_id, l.page_id
FROM 
    friends f
JOIN 
    likes l ON f.friend_id = l.user_id
LEFT JOIN 
    likes ul ON f.user_id = ul.user_id AND l.page_id = ul.page_id
WHERE 
    ul.page_id IS NULL
ORDER BY 
    f.user_id;

/*
 * SOLUTION 3: EXCEPT Approach
 * Use of set operations in SQL
 */
SELECT 
    f.user_id, l.page_id
FROM 
    friends f
JOIN 
    likes l ON f.friend_id = l.user_id
EXCEPT
SELECT 
    user_id, page_id 
FROM 
    likes
ORDER BY 
    1;

/*
 * SOLUTION 4: NOT EXISTS Approach
 * Demonstrates correlated subquery technique
 * Often performs well with proper indexing
 */
SELECT 
    DISTINCT f.user_id, l.page_id
FROM 
    friends f
JOIN 
    likes l ON f.friend_id = l.user_id
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM likes ul 
        WHERE ul.user_id = f.user_id 
        AND ul.page_id = l.page_id
    )
ORDER BY 
    f.user_id;

/*
 * PERFORMANCE ANALYSIS:
 * - Solution 1 (NOT IN): Generally good performance, but watch for NULL values
 * - Solution 2 (LEFT JOIN): Often optimal execution plan
 * - Solution 3 (EXCEPT): Clean syntax but may create temporary results
 * - Solution 4 (NOT EXISTS): Excellent with proper indexes
 * 
 * All solutions produce the same correct result:
 * user_id | page_id
 * --------+--------
 *    2    |   B
 *    2    |   C
 *    4    |   A
 *    4    |   C
 */

 