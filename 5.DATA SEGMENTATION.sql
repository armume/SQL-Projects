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

