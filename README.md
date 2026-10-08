# Customer Transaction & Behavioral Analysis

A SQL-based customer analytics project exploring transaction behavior, customer segmentation, retention, churn, spending patterns, merchant activity, payment channels, and customer value.

The project was developed using **Oracle SQL** and **SQLite** to demonstrate the ability to apply analytical SQL techniques across different database environments.

## Project Overview

This project analyzes a transaction dataset containing more than **13 million transactions** across **1,200+ customers**.

The analysis focuses on understanding:

* Customer transaction behavior
* RFM customer segmentation
* Customer cohorts and retention
* Customer churn
* Historical customer value
* Customer acquisition and growth
* Transaction and spending behavior
* Payment channel usage
* Merchant and category activity
* Customer concentration and value contribution
* Customer value profiles

## Dataset

The dataset contains:

* **13,305,915 transactions**
* **1,219 customers**
* **4,071 cards**
* **74,831 merchants**
* Transaction dates from **2010 to 2019**

Key fields include:

* `client_id`
* `card_id`
* `date`
* `amount`
* `use_chip`
* `merchant_id`
* `merchant_city`
* `merchant_state`
* `zip`
* `mcc`
* `errors`

The transaction data is used for analytical purposes only.

## Analysis Areas

### 1. Customer Behavior Analysis

Examines overall transaction activity and builds customer-level profiles using:

* Transaction frequency
* Historical transaction value
* Average transaction value
* First and last observed transaction dates

### 2. RFM Customer Segmentation

Customers are evaluated using:

* **Recency** — how recently the customer transacted
* **Frequency** — how often the customer transacted
* **Monetary Value** — historical transaction value

Customers are then grouped into behavioral segments such as:

* Champions
* Potential Loyalists
* Loyal Customers
* Big Spenders
* New / Low Engagement
* At Risk
* Inactive

### 3. Cohort & Retention Analysis

Customers are grouped according to their first observed transaction month.

The analysis evaluates:

* Monthly customer activity
* Periodic retention
* Continuous retention
* Customer activity over time

> Note: first observed transaction is treated as a proxy for acquisition because the dataset does not necessarily represent the customer's complete relationship history.

### 4. Churn Analysis

Customers are classified as churned when they have had no transaction for at least **365 days** before the dataset's final observation date.

The analysis examines:

* Churned customer count
* Historical transaction value associated with churned customers
* Churned customers' share of total transactions and value

### 5. Historical Customer Value

Customers are ranked into value quintiles to examine the distribution of historical transaction value across the customer base.

### 6. Customer Acquisition & Growth

Analyzes the number of customers first observed over time, including:

* Monthly observed customer acquisition
* Annual observed customer acquisition
* Cumulative customer growth

### 7. Transaction & Spending Behavior

Examines transaction-value distributions, including:

* Negative-value transactions
* Small-value transactions
* Medium-value transactions
* Higher-value transactions

### 8. Payment Channel Analysis

Analyzes transaction behavior across:

* Swipe transactions
* Chip transactions
* Online transactions

The analysis also identifies customers' dominant payment channels and their level of channel diversification.

### 9. Merchant & Category Analysis

Uses **Merchant Category Codes (MCC)** to examine:

* Transaction volume
* Transaction value
* Customer penetration
