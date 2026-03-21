-- =========================================
-- CUSTOMER ANALYTICS
-- RFM SEGMENTATION ANALYSIS
-- =========================================

/* Recency (R)   - How recently the customer purchased (days since last order) 
   Frequency (F) - How often they purchase (number of orders)                  
   Monetary (M)  - How much they spend in total ($)                            */


-- Step 1: Build RFM Base Table
-- Calculate Recency, Frequency, Monetary
CREATE OR REPLACE VIEW rfm_base AS 
SELECT
    customer_id,
    (SELECT MAX(invoice_date::date) FROM retail_clean) - MAX(invoice_date::date) AS recency,
    COUNT(DISTINCT invoice_no) AS frequency,
    ROUND(SUM(quantity * unit_price)::numeric, 2) AS monetary,
    ROUND(SUM(quantity * unit_price)::numeric, 2) AS total_revenue,
    SUM(quantity) AS total_quantity
FROM retail_clean
WHERE customer_id IS NOT NULL
  AND quantity > 0
  AND invoice_no NOT LIKE 'C%'
GROUP BY customer_id;


-- Step 2: Assign RFM Scores
-- Convert raw metrics into scores (1–4)
CREATE OR REPLACE VIEW rfm_scored AS
SELECT
    customer_id,
    recency,
    frequency,
    monetary,
    total_revenue,
    total_quantity,
    r_score,
    f_score,
    m_score,

    -- Combined RFM score
    CONCAT(r_score, f_score, m_score) AS rfm_score,

    CASE
       -- Top tier
       WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
       WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'

       -- Recent but low frequency (R=4-5, F≤2)
       WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
       WHEN r_score >= 4 AND f_score >= 3 AND m_score <= 2 THEN 'Potential Loyalists'

       -- Middle recency (R=3) — was the biggest gap
       WHEN r_score = 3 AND f_score <= 1 THEN 'About to Sleep'
       WHEN r_score = 3 AND f_score = 2 AND m_score >= 3 THEN 'Promising'
       WHEN r_score = 3 AND f_score = 2 AND m_score <= 2 THEN 'Cooling Down'
       WHEN r_score = 3 AND f_score >= 3 AND m_score <= 2 THEN 'Potential Loyalists'

       -- Fading customers (R=2)
       WHEN r_score = 2 AND f_score >= 3 AND m_score >= 3 THEN 'At Risk'
       WHEN r_score = 2 AND f_score >= 2 AND m_score <= 2 THEN 'Need Attention'
       WHEN r_score = 2 AND f_score <= 1 THEN 'Hibernating'
       WHEN r_score = 2 AND f_score = 2 AND m_score >= 3 THEN 'Big Spenders at Risk'

       -- Gone (R=1)
       WHEN r_score = 1 AND f_score >= 3 AND m_score >= 3 THEN 'Cannot Lose Them'
       WHEN r_score = 1 AND f_score >= 2 AND m_score <= 2 THEN 'Need Attention'
       WHEN r_score = 1 AND f_score <= 1 AND m_score >= 3 THEN 'Big Spenders at Risk'
       WHEN r_score = 1 AND f_score <= 2 AND m_score <= 2 THEN 'Lost'

       ELSE 'Others'
   END AS rfm_segment

FROM (
    SELECT
        *,

        -- Recency Score
        CASE
            WHEN recency <= 20  THEN 5
            WHEN recency <= 40  THEN 4
            WHEN recency <= 80  THEN 3
            WHEN recency <= 150 THEN 2
            ELSE 1
        END AS r_score,

        -- Frequency Score
        CASE
            WHEN frequency >= 12 THEN 5
            WHEN frequency >= 7  THEN 4
            WHEN frequency >= 4  THEN 3
            WHEN frequency >= 2  THEN 2
            ELSE 1
        END AS f_score,

        -- Monetary Score
        CASE
            WHEN monetary >= 2500 THEN 5
            WHEN monetary >= 1500 THEN 4
            WHEN monetary >= 1000 THEN 3
            WHEN monetary >= 500  THEN 2
            ELSE 1
        END AS m_score

    FROM rfm_base
) scored;


-- Step 3: View Final Customer Segments
SELECT * FROM rfm_scored;
