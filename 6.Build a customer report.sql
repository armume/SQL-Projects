-- /6. Build a customer report	.

/* Objetive: The report consolidates key customer metrics and behaviors

Highlights: 
	1. Gathers essential fiels such a names,ages and transaction details
	2. Segments customers into categories and age groups
	3. Aggregates customer-level metrics: 
		-total ordes
		-total sales
		-total quantity purchased
		-total products
		-lifespan (months)
	4. Calculates valuable KPISs:
	-recency
	-average order value
	-average monthly spend */

CREATE VIEW gold.report_customers AS 
WITH base_query AS (
/* 1. Base Query: Retrieves core columns from tables*/
SELECT 
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
DATEDIFF(year, c.birthdate, getdate()) age
FROM  gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key=f.customer_key
WHERE order_date IS NOT NULL ),

customer_aggregation AS (
/* 2.Summarizes key metrics at the customer level*/
SELECT
	customer_key,
	customer_number,
	customer_name,
	age,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	COUNT(DISTINCT product_key) AS total_products,
	MAX(order_date) AS last_order_date,
	DATEDIFF(month, MIN(order_date), MAX(order_date)) as Lifespan
FROM base_query
GROUP BY
	customer_key,
	customer_number,
	customer_name,
	age
)


SELECT
customer_key,
customer_number,
customer_name,
age,
CASE 
	WHEN age <20 then  'Under 20'
	WHEN age between 20 and 29 then '20-29'
	WHEN age between 30 and 39 then '30-39'
	WHEN age between 40 and 49 then '40-49'
	ELSE '50 and above'
END AS age_group,

CASE 
	WHEN Lifespan >= 12 and total_sales > 5000 THEN 'VIP'
	WHEN Lifespan >= 12 and total_sales <=5000 THEN 'REGULAR'
	ELSE 'NEW'
END AS customer_segment,
last_order_date,
DATEDIFF(month, last_order_date, GETDATE()) AS recency,
total_orders,
total_sales,
total_quantity,
total_products,
Lifespan,
-- Compuate average order value (avo)
CASE WHEN total_sales =0 THEN 0
	ELSE total_sales/total_orders
END AS  Avg_order_value,
-- Compuate average monthly spend
CASE WHEN Lifespan =0 then total_sales
	ELSE total_sales/Lifespan 
END AS Avg_monthly_spend
from customer_aggregation
