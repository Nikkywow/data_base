/* Задача 1 */
SELECT v.maker, v.model
FROM Vehicle v
JOIN Motorcycle m ON v.model = m.model
WHERE m.horsepower > 150 
  AND m.price < 20000 
  AND m.type = 'Sport'
ORDER BY m.horsepower DESC;



/* Задача 2 */
-- Автомобили
SELECT v.maker, v.model, c.horsepower, c.engine_capacity, 'Car' AS vehicle_type
FROM Vehicle v
JOIN Car c ON v.model = c.model
WHERE c.horsepower > 150 
  AND c.engine_capacity < 3 
  AND c.price < 35000

UNION ALL

-- Мотоциклы
SELECT v.maker, v.model, m.horsepower, m.engine_capacity, 'Motorcycle' AS vehicle_type
FROM Vehicle v
JOIN Motorcycle m ON v.model = m.model
WHERE m.horsepower > 150 
  AND m.engine_capacity < 1.5 
  AND m.price < 20000

UNION ALL

-- Велосипеды
SELECT v.maker, v.model, NULL AS horsepower, NULL AS engine_capacity, 'Bicycle' AS vehicle_type
FROM Vehicle v
JOIN Bicycle b ON v.model = b.model
WHERE b.gear_count > 18 
  AND b.price < 4000

ORDER BY horsepower DESC NULLS LAST;