# RFM-Customer_Segmentation

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
Source: UCI Machine Learning Repository E-Commerce UK Dataset

Link : https://archive.ics.uci.edu/dataset/352/online+retail

Records: 500K+ transactions

Fields: InvoiceNo, Product Description, Quantity, UnitPrice, CustomerID, Country, InvoiceDate

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
* Excluded cancelled orders (InvoiceNo starting with 'C') and negative quantities

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


## Dashboard Overview:

<img src="https://github.com/ajoalenjeen/RFM-Customer_Segmentation/blob/6d7a13831990f3da99131db2c5b736c051661b48/Dashboard/Screenshot%202026-03-18%20001354.png?raw=true" width="800">
