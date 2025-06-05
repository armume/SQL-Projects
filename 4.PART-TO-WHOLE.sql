--/STEP 4: PART-TO-WHOLE: WICH CATEGORIES CONTRIBUTUE THE MOST TO OVERALL SALES?/--

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