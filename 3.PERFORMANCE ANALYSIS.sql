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