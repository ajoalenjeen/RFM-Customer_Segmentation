-- Scenario 1

-- Filter for just June 2011 and July 2011
SELECT
    ROUND(SUM(quantity * unit_price), 2) AS revenue_june_july
FROM retail_clean
WHERE invoice_date BETWEEN '2011-06-01' AND '2011-07-31';


SELECT 
    ROUND(SUM(CASE 
        WHEN invoice_date BETWEEN '2011-06-01' AND '2011-06-30' 
        THEN quantity * unit_price 
        ELSE 0 
    END), 2) AS june,

    ROUND(SUM(CASE 
        WHEN invoice_date BETWEEN '2011-07-01' AND '2011-07-31' 
        THEN quantity * unit_price 
        ELSE 0 
    END), 2) AS july
FROM retail_clean;


SELECT 
    description AS products,
    ROUND(SUM(quantity * unit_price), 2) AS revenue
FROM retail_clean
WHERE invoice_date BETWEEN '2011-07-01' AND '2011-07-31'
GROUP BY description
ORDER BY revenue DESC;


-- lets find how many orders were made in june and july to compare
SELECT 
    COUNT(DISTINCT CASE 
        WHEN invoice_date BETWEEN '2011-06-01' AND '2011-06-30' 
        THEN invoice_no 
    END) AS june,

    COUNT(DISTINCT CASE 
        WHEN invoice_date BETWEEN '2011-07-01' AND '2011-07-31' 
        THEN invoice_no 
    END) AS july
FROM retail_clean;


SELECT 
    COUNT(DISTINCT CASE 
        WHEN invoice_date BETWEEN '2011-06-01' AND '2011-06-30' 
        THEN customer_id 
    END) AS june,

    COUNT(DISTINCT CASE 
        WHEN invoice_date BETWEEN '2011-07-01' AND '2011-07-31' 
        THEN customer_id 
    END) AS july
FROM retail_clean;

/* Analysis Insight:
Revenue dropped from June (£641,129) to July (£580,715) by about 9.4%.

Orders fell 7.8% (1,686 → 1,555) and unique customers dropped
6.4% (1,049 → 982), meaning ~67 fewer buyers in July.

Product-level analysis shows heavy concentration:
- Top 10 products (0.4%) drove 11.2% of July revenue
- Top 50 products (2%) drove 29.1% of July revenue
- Bottom half (1,194 products) contributed only 4.3%
- 29 products had negative revenue (returns/cancellations)

Top sellers: Regency Cakestand 3 Tier (£11,964),
Party Bunting (£10,311), White Hanging Heart T-Light Holder (£8,274)

The decline was broad — revenue, orders, and customers all fell
together. July was propped up by a few strong sellers while most
products contributed very little. This points to a demand-side
slowdown (likely seasonal) rather than a pricing or supply issue.

Next steps: check if average order value also declined and
whether lost June customers returned in August.
*/
-------------------------------------------------------



-- Scenario 2: Product Returns & Refund Patterns

-- 1. View all cancelled / returned transactions
SELECT *
FROM retail_clean
WHERE invoice_no LIKE 'C%';


SELECT
    COUNT(DISTINCT invoice_no) AS returned_invoices,
    COUNT(*) AS total_products_returned
FROM retail_clean
WHERE invoice_no LIKE 'C%';


SELECT
    description,
    ABS(SUM(quantity)) AS return_quantity
FROM retail_clean
WHERE invoice_no LIKE 'C%'
GROUP BY description
ORDER BY return_quantity DESC
LIMIT 10;


SELECT
    description,
    ABS(SUM(quantity*unit_price)) AS return_amount
FROM retail_clean
WHERE invoice_no LIKE 'C%'
GROUP BY description
ORDER BY return_amount DESC
LIMIT 10;


SELECT
    ROUND(ABS(SUM(unit_price * quantity)), 2) AS total_return_amount
FROM retail_clean
WHERE invoice_no LIKE 'C%';

/* Analysis Insight:
There were 7,495 returned items across 2,950 cancelled
transactions, totalling £280,419 in refunds.

Returns are massively dominated by one product:
- "Medium Ceramic Top Storage Jar" → 74,494 units returned
  (£77,480) — accounting for 82.8% of top-10 return quantity
  and 63.8% of top-10 return amount. This is a clear outlier
  and likely represents bulk order cancellations rather than
  typical customer returns.

After that, return amounts drop sharply — the 2nd highest
(Regency Cakestand 3 Tier, £8,621) is 9x smaller than #1.

Other notable high-return products by quantity:
- Fairy Cake Flannel Assorted Colour → 3,132 units (£6,554)
- White Hanging Heart T-Light Holder → 2,049 units (£5,265)
- Gin + Tonic Diet Metal Sign → 2,029 units (£3,773)

Recommendations:
- Investigate the Medium Ceramic Top Storage Jar for data
  quality or bulk order issues
- Monitor return rate (returns/sales) per product, not just
  absolute return counts
- Flag products where return rate exceeds a threshold (e.g. 10%)
*/
-------------------------------------------------------



