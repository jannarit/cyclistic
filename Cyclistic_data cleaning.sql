
-- Check table structure
USE cyclistics;
SELECT * FROM tripdata;

-- Number total rows before cleaning 
SELECT 
	COUNT(*) AS total_rows
FROM 
	tripdata;

-- Search for rows where the date in the started_at field is not a valid date, even though it contains a value.
-- Create a new column datetime_start that contains the end date in the format '%Y-%m-%d %H:%i:%s'
SELECT 
	* 
FROM 
	tripdata
WHERE STR_TO_DATE(started_at, '%Y-%m-%d %H:%i') IS NULL 
	AND started_at IS NOT NULL;

ALTER TABLE 
	tripdata 
ADD COLUMN 
	datetime_start DATETIME;

UPDATE 
	tripdata
SET 
	datetime_start = STR_TO_DATE(started_at, '%Y-%m-%d %H:%i:%s');


-- Search for rows where the date in the ended_at field is not a valid date, even though it contains a value.
-- Create a new column datetime_end that contains the end date in the format '%Y-%m-%d %H:%i:%s'

SELECT 
	* 
FROM 
	tripdata
WHERE 
	STR_TO_DATE(ended_at, '%Y-%m-%d %H:%i') IS NULL AND ended_at IS NOT NULL;

ALTER TABLE 
	tripdata 
ADD COLUMN 
	datetime_end DATETIME;

UPDATE 
	tripdata
SET 
	datetime_end = STR_TO_DATE(ended_at, '%Y-%m-%d %H:%i:%s');


-- Check for inconsistencies: temp_datetime_start > temp_datetime_end => 187 rows
-- Because I don´t know the reason, I set the respective cells to NULL.

SELECT 
	*
FROM 
	tripdata
WHERE 
	datetime_start > datetime_end;

UPDATE 
	tripdata
SET 
	started_at = NULL, ended_at = NULL, datetime_start = NULL, datetime_end = NULL
WHERE 
	started_at > ended_at;

-- Check for inconsistencies in the column rideable_type and member_casual // no inconsistencies

SELECT 
	rideable_type
FROM 
	tripdata
GROUP BY 
	rideable_type;
    

SELECT 
	member_casual
FROM 
	tripdata
GROUP BY 
	member_casual;

-- Check for NULL

SELECT 'ride_id' AS column_name, COUNT(*) AS null_count FROM tripdata WHERE ride_id IS NULL
UNION ALL
SELECT 'rideable_type' AS column_name, COUNT(*) AS null_count FROM tripdata WHERE rideable_type IS NULL
UNION ALL
SELECT 'started_at' AS column_name, COUNT(*) AS null_count FROM tripdata WHERE started_at IS NULL
UNION ALL
SELECT 'ended_at' AS column_name, COUNT(*) AS null_count FROM tripdata WHERE ended_at IS NULL
UNION ALL
SELECT 'start_station_name' AS column_name, COUNT(*) AS null_count FROM tripdata WHERE start_station_name IS NULL
UNION ALL
SELECT 'start_station_id' AS column_name, COUNT(*) AS null_count FROM tripdata WHERE start_station_id IS NULL
UNION ALL
SELECT 'end_station_name' AS column_name, COUNT(*) AS null_count FROM tripdata WHERE end_station_name IS NULL
UNION ALL
SELECT 'end_station_id' AS column_name, COUNT(*) AS null_count FROM tripdata WHERE end_station_id IS NULL
UNION ALL
SELECT 'start_lat' AS column_name, COUNT(*) AS null_count FROM tripdata WHERE start_lat IS NULL
UNION ALL
SELECT 'start_lng' AS column_name, COUNT(*) AS null_count FROM tripdata WHERE start_lng IS NULL
UNION ALL
SELECT 'end_lat' AS column_name, COUNT(*) AS null_count FROM tripdata WHERE end_lat IS NULL
UNION ALL
SELECT 'end_lng' AS column_name, COUNT(*) AS null_count FROM tripdata WHERE end_lng IS NULL
UNION ALL
SELECT 'member_casual' AS column_name, COUNT(*) AS null_count FROM tripdata WHERE member_casual IS NULL;

-- Check for duplicates 
-- 13 ride_ids are duplicates. ride_id should be unique. 

SELECT 
	ride_id, 
	COUNT(*) AS occurrence_count
FROM 
	tripdata
GROUP BY 
	ride_id
HAVING 
	COUNT(*) > 1;

-- Check rest of the data for these duplicates. Only ids are duplicates and the rest of the data differs. // 26 rows
-- I decided to delete the entries because it is not clear if the data for the first or the second ride_id is correct.

SELECT 
    t.*
FROM 
    tripdata t
JOIN (
    SELECT 
        ride_id
    FROM 
        tripdata
    GROUP BY 
        ride_id
    HAVING 
        COUNT(*) > 1
) dups ON t.ride_id = dups.ride_id;

DELETE t
FROM tripdata t
JOIN (
    SELECT 
        ride_id
    FROM 
        tripdata
    GROUP BY 
        ride_id
    HAVING 
        COUNT(*) > 1
) dups ON t.ride_id = dups.ride_id;

-- Add column and calculate ride_length

SELECT datetime_start, datetime_end,
       TIMEDIFF(datetime_end, datetime_start) AS ride_length
FROM 
	tripdata;

ALTER TABLE 
	tripdata 
ADD COLUMN ride_length_minutes INT;

UPDATE 
	tripdata
SET 
	ride_length_minutes = TIMESTAMPDIFF(MINUTE, datetime_start, datetime_end);


-- Check for rides that lasted less than a minute // 80025 rides => deleted rows because the rides did not happen or were not tracked due to a technical error


SELECT 
	COUNT(*) AS less_than_minute
FROM
	tripdata
WHERE 
	ride_length_minutes < 1;


DELETE FROM
	tripdata
WHERE 
	ride_length_minutes < 1;
    

-- Check for rides that lasted longer than a day // 7544 rides => flag those rides as anomalies in a new column longer_than_a_day

SELECT 
	COUNT(*) AS longer_than_a_day
FROM
	tripdata
WHERE 
	ride_length_minutes > 1440;

ALTER TABLE tripdata ADD COLUMN longer_than_a_day BOOLEAN;

UPDATE 
	tripdata 
SET longer_than_a_day = CASE
	WHEN ride_length_minutes > 1440 THEN TRUE
    ELSE FALSE
END;
    

-- Insert new column day_of_week_start with VARCHAR(20) data type
-- Extracting name of day of week values for each row in the table. Decided to use started_at since there are rides that lasted longer than a day

ALTER TABLE 
	tripdata 
ADD COLUMN day_of_week_start VARCHAR(20);

UPDATE 
	tripdata
SET 
	day_of_week_start = DATE_FORMAT(started_at, '%W');

