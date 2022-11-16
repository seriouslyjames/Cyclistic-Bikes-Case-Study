# Data Analysis Process

## Prepare Data

Data was downloaded as 12 individual .csv files, one for each month of the analysis period. Each file was then loaded onto MS SQL Server.

```sql
-- Combine all 12 individual files into a single table

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
```

Lets check the datatype of our table - ideally we'll want our datatypes to be representative of the data in each column.

![image](https://user-images.githubusercontent.com/12231066/202110418-4b793c45-4685-41b2-a779-a4f5646fb33b.png)

```sql
SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'combined_table';
```

Since all our columns are currently VARCHAR datatypes, we should update them before we begin analysis.

Lets convert column datatypes to match their data, e.g. the 'started_at' and 'ended_at' columns should be more accessible as DATETIME datatypes.

```sql
SELECT CONVERT(datetime, started_at, 100)
    FROM dbo.combined_table;
```
![image](https://user-images.githubusercontent.com/12231066/202110836-92184099-7485-470b-b070-3354cbd5e0fb.png)

Turns out we cannot convert a column's datatype in place - so I have created several new columns with appropriate datatypes instead.

https://learn.microsoft.com/en-us/answers/questions/299556/conversion-failed-when-converting-date-andor-time.html

https://learn.microsoft.com/en-us/sql/t-sql/functions/isdate-transact-sql?view=sql-server-ver15#b-showing-the-effects-of-the-set-dateformat-and-set-language-settings-on-return-values

https://stackoverflow.com/questions/57217111/convert-column-from-varchar-to-datetime-and-update-it-in-the-table

We'll convert the data from our VARCHAR columns into these new ones.

Lets create the new 'started_at' and 'ended_at' columns - this time we'll separate the date and time into different columns.

```sql
ALTER TABLE dbo.combined_table
    ADD trip_start_date Date NULL,
        trip_start_time Time NULL,
        trip_end_date Date NULL,
        trip_end_time Time NULL;
```

Inserting the separated start and end dates/times into the newly created columns - the dates are formatted to the British dd/mm/yyyy format.

https://learn.microsoft.com/en-us/sql/t-sql/functions/cast-and-convert-transact-sql?redirectedfrom=MSDN&view=sql-server-ver16

```sql
-- The date is formatted to British dd/mm/yyyy per the '103' argument 
-- for the CONVERT function

UPDATE dbo.combined_table
    SET trip_start_date = CONVERT(datetime, started_at, 103),
        trip_start_time = RIGHT(started_at, 5),
        trip_end_date = CONVERT(datetime, ended_at, 103),
        trip_end_time = RIGHT(ended_at, 5);
```

Check our new columns.

```sql
SELECT TOP 10 trip_start_date, trip_start_time, trip_end_date, trip_end_time
    FROM dbo.combined_table;
```
![image](https://user-images.githubusercontent.com/12231066/202111099-3128cf3c-7dc4-4f14-b429-3186d5b986c4.png)

Check the updated datatypes in our table.

```sql
SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'combined_table';
```
![image](https://user-images.githubusercontent.com/12231066/202111131-69cebc2d-884f-47d2-88ec-d4b1004d5802.png)

Lets drop the now redundant original columns of 'started_at' and 'ended_at'.

```sql
ALTER TABLE dbo.combined_table
    DROP COLUMN started_at,
             ended_at;
```

We'll also convert the Latitude and Longitude columns to decimals. The Decimal datatype will allow us to retain precision for geographic data. We'll create new columns for our Latitude/Longitude data.

```sql
-- For column parameters, precision left at the default value of 18 
-- but scale is extended to 14 as some values in our Latitude/Longitude
-- columns have up to 14 decimals

ALTER TABLE dbo.combined_table
    ADD start_lat_conv decimal(18,14) NULL,
        start_lng_conv decimal(18,14) NULL,
        end_lat_conv decimal(18,14) NULL,
        end_lng_conv decimal(18,14) NULL;
```

Converting the default Latitude and Longitude data to the new columns.

```sql
UPDATE dbo.combined_table
    SET start_lat_conv = CONVERT(decimal(18,14), start_lat),
        start_lng_conv = CONVERT(decimal(18,14), start_lng),
        end_lat_conv = CONVERT(decimal(18,14), end_lat),
        end_lng_conv = CONVERT(decimal(18,14), end_lng);
```

Lets drop the redundant 'start_lat/lng' and 'end_lat/lng' VARCHAR columns. 

```sql
ALTER TABLE dbo.combined_table
    DROP COLUMN start_lat,
             start_lng,
             end_lat,
             end_lng;
```

Unlike our earlier conversion of the trip start and end date/time columns - now that we've deleted the original columns, lets recreate the Latitude and Longitude columns with the original column names but with the Decimal datatype and convert our data to these 'new' columns.

Add the same columns we just dropped but with the updated Decimal dataype.

```sql
ALTER TABLE dbo.combined_table
    ADD start_lat decimal(18,14) NULL,
        start_lng decimal(18,14) NULL,
        end_lat decimal(18,14) NULL,
        end_lng decimal(18,14) NULL;
```

Copy the row data from the columns ending in 'conv' back our re-created 'start_lat/lng' and 'end_lat/lng' columns.

```sql
UPDATE dbo.combined_table
    SET start_lat = start_lat_conv,
        start_lng = start_lng_conv,
        end_lat = end_lat_conv,
        end_lng = end_lng_conv;
```

Lets check our new columns.

```sql
SELECT TOP 100 start_lat, start_lng, end_lat, end_lng
    FROM dbo.combined_table;
```
![image](https://user-images.githubusercontent.com/12231066/202111180-7bbc6257-4a6f-4183-8ec4-77ab05738302.png)

```sql
SELECT *
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'combined_table';
```
![image](https://user-images.githubusercontent.com/12231066/202111264-d7cdb626-3f16-431b-a2f8-af11df5e4a34.png)

Once again, lets drop the now redundant 'conv' columns.

```sql
ALTER TABLE dbo.combined_table
    DROP COLUMN start_lat_conv,
             start_lng_conv,
             end_lat_conv,
             end_lng_conv;
```

Now lets update the datatype of the ride_length column to the datatype TIME.

```sql
ALTER TABLE dbo.combined_table
	ADD ride_length_conv Time NULL;

```

```sql
UPDATE dbo.combined_table
	SET ride_length_conv = CONVERT(time, ride_length)

```

```sql
ALTER TABLE dbo.combined_table
	DROP COLUMN ride_length;

```

Again, we've created a new column with the appropriate datatype called 'ride_length_conv' and converted the data in the original 'ride_length' column to our new column.

Lets take a final look at our table schema and updated datatypes.

```sql
SELECT *
	FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'combined_table';

```
![image](https://user-images.githubusercontent.com/12231066/202111322-52523a25-ff11-485a-99b7-a6c197053bc9.png)

## Clean Data

Lets remove the zero values in our 'ride_length_conv' column - we only want non-zero values for the ride duration in our analysis.

```sql
DELETE
	FROM dbo.combined_table
	WHERE ride_length = '0:00:00' OR ride_length = '00:00:00';

```
Looking at our table, we can see the 'day_of_week' column is currently filled with numerals representing day of the week.

![image](https://user-images.githubusercontent.com/12231066/202111371-78a30434-8a72-4542-b27f-b6d9134bfa5d.png)

We'll replace the numeric values in the 'day_of_week' column with the actual corresponding day, i.e. 1 = Sunday, 2 = Monday, and so forth.

```sql
UPDATE dbo.combined_table
	SET day_of_week = REPLACE(day_of_week, '1', 'Sunday'),
		day_of_week = REPLACE(day_of_week, '2', 'Monday'),
		day_of_week = REPLACE(day_of_week, '3', 'Tuesday'),
		day_of_week = REPLACE(day_of_week, '4', 'Wednesday'),
		day_of_week = REPLACE(day_of_week, '5', 'Thursday'),
		day_of_week = REPLACE(day_of_week, '6', 'Friday'),
		day_of_week = REPLACE(day_of_week, '7', 'Saturday');

```

Turns out I cannot update it via a single SET call.

![image](https://user-images.githubusercontent.com/12231066/202111449-6282a018-5006-43a8-93f2-82961117159e.png)

```sql
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

```
![image](https://user-images.githubusercontent.com/12231066/202111475-87228b3c-9db4-451a-9438-1ef570766d58.png)

## Analyse Data

Here's a few descriptive analyses.

Checking the average, max, and min ride durations, broken down by ride type and whether customer is a member or not.

```sql
-- Average ride length is converted to minutes

SELECT 
	rideable_type, 
	member_casual, 
	(AVG(CAST(DATEDIFF(second, 0, ride_length) AS decimal)) / 60) AS avg_ride_length,
	MAX(ride_length) AS max_ride_length,
	MIN(ride_length) AS min_ride_length
FROM dbo.combined_table
GROUP BY rideable_type, member_casual


```
![image](https://user-images.githubusercontent.com/12231066/202111501-616057d8-11d0-4a09-a161-066c44d5c364.png)

Checking the median ride duration broken down by ride type and whether the customer is a member or not.

```sql
-- MS SQL unfortunately does not have a built in MEDIAN function 
-- (unlike MySQL for example) so I've use a Window function instead

SELECT
	DISTINCT rideable_type,
	member_casual,
	PERCENTILE_DISC(0.5) WITHIN GROUP(ORDER BY (CAST(DATEDIFF(second, 0, ride_length) AS decimal) / 60)) OVER(PARTITION BY rideable_type, member_casual) AS median_ride_length
FROM dbo.combined_table
GROUP BY rideable_type, member_casual, ride_length


```
![image](https://user-images.githubusercontent.com/12231066/202111528-c251d7cb-0cd4-4740-a15b-ce01a12acc54.png)

We'll check the average, max, and min ride duration again - this time broken down by day of week.

```sql
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

```

![image](https://user-images.githubusercontent.com/12231066/202111555-e64d5071-bcab-4da2-b493-ce1e7861304a.png)

