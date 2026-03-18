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
Revenue dropped from June ($641,129) to July ($580,715) by about 9.4%.

Orders fell 7.8% (1,686 → 1,555) and unique customers dropped
6.4% (1,049 → 982), meaning ~67 fewer buyers in July.

Product-level analysis shows heavy concentration:
- Top 10 products (0.4%) drove 11.2% of July revenue
- Top 50 products (2%) drove 29.1% of July revenue
- Bottom half (1,194 products) contributed only 4.3%
- 29 products had negative revenue (returns/cancellations)

Top sellers: Regency Cakestand 3 Tier ($11,964),
Party Bunting ($10,311), White Hanging Heart T-Light Holder ($8,274)

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
There were 8,507 returned items across 3,383 cancelled transactions.

Returns are massively dominated by just 2 products:
- "Paper Craft, Little Birdie" → 80,995 units returned ($168,470)
- "Medium Ceramic Top Storage Jar" → 74,494 units returned ($77,480)
These two alone account for 85% of top-10 return amount and
87.2% of top-10 return quantity. These are clear outliers and
likely represent bulk order cancellations rather than typical
customer returns.

After those two, return amounts drop sharply — the 3rd highest
(Regency Cakestand 3 Tier, $9,697) is 17x smaller than #1.

Recommendations:
- Investigate the two outlier products for data quality or
  bulk order issues
- Monitor return rate (returns/sales) per product, not just
  absolute return counts
- Flag products where return rate exceeds a threshold (e.g. 10%)
*/
-------------------------------------------------------


-- Scenario 3: Profit Margin leak detection
/* The Case:
“Some of our products are making very little or no profit.
A few might even be selling below cost. We suspect a margin leak.
Can you identify low or negative-margin products?”
*/

-- Assume cost = 70% of selling price
CREATE OR REPLACE VIEW retail_margin AS
SELECT
    *,
    ROUND(unit_price * 0.70, 2) AS cost_price,
    ROUND(unit_price - (unit_price * 0.70), 2) AS profit_per_unit,
    ROUND((unit_price - (unit_price * 0.70)) * quantity, 2) AS total_profit
FROM retail_clean;

SELECT
    description,
    ROUND(SUM(quantity), 2) AS units_sold,
    ROUND(SUM(total_profit), 2) AS total_profit
FROM retail_margin
WHERE profit_per_unit <= 0.10
GROUP BY description
HAVING SUM(quantity) > 1
ORDER BY total_profit
LIMIT 20;

/* Analysis Insight:
All 20 flagged low-margin products have exactly $0.00 profit,
meaning they were sold at or very near cost (profit_per_unit <= $0.10).
A total of 938 units were moved with essentially zero return.

High-volume zero-profit products to watch:
- Set of 6 Nativity Magnets → 240 units at $0 profit
- Biscuit Tin Vintage Christmas → 216 units at $0 profit
- 36 Foil Star Cake Cases → 144 units at $0 profit
- Set of 2 Ceramic Painted Hearts → 96 units at $0 profit
These are generating transactions and operational costs
(storage, shipping, handling) with no margin to cover them.

Recommendations:
- Audit pricing on these 20 products — confirm whether $0
  margin is intentional (promotions) or a pricing error
- Prioritize the high-volume zero-margin items — they are
  actively costing money to fulfill
- Investigate why top sellers have some units at zero margin;
  could indicate inconsistent pricing or bulk discount leakage
*/
-------------------------------------------------------


-- Scenario 4: New vs Returning Customer Analysis

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



/* Analysis Insight:
Returning customers are the backbone of this business:
- 2,972 returning customers generated $6.46M across 17,076
  orders — that's 78.1% of total revenue from just 40.5%
  of the customer base.
- 4,363 new customers brought in $1.81M across 4,715 orders,
  contributing 21.9% of revenue.

Returning customers place far more orders per person:
- Returning: ~5.7 orders per customer (17,076 / 2,972)
- New: ~1.1 orders per customer (4,715 / 4,363)

However, average order value (AOV) is nearly identical:
- New: $383.68
- Returning: $378.49
This means returning customers don't spend more per order —
they just order more frequently. Revenue growth is driven
by repeat purchase behavior, not higher basket sizes.

Key takeaway:
The business is heavily repeat-customer dependent. Retaining
customers matters more than acquiring new ones since a
returning customer generates ~5x more orders. However, only
2,972 out of 4,363 new customers ever came back (~68%
retention), meaning ~32% of new customers never returned.

Recommendations:
- Focus on converting first-time buyers into repeat customers
  — that's where the biggest revenue upside lies
- Investigate what drives the 32% who never return (price,
  product satisfaction, lack of follow-up)
- Since AOV is flat across segments, upselling or bundling
  strategies could lift revenue per transaction for both groups
*/
-------------------------------------------------------


-- Scenario 5: Repeat Purchase Rate

SELECT
    SUM(CASE WHEN orders = 1 THEN 1 ELSE 0 END) AS one_time_buyers,
    SUM(CASE WHEN orders >= 2 THEN 1 ELSE 0 END) AS repeated_buyers,
    COUNT(*) AS total_customers,
    ROUND(SUM(CASE WHEN orders >= 2 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS repeat_rate_percentage
FROM (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_no) AS orders
    FROM retail_clean
    GROUP BY customer_id
) AS customer_orders;

/* Analysis Insight:
69.56% repeat rate — 3,035 of 4,363 customers bought 2+ times.
Only 1,328 (30.44%) were one-time buyers.

This confirms Scenario 4: strong customer loyalty with nearly
7 in 10 customers returning. These repeat buyers drive 78% of
total revenue.

The 1,328 one-time buyers are the key opportunity — converting
even 10% into repeat buyers could add significant revenue since
returning customers average ~5.7 orders each.

Recommendations:
- Segment one-time buyers to understand why they didn't return
- Target them with post-purchase follow-ups or second-order
  incentives
*/
-------------------------------------------------------