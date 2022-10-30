# Final Report

## 1. The Task

Identify how do annual members and casual riders use Cyclistic bikes differently?

## 2. Data Sources

We will use the last 12 months of historical trip data for Cyclistic (a fictional company - nominally based on Divvy Bikes https://divvybikes.com/), from August 2021 to September 2022.

The dataset is obtained from https://divvy-tripdata.s3.amazonaws.com/index.html and made available by Motivate International Inc. under this license, https://ride.divvybikes.com/data-license-agreement.

## 3. Data Cleaning

Before the dataset was loaded onto MS SQL, we used Excel to perform a few basic housekeeping on each of the 12 files.

- Created a "ride_length" column by subtracting the column "started_at" from the column "ended_at" and formatted the column as HH:MM:SS
- Created a "day_of_week" column and returned the day of the week for each ride using the "WEEKDAY" function and formatted as General

The dataset was then loaded onto Microsoft SQL Server Management Studio and cleaned via SQL - refer to the separate .SQL [file](https://github.com/seriouslyjames/Cyclistic-Bikes-Case-Study/blob/main/bikes_case1_code.sql) for the code used in this cleaning process.

## 4. Analysis

- Most popular starting stations

https://public.tableau.com/views/C1_Pop_Start_Stations/Dashboard1?:language=en-US&:display_count=n&:origin=viz_share_link

The interactive map shows a concentration of trips beginning at stations close to the shore of Lake Michigan.

Selecting only the trips for members, we can see the popularity of stations becomes less concentrated and spread further into the city from the shore which may indicate that members not only use Cyclistic bikes for leisure but broader reasons such as errands and commuting.

Filtering for casual customers only shows heavy concentration trips starting along the shore and other points of interest such as the Shedd Aquarium and Millennium Park - possibly indicating that casual members are using Cyclistic bikes primarily for leisure.

- When are trips taken?

https://public.tableau.com/views/C1_When_Trips_Taken/Dashboard1?:language=en-US&:display_count=n&:origin=viz_share_link

The chart indicates the vast marjority of trips are taken in the warmer months of the year between May and October. This usages is consistent whether the customer is a casual user of Cyclistic Bikes or a member.

The most popular day of the week is Saturdays in July 2022 and the least popular day December 2021.

Drilling down, casual users of Cyclistic favor taking trips later in the week and on the weekends, further reinforcing their leisure usage. 

Members are more evenly distributed in their use of Cyclistic bikes over the week - while members also do show increased use on weekends, the difference between Saturday/Sunday usage is not as pronounced as casual customers. 

Interestingly, peak member usage are on weekdays not weekends, in particular, the peak member trip count is on Tuesdays in August 2022 closely followed by Wednesdays in August 2022 and Thursdays in June 2022. This could be an indicator of members using the service to commute to and from work. Given the concentration of trips on Tuesdays/Wednesdays/Thursdays, this may be a reflection of the post-COVID-19 shift in working patterns - since Mondays and Fridays are often preferred work-from-home days.

- How long do trips take and which bikes?

https://public.tableau.com/views/C1_Trip_Duration_and_Ride_Type/Dashboard1?:language=en-US&:display_count=n&:origin=viz_share_link

https://public.tableau.com/views/C1_Trip_Duration_and_Ride_Type_11/Dashboard1?:language=en-US&:display_count=n&:origin=viz_share_link

The visualisation has been split between trips of 10 minutes or shorter and trips of 11 minutes or longer given the steep drop off in trip duration after 10 minutes.

The vast majority of trips are 10 minutes or shorter regardless of whether the customer is a member or not. The most frequent duration of trips is 6 minutes across all customers.

Breaking this down, the most frequent duration of trips taken by casual users is 8 minutes with members at 5 minutes. This could be a further indicator that members use Cyclistic bikes not just for leisure but also for runinng errands, shopping, and picking up food orders.

Of the two bike types, classic bikes account for approximately 170,000 trips out of the approximately 280,000 trips taken at 10 minutes or shorter. 

Members are by far more likely to use the classic bike - based on a trip duration of 5 minutes, members used classic bikes for 133,696 trips as opposed to 35,482 trips with the electric bike.

The split between classic and electric bikes is not as pronounced for casual customers. For trips of 8 minutes, casual customers used classic bikes for 44,065 trips against 39,768 electric bike trips. 

Given members are more frequent users of this service, their preference for classic bikes could indicate a higher fitness level and reduces the preference and/or requirement to use an electric bike. As casual customers prefer longer trips, they may not have the neccessary fitness level for such durations without an electric bike but it cannot be dismissed that the data could also indicate that electric bikes encourage longer trips given the lower fitness requirement. 

## 5. Recommendations

In line with the original business task - identifying "how do annual members and casual riders use Cyclistic bikes differently?", these are three recommendations on how we may convert casual riders into annual members.

- 






