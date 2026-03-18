-- =========================================
-- EXPLORATORY DATA ANALYSIS (EDA)
-- Retail Sales Dataset
-- =========================================


-- Preview Raw Dataset
select * from retail_data;


-- Order and Customer Overview
SELECT
    COUNT(DISTINCT invoice_no) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers
FROM retail_data
WHERE quantity > 0;


-- Transaction Date Range
SELECT 
    MIN(invoice_date::DATE) AS first_date,
    MAX(invoice_date::DATE) AS last_date
FROM retail_data
WHERE quantity > 0;


-- Count unique products
SELECT COUNT(DISTINCT stock_code) AS total_unique_products
FROM retail_data;


-- Count null values in important columns
SELECT
COUNT(*) AS total_rows,
COUNT(*) FILTER (WHERE description IS NULL OR description = '') AS null_description,
COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer,
COUNT(*) FILTER (WHERE invoice_date IS NULL) AS null_invoice_date
FROM retail_data;


-- Duplicate Record Check
SELECT 
    invoice_no, 
    stock_code, 
    COUNT(*) AS occurrences
FROM retail_data
GROUP BY invoice_no, stock_code
HAVING COUNT(*) > 1
ORDER BY occurrences DESC
LIMIT 20;


-- Check rows with zero or negative quantities
select * from retail_data
where quantity <=0
order by quantity;


-- Top selling products by quantity sold
SELECT 
    description,
    SUM(quantity) AS total_quantity_sold
FROM retail_data
WHERE description IS NOT NULL
AND quantity > 0
GROUP BY description
ORDER BY total_quantity_sold DESC
LIMIT 10;


-- Top countries by order count
select country, count(distinct invoice_no) as total_orders
from retail_data
group by country
order by total_orders desc
limit 50;


-- Section 10: Cancellation Analysis
select * from retail_data
where invoice_no like 'C%';

select count(*) from retail_data
where invoice_no like 'C%';
