--Задача 1
WITH CustomerStats AS (
    SELECT 
        c.ID_customer,
        c.name,
        c.email,
        c.phone,
        COUNT(b.ID_booking) AS total_bookings,
        STRING_AGG(DISTINCT h.name, ', ' ORDER BY h.name) AS hotels,
        AVG(b.check_out_date - b.check_in_date) AS avg_stay_duration
    FROM Customer c
    JOIN Booking b ON c.ID_customer = b.ID_customer
    JOIN Room r ON b.ID_room = r.ID_room
    JOIN Hotel h ON r.ID_hotel = h.ID_hotel
    GROUP BY c.ID_customer, c.name, c.email, c.phone
    HAVING COUNT(DISTINCT h.ID_hotel) > 1 AND COUNT(b.ID_booking) > 2
)
SELECT 
    name,
    email,
    phone,
    total_bookings,
    hotels,
    ROUND(avg_stay_duration::numeric, 4) AS avg_stay_duration
FROM CustomerStats
ORDER BY total_bookings DESC;

--Задача 2

WITH CustomerBookings AS (
    SELECT 
        c.ID_customer,
        c.name,
        COUNT(b.ID_booking) AS total_bookings,
        COUNT(DISTINCT h.ID_hotel) AS unique_hotels,
        SUM(r.price * (b.check_out_date - b.check_in_date)) AS total_spent
    FROM Customer c
    JOIN Booking b ON c.ID_customer = b.ID_customer
    JOIN Room r ON b.ID_room = r.ID_room
    JOIN Hotel h ON r.ID_hotel = h.ID_hotel
    GROUP BY c.ID_customer, c.name
    HAVING COUNT(DISTINCT h.ID_hotel) > 1 AND COUNT(b.ID_booking) > 2
),
BigSpenders AS (
    SELECT 
        c.ID_customer,
        c.name,
        SUM(r.price * (b.check_out_date - b.check_in_date)) AS total_spent,
        COUNT(b.ID_booking) AS total_bookings
    FROM Customer c
    JOIN Booking b ON c.ID_customer = b.ID_customer
    JOIN Room r ON b.ID_room = r.ID_room
    GROUP BY c.ID_customer, c.name
    HAVING SUM(r.price * (b.check_out_date - b.check_in_date)) > 500
)
SELECT 
    cb.ID_customer,
    cb.name,
    cb.total_bookings,
    cb.total_spent,
    cb.unique_hotels
FROM CustomerBookings cb
JOIN BigSpenders bs ON cb.ID_customer = bs.ID_customer
ORDER BY cb.total_spent ASC;

--Задача 3

WITH HotelCategories AS (
    SELECT 
        h.ID_hotel,
        h.name,
        CASE 
            WHEN AVG(r.price) < 175 THEN 'Дешевый'
            WHEN AVG(r.price) BETWEEN 175 AND 300 THEN 'Средний'
            ELSE 'Дорогой'
        END AS category
    FROM Hotel h
    JOIN Room r ON h.ID_hotel = r.ID_hotel
    GROUP BY h.ID_hotel, h.name
),
CustomerHotels AS (
    SELECT 
        c.ID_customer,
        c.name,
        STRING_AGG(DISTINCT h.name, ', ' ORDER BY h.name) AS visited_hotels,
        MAX(CASE 
            WHEN hc.category = 'Дорогой' THEN 3 
            WHEN hc.category = 'Средний' THEN 2 
            ELSE 1 
        END) AS category_priority
    FROM Customer c
    JOIN Booking b ON c.ID_customer = b.ID_customer
    JOIN Room r ON b.ID_room = r.ID_room
    JOIN Hotel h ON r.ID_hotel = h.ID_hotel
    JOIN HotelCategories hc ON h.ID_hotel = hc.ID_hotel
    GROUP BY c.ID_customer, c.name
)
SELECT 
    ID_customer,
    name,
    CASE 
        WHEN category_priority = 3 THEN 'Дорогой'
        WHEN category_priority = 2 THEN 'Средний'
        ELSE 'Дешевый'
    END AS preferred_hotel_type,
    visited_hotels
FROM CustomerHotels
ORDER BY category_priority, name;