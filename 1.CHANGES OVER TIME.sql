--STEP 1-- CHANGES OVER TIME: ANALIZE HOW THE MESURES EVOLVE OVER TIME--

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