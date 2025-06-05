/*STEP 2 CUMULATIVE ANALYSIS: HOW THE BUSINESS IS GROWING OR DECLINIG
2.1 CALCULATE THE TOTAL SALES PER MONTH
2.2 RUNNING TOTAL OF SALES OVER TIME*/

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