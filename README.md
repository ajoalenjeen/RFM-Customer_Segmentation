# RFM-Customer-Segmentation

## Project Overview
This project analyzes a real-world UK-based e-commerce dataset of 541,909 transactions using SQL to uncover revenue trends, customer retention patterns, and purchasing behavior. Data was imported into PostgreSQL, cleaned through a multi-step pipeline, and segmented using RFM (Recency, Frequency, Monetary) analysis across five business scenarios. Results are visualized through an interactive Tableau Public dashboard.

## 📊 Business Objective
To segment customers for targeted marketing by identifying:
 * Champions & Loyal Customers
 * New Customers & Potential Loyalists
 * At Risk, Lost & Big Spenders at Risk
 * And 7 other behavioural segments 

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
| Potential Loyalists  | R ≥ 3, F ≥ 3, M ≤ 2              |
| About to Sleep       | R = 3, F ≤ 1                      |
| Promising            | R = 3, F = 2, M ≥ 3              |
| Cooling Down         | R = 3, F = 2, M ≤ 2              |
| At Risk              | R = 2, F ≥ 3, M ≥ 3              |
| Need Attention       | R ≤ 2, F ≥ 2, M ≤ 2              |
| Hibernating          | R = 2, F ≤ 1                      |
| Big Spenders at Risk | R ≤ 2, F ≤ 2, M ≥ 3              |
| Cannot Lose Them     | R = 1, F ≥ 3, M ≥ 3              |
| Lost                 | R = 1, F ≤ 2, M ≤ 2              |
| Others               | Everything else                   |

## 📌 Sample RFM Output
| CustomerID | Recency | Frequency | Monetary   | RFM Score | Segment              |
|------------|---------|-----------|------------|-----------|----------------------|
| 12347      | 30      | 5         | 3,373.39   | 435       | Loyal Customers      |
| 12348      | 66      | 3         | 784.44     | 322       | Cooling Down         |
| 12349      | 9       | 1         | 1,457.55   | 513       | New Customers        |
| 12350      | 301     | 1         | 294.40     | 111       | Lost                 |
| 12354      | 223     | 1         | 1,079.40   | 113       | Big Spenders at Risk |

## Dashboard Overview [link](https://public.tableau.com/app/profile/ajo.jeen5964/viz/RetailAnalysisRFM/Overview?publish=yes)
<img src="https://github.com/ajoalenjeen/RFM-CUSTOMER-SEGMENTATION/blob/36c3c0ef3d1cfaa57b55908ce5445c2c5a8dcab1/Dashboard/Screenshot%202026-03-24%20034235.png?raw=true" width="800">

## Insights
* Revenue concentration — 474 Champions (11.3%) drive 55.7% of revenue (£4.27M). Losing even a few is costly.
* One-time buyer problem — 1,450 customers (34.6%) never returned. Returning customers average £2,578 each.
* Q4 dependency — Sep–Nov generates 40.6% of annual revenue. Monthly average nearly doubles (£548K → £999K).
* Long-tail catalog — Bottom 50% of products contribute only 3.9% of revenue.
* High-value churn risk — 161 At Risk/Cannot Lose customers hold £377K in historical revenue and are slipping away.

## Recommendations
* VIP retention for Champions — Loyalty rewards, early access, dedicated support. Losing 10% = ~£427K gone.
* First-purchase follow-up sequence — Converting just 10% of one-timers into repeats could add ~£374K.
* Win-back campaigns for at-risk customers — Personalised offers to 161 high-value churning buyers.
* Rationalise the product catalog — Discontinue or bundle low-performing products eating operational costs.
* mp up for Q4 by August — Stock, staff, and marketing should scale ahead of the Sep–Nov surge.


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