-- Scenario 3: New vs Returning Customer Analysis

CREATE OR REPLACE VIEW customer_first_order AS
SELECT
    customer_id,
    MIN(invoice_date) AS first_purchase_date
FROM retail_clean
WHERE customer_id IS NOT NULL
GROUP BY customer_id;


CREATE OR REPLACE VIEW retail_customer_type AS
SELECT
    r.*,
    c.first_purchase_date,
    CASE 
        WHEN r.invoice_date = c.first_purchase_date THEN 'New'
        ELSE 'Returning'
    END AS customer_type
FROM retail_clean r
JOIN customer_first_order c
    ON r.customer_id = c.customer_id;


SELECT
    customer_type,
    COUNT(DISTINCT invoice_no) AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    ROUND(SUM(quantity * unit_price), 2) AS total_revenue
FROM retail_customer_type
GROUP BY customer_type;


SELECT
    customer_type,
    COUNT(DISTINCT invoice_no) AS total_orders,
    ROUND(SUM(quantity * unit_price), 2) AS total_revenue,
    ROUND(SUM(quantity * unit_price) / COUNT(DISTINCT invoice_no), 2) AS aov
FROM retail_customer_type
GROUP BY customer_type;


-- Monthly New vs Returning customer count over time
SELECT
    TO_CHAR(r.invoice_date, 'YYYY-MM') AS month,
    r.customer_type,
    COUNT(DISTINCT r.customer_id) AS unique_customers
FROM retail_customer_type r
GROUP BY TO_CHAR(r.invoice_date, 'YYYY-MM'), r.customer_type
ORDER BY month, customer_type;


-- Monthly New vs Returning revenue over time
SELECT
    TO_CHAR(r.invoice_date, 'YYYY-MM') AS month,
    r.customer_type,
    ROUND(SUM(r.quantity * r.unit_price), 2) AS total_revenue
FROM retail_customer_type r
GROUP BY TO_CHAR(r.invoice_date, 'YYYY-MM'), r.customer_type
ORDER BY month, customer_type;



/* Analysis Insight:
Returning customers are the backbone of this business:
- 2,735 customers (65.4%) made repeat purchases, generating
  £5.62M across 14,726 orders — that's 76.1% of total revenue.
- First-visit transactions across all 4,185 customers brought
  in £1.77M across 4,461 orders (23.9% of revenue).

Returning customers place far more orders per person:
- Returning: ~5.4 orders per customer (14,726 / 2,735)
- New (first-visit): ~1.1 orders per customer (4,461 / 4,185)

However, average order value (AOV) is nearly identical:
- First-visit: £396.48
- Returning: £381.41
This means returning customers don't spend more per order —
they just order more frequently. Revenue growth is driven
by repeat purchase behavior, not higher basket sizes.

Key takeaway:
1,450 customers (34.6%) never returned after their first
purchase. Converting even a fraction of these into repeat
buyers represents the biggest revenue upside, since returning
customers generate ~5x more orders at similar AOV.

Recommendations:
- Focus on converting first-time buyers into repeat customers
- Investigate what drives the 34.6% who never return (price,
  product satisfaction, lack of follow-up)
- Since AOV is flat across segments, upselling or bundling
  strategies could lift revenue per transaction for both groups
*/
-------------------------------------------------------


-- Scenario 4: Repeat Purchase Rate

SELECT
    SUM(CASE WHEN orders = 1 THEN 1 ELSE 0 END) AS one_time_buyers,
    SUM(CASE WHEN orders >= 2 THEN 1 ELSE 0 END) AS repeated_buyers,
    COUNT(*) AS total_customers,
    ROUND(SUM(CASE WHEN orders >= 2 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS repeat_rate_percentage
FROM (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_date) AS orders
    FROM retail_clean
    GROUP BY customer_id
) AS customer_orders;

/* Analysis Insight:
65.35% repeat rate — 2,735 of 4,185 customers bought on
2+ distinct dates. 1,450 (34.65%) were one-time buyers.

This aligns with Scenario 3: strong customer loyalty with
nearly 2 in 3 customers returning.

The 1,450 one-time buyers are the key opportunity — converting
even 10% into repeat buyers could add significant revenue since
returning customers average ~5.4 orders each.

Recommendations:
- Segment one-time buyers to understand why they didn't return
- Target them with post-purchase follow-ups or second-order
  incentives
*/
-------------------------------------------------------