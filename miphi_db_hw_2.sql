--Задача 1
WITH CarStats AS (
    SELECT 
        c.name AS car_name,
        c.class AS car_class,
        AVG(r.position) AS average_position,
        COUNT(r.race) AS race_count
    FROM Cars c
    JOIN Results r ON c.name = r.car
    GROUP BY c.name, c.class
),
MinAvgPositions AS (
    SELECT 
        car_class,
        MIN(average_position) AS min_avg_position
    FROM CarStats
    GROUP BY car_class
)
SELECT 
    cs.car_name,
    cs.car_class,
    cs.average_position,
    cs.race_count
FROM CarStats cs
JOIN MinAvgPositions m ON cs.car_class = m.car_class AND cs.average_position = m.min_avg_position
ORDER BY cs.average_position;

--Задача 2

WITH CarStats AS (
    SELECT 
        c.name AS car_name,
        c.class AS car_class,
        AVG(r.position) AS average_position,
        COUNT(r.race) AS race_count
    FROM Cars c
    JOIN Results r ON c.name = r.car
    GROUP BY c.name, c.class
)
SELECT 
    cs.car_name,
    cs.car_class,
    cs.average_position,
    cs.race_count,
    cl.country AS car_country
FROM CarStats cs
JOIN Classes cl ON cs.car_class = cl.class
WHERE cs.average_position = (SELECT MIN(average_position) FROM CarStats)
ORDER BY cs.car_name
LIMIT 1;

--Задача 3

WITH ClassPerformance AS (
    SELECT 
        c.class AS car_class,
        AVG(r.position) AS avg_class_position,
        COUNT(DISTINCT r.race) AS total_races
    FROM Cars c
    JOIN Results r ON c.name = r.car
    GROUP BY c.class
),
BestClasses AS (
    SELECT car_class, avg_class_position, total_races
    FROM ClassPerformance
    WHERE avg_class_position = (SELECT MIN(avg_class_position) FROM ClassPerformance)
)
SELECT 
    c.name AS car_name,
    c.class AS car_class,
    AVG(r.position) AS average_position,
    COUNT(r.race) AS race_count,
    cl.country AS car_country,
    bc.total_races
FROM Cars c
JOIN Results r ON c.name = r.car
JOIN Classes cl ON c.class = cl.class
JOIN BestClasses bc ON c.class = bc.car_class
GROUP BY c.name, c.class, cl.country, bc.total_races
ORDER BY c.class;

--Задача 4


WITH CarStats AS (
    SELECT 
        c.name AS car_name,
        c.class AS car_class,
        AVG(r.position) AS average_position,
        COUNT(r.race) AS race_count
    FROM Cars c
    JOIN Results r ON c.name = r.car
    GROUP BY c.name, c.class
),
ClassAvg AS (
    SELECT 
        car_class,
        AVG(average_position) AS class_avg_position
    FROM CarStats
    GROUP BY car_class
    HAVING COUNT(*) > 1
)

SELECT 
    cs.car_name,
    cs.car_class,
    cs.average_position,
    cs.race_count,
    cl.country AS car_country
FROM CarStats cs
JOIN Classes cl ON cs.car_class = cl.class
JOIN ClassAvg ca ON cs.car_class = ca.car_class
WHERE cs.average_position < ca.class_avg_position
ORDER BY cs.car_class, cs.average_position;

--Задача 5

WITH CarStats AS (
    SELECT 
        c.name AS car_name,
        c.class AS car_class,
        AVG(r.position) AS average_position,
        COUNT(r.race) AS race_count
    FROM Cars c
    JOIN Results r ON c.name = r.car
    GROUP BY c.name, c.class
),
LowPositionCars AS (
    SELECT 
        car_class,
        COUNT(*) AS low_position_count
    FROM CarStats
    WHERE average_position > 3.0
    GROUP BY car_class
),
MaxLowPositionClasses AS (
    SELECT 
        car_class
    FROM LowPositionCars
    WHERE low_position_count = (SELECT MAX(low_position_count) FROM LowPositionCars)
)
SELECT 
    cs.car_name,
    cs.car_class,
    cs.average_position,
    cs.race_count,
    cl.country AS car_country,
    (SELECT COUNT(DISTINCT race) FROM Results r JOIN Cars c ON r.car = c.name WHERE c.class = cs.car_class) AS total_races,
    lpc.low_position_count
FROM CarStats cs
JOIN Classes cl ON cs.car_class = cl.class
JOIN LowPositionCars lpc ON cs.car_class = lpc.car_class
JOIN MaxLowPositionClasses mlpc ON cs.car_class = mlpc.car_class
WHERE cs.average_position > 3.0
ORDER BY lpc.low_position_count DESC;