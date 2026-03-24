# RFM-Customer-Segmentation

## Project Overview
This project applies Recency, Frequency, and Monetary (RFM) analysis to segment customers based on their purchasing behavior using SQL.

It was performed on a real-world UK-based e-commerce transactions dataset, imported into MySQL and cleaned to prepare for analysis.

## 📊 Business Objective
To segment customers for targeted marketing by identifying:
 * Champions
 * Loyal Customers
 * At Risk / Lost Customers
 * New Customers
 * Big Spenders at Risk

## 🧱 Dataset Summary
**Source**: UCI Machine Learning Repository E-Commerce UK Dataset

**Link** : https://archive.ics.uci.edu/dataset/352/online+retail

**Records** : 500K+ transactions

**Fields** : InvoiceNo, Product Description, Quantity, UnitPrice, CustomerID, Country, InvoiceDate

## 🔧 Process Summary
### 1. Data Cleaning
* Removed duplicate records using ROW_NUMBER() with composite key 
  (InvoiceNo, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country)
* Removed rows with null or blank Description and CustomerID
* Standardized InvoiceDate to DATE format
* Removed non-product records (postage, bank charges, discounts, Amazon fees, 
  donations, manual adjustments, gift codes, etc.)

### 2. Exploratory Data Analysis (EDA)

#### Dataset Overview
* Checked total orders, unique customers, unique products, and transaction date range
* Dataset spans from 01/12/2010 to 09/12/2011

#### Data Quality Checks
* Identified null/blank values in Description and CustomerID columns
* Detected duplicate records using InvoiceNo + StockCode grouping
* Found rows with zero or negative quantities (returns/errors)
* Identified cancellation transactions (InvoiceNo starting with 'C')

#### Key Insights Explored
* Top 10 best-selling products by quantity sold
* Top countries by order count
* Cancellation volume and patterns


### 3. RFM Segmentation

#### RFM Base Metrics
* **Recency** — Days since last purchase (from max date in dataset)
* **Frequency** — Count of distinct invoices per customer
* **Monetary** — Total spend (quantity × unit price)

#### RFM Scoring (1–5 scale)
| Score | Recency (days) | Frequency (orders) | Monetary (£) |
|-------|----------------|-------------------|--------------|
| 5     | ≤ 20           | ≥ 12              | ≥ 2,500      |
| 4     | ≤ 40           | ≥ 7               | ≥ 1,500      |
| 3     | ≤ 80           | ≥ 4               | ≥ 1,000      |
| 2     | ≤ 150          | ≥ 2               | ≥ 500        |
| 1     | > 150          | 1                 | < 500        |

#### Customer Segments
| Segment              | Criteria                          |
|----------------------|-----------------------------------|
| Champions            | R ≥ 4, F ≥ 4, M ≥ 4              |
| Loyal Customers      | R ≥ 3, F ≥ 3, M ≥ 3              |
| New Customers        | R ≥ 4, F ≤ 2                      |
| Potential Loyalists  | R ≥ 4, F ≥ 3, M ≤ 3              |
| At Risk              | R ≤ 2, F ≥ 3, M ≥ 3              |
| Big Spenders at Risk | R ≤ 2, F ≤ 2, M ≥ 3              |
| Need Attention       | R ≤ 2, F ≥ 2, M ≤ 2              |
| Cannot Lose Them     | R = 1, F ≤ 2, M ≥ 3              |
| Lost                 | R = 1, F ≤ 2, M ≤ 2              |
| Others               | Everything else                   |


## 📌 Sample RFM Output

| CustomerID | Recency | Frequency | Monetary   | RFM Score | Segment              |
|------------|---------|-----------|------------|-----------|----------------------|
| 12347      | 2       | 7         | 4,310.00   | 545       | Champions            |
| 12348      | 75      | 4         | 1,437.24   | 333       | Loyal Customers      |
| 12349      | 18      | 1         | 1,457.55   | 513       | New Customers        |
| 12350      | 310     | 1         | 294.40     | 111       | Lost                 |
| 12354      | 232     | 1         | 1,079.40   | 113       | Big Spenders at Risk |


## Dashboard Overview [link](https://public.tableau.com/app/profile/ajo.jeen5964/viz/RetailAnalysisRFM/Overview?publish=yes)
<img src="https://github.com/ajoalenjeen/RFM-CUSTOMER-SEGMENTATION/blob/879e7c00fb9969aeec95cd972a001d4546034dbc/Dashboard/Screenshot%202026-03-23%20222517.png?raw=true" width="800">

## Key Insights
* Champions (11.4% of customers) drive 55.67% of revenue — extreme concentration risk
* Champions + Loyal combined (24.7% of customers) account for 72.3% of total revenue
* New Customers is the largest RFM segment (933) — biggest pipeline for future Loyalists
* 67.17% repeat purchase rate, but 34.6% never return — retention gap between first and second purchase
* Lost (618) and About to Sleep (327) together hold 22.7% of customers contributing only 4.1% of revenue — reactivation opportunity
  
## Recommendations
* Create VIP program for Champions (R5F5M5) with exclusive perks to protect the 55.67% revenue base
* Build post-first-purchase email flows for New Customers segment (933) to move them toward Loyal
* Launch win-back campaigns for Cannot Lose Them (17) and At Risk (55) before they slip to Lost
* Target About to Sleep (327) and Cooling Down (204) with re-engagement offers while they're still reachable
* Monitor RFM segment migration monthly — track how many New Customers convert to Loyal vs drop to Lost


## 📈 Tools Used
 * MySQL Workbench
 * CSV Import & Table Creation
 * SQL Views & Case Logic
 * Exported final table for Tableau dashboard

## 🧠 SQL - Key Skills Demonstrated
 * Data Cleaning (NULLs, Duplicates, Returns)
 * Exploratory Data Anlysis
 * Customer Segmentation via RFM
 * Business Logic Implementation
 * Preparation for Tableau Visualization
