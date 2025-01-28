create database electric_vehicle_sales;
use electric_vehicle_sales;

create table dim_date(`date` text,	fiscal_year year,`quarter`  text);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\dim_date.csv'
INTO TABLE dim_date
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

create table electric_vehicle_sales_by_makers (`date` text,vehicle_category varchar(20),
maker varchar(60),electric_vehicles_sold int);


LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\electric_vehicle_sales_by_makers.csv'
INTO TABLE electric_vehicle_sales_by_makers
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

create table electric_vehicle_sales_by_state(`date` text,
state varchar(30),vehicle_category varchar(40),electric_vehicles_sold int,total_vehicles_sold int);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\electric_vehicle_sales_by_state.csv'
INTO TABLE electric_vehicle_sales_by_state
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


select * from dim_date;
select * from electric_vehicle_sales_by_makers;
select * from electric_vehicle_sales_by_state;


/*1.List the top 3 and bottom 3 makers for the fiscal years 2023 and 2024
 in terms of the number of 2-wheelers sold. */
 
    select maker,sum(electric_vehicles_sold) as'no of sales'
from dim_date join electric_vehicle_sales_by_makers 
on dim_date.date=electric_vehicle_sales_by_makers.date
where fiscal_year in (2023, 2024) and vehicle_category='2-wheelers'
group by maker
order by sum(electric_vehicles_sold) desc limit 3 ;

# bottom 3 2023 and 2024

select maker,sum(electric_vehicles_sold) as'no of sales'
from dim_date join electric_vehicle_sales_by_makers 
on dim_date.date=electric_vehicle_sales_by_makers.date
where fiscal_year in (2023,2024) and vehicle_category='2-wheelers'
group by maker
order by sum(electric_vehicles_sold) asc limit 3 ;

/*2.Find the overall penetration rate in India for 2023 and 2022*/

select fiscal_year,(sum(electric_vehicles_sold) / sum(total_vehicles_sold)) * 100 as penetration_rate
 from electric_vehicle_sales_by_state inner join dim_date 
 on electric_vehicle_sales_by_state.`date`= dim_date.`date`
 where fiscal_year in (2023,2022)
 group by fiscal_year;
 
 /*3.	Identify the top 5 states with the highest penetration rate 
 in 2-wheeler and 4-wheeler EV sales in FY 2024. */
 
 # 2-wheelers
 Select state,sum(electric_vehicles_sold)as Total_evs,sum(total_vehicles_sold) as total_vehicles,
 (sum(electric_vehicles_sold) / sum(total_vehicles_sold)) * 100
 as penetration_rate
 from electric_vehicle_sales_by_state join dim_date 
 on electric_vehicle_sales_by_state.`date`=dim_date.`date`
 where fiscal_year = 2024
 and vehicle_category='2-Wheelers'
 group by state
 order by penetration_rate desc limit 5 ;
 
 # 4-wheelers
 Select state,sum(electric_vehicles_sold)as Total_evs,sum(total_vehicles_sold) as total_vehicles,
 (sum(electric_vehicles_sold) / sum(total_vehicles_sold)) * 100
 as penetration_rate
 from electric_vehicle_sales_by_state join dim_date 
 on electric_vehicle_sales_by_state.`date`=dim_date.`date`
 where fiscal_year = 2024
 and vehicle_category='4-Wheelers'
 group by state
 order by penetration_rate desc limit 5 ;
 
 #4.List the top 5 states having highest number of EVs sold in 2023
 
 select state,sum(electric_vehicles_sold) as EVs_sold from electric_vehicle_sales_by_state 
 join dim_date on electric_vehicle_sales_by_state.`date`=dim_date.`date`
 where fiscal_year=2023
 group by state
 order by EVs_sold desc limit 5;
 
 #5.List the states with negative penetration (decline) in EV sales from 2022 to 2024? 
 
with state_with_PR as (select state, fiscal_year, 
(SUM(electric_vehicles_sold) / SUM(total_vehicles_sold)) * 100 as penetration_rate
from electric_vehicle_sales_by_state  as ev
join dim_date as dm on ev.date = dm.date
group by state, fiscal_year
order by state, fiscal_year),
STATE_WITH_PR_DIFF as (select *, 
penetration_rate - lag(penetration_rate) over (partition by state order by fiscal_year) as difference
from state_with_PR)
select state,difference from STATE_WITH_PR_DIFF where difference < 0;

 
#6.	Which are the Top 5 EV makers in India?

select maker,sum(electric_vehicles_sold) as EV_sold from electric_vehicle_sales_by_makers
group by maker
order by EV_sold desc limit 5;
 
 
#7.	How many EV makers sell 4-wheelers in India?

select count(distinct(maker)) as no_of_makers
from electric_vehicle_sales_by_makers
where vehicle_category='4-Wheelers';

#8.What is ratio of 2-wheeler makers to 4-wheeler makers?

select 
(select count(distinct(maker)) from electric_vehicle_sales_by_makers where vehicle_category='2-Wheelers')/
(select count(distinct(maker)) from electric_vehicle_sales_by_makers where vehicle_category='4-Wheelers')
as maker_ratio;

/*9.	What are the quarterly trends based on sales volume for the
 top 5 EV makers (4-wheelers) from 2022 to 2024? */

WITH top_4_wheeler_maker AS (
    SELECT maker 
    FROM electric_vehicle_sales_by_makers
    WHERE vehicle_category = '4-Wheelers' 
    GROUP BY maker 
    ORDER BY SUM(electric_vehicles_sold) DESC 
    LIMIT 5
),
Quarterly_sales_top5 AS (
    SELECT 
        maker, 
        fiscal_year,
        CASE 
            WHEN MONTH(dm.date) BETWEEN 1 AND 3 THEN 'Q1'
            WHEN MONTH(dm.date) BETWEEN 4 AND 6 THEN 'Q2'
            WHEN MONTH(dm.date) BETWEEN 7 AND 9 THEN 'Q3'
            WHEN MONTH(dm.date) BETWEEN 10 AND 12 THEN 'Q4'
        END AS quarter,
        SUM(electric_vehicles_sold) AS total_sales
    FROM electric_vehicle_sales_by_makers AS ev 
    JOIN dim_date AS dm ON ev.date = dm.date 
    WHERE vehicle_category = '4-Wheelers' 
      AND maker IN (SELECT * FROM top_4_wheeler_maker)
    GROUP BY maker, fiscal_year, 
        CASE 
            WHEN MONTH(dm.date) BETWEEN 1 AND 3 THEN 'Q1'
            WHEN MONTH(dm.date) BETWEEN 4 AND 6 THEN 'Q2'
            WHEN MONTH(dm.date) BETWEEN 7 AND 9 THEN 'Q3'
            WHEN MONTH(dm.date) BETWEEN 10 AND 12 THEN 'Q4'
        END
    ORDER BY maker, fiscal_year
)
SELECT 
    maker, 
    MAX(CASE WHEN fiscal_year = 2022 AND quarter = 'Q1' THEN total_sales END) AS `2022_Q1`,
    MAX(CASE WHEN fiscal_year = 2022 AND quarter = 'Q2' THEN total_sales END) AS `2022_Q2`,
    MAX(CASE WHEN fiscal_year = 2022 AND quarter = 'Q3' THEN total_sales END) AS `2022_Q3`,
    MAX(CASE WHEN fiscal_year = 2022 AND quarter = 'Q4' THEN total_sales END) AS `2022_Q4`,
    MAX(CASE WHEN fiscal_year = 2023 AND quarter = 'Q1' THEN total_sales END) AS `2023_Q1`,
    MAX(CASE WHEN fiscal_year = 2023 AND quarter = 'Q2' THEN total_sales END) AS `2023_Q2`,
    MAX(CASE WHEN fiscal_year = 2023 AND quarter = 'Q3' THEN total_sales END) AS `2023_Q3`,
    MAX(CASE WHEN fiscal_year = 2023 AND quarter = 'Q4' THEN total_sales END) AS `2023_Q4`,
    MAX(CASE WHEN fiscal_year = 2024 AND quarter = 'Q1' THEN total_sales END) AS `2024_Q1`,
    MAX(CASE WHEN fiscal_year = 2024 AND quarter = 'Q2' THEN total_sales END) AS `2024_Q2`,
    MAX(CASE WHEN fiscal_year = 2024 AND quarter = 'Q3' THEN total_sales END) AS `2024_Q3`,
    MAX(CASE WHEN fiscal_year = 2024 AND quarter = 'Q4' THEN total_sales END) AS `2024_Q4`
FROM Quarterly_sales_top5
GROUP BY maker;




#10.How do the EV sales and penetration rates in Maharashtra compare to Tamil Nadu for 2024? 

select state, sum(electric_vehicles_sold) as EV_sales,
(sum(electric_vehicles_sold) / sum(total_vehicles_sold)) * 100
as penetration_rate
from electric_vehicle_sales_by_state
join dim_date on electric_vehicle_sales_by_state.`date`=dim_date.`date`
where fiscal_year=2024 and 
state in ('Maharashtra', 'Tamil Nadu')
group by state;

/*11.List down the compounded annual growth rate
 (CAGR) in 4-wheeler units for the top 5 makers from 2022 to 2024.*/
 
WITH top5_maker AS (
    SELECT maker
    FROM electric_vehicle_sales_by_makers
    WHERE vehicle_category = '4-Wheelers'
    GROUP BY maker
    ORDER BY SUM(electric_vehicles_sold) DESC
    LIMIT 5
),
agg_sales AS (
    SELECT 
        maker,
        fiscal_year,
        SUM(electric_vehicles_sold) AS total_evs
    FROM electric_vehicle_sales_by_makers AS ev
    JOIN dim_date AS dim ON ev.date = dim.date
    WHERE maker IN (SELECT * FROM top5_maker) AND fiscal_year IN (2022, 2024)
    GROUP BY maker, fiscal_year
    ORDER BY maker, fiscal_year
),
`2022_and_2024_sales` AS (
    SELECT 
        maker,
        MAX(CASE WHEN fiscal_year = 2022 THEN total_evs END) AS sales_2022,
        MAX(CASE WHEN fiscal_year = 2024 THEN total_evs END) AS sales_2024
    FROM agg_sales
    GROUP BY maker
)
SELECT 
    *, 
    ROUND(POWER(sales_2024 / sales_2022, 1/2) - 1, 2) AS CAGR
FROM `2022_and_2024_sales`;


/* 12.	List down the top 10 states that had the highest compounded annual growth rate (CAGR)
 from 2022 to 2024 in total vehicles sold.*/
 
WITH total_vehicles_sold AS (
    SELECT 
        state, 
        fiscal_year, 
        SUM(total_vehicles_sold) AS total_vehicles
    FROM electric_vehicle_sales_by_state AS ev
    JOIN dim_date AS dim ON ev.date = dim.date
    WHERE fiscal_year IN (2022, 2024)
    GROUP BY state, fiscal_year
    ORDER BY state, fiscal_year
),
pivoted_sales_by_state AS (
    SELECT 
        state,
        MAX(CASE WHEN fiscal_year = 2022 THEN total_vehicles END) AS sales_2022,
        MAX(CASE WHEN fiscal_year = 2024 THEN total_vehicles END) AS sales_2024
    FROM total_vehicles_sold
    GROUP BY state
)
SELECT 
    *, 
    ROUND(POWER(sales_2024 / sales_2022, 1/2) - 1, 2) AS cagr
FROM pivoted_sales_by_state
ORDER BY ROUND(POWER(sales_2024 / sales_2022, 1/2) - 1, 2) DESC 
LIMIT 10;


#13.What are the peak and low season months for EV sales based on the data from 2022 to 2024?

# peak ev sales

select monthname(str_to_date(dim_date.`date`,'%d-%M-%Y')) as month_name,
sum(electric_vehicles_sold) as total_ev_sold
from dim_date join electric_vehicle_sales_by_makers as evm on evm.`date`=dim_date.`date`
where fiscal_year between 2022 and 2024 
group by month_name
order by total_ev_sold desc limit 1;

#low ev sales

select monthname(str_to_date(dim_date.`date`,'%d-%M-%Y')) as month_name,
sum(electric_vehicles_sold) as total_ev_sold
from dim_date join electric_vehicle_sales_by_makers as evm on evm.`date`=dim_date.`date`
where fiscal_year between 2022 and 2024 
group by month_name
order by total_ev_sold limit 1;
 
/*14.	Estimate the revenue growth rate of 4-wheeler and 2-wheelers EVs in India
 for 2022 vs 2024 and 2023 vs 2024, assuming an average unit price.*/

create view  sale2 as
(select fiscal_year,vehicle_category,sum(electric_vehicles_sold) as sales
 from electric_vehicle_sales_by_makers
join dim_date on electric_vehicle_sales_by_makers.`date`=dim_date.`date`
where vehicle_category='2-Wheelers'
group by fiscal_year,vehicle_category order by fiscal_year);
create view sale4 as 
(select fiscal_year,vehicle_category,sum(electric_vehicles_sold) as sales
 from electric_vehicle_sales_by_makers
join dim_date on electric_vehicle_sales_by_makers.`date`=dim_date.`date`
where vehicle_category='4-Wheelers'
group by fiscal_year,vehicle_category order by fiscal_year);

create view revenue2 as(
select fiscal_year,(sales * 85000) as revenue2
from sale2);

select * from revenue2;
create view revenue4 as(
select fiscal_year,(sales * 1500000) as revenue4
from sale4);

# 2Wheelers growthrate

select 
    ((r2024.revenue2 - r2022.revenue2) / r2022.revenue2) * 100 as growth_rate_2022_vs_2024,
    ((r2024.revenue2 - r2023.revenue2) / r2023.revenue2) * 100 as growth_rate_2023_vs_2024
from
    (select revenue2 from revenue2 where fiscal_year = 2024) as r2024,
    (select revenue2 from revenue2 where fiscal_year = 2022) as r2022,
    (select revenue2 from revenue2 where fiscal_year = 2023) as r2023;
    
    # 4Wheelers
    
    select
    ((r2024.revenue4 - r2022.revenue4) / r2022.revenue4) * 100 as growth_rate_2022_vs_2024,
    ((r2024.revenue4 - r2023.revenue4) / r2023.revenue4) * 100 as growth_rate_2023_vs_2024
from 
    (select revenue4 from revenue4 where fiscal_year = 2024) as r2024,
    (select revenue4 from revenue4 where fiscal_year = 2022) as r2022,
    (select revenue4 from revenue4 where fiscal_year = 2023) as r2023;

    

    
    
    

    
    
    
    





 
 
 



 


