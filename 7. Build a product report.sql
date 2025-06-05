--7. Build a product report 
--Objetive: The report consolidates key customer metrics and behaviors
--Highlights: 
--	1. Gathers essential fiels such a name,category, subcategory and cost.
--	2. Segments products by renueve to identify High-Performers,Mid-Range,or Low-Performers.
--	3. Aggregates product-level metrics: 
--		-total ordes
--		-total sales
--		-total quantity sold
--		-total customers (unique)
--		-lifespan (months)
--	4. Calculates valuable KPISs:
--	-recency (month since last sale)
--	-average order revenue (AOR)
--	-average monthly revenue (AMR)

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