-- =========================================
-- DATA CLEANING STAGE
-- Retail Dataset Preparation
-- =========================================


-- Step 1: Create Working Table
-- Copy raw data into a cleaning workspace

CREATE TABLE retail_clean AS
SELECT *
FROM retail_data;



-- Step 2: Remove Duplicate Records
-- Identify duplicates using ROW_NUMBER

CREATE TABLE retail_clean_dedup AS
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY invoice_no, stock_code, description,
                            quantity, invoice_date, unit_price,
                            customer_id, country
               ORDER BY invoice_date
           ) AS rn
    FROM retail_clean
) t
WHERE rn = 1;



-- Step 3: Replace Original Table
-- Keep only the deduplicated dataset

DROP TABLE retail_clean;
ALTER TABLE retail_clean_dedup RENAME TO retail_clean;



-- Step 4: Remove Null / Missing Values
-- Ensure essential fields exist

DELETE FROM retail_clean
WHERE description IS NULL OR description = ''
OR customer_id IS NULL OR customer_id = '';



-- Step 5: Standardize Date Format
-- Convert invoice_date to DATE type

ALTER TABLE retail_clean
ALTER COLUMN invoice_date TYPE DATE
USING invoice_date::DATE;



-- Step 6: Remove non-product / service records

DELETE FROM retail_clean
WHERE stock_code IN (
    'POST','DOT','M','D','CRUK','BANK CHARGES','AMAZONFEE','PADS','S'
)
OR stock_code LIKE 'gift%'
OR description IN (
    'Manual','Discount','POSTAGE','DOTCOM POSTAGE','CRUK Commission','Bank Charges'
);


select * from retail_clean;