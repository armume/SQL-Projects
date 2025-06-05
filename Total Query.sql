--ADVANCE ANALYTICS QUERIES--

-- STEP 1-- CHANGES OVER TIME: ANALIZE HOW THE MESURES EVOLVE OVER TIME--
SELECT
YEAR(order_date) as Order_year, 
MONTH(order_date) as Order_month,
SUM(sales_amount) as Total_sales,
COUNT(DISTINCT customer_key) as Total_customers,
SUM (quantity) as Total_Quantity
from gold.fact_sales
WHERE order_date is not null
group by YEAR(order_date),MONTH(order_date)
order by YEAR(order_date),MONTH(order_date)

-- STEP 2 CUMULATIVE ANALYSIS: HOW THE BUSINESS IS GROWING OR DECLINIG
--2.1 CALCULATE THE TOTAL SALES PER MONTH
--2.2 RUNNING TOTAL OF SALES OVER TIME 

SELECT
Order_year,
Total_sales,
SUM(Total_sales) OVER (ORDER BY Order_year) as Running_total_sales,
AVG(Avg_price) OVER (ORDER BY Order_year) as Moving_average_price
FROM
(
SELECT
YEAR(order_date) as Order_year,
SUM(sales_amount) as Total_sales,
AVG(price) as Avg_price
FROM gold.fact_sales
WHERE order_date is not null
GROUP BY YEAR(order_date)
)A

-- STEP 3 PERFORMANCE ANALYSIS: HOW THE BUSINESS IS GROWING OR DECLINIG--
-- ANALIZE THE YEARLY PERFORMANCE OF PRODUCTS BY COMPARING THEIR SALES TO BOTH THE AVG SALES PERFORMANCE OF THE PRODUCT AND THE PREVIOUS YEAR'S SALES--

WITH yearly_products_sales AS 
(
SELECT
YEAR(f.order_date) AS Order_Year,
p.product_name,
SUM(f.sales_amount) AS Current_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key = p.product_key
WHERE f.order_date IS NOT NULL
GROUP BY YEAR(f.order_date), p.product_name
)

SELECT 
Order_Year,
product_name,
Current_sales,
AVG(Current_sales) OVER (PARTITION BY product_name) AS AVG_sales,
Current_sales-AVG(Current_sales) OVER (PARTITION BY product_name) AS DIF_avg,
CASE 
	WHEN Current_sales-AVG(Current_sales) OVER (PARTITION BY product_name) >0 THEN 'Above avg'
	WHEN Current_sales-AVG(Current_sales) OVER (PARTITION BY product_name) <0 THEN 'Below avg'
	ELSE 'AVG'
END AVG_CHANGE,
LAG(Current_sales) OVER(PARTITION BY product_name ORDER BY Order_Year) Prev_Years,
Current_sales-LAG(Current_sales) OVER(PARTITION BY product_name ORDER BY Order_Year) AS DIF_PREV_YEARS,
CASE 
	WHEN Current_sales-LAG(Current_sales) OVER(PARTITION BY product_name ORDER BY Order_Year) >0 THEN 'Increase'
	WHEN Current_sales-LAG(Current_sales) OVER(PARTITION BY product_name ORDER BY Order_Year) <0 THEN 'Decrease'
	ELSE 'No change'
END Prev_Years
FROM yearly_products_sales
ORDER BY product_name,Order_Year  



--//STEP 4: PART-TO-WHOLE: WICH CATEGORIES CONTRIBUTUE THE MOST TO OVERALL SALES?//--

WITH category_sales AS 
(
SELECT 
category, 
SUM (sales_amount) total_sales
from gold.fact_sales f
left join gold.dim_products p 
ON p.product_key = f.product_key
GROUP BY category
)

SELECT
category, 
total_sales,
SUM(total_sales) OVER() Overall_sales,
CONCAT(ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER())*100 ,2), '%') AS Percentage_total
from category_sales
ORDER BY PERCENTAGE_TOTAL DESC


---STEP 5: DATA  SEGMENTATION---
---/5.1. SEGMENT PRODUCTS INTO COST RANGES AND COUNT HOW MANY PRODUCTS FALL INTO EACH SEGMENT/

WITH product_seg AS
(
SELECT
product_key,
product_name,
cost,
CASE WHEN cost <100 THEN 'Below 100'
	 WHEN cost BETWEEN 100 AND 500 THEN '100-500'
	 WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
	 ELSE 'Above 1000'
END Cost_range
FROM gold.dim_products
)

SELECT
Cost_range,
COUNT(product_key) AS Total_products
FROM product_seg
GROUP BY Cost_range
ORDER BY Total_products DESC



-- /5.2. GROUP CUSTOMERS INTO THREE SEGMENTS BASED ON THEIR SPENDING BEHAVIOR AND FIND THE TOTAL NUMBER OF CUSTOMERS BY EACH GROUP.
-- /THE THREE SEGMENTS OF CUSTOMERS ARE: 
--- VIP:CUSTOMERS WITH AT LEAST 12 MONTHS SPENDING MORE THAN 5,000
--- REG: CUSTOMERS WITH AT LEAST 12 MONTHS SPENDING 5,000 OR LESS
--- NEW: CUSTOMERS WITH A LIFESPAN LESS THAN 12 MONTH.


WITH customer_spending AS 
(
SELECT
c.customer_key,
SUM(f.sales_amount) AS Total_spending,
MIN(order_date) as first_order,
MAX(order_date) as last_order,
DATEDIFF(month, MIN(order_date), MAX(order_date)) as Lifespan
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_key= c.customer_key
GROUP BY c.customer_key
)

SELECT
Customer_segment,
COUNT(customer_key) AS Total_customer
FROM (
	SELECT
	customer_key,
	CASE WHEN Lifespan >= 12 and Total_spending > 5000 THEN 'VIP'
		 WHEN Lifespan >= 12 and Total_spending <=5000 THEN 'REGULAR'
		 ELSE 'NEW'
	END Customer_segment
	FROM customer_spending)A
GROUP BY customer_segment
ORDER BY Total_customer DESC


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


-- /* 7. Build a product report 
/* Objetive: The report consolidates key customer metrics and behaviors
Highlights: 
	1. Gathers essential fiels such a name,category, subcategory and cost.
	2. Segments products by renueve to identify High-Performers,Mid-Range,or Low-Performers.
	3. Aggregates product-level metrics: 
		-total ordes
		-total sales
		-total quantity sold
		-total customers (unique)
		-lifespan (months)
	4. Calculates valuable KPISs:
	-recency (month since last sale)
	-average order revenue (AOR)
	-average monthly revenue (AMR)*/

CREATE VIEW gold.report_products AS 
WITH base_query AS (
/* 1. Base Query: Retrieves core columns from fact_sales and dim_products*/
SELECT 
f.order_number,
f.customer_key,
f.order_date,
f.sales_amount,
f.quantity,
p.product_key,
p.product_name,
p.category,
p.subcategory,
p.cost
FROM  gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key=p.product_key
WHERE order_date IS NOT NULL), 

product_aggregation AS (
/* 2.Summarizes key metrics at the product level*/
SELECT
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	DATEDIFF(month, MIN(order_date), MAX(order_date)) as Lifespan,
	MAX(order_date) AS last_sale_date,
	COUNT(DISTINCT order_number) AS total_orders,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	ROUND(AVG(CAST(sales_amount as FLOAT) /NULLIF(quantity,0)),1) as Avg_Selling_Price
FROM base_query
GROUP BY
	product_key,
	product_name,
	category,
	subcategory,
	cost)

-- 3.Final Query: Combines all product results into one output--

SELECT
product_key,
product_name,
category,
subcategory,
cost,
last_sale_date,
DATEDIFF(month, last_sale_date, GETDATE()) AS recency_in_months,
CASE 
	WHEN total_sales > 5000 THEN 'High-Performer'
	WHEN total_sales >=5000 THEN 'Mid-Range'
	ELSE 'Low-performer'
END AS product_segment,
Lifespan,
total_orders,
total_sales,
total_quantity,
total_customers,
Avg_Selling_Price,

-- average order revenue (AOR)
CASE 
	WHEN total_orders =0 THEN 0
	ELSE total_sales/total_orders
END AS  Avg_order_revenue,

-- average monthly revenue (AMR)
CASE WHEN Lifespan =0 then total_sales
	ELSE total_sales/Lifespan 
END AS Avg_monthly_revenue
from product_aggregation
