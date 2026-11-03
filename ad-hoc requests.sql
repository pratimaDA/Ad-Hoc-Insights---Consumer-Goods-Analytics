-- Request 1
select DISTINCT market from dim_customer 
WHERE customer LIKE "Atliq Exclusive"
AND region = 'APAC';

-- Request 2
WITH cte1 as (
select COUNT(DISTINCT product_code)  as unique_products_2020
from fact_sales_monthly 
WHERE fiscal_year = 2020
),
cte2 as (
select COUNT(DISTINCT product_code)  as unique_products_2021
from fact_sales_monthly 
WHERE fiscal_year = 2021
)
select cte1.unique_products_2020,cte2.unique_products_2021 , 
ROUND(((cte2.unique_products_2021-cte1.unique_products_2020)/cte2.unique_products_2021)*100,2) as percentage_chg
from cte1 
CROSS JOIN cte2;

-- Request 3
select segment , COUNT(DISTINCT product_code) as product_count
from dim_product
GROUP BY segment
ORDER BY product_count DESC;

-- Request 4
WITH product_count_2021_and_segment as (
select p.segment segment, COUNT(DISTINCT fs.product_code) product_count_2021
from fact_sales_monthly fs
JOIN dim_product p USING(product_code)
WHERE fiscal_year = 2021
GROUP BY segment
),
product_count_2020_and_segment as (
select p.segment segment, COUNT(DISTINCT fs.product_code) product_count_2020
from fact_sales_monthly fs
JOIN dim_product p USING(product_code)
WHERE fiscal_year = 2020
GROUP BY segment
)

select pc21.segment ,product_count_2020,product_count_2021, (product_count_2021-product_count_2020) as diff
from product_count_2021_and_segment pc21
JOIN product_count_2020_and_segment pc20 USING(segment);

-- Request 5

select product_code, p.product, manufacturing_cost
from fact_manufacturing_cost
JOIN dim_product as p USING(product_code)
WHERE manufacturing_cost = (select MAX(manufacturing_cost) from fact_manufacturing_cost)
OR manufacturing_cost = (select MIN(manufacturing_cost) from fact_manufacturing_cost); 

-- Request 6

WITH avg_pre_inv_discount as 
(select ROUND(AVG(pre_invoice_discount_pct),4) avg_discount
from fact_pre_invoice_deductions p
JOIN dim_customer c USING(customer_code)
WHERE c.market = 'India'
AND p.fiscal_year = 2021
)
select p.customer_code , c.customer , ROUND(pre_invoice_discount_pct,4) average_discount_percentage
from fact_pre_invoice_deductions p
JOIN dim_customer c USING(customer_code)
WHERE c.market = 'India'
AND p.fiscal_year = 2021
AND pre_invoice_discount_pct >= (select avg_discount from avg_pre_inv_discount)
order by average_discount_percentage DESC 
LIMIT 5;

-- Request 7

select MONTH(fsm.date) Month ,fsm.fiscal_year as Year ,ROUND(SUM((fgp.gross_price*fsm.sold_quantity))/1000000,3) as gross_sales_amount_mln
from fact_sales_monthly fsm
JOIN fact_gross_price fgp USING(product_code,fiscal_year)
JOIN dim_customer c USING(customer_code)
WHERE c.customer = 'Atliq Exclusive'
GROUP BY MONTH(fsm.date),Year
ORDER BY Month ASC,Year ASC;

-- Request 8
select  QUARTER(date) quarter, SUM(sold_quantity) total_sold_quantity from fact_sales_monthly
WHERE Year(date) = 2020
GROUP by QUARTER(date)
ORDER BY total_sold_quantity DESC;

-- Request 9
WITH total_sales_amount_in_2021 as (
select fsm.fiscal_year as Year,ROUND(SUM((fgp.gross_price*fsm.sold_quantity))/1000000,3) as total_gross_sales
from fact_sales_monthly fsm
JOIN fact_gross_price fgp USING(product_code,fiscal_year)
WHERE fsm.fiscal_year = 2021
)
select c.channel as channel,ROUND(SUM((fgp.gross_price*fsm.sold_quantity))/1000000,3) as gross_sales_amount_mln,
ROUND((ROUND(SUM((fgp.gross_price*fsm.sold_quantity))/1000000,3)/(select total_gross_sales from total_sales_amount_in_2021)*100),2)
as percentage 
from fact_sales_monthly fsm
JOIN fact_gross_price fgp USING(product_code,fiscal_year)
JOIN dim_customer c USING(customer_code)
WHERE fsm.fiscal_year= 2021
group by c.channel
ORDER BY gross_sales_amount_mln DESC;

-- Request 10
WITH get_total_sold_qty as (
select division,p.product_code, p.product, SUM(f.sold_quantity) total_sold_quantity 
from fact_sales_monthly f
JOIN dim_product p USING(product_code)
WHERE f.fiscal_year = 2021
GROUP by p.product_code
),
get_top_3_products as (
select *, RANK() OVER(partition by division order by total_sold_quantity DESC) rank_order
from get_total_sold_qty
)
select * from get_top_3_products
WHERE rank_order<=3;















