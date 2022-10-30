-- PREPARE DATA

-- Combine Dataset 
-- Raw files loaded into MS SQL Server from 12 .csv files, 1 file per month
-- Dataset downloaded from https://divvy-tripdata.s3.amazonaws.com/index.html

SELECT x.*
	INTO combined_table
	FROM (SELECT * FROM dbo.[202110-divvy_cleaned]
		  UNION ALL
		  SELECT * FROM dbo.[202111-divvy_cleaned]
		  UNION ALL
		  SELECT * FROM dbo.[202112-divvy_cleaned]
		  UNION ALL
		  SELECT * FROM dbo.[202201-divvy_cleaned]
		  UNION ALL
		  SELECT * FROM dbo.[202202-divvy_cleaned]
		  UNION ALL
		  SELECT * FROM dbo.[202203-divvy_cleaned]
		  UNION ALL
		  SELECT * FROM dbo.[202204-divvy_cleaned]
		  UNION ALL
		  SELECT * FROM dbo.[202205-divvy_cleaned]
		  UNION ALL
		  SELECT * FROM dbo.[202206-divvy_cleaned]
		  UNION ALL
		  SELECT * FROM dbo.[202207-divvy_cleaned]
		  UNION ALL
		  SELECT * FROM dbo.[202208-divvy_cleaned]
		  UNION ALL
		  SELECT * FROM dbo.[202209-divvy_cleaned]) x

-- Check datatype for each column

SELECT *
	FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'combined_table';

-- MS SQL has imported the columns as VARCHAR for all columns
-- We'll convert each column's datatype to match their data, e.g. the started_at and ended_at columns are dates and times 
-- so should have the datatype of DATETIME etc.

SELECT CONVERT(datetime, started_at, 100)
	FROM dbo.combined_table;

-- Got the above error when attempting to conver the started_at column's datatype from VARCHAR to DATETIME

-- After some research (via Google), turns out I cannot conver the datatype of a column in place
-- https://learn.microsoft.com/en-us/answers/questions/299556/conversion-failed-when-converting-date-andor-time.html
-- https://learn.microsoft.com/en-us/sql/t-sql/functions/isdate-transact-sql?view=sql-server-ver15#b-showing-the-effects-of-the-set-dateformat-and-set-language-settings-on-return-values
-- https://stackoverflow.com/questions/57217111/convert-column-from-varchar-to-datetime-and-update-it-in-the-table

-- Instead we'll create several new columns with the correct data types and convert the columns with incorrect datatypes into them

ALTER TABLE dbo.combined_table
	ADD trip_start_date Date NULL,
	    trip_start_time Time NULL,
	    trip_end_date Date NULL,
	    trip_end_time Time NULL;

-- The started_at column is split into trip_start_date (DATE datatype) and trip_start_time (TIME datatype)
-- The ended_at column is split into trip_end_date (DATE datatype) and trip_end_time (TIME datatype)

-- The date columns (trip_start_date and trip_end_date) are formatted to British DD/MM/YYYY per the argument of 103 in the CONVERT function
-- https://learn.microsoft.com/en-us/sql/t-sql/functions/cast-and-convert-transact-sql?redirectedfrom=MSDN&view=sql-server-ver16

UPDATE dbo.combined_table
	SET trip_start_date = CONVERT(datetime, started_at, 103),
	    trip_start_time = RIGHT(started_at, 5),
	    trip_end_date = CONVERT(datetime, ended_at, 103),
	    trip_end_time = RIGHT(ended_at, 5);

-- Let's check our new columns

SELECT TOP 10 trip_start_date, trip_start_time, trip_end_date, trip_end_time
	FROM dbo.combined_table;

-- Let's check the datatype of our new columns
-- We can now see the updated datatypes for our newly created columns

SELECT *
	FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'combined_table';

-- Let's drop the redundant started_at and ended_at columns from our table

ALTER TABLE dbo.combined_table
	DROP COLUMN started_at,
		     ended_at;

-- Let’s also convert the Latitude and Longitude columns to Decimal (as opposed to Float, Decimal allows us to retain precision for geographic data) 
-- This way, we don't have to keep casting them as decimal whenever we need to use those columns

-- The precision for Decimal has been left at the default of 18, but Scale is extended to 14 as some values in our Latitude/Longitude columns have up 14 decimal places

-- We'll create the new columns we need as temporary columns, with the suffix '_conv'

ALTER TABLE dbo.combined_table
	ADD start_lat_conv decimal(18,14) NULL,
	    start_lng_conv decimal(18,14) NULL,
	    end_lat_conv decimal(18,14) NULL,
	    end_lng_conv decimal(18,14) NULL;

-- Let's convert the original columns into our new temporary columns

UPDATE dbo.combined_table
	SET start_lat_conv = CONVERT(decimal(18,14), start_lat),
	    start_lng_conv = CONVERT(decimal(18,14), start_lng),
	    end_lat_conv = CONVERT(decimal(18,14), end_lat),
	    end_lng_conv = CONVERT(decimal(18,14), end_lng);

-- We'll drop the original columns (without the '_conv' suffix)

ALTER TABLE dbo.combined_table
	DROP COLUMN start_lat,
		     start_lng,
		     end_lat,
		     end_lng;

-- And we'll add back the columns we just dropped but with the correct Decimal datatype

ALTER TABLE dbo.combined_table
	ADD start_lat decimal(18,14) NULL,
	    start_lng decimal(18,14) NULL,
	    end_lat decimal(18,14) NULL,
	    end_lng decimal(18,14) NULL;

-- Let's copy the data from the '_conv' temporary columns to our newly created columns

UPDATE dbo.combined_table
	SET start_lat = start_lat_conv,
		start_lng = start_lng_conv,
		end_lat = end_lat_conv,
		end_lng = end_lng_conv;

-- Again, let's check our columns to ensure they are correct

SELECT TOP 100 start_lat, start_lng, end_lat, end_lng
	FROM dbo.combined_table;
SELECT *
	FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'combined_table';

-- Finally, we'll drop the now redundant '_conv' temporary columns

ALTER TABLE dbo.combined_table
	DROP COLUMN start_lat_conv,
		     start_lng_conv,
		     end_lat_conv,
		     end_lng_conv;

-- Let's repeat this process for the ride_length column, updating the column dataype to TIME
-- Creating a temporary column called ride_lenght_conv with the TIME datatype

ALTER TABLE dbo.combined_table
	ADD ride_length_conv Time NULL;

UPDATE dbo.combined_table
	SET ride_length_conv = CONVERT(time, ride_length)

ALTER TABLE dbo.combined_table
	DROP COLUMN ride_length;

-- We'll drop and recreate the ride_length column with the correct datatype and copy converted data from the temporary column to our newly recreated column

ALTER TABLE dbo.combined_table
	ADD ride_length Time NULL;

UPDATE dbo.combined_table
	SET ride_length = ride_length_conv;

ALTER TABLE dbo.combined_table
	DROP COLUMN ride_length_conv;

-- Let's check the table again

SELECT *
	FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'combined_table';

-- CLEAN DATA

-- We'll remove zero values from the ride_length column

DELETE
	FROM dbo.combined_table
	WHERE ride_length = '0:00:00' OR ride_length = '00:00:00';

-- Let's replace the numeric values in the day_of_week column with the actual correspending day
-- I.e. 1 = Sunday, 2 = Monday, etc.

UPDATE dbo.combined_table
	SET day_of_week = REPLACE(day_of_week, '1', 'Sunday'),
		day_of_week = REPLACE(day_of_week, '2', 'Monday'),
		day_of_week = REPLACE(day_of_week, '3', 'Tuesday'),
		day_of_week = REPLACE(day_of_week, '4', 'Wednesday'),
		day_of_week = REPLACE(day_of_week, '5', 'Thursday'),
		day_of_week = REPLACE(day_of_week, '6', 'Friday'),
		day_of_week = REPLACE(day_of_week, '7', 'Saturday');

-- Turns out I cannot use one SET over multiple queries
-- Let's do repeat for all days instead

UPDATE dbo.combined_table
	SET day_of_week = REPLACE(day_of_week, '1', 'Sunday');

UPDATE dbo.combined_table
	SET day_of_week = REPLACE(day_of_week, '2', 'Monday');

UPDATE dbo.combined_table
	SET day_of_week = REPLACE(day_of_week, '3', 'Tuesday');

UPDATE dbo.combined_table
	SET day_of_week = REPLACE(day_of_week, '4', 'Wednesday');

UPDATE dbo.combined_table
	SET day_of_week = REPLACE(day_of_week, '5', 'Thursday');

UPDATE dbo.combined_table
	SET day_of_week = REPLACE(day_of_week, '6', 'Friday');

UPDATE dbo.combined_table
	SET day_of_week = REPLACE(day_of_week, '7', 'Saturday');

-- ANALYSE DATA

-- A few descriptive analyses

-- Checking the average ride duration, max ride duration, and minimum ride duration
-- Broken down by ride type and whether the customer is a member or not
-- We've used DATEDIFF with a starting point of 0 to return the ride duration as we cannot CAST a TIME dataype into a DECIMAL otherwise
-- The result is divided by 60 to convert it into minutes and the average is applied

SELECT 
	rideable_type, 
	member_casual, 
	(AVG(CAST(DATEDIFF(second, 0, ride_length) AS decimal)) / 60) AS avg_ride_length,
	MAX(ride_length) AS max_ride_length,
	MIN(ride_length) AS min_ride_length
FROM dbo.combined_table
GROUP BY rideable_type, member_casual

-- Checking the median ride duration
-- Broken down by ride type and whether the customer is a member or not
-- We'll use a window function to assist with calculating the median as MS SQL does not have a dedicated Median aggregator like MySQL for example

SELECT
	DISTINCT rideable_type,
	member_casual,
	PERCENTILE_DISC(0.5) WITHIN GROUP(ORDER BY (CAST(DATEDIFF(second, 0, ride_length) AS decimal) / 60)) OVER(PARTITION BY rideable_type, member_casual) AS median_ride_length
FROM dbo.combined_table
GROUP BY rideable_type, member_casual, ride_length

-- Checking the average ride duration, max ride duration, and minimum ride duration again
-- Broken down by ride type, whether the customer is a member or not, and on which day of the week

SELECT 
	rideable_type, 
	member_casual,
	day_of_week,
	(AVG(CAST(DATEDIFF(second, 0, ride_length) AS decimal)) / 60) AS avg_ride_length,
	MAX(ride_length) AS max_ride_length,
	MIN(ride_length) AS min_ride_length
FROM dbo.combined_table
GROUP BY rideable_type, member_casual, day_of_week
ORDER BY rideable_type, member_casual;
