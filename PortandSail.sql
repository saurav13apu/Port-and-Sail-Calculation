    -- Create the database (if not already created)
CREATE DATABASE IF NOT EXISTS maritime_voyages;

-- Select the database
USE maritime_voyages;

-- Create the voyages table
CREATE TABLE IF NOT EXISTS voyages (
    id INT,
    event VARCHAR(50),
    dateStamp INT,
    timeStamp FLOAT,
    voyage_From VARCHAR(50),
    lat DECIMAL(9,6),
    lon DECIMAL(9,6),
    imo_num VARCHAR(20),
    voyage_Id VARCHAR(20),
    allocatedVoyageId VARCHAR(20)
);

-- Insert sample data
INSERT INTO voyages VALUES
(1, 'SOSP', 43831, 0.708333, 'Port A', 34.0522, -118.2437, '9434761', '6', NULL),
(2, 'EOSP', 43831, 0.791667, 'Port A', 34.0522, -118.2437, '9434761', '6', NULL),
(3, 'SOSP', 43832, 0.333333, 'Port B', 36.7783, -119.4179, '9434761', '6', NULL),
(4, 'EOSP', 43832, 0.583333, 'Port B', 36.7783, -119.4179, '9434761', '6', NULL);

-- Main query
WITH voyage_data AS (
    SELECT
        id,
        event,
        DATE_ADD(DATE_ADD('1900-01-01', INTERVAL dateStamp DAY), INTERVAL timeStamp * 24 * 60 * 60 SECOND) AS event_datetime,
        voyage_From,
        lat,
        lon,
        imo_num,
        voyage_Id,
        LAG(event) OVER (PARTITION BY voyage_Id ORDER BY dateStamp, timeStamp) AS prev_event,
        LAG(DATE_ADD(DATE_ADD('1900-01-01', INTERVAL dateStamp DAY), INTERVAL timeStamp * 24 * 60 * 60 SECOND)) OVER (PARTITION BY voyage_Id ORDER BY dateStamp, timeStamp) AS prev_event_datetime,
        LAG(voyage_From) OVER (PARTITION BY voyage_Id ORDER BY dateStamp, timeStamp) AS prev_voyage_From,
        LAG(lat) OVER (PARTITION BY voyage_Id ORDER BY dateStamp, timeStamp) AS prev_lat,
        LAG(lon) OVER (PARTITION BY voyage_Id ORDER BY dateStamp, timeStamp) AS prev_lon
    FROM
        voyages
    WHERE
        imo_num = '9434761'
        AND voyage_Id = '6'
        AND allocatedVoyageId IS NULL
)
SELECT
    id,
    event,
    event_datetime,
    voyage_From,
    lat,
    lon,
    imo_num,
    voyage_Id,
    prev_event,
    prev_event_datetime,
    prev_voyage_From,
    ROUND(
        6371 * 2 * ASIN(SQRT(POWER(SIN(RADIANS(lat - prev_lat) / 2), 2) + COS(RADIANS(prev_lat)) * COS(RADIANS(lat)) * POWER(SIN(RADIANS(lon - prev_lon) / 2), 2)))
        * 0.539957, 2  -- Convert km to nautical miles
    ) AS distance_travelled,  -- Distance in nautical miles
    TIMESTAMPDIFF(MINUTE, prev_event_datetime, event_datetime) AS time_difference,
    CASE
        WHEN event = 'SOSP' THEN TIMESTAMPDIFF(MINUTE, prev_event_datetime, event_datetime)
        ELSE NULL
    END AS sailing_time,
    CASE
        WHEN event = 'EOSP' THEN TIMESTAMPDIFF(MINUTE, prev_event_datetime, event_datetime)
        ELSE NULL
    END AS port_stay_duration
FROM
    voyage_data;