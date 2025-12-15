create database hostel1;
use hostel1;

create table booking(booking_id varchar(50) primary key, date_of_booking  varchar (30),check_in_date  varchar (30), check_out_date
 varchar (30),room_id int,customer_id int,nights_stayed int,room_rate_per_night double, total_booking_value double);
drop table booking;
create table customer(customer_id int primary key,customer_name varchar(30),gender varchar(20),age int,
city varchar (20),loyalty_points int);

create table hostel(hostel_id int primary key,hostel_name varchar(30),location varchar(20),total_rooms int,
manager_name varchar(30),monthly_rent double);

create table room(room_id int primary key,room_type varchar(30),room_capacity int, room_rate double,
availability varchar(10), hostel_id int);
drop table room;
alter table booking
modify booking_id varchar(50);
select count(*) from customer;

select count(*)from room;
select *from room;
desc room;

select count(*)from hostel;
desc hostel;

select count(*)from customer;
desc customer;

select count(*)from booking;
select *from booking;
desc booking;


ALTER TABLE booking
add CONSTRAINT customer_room 
FOREIGN KEY (customer_id)
REFERENCES customer(customer_id);
SELECT customer_id FROM booking as s
WHERE customer_id NOT IN (SELECT customer_id FROM customer);
DELETE FROM booking
WHERE customer_id NOT IN (SELECT customer_id FROM customer);


ALTER TABLE booking
add CONSTRAINT c_room 
FOREIGN KEY (room_id)
REFERENCES room(room_id);
SELECT room_id FROM booking as s
WHERE room_id NOT IN (SELECT room_id FROM room);
DELETE FROM booking
WHERE room_id NOT IN (SELECT room_id FROM room);

ALTER TABLE room
ADD CONSTRAINT cid_room
FOREIGN KEY (hostel_id)
REFERENCES hostel(hostel_id);

-- TOP 5 HOSTEL BY TOTAL  REVENUE
SELECT h.hostel_name, SUM(b.total_booking_value) AS total_revenue FROM booking b
JOIN room r ON b.room_id = r.room_id
JOIN hostel h ON r.hostel_id = h.hostel_id
GROUP BY h.hostel_name
ORDER BY total_revenue DESC
LIMIT 5;


-- What is the occupancy rate of those top 5 hostels?
WITH booking_with_hostel AS (
    SELECT h.hostel_id, h.hostel_name, sum(h.total_rooms) as rooms,
    SUM(b.nights_stayed) AS total_room_nights_booked, SUM(b.total_booking_value) AS total_revenue
    FROM booking b JOIN room r ON b.room_id = r.room_id JOIN hostel h ON r.hostel_id = h.hostel_id
    GROUP BY h.hostel_id, h.hostel_name, h.total_rooms
),
top_5_revenue_hostels AS (
    SELECT * FROM booking_with_hostel ORDER BY total_revenue DESC LIMIT 5
)
SELECT hostel_name, total_revenue, total_room_nights_booked, rooms  AS total_room_nights_available,
floor((total_room_nights_booked / rooms)*100) AS occupancy_rate_percent FROM top_5_revenue_hostels;


--  What are the peak booking months for those top hostels
WITH top_5_hostels AS (
    SELECT 
        h.hostel_id,
        h.hostel_name,
        SUM(b.total_booking_value) AS total_revenue
    FROM booking b
    JOIN room r ON b.room_id = r.room_id
    JOIN hostel h ON r.hostel_id = h.hostel_id
    WHERE b.check_in_date IS NOT NULL
    GROUP BY h.hostel_id, h.hostel_name
    ORDER BY total_revenue DESC
    LIMIT 5
)

SELECT 
    h.hostel_name,
    MONTH(STR_TO_DATE(b.check_in_date, '%Y-%m-%d')) AS month,
    COUNT(*) AS bookings
FROM booking b
JOIN room r ON b.room_id = r.room_id
JOIN hostel h ON r.hostel_id = h.hostel_id
JOIN top_5_hostels t5 ON h.hostel_id = t5.hostel_id
WHERE b.check_in_date IS NOT NULL
GROUP BY h.hostel_name, MONTH(STR_TO_DATE(b.check_in_date, '%Y-%m-%d'))
ORDER BY h.hostel_name, month;
--   which age group is most prefre top hostel
WITH mcdonald_customers AS (
    SELECT c.customer_id,c.gender,c.age,b.total_booking_value FROM booking b
    JOIN customer c ON b.customer_id = c.customer_id JOIN room r ON b.room_id = r.room_id 
    JOIN hostel h ON r.hostel_id = h.hostel_id WHERE h.hostel_name = 'Mcdonald-Murray'),
customer_total_spend AS (SELECT customer_id, gender,
        CASE 
            WHEN age < 18 THEN 'Teen'
            WHEN age BETWEEN 18 AND 29  THEN '18-30'
            WHEN age BETWEEN 30 AND 49 THEN '30-50'
            ELSE '50+' 
        END AS age_group,SUM(total_booking_value) AS total_spend
    FROM mcdonald_customers GROUP BY customer_id, gender, age_group)
SELECT age_group, gender, COUNT(*) AS num_customers FROM customer_total_spend
GROUP BY age_group, gender ORDER BY age_group, gender;
--  Top 3 customer which high stayed in Mconald-Murray hostel 

SELECT c.customer_id,c.customer_name, COUNT(*) AS visit_count,SUM(b.nights_stayed) AS total_nights_stayed
FROM booking b JOIN room r ON b.room_id = r.room_id JOIN hostel h ON r.hostel_id = h.hostel_id
JOIN customer c ON b.customer_id = c.customer_id WHERE h.hostel_name = 'Mcdonald-Murray'
GROUP BY c.customer_id, c.customer_name ORDER BY visit_count DESC, total_nights_stayed DESC LIMIT 3;





WITH top_customers AS (
    SELECT b.customer_id,c.customer_name,COUNT(*) AS visit_count,SUM(b.nights_stayed) AS total_nights_stayed
    FROM booking b
    JOIN room r ON b.room_id = r.room_id
    JOIN hostel h ON r.hostel_id = h.hostel_id
    JOIN customer c ON b.customer_id = c.customer_id
    WHERE h.hostel_name = 'Mcdonald-Murray' GROUP BY b.customer_id, c.customer_name
    ORDER BY visit_count DESC, total_nights_stayed DESC LIMIT 3
)
SELECT DISTINCT tc.customer_id, tc.customer_name, r.room_type FROM booking b
JOIN room r ON b.room_id = r.room_id
JOIN hostel h ON r.hostel_id = h.hostel_id
JOIN top_customers tc ON b.customer_id = tc.customer_id WHERE h.hostel_name = 'Mcdonald-Murray'
ORDER BY tc.customer_name, r.room_type;




--  which room type is refer top 3 customer
SELECT c.customer_id, c.customer_name, r.room_type FROM booking b
JOIN room r ON b.room_id = r.room_id JOIN hostel h ON r.hostel_id = h.hostel_id
JOIN customer c ON b.customer_id = c.customer_id WHERE h.hostel_name = 'Mcdonald-Murray'
AND c.customer_name IN ('Wendy Anderson', 'Nicole Farley', 'David Mack');


-- top 3 city which is help to generate high revenue 
SELECT c.city AS customer_city, count(c.customer_id) AS Number_of_customer,
    SUM(b.total_booking_value) AS total_revenue FROM booking b
JOIN customer c ON b.customer_id = c.customer_id
GROUP BY c.city ORDER BY total_revenue DESC ;



-- what is total booking ,total nights booked by room type 
SELECT r.room_type, COUNT(b.booking_id) AS total_bookings, SUM(b.nights_stayed) AS total_nights_booked,
SUM(b.total_booking_value) AS total_revenue,
ROUND(SUM(b.total_booking_value) / NULLIF(SUM(b.nights_stayed), 0), 2) AS avg_price_per_night
FROM booking b JOIN room r ON b.room_id = r.room_id GROUP BY r.room_type ORDER BY total_revenue DESC;


-- Which room type is prefer customer more than 5 nightha for stayed 
SELECT r.room_type, COUNT(*) AS long_stay_bookings FROM booking b
JOIN room r ON b.room_id = r.room_id
WHERE b.nights_stayed > 5 GROUP BY r.room_type ORDER BY long_stay_bookings DESC;




--  what is the  average room rate of single room type in top 5 location?

WITH top_locations AS (
    SELECT h.location,COUNT(*) AS total_bookings FROM booking b
    JOIN room r ON b.room_id = r.room_id JOIN hostel h ON r.hostel_id = h.hostel_id
    GROUP BY h.location ORDER BY total_bookings DESC LIMIT 5),
single_room_bookings AS (
    SELECT h.location, b.total_booking_value, b.nights_stayed FROM booking b
    JOIN room r ON b.room_id = r.room_id JOIN hostel h ON r.hostel_id = h.hostel_id
    WHERE r.room_type = 'Single' AND b.nights_stayed > 0)
SELECT srb.location, ROUND(AVG(srb.total_booking_value / srb.nights_stayed), 2) AS avg_room_rate
FROM single_room_bookings srb JOIN top_locations tl ON srb.location = tl.location
GROUP BY srb.location ORDER BY avg_room_rate DESC;




-- what is the  average room rate of double and suite   room type in  Mcdonald-Murray
SELECT r.room_type, avg(room_rate_per_night) AS avg_room_rate FROM booking b
JOIN room r ON b.room_id = r.room_id
JOIN hostel h ON r.hostel_id = h.hostel_id WHERE h.hostel_name = 'Mcdonald-Murray'
AND r.room_type IN ('Double', 'Suite') AND b.nights_stayed > 0 GROUP BY r.room_type 
ORDER BY r.room_type;



--  What is the  number of days between booking and check-in, and how does that affect total booking value?

SELECT b.booking_id,c.customer_name,h.hostel_name,
    DATEDIFF(STR_TO_DATE(b.check_in_date, '%d-%m-%Y'),STR_TO_DATE(b.date_of_booking, '%d-%m-%Y')) 
    AS lead_days,b.total_booking_value FROM booking b
JOIN room r ON b.room_id = r.room_id
JOIN hostel h ON r.hostel_id = h.hostel_id
JOIN customer c ON b.customer_id = c.customer_id
WHERE b.date_of_booking IS NOT NULL 
  AND b.check_in_date IS NOT NULL
  AND DATEDIFF(STR_TO_DATE(b.check_in_date, '%d-%m-%Y'),STR_TO_DATE(b.date_of_booking, '%d-%m-%Y')) > 365
ORDER BY lead_days DESC;



SELECT 
    c.city AS customer_city,
    COUNT(b.booking_id) AS total_bookings,
    SUM(b.total_booking_value) AS total_revenue
FROM booking b
JOIN customer c ON b.customer_id = c.customer_id
WHERE b.total_booking_value IS NOT NULL
GROUP BY c.city
ORDER BY total_revenue DESC;

--  which Location is more help to generate revenue? 
SELECT h.location AS hostel_location, COUNT(b.booking_id) AS total_bookings, 
SUM(b.total_booking_value) AS total_revenue FROM booking b
JOIN room r ON b.room_id = r.room_id
JOIN hostel h ON r.hostel_id = h.hostel_id WHERE b.total_booking_value IS NOT NULL
GROUP BY h.location ORDER BY total_revenue DESC;


--  which hostel in tonyton location help generate revenue and its avg room type
SELECT h.hostel_name, h.manager_name, COUNT(DISTINCT b.booking_id) AS total_bookings,
SUM(b.total_booking_value) AS total_revenue, ROUND(AVG(r.room_rate), 2) AS avg_room_rate
FROM hostel h JOIN room r ON h.hostel_id = r.hostel_id LEFT JOIN booking b ON b.room_id = r.room_id
WHERE h.location = 'Tonyton' GROUP BY h.hostel_id, h.hostel_name, h.manager_name
ORDER BY total_revenue DESC;


-- What months see the highest check-ins?  
SELECT MONTHNAME(STR_TO_DATE(b.check_in_date, '%Y-%m-%d')) AS check_in_month,
COUNT(b.booking_id) AS total_checkins, SUM(b.total_booking_value) AS total_revenue
FROM booking b
JOIN room r ON b.room_id = r.room_id
JOIN hostel h ON r.hostel_id = h.hostel_id WHERE h.hostel_name = 'Mcdonald-Murray' AND b.check_in_date IS NOT NULL
GROUP BY monthname(STR_TO_DATE(b.check_in_date, '%Y-%m-%d')) order by total_checkins desc;



SELECT 
    r.room_type,
    COUNT(DISTINCT b.booking_id) AS total_bookings,
    SUM(b.total_booking_value) AS total_revenue,
    ROUND(AVG(r.room_rate), 2) AS avg_room_rate,
     AVG(r.room_capacity) AS avg_room_capacity,
    ROUND(SUM(b.nights_stayed) / (COUNT(DISTINCT r.room_id) * 365) * 100, 2) AS occupancy_rate_percent
FROM room r
LEFT JOIN booking b ON r.room_id = b.room_id
GROUP BY r.room_type
ORDER BY total_revenue DESC;


-- How does revenue compare across room types? Show total revenue, average price per night, and occupancy per type. 
SELECT r.room_type, COUNT(DISTINCT b.booking_id) AS total_bookings, 
SUM(b.total_booking_value) AS total_revenue, ROUND(AVG(r.room_rate), 2) AS avg_room_rate,
FLOOR(AVG(r.room_capacity)) AS avg_room_capacity FROM room r
JOIN hostel h ON r.hostel_id = h.hostel_id
LEFT JOIN booking b ON r.room_id = b.room_id WHERE h.hostel_name = 'Mcdonald-Murray'
GROUP BY r.room_type ORDER BY total_revenue DESC;

-- Which hostel managers oversee the most profitable hostels? Include name, total bookings, and revenue. 
SELECT h.manager_name, h.hostel_name, COUNT(b.booking_id) AS total_bookings,
SUM(b.total_booking_value) AS total_revenue FROM hostel h
LEFT JOIN room r ON h.hostel_id = r.hostel_id
LEFT JOIN booking b ON r.room_id = b.room_id GROUP BY h.manager_name, h.hostel_name
ORDER BY total_revenue DESC;
 
 select * from room;
SELECT b.booking_id, c.customer_name, h.hostel_name, DATEDIFF(STR_TO_DATE(b.check_in_date, '%d-%m-%Y'),
STR_TO_DATE(b.date_of_booking, '%d-%m-%Y')) AS lead_days, b.total_booking_value FROM booking b
JOIN room r ON b.room_id = r.room_id JOIN hostel h ON r.hostel_id = h.hostel_id
JOIN customer c ON b.customer_id = c.customer_id WHERE h.hostel_name = 'Mcdonald-Murray'
  AND b.date_of_booking IS NOT NULL  AND b.check_in_date IS NOT NULL
  AND DATEDIFF(
        STR_TO_DATE(b.check_in_date, '%d-%m-%Y'), STR_TO_DATE(b.date_of_booking, '%d-%m-%Y')) > 365
ORDER BY lead_days DESC;





    
    
