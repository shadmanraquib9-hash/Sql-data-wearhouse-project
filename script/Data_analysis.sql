/*
===============================================================================
Monthly Customer & Sales Summary
Purpose:
	Aggregates monthly performance to track sales volume, active customers,
	and unit quantities over time.

Highlights:
	1. Groups sales transaction data by year and month.
	2. Calculates total revenue and total units sold per month.
	3. Tracks active customer counts using unique customer IDs.
===============================================================================
*/

select
year(order_date) as order_year,
month(order_date) as order_month,
sum(sales_amount) as total_sales,
count(distinct customer_id) as total_customer,
sum(quantity) as total_quantity
from Gold.fact_sales
where order_date is not null
group by year(order_date), month(order_date)
order by year(order_date), month(order_date)

/*
===============================================================================
Monthly Sales & Cumulative Growth Report
Purpose:
	Evaluates monthly revenue trends, running cumulative totals, and moving averages.

Highlights:
	1. Truncates transaction dates to monthly time buckets.
	2. Uses window functions to compute cumulative revenue over time.
	3. Calculates a moving average of item prices across consecutive months.
===============================================================================
*/

select
order_months,
total_sales,
sum(total_sales) over (order by order_months) as running_total_sales,
AVG(avg_price) over (order by order_months) as moving_average
from(
select
datetrunc(month,order_date) as order_months,
sum(sales_amount) as total_sales,
AVG(sls_price) as avg_price
from Gold.fact_sales
where order_date is not null
group by datetrunc(month,order_date)
)t 

/*
===============================================================================
Product Year-over-Year Performance Analysis
Purpose:
	Analyzes individual product growth by comparing annual sales against historical
	averages and prior year performance.

Highlights:
	1. Aggregates product revenue by calendar year in a CTE.
	2. Uses AVG() OVER (PARTITION BY) to benchmark against multi-year product averages.
	3. Employs LAG() to compute Year-over-Year (YoY) revenue differences.
	4. Categorizes growth trends into intuitive flags ('Increase', 'Decrease', 'No change').
===============================================================================
*/

with yearly_prd_sales as(
select 
year(s.order_date) as order_year,
p.product_name,
sum(s.sales_amount) as current_sales
from Gold.fact_sales s
left join Gold.dim_products p
on s.product_number=p.product_number
where s.order_date is not null
group by year(s.order_date), p.product_name
)

select order_year,
product_name,
current_sales,
AVG(current_sales) over (partition by product_name) as avg_sale,
current_sales - AVG(current_sales) over (partition by product_name) as diff_avg,
case when current_sales - AVG(current_sales) over (partition by product_name) >0 then 'above avg'
when current_sales - AVG(current_sales) over (partition by product_name) <0 then 'below avg'
else 'Avg'
end,
LAG(current_sales) over (partition by product_name order by order_year) as per_sales,
current_sales - LAG(current_sales) over (partition by product_name order by order_year) as diff_avg,
case when current_sales - LAG(current_sales) over (partition by product_name order by order_year) >0 then 'Increase'
when current_sales - LAG(current_sales) over (partition by product_name order by order_year) <0 then 'Decrease'
else 'No change'
end
from yearly_prd_sales 
order by product_name, order_year;


/*
===============================================================================
Category Contribution & Market Share Analysis
Purpose:
	Calculates the total revenue and percentage contribution of each product category 
	relative to overall business sales.

Highlights:
	1. Summarizes sales by product category.
	2. Uses SUM() OVER () to derive overall company revenue across all categories.
	3. Computes percentage share using CAST to avoid integer division/overflow.
===============================================================================
*/

select
category,
sum(sales_amount) as total_sales,
sum(sum(sales_amount)) over () as overall_sales,
concat(round(cast (sum(sales_amount) as float)/sum(sum(sales_amount)) over () *100,2),'%') as categories_contribution
from Gold.fact_sales s
left join Gold.dim_products p
on p.product_number=s.product_number
group by category
order by sum(sales_amount) desc

/*
===============================================================================
Product Cost Segmentation Analysis
Purpose:
	Segments products into predefined cost brackets to analyze inventory distribution.

Highlights:
	1. Categorizes products into cost tiers ('Below 100', '100-500', '500-1000', 'Above 1000').
	2. Aggregates product counts by cost tier to identify catalog focus areas.
===============================================================================
*/

with prd_serg as(
select
product_key,
product_name,
product_cost,
case when product_cost<100 then 'Below 100'
when product_cost between 100 and 500 then '100-500'
when product_cost between 500 and 1000 then '500-1000'
else 'Above 1000'
end cost_range
from Gold.dim_products)

select
cost_range,
count(product_key) as total_product
from prd_serg 
group by cost_range
order by total_product desc

/*
===============================================================================
Customer Behavior & Segmentation Report
Purpose:
	Classifies customers into behavioral tiers based on tenure and monetary value.

Highlights:
	1. Calculates customer lifetime tenure (in months) and total spending in a CTE.
	2. Segments accounts into actionable tiers:
		- VIP: ≥12 months history & > €5,000 spending
		- Regular: ≥12 months history & ≤ €5,000 spending
		- New: <12 months history
	3. Aggregates total customer counts per segment for executive reporting.
===============================================================================
*/

with cus_spend as (
select 
c.customer_key,
sum(s.sales_amount) as total_spending,
min(s.order_date) as first_order,
max(s.order_date) as last_order,
DATEDIFF(month,min(s.order_date),max(s.order_date)) as lifespan
from Gold.fact_sales s
left join Gold.dim_customers c
on c.Customer_id=s.Customer_id
group by c.customer_key)

,cus_seg as (
select 
customer_key,
total_spending,
lifespan,
case when lifespan>=12 and total_spending>5000 then 'VIP'
when lifespan>=12 and total_spending<=5000 then 'Regular'
else 'New'
end as cus_segment
from cus_spend)

select 
cus_segment,
count(customer_key) as total_customers
from cus_seg
group by cus_segment
order by total_customers desc


/*
Customer Report
Purpose:
	This report consolidates key customer metrics and behaviors

Highlights:
	1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
	3. Aggregates customer-level metrics:
		total orders
		total sales
		total quantity purchased
		total products
		lifespan (in months)
	4. Calculates valuable KPIs:
		recency (months since last order)
		average order value
		average monthly spend

*/

--create view Gold.report_cus as 

--1. Base quarry
with base_quarry as(
select
order_number,
product_number,
order_date,
sales_amount,
quantity,
sls_price,
customer_key,
Customer_number,
CONCAT(First_name,'',Last_name) as cus_name,
DATEDIFF(YEAR,Brithdate, GETDATE()) as age
from Gold.fact_sales s
left join Gold.dim_customers c
on c.Customer_id=s.Customer_id
)

--2. customer aggregation
, cus_aggra as (
select
customer_key,
cus_name,
Customer_number,
age,
max(order_date) as last_order,
count(distinct order_number) as total_order,
sum(sales_amount) as total_sales,
sum(quantity) as total_quantity,
count(distinct product_number) as total_products,
max(order_date) as old_order_date,
DATEDIFF(month,min(order_date),max(order_date)) as lifespan
from base_quarry
group by customer_key,
cus_name,
Customer_number,
age)

select
customer_key,
cus_name,
Customer_number,
age,
case when age<20 then ''
when age between 20 and 30 then '20-30'
when age between 30 and 40 then '30-40'
when age between 40 and 50 then '40-50'
else '50 and above'
end as age_group,
case when lifespan>=12 and total_sales>5000 then 'VIP'
when lifespan>=12 and total_sales<=5000 then 'Regular'
else 'New'
end as cus_segment,
total_order,
total_sales,
total_quantity,
total_products,
old_order_date,
lifespan,
DATEDIFF(month,last_order,GETDATE()) as recency,
case when total_order=0 then 0
else total_sales/total_order 
end as avg_ord_value,
case when lifespan=0 then total_sales
else total_sales/lifespan
end as avg_month_spend
from cus_aggra



/*
Customer Report
Purpose:
	This report consolidates key customer metrics and behaviors

Highlights:
	1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
	3. Aggregates customer-level metrics:
		total orders
		total sales
		total quantity purchased
		total products
		lifespan (in months)
	4. Calculates valuable KPIs:
		recency (months since last order)
		average order value
		average monthly spend

*/


--1) Base Query: Retrieves core columns from fact_sales and dim_products
--create view Gold.report_prd as 

with base_query as (
select 
order_number,
s.product_number,
Customer_id,
order_date,
sales_amount,
quantity,
sls_price,
product_key,
product_name,
category,
subcategory,
product_cost
from Gold.fact_sales s
left join Gold.dim_products p
on s.product_number=p.product_number
where order_date is not null )

--2. prodcut aggregation
, prd_aggra as (
select 
product_number,
product_name,
category,
subcategory,
product_cost,
DATEDIFF(MONTH, MIN(order_date),MAX(order_date)) as lifespan,
max(order_date) as last_sale_date,
COUNT(order_number) as total_orders,
COUNT(Customer_id) as total_customers,
sum(sales_amount) as total_sales,
sum(quantity) as total_quantity,
ROUND( avg(cast(sales_amount as float)/ nullif(quantity,0)),1) as avg_selling_price
from base_query
group by product_number,
product_name,
category,
subcategory,
product_cost
)

--3) Final Query: Combines all product results into one output
select
product_number,
product_name,
category,
subcategory,
product_cost,
last_sale_date,
DATEDIFF(month,last_sale_date,GETDATE()) as recency_in_months,
case when total_sales >= 50000 then 'High-Perfomance'
when total_sales >= 10000 then 'Mid-range'
else 'Low-Performance'
end as product_segment,
lifespan,
total_orders,
total_sales,
total_quantity,
total_customers,
avg_selling_price,
case when total_orders =0 then 0
else total_sales/total_orders
end as avg_order_revenue,
case when lifespan=0 then total_sales
else cast(1.0*total_sales/lifespan as decimal(10,2))
end as avg_monthly_revernue
from prd_aggra
