--Q65
-- SQL Practice: Removing Duplicate City Routes  
-- Purpose: Deduplicate bidirectional city routes using different approaches
-- Dataset: Distances between Indian cities with possible bidirectional duplicates

-- =============================================
-- 1.  SCRIPT  
-- =============================================
CREATE TABLE city_distance (distance INT, source VARCHAR(512), destination VARCHAR(512));
INSERT INTO city_distance VALUES (100,'New Delhi','Panipat'),(200,'Ambala','New Delhi'),(150,'Bangalore','Mysore'),(150,'Mysore','Bangalore'),(250,'Mumbai','Pune');
INSERT INTO city_distance VALUES (250,'Pune','Mumbai'),(2500,'Chennai','Bhopal'),(2500,'Bhopal','Chennai'),(60,'Tirupati','Tirumala'),(80,'Tirumala','Tirupati');

-- =============================================
-- 2. SOLUTION QUERIES
-- =============================================

-- Solution A: Alternative Approach (Retains either direction)
-- Pros: Simple logic using CASE to normalize direction
-- Cons: Doesn't guarantee first occurrence, just keeps one direction
WITH cte AS (
    SELECT *,
           CASE WHEN source < destination THEN source ELSE destination END AS city1,
           CASE WHEN source < destination THEN destination ELSE source END AS city2
    FROM city_distance
),
cte2 AS (
    SELECT *,
           COUNT(*) OVER(PARTITION BY city1, city2, distance) AS cnt
    FROM cte
)
SELECT distance, source, destination
FROM cte2
WHERE cnt = 1 OR (source < destination);

-- Solution B: My Original Improved Version (Keeps first occurrence)
-- Pros: Preserves original order by keeping first entry
-- Cons: Uses NOT IN which may be slower for huge datasets
WITH cte AS (
    SELECT *, ROW_NUMBER() OVER() AS rn 
    FROM city_distance
)
SELECT * FROM city_distance
WHERE (distance, source, destination) NOT IN (
    SELECT c2.distance, c2.source, c2.destination 
    FROM cte c1 
    JOIN cte c2 ON c1.source = c2.destination 
               AND c1.destination = c2.source
               AND c1.distance = c2.distance
    WHERE c2.rn > c1.rn
);

-- Solution C: From YouTube Video (General Approach)
-- Pros: Uses LEFT JOIN which may be better for large datasets
-- Cons: Complex logic with multiple OR conditions
WITH cte AS (
    SELECT *, ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS rn
    FROM city_distance
)
SELECT c1.distance, c1.source, c1.destination
FROM cte c1
LEFT JOIN cte c2 ON c1.source = c2.destination 
                AND c1.destination = c2.source
WHERE c2.distance IS NULL 
   OR c1.distance != c2.distance 
   OR c1.rn < c2.rn;

-- =============================================
-- 3. COMPARISON NOTES
-- =============================================
/*
Key Differences:

1. Solution A (New Alternative):
   - Normalizes direction using CASE statements
   - Keeps EITHER direction (whichever has source < destination)
   - Most concise logic but doesn't preserve insertion order

2. Solution B (My Original):
   - Guarantees to keep the first occurrence in the table
   - More complex but preserves original data order
   - Better when insertion order matters

3. Solution C (Video):
   - Most general approach
   - Handles cases beyond just simple duplicates
   - Most complex to understand and maintain

AI Recommendation:
- Use Solution A when any direction is acceptable
- Use Solution B when preserving first entry is required
- Use Solution C when dealing with complex deduplication scenarios
*/