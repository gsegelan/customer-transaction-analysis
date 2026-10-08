-- ============================================================
-- 1. CUSTOMER BEHAVIOR ANALYSIS
-- ============================================================

-- 1.1 Overall customer and transaction overview

SELECT
    COUNT(DISTINCT client_id) AS unique_customers,
    COUNT(*) AS total_transactions,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT client_id),2) AS avg_transactions_per_customer
FROM transactions_clean;



-- 1.2 Customer transaction profile

SELECT
    client_id,
    COUNT(*) AS transaction_count,
    ROUND(SUM(amount), 2) AS total_transaction_value,
    ROUND(AVG(amount), 2) AS avg_transaction_value,
    ROUND(MIN(amount), 2) AS min_transaction_value,
    ROUND(MAX(amount), 2) AS max_transaction_value,
    MIN(date) AS first_transaction_date,
    MAX(date) AS last_transaction_date
FROM transactions_clean
GROUP BY client_id
ORDER BY total_transaction_value DESC;
/




-- ============================================================
-- 2. RFM CUSTOMER SEGMENTATION
-- ============================================================

-- 2.1 Calculate customer-level RFM metrics

WITH customer_rfm AS
(
    SELECT
        client_id,
        TRUNC(DATE '2019-10-31' - TRUNC(MAX(date))) AS recency_days,
        COUNT(*) AS frequency,
        SUM(amount) AS monetary_value
    FROM transactions_clean
    GROUP BY client_id
)

SELECT
    client_id,
    recency_days,
    frequency,
    ROUND(monetary_value, 2) AS monetary_value,
    CASE
        WHEN recency_days <= 7 THEN 5
        WHEN recency_days <= 30 THEN 4
        WHEN recency_days <= 90 THEN 3
        WHEN recency_days <= 180 THEN 2
        ELSE 1
    END AS recency_score,
    NTILE(5) OVER (ORDER BY frequency) AS frequency_score,
    NTILE(5) OVER (ORDER BY monetary_value) AS monetary_score
FROM customer_rfm
ORDER BY monetary_value DESC;



-- 2.2 Assign customers to RFM segments

WITH customer_rfm AS 
(
    SELECT
        client_id,
        TRUNC(DATE '2019-10-31' - TRUNC(MAX(date))) AS recency_days,
        COUNT(*) AS frequency,
        SUM(amount) AS monetary_value
    FROM transactions_clean
    GROUP BY client_id
),
rfm_scores AS 
(
    SELECT
        client_id,
        recency_days,
        frequency,
        monetary_value,
        CASE
            WHEN recency_days <= 7 THEN 5
            WHEN recency_days <= 30 THEN 4
            WHEN recency_days <= 90 THEN 3
            WHEN recency_days <= 180 THEN 2
            ELSE 1
        END AS recency_score,
        NTILE(5) OVER (ORDER BY frequency) AS frequency_score,
        NTILE(5) OVER (ORDER BY monetary_value) AS monetary_score
    FROM customer_rfm
),
rfm_segments AS 
(
    SELECT
        *,
        CASE
            WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
            WHEN recency_score >= 4 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Loyal Customers'
            WHEN recency_score >= 4 AND frequency_score >= 3 THEN 'Potential Loyalists'
            WHEN recency_score >= 4 AND monetary_score >= 4 THEN 'Big Spenders'
            WHEN recency_score <= 2 AND frequency_score >= 4 THEN 'At Risk'
            WHEN recency_score <= 2 AND frequency_score <= 2 THEN 'Inactive'
            ELSE 'New / Low Engagement'
        END AS customer_segment
    FROM rfm_scores
)

SELECT
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 /(SELECT COUNT(*) FROM rfm_segments),2) AS customer_percentage,
    ROUND(SUM(monetary_value), 2) AS total_transaction_value,
    ROUND(AVG(monetary_value), 2) AS avg_customer_value,
    ROUND(AVG(frequency), 2) AS avg_transactions
FROM rfm_segments
GROUP BY customer_segment
ORDER BY total_transaction_value DESC;



-- 2.3 Customer-level RFM profile

WITH customer_rfm AS 
(
    SELECT
        client_id,
        TRUNC(DATE '2019-10-31' - TRUNC(MAX(date))) AS recency_days,
        COUNT(*) AS frequency,
        SUM(amount) AS monetary_value
    FROM transactions_clean
    GROUP BY client_id
),
rfm_scores AS 
(
    SELECT
        client_id,
        recency_days,
        frequency,
        monetary_value,
        CASE
            WHEN recency_days <= 7 THEN 5
            WHEN recency_days <= 30 THEN 4
            WHEN recency_days <= 90 THEN 3
            WHEN recency_days <= 180 THEN 2
            ELSE 1
        END AS recency_score,
        NTILE(5) OVER (ORDER BY frequency) AS frequency_score,
        NTILE(5) OVER (ORDER BY monetary_value) AS monetary_score
    FROM customer_rfm
)

SELECT
    client_id,
    recency_days,
    frequency,
    ROUND(monetary_value, 2) AS monetary_value,
    recency_score,
    frequency_score,
    monetary_score,
    CASE
		WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
		WHEN recency_score >= 4 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Loyal Customers'
		WHEN recency_score >= 4 AND frequency_score >= 3 THEN 'Potential Loyalists'
		WHEN recency_score >= 4 AND monetary_score >= 4 THEN 'Big Spenders'
		WHEN recency_score <= 2 AND frequency_score >= 4 THEN 'At Risk'
		WHEN recency_score <= 2 AND frequency_score <= 2 THEN 'Inactive'
		ELSE 'New / Low Engagement'
	END AS customer_segment
FROM rfm_scores
ORDER BY monetary_value DESC;
/




-- ============================================================
-- 3. COHORT ANALYSIS
-- ============================================================

-- 3.1 Identify each customer's first observed transaction month

WITH customer_cohorts AS 
(
    SELECT
        client_id,
        TO_CHAR(MIN(date), 'YYYY-MM') AS cohort_month
    FROM transactions_clean
    GROUP BY client_id
)
SELECT
    cohort_month,
    COUNT(*) AS customer_count
FROM customer_cohorts
GROUP BY cohort_month
ORDER BY cohort_month;



-- 3.2 Monthly customer activity

SELECT
    TO_CHAR(date, 'YYYY-MM') AS transaction_month,
    COUNT(DISTINCT client_id) AS active_customers
FROM transactions_clean
GROUP BY TO_CHAR(date, 'YYYY-MM')
ORDER BY transaction_month;



-- 3.3 Calculate months since cohort

WITH customer_cohorts AS 
(
    SELECT
        client_id,
        MIN(date) AS first_transaction_date,
        TRUNC(MIN(date), 'MM') AS cohort_month
    FROM transactions_clean
    GROUP BY client_id
),
customer_activity AS 
(
    SELECT DISTINCT
        client_id,
        TRUNC(date, 'MM') AS transaction_month
    FROM transactions_clean
)

SELECT
    c.cohort_month,
    a.transaction_month,
    TRUNC(MONTHS_BETWEEN(a.transaction_month,c.cohort_month)) AS months_since_cohort,
    COUNT(DISTINCT a.client_id) AS active_customers
FROM customer_cohorts c
JOIN customer_activity a ON c.client_id = a.client_id
GROUP BY
    c.cohort_month,
    a.transaction_month
ORDER BY
    c.cohort_month,
    a.transaction_month;

	
	
-- 3.4 Cohort retention analysis

WITH customer_cohorts AS 
(
    SELECT
        client_id,
        TRUNC(MIN(date), 'MM') AS cohort_month
    FROM transactions_clean
    GROUP BY client_id
),
customer_activity AS 
(
    SELECT DISTINCT
        client_id,
        TRUNC(date, 'MM') AS transaction_month
    FROM transactions_clean
),
cohort_activity AS 
(
    SELECT
        c.cohort_month,
        a.transaction_month,
		TRUNC(MONTHS_BETWEEN(a.transaction_month,c.cohort_month)) AS months_since_cohort,
        COUNT(DISTINCT a.client_id) AS active_customers
    FROM customer_cohorts c
    JOIN customer_activity a ON c.client_id = a.client_id
    GROUP BY
        c.cohort_month,
        a.transaction_month
),
cohort_sizes AS 
(
    SELECT
        cohort_month,
        COUNT(*) AS cohort_size
    FROM customer_cohorts
    GROUP BY cohort_month
)

SELECT
    ca.cohort_month,
    ca.months_since_cohort,
    ca.active_customers,
    cs.cohort_size,
    ROUND(ca.active_customers * 100.0 /cs.cohort_size,2) AS retention_percentage
FROM cohort_activity ca
JOIN cohort_sizes cs ON ca.cohort_month = cs.cohort_month
ORDER BY
    ca.cohort_month,
    ca.months_since_cohort;
	
	
	
-- 3.5 Continuous retention analysis

WITH customer_cohorts AS 
(
    SELECT
        client_id,
        TRUNC(MIN(date), 'MM') AS cohort_month
    FROM transactions_clean
    GROUP BY client_id
),
customer_activity AS 
(
    SELECT DISTINCT
        client_id,
        TRUNC(date, 'MM') AS transaction_month
    FROM transactions_clean
),
cohort_activity AS 
(
    SELECT
        c.client_id,
        c.cohort_month,
        a.transaction_month,
		TRUNC(MONTHS_BETWEEN(a.transaction_month,c.cohort_month)) AS months_since_cohort,
    FROM customer_cohorts c
    JOIN customer_activity a ON c.client_id = a.client_id
),
customer_continuity AS 
(
    SELECT
        client_id,
        cohort_month,
        MAX(months_since_cohort) AS latest_month,
        COUNT(DISTINCT CASE WHEN months_since_cohort BETWEEN 1 AND 12 THEN months_since_cohort END) AS active_months_1_to_12
    FROM cohort_activity
    GROUP BY
        client_id,
        cohort_month
)

SELECT
    cohort_month,
    COUNT(*) AS cohort_size,
    SUM(CASE WHEN active_months_1_to_12 = 12 THEN 1 ELSE 0 END) AS continuously_retained_12_months,
    ROUND(SUM(CASE WHEN active_months_1_to_12 = 12 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),2) AS continuous_12_month_retention
FROM customer_continuity
GROUP BY cohort_month
ORDER BY cohort_month;
/




-- ============================================================
-- 4. CHURN ANALYSIS
-- ============================================================

-- 4.1 Identify customers inactive for at least 365 days

WITH customer_activity AS 
(
    SELECT
        client_id,
        MAX(date) AS last_transaction_date,
        COUNT(*) AS transaction_count,
        SUM(amount) AS historical_value
    FROM transactions_clean
    GROUP BY client_id
)

SELECT
    client_id,
    last_transaction_date,
    TRUNC(DATE '2019-10-31' - TRUNC(last_transaction_date)) AS days_since_last_transaction,
    transaction_count,
    ROUND(historical_value, 2) AS historical_value,
    CASE WHEN DATE '2019-10-31' - TRUNC(last_transaction_date) >= 365 THEN 'Churned' ELSE 'Active' END AS customer_status
FROM customer_activity
ORDER BY days_since_last_transaction DESC;



-- 4.2 Churn summary

WITH customer_activity AS 
(
    SELECT
        client_id,
        MAX(date) AS last_transaction_date,
        COUNT(*) AS transaction_count,
        SUM(amount) AS historical_value
    FROM transactions_clean
    GROUP BY client_id
),
customer_status AS 
(
    SELECT
        client_id,
        transaction_count,
        historical_value,
        CASE WHEN DATE '2019-10-31' - TRUNC(last_transaction_date) >= 365 THEN 'Churned' ELSE 'Active' END AS customer_status
    FROM customer_activity
)

SELECT
    customer_status,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 /(SELECT COUNT(*) FROM customer_status),2) AS customer_percentage,
    SUM(transaction_count) AS total_transactions,
    ROUND(SUM(historical_value),2) AS historical_value,
    ROUND(AVG(historical_value),2) AS avg_historical_value
FROM customer_status
GROUP BY customer_status
ORDER BY customer_count DESC;
/




-- ============================================================
-- 5. HISTORICAL CUSTOMER VALUE
-- ============================================================

-- 5.1 Customer historical value profile

SELECT
    client_id,
    MIN(date) AS first_transaction_date,
    MAX(date) AS last_transaction_date,
    TRUNC(MAX(date) - MIN(date)) AS observed_lifetime_days,
    COUNT(*) AS transaction_count,
    COUNT(DISTINCT TRUNC(date, 'MM')) AS active_months,
    ROUND(SUM(amount),2) AS historical_value,
    ROUND(AVG(amount),2) AS avg_transaction_value,
    ROUND(SUM(amount) /COUNT(DISTINCT TRUNC(date, 'MM')),2) AS avg_value_per_active_month
FROM transactions_clean
GROUP BY client_id
ORDER BY historical_value DESC;



-- 5.2 Customer value quintiles

WITH customer_value AS 
(
    SELECT
        client_id,
        COUNT(*) AS transaction_count,
        COUNT(DISTINCT TRUNC(date, 'MM')) AS active_months,
        SUM(amount) AS historical_value,
        AVG(amount) AS avg_transaction_value
    FROM transactions_clean
    GROUP BY client_id
),
customer_quintiles AS 
(
    SELECT
        *,
        NTILE(5) OVER (ORDER BY historical_value DESC) AS value_quintile
    FROM customer_value
)

SELECT
    value_quintile,
    COUNT(*) AS customer_count,
    ROUND(SUM(historical_value),2 ) AS total_historical_value,
    ROUND(SUM(historical_value) * 100.0 /(SELECT SUM(historical_value)FROM customer_value),2) AS value_share_percentage,
    ROUND(AVG(historical_value),2) AS avg_customer_value,
    ROUND(AVG(transaction_count), 2) AS avg_transactions,
    ROUND(AVG(active_months),2) AS avg_active_months,
    ROUND(AVG(avg_transaction_value),2) AS avg_transaction_value
FROM customer_quintiles
GROUP BY value_quintile
ORDER BY value_quintile;
/




-- ============================================================
-- 6. CUSTOMER ACQUISITION & GROWTH
-- ============================================================

-- 6.1 Monthly observed customer acquisition

WITH customer_first_transaction AS 
(
    SELECT
        client_id,
        MIN(date) AS first_transaction_date
    FROM transactions_clean
    GROUP BY client_id
)

SELECT
    TO_CHAR(first_transaction_date, 'YYYY-MM') AS acquisition_month,
    COUNT(*) AS new_customers
FROM customer_first_transaction
GROUP BY
    TO_CHAR(first_transaction_date, 'YYYY-MM')
ORDER BY acquisition_month;



-- 6.2 Annual observed customer acquisition and cumulative growth

WITH customer_first_transaction AS 
(
    SELECT
        client_id,
        MIN(date) AS first_transaction_date
    FROM transactions_clean
    GROUP BY client_id
),
annual_acquisition AS 
(
    SELECT
        TO_CHAR(first_transaction_date,'YYYY') AS acquisition_year,
        COUNT(*) AS new_customers
    FROM customer_first_transaction
    GROUP BY
        TO_CHAR(first_transaction_date,'YYYY')
)

SELECT
    acquisition_year,
    new_customers,
    SUM(new_customers) OVER (ORDER BY acquisition_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_customers
FROM annual_acquisition
ORDER BY acquisition_year;
/




-- ============================================================
-- 7. TRANSACTION & SPENDING BEHAVIOR
-- ============================================================

-- 7.1 Customer transaction and spending profile

SELECT
    client_id,
    COUNT(*) AS transaction_count,
    ROUND(SUM(amount), 2) AS total_transaction_value,
    ROUND(AVG(amount), 2) AS avg_transaction_value,
    ROUND(MIN(amount), 2) AS min_transaction_value,
    ROUND(MAX(amount), 2) AS max_transaction_value
FROM transactions_clean
GROUP BY client_id
ORDER BY total_transaction_value DESC;



-- 7.2 Transaction value distribution

SELECT
    CASE
        WHEN amount < 0 THEN 'Negative'
        WHEN amount < 25 THEN '0 - 24.99'
        WHEN amount < 50 THEN '25 - 49.99'
        WHEN amount < 100 THEN '50 - 99.99'
        WHEN amount < 250 THEN '100 - 249.99'
        WHEN amount < 500 THEN '250 - 499.99'
        ELSE '500+'
    END AS transaction_value_band,
    COUNT(*) AS transaction_count,
    ROUND(COUNT(*) * 100.0 /(SELECT COUNT(*) FROM transactions_clean),2) AS transaction_percentage,
    ROUND(SUM(amount),2) AS total_transaction_value,
    ROUND(AVG(amount),2) AS avg_transaction_value
FROM transactions_clean
GROUP BY
    CASE
        WHEN amount < 0 THEN 'Negative'
        WHEN amount < 25 THEN '0 - 24.99'
        WHEN amount < 50 THEN '25 - 49.99'
        WHEN amount < 100 THEN '50 - 99.99'
        WHEN amount < 250 THEN '100 - 249.99'
        WHEN amount < 500 THEN '250 - 499.99'
        ELSE '500+'
    END
ORDER BY MIN(amount);



-- 7.3 Negative-value transactions

SELECT
    COUNT(*) AS negative_transaction_count,
    ROUND(COUNT(*) * 100.0 /(SELECT COUNT(*) FROM transactions_clean),2) AS negative_transaction_percentage,
    ROUND(SUM(amount),2) AS total_negative_value,
    ROUND(AVG(amount),2) AS average_negative_value
FROM transactions_clean
WHERE amount < 0;
/




-- ============================================================
-- 8. PAYMENT CHANNEL ANALYSIS
-- ============================================================

-- 8.1 Overall payment channel performance

SELECT
    use_chip AS payment_channel,
    COUNT(*) AS transaction_count,
    ROUND(COUNT(*) * 100.0 /(SELECT COUNT(*) FROM transactions_clean),2) AS transaction_percentage,
    ROUND(SUM(amount),2) AS total_transaction_value,
    ROUND(SUM(amount) * 100.0 /(SELECT SUM(amount) FROM transactions_clean),2) AS value_share_percentage,
    ROUND(AVG(amount),2) AS avg_transaction_value,
    COUNT(DISTINCT client_id) AS unique_customers
FROM transactions_clean
GROUP BY use_chip
ORDER BY transaction_count DESC;



-- 8.2 Dominant payment channel by customer

WITH customer_channels AS 
(
    SELECT
        client_id,
        use_chip AS payment_channel,
        COUNT(*) AS transaction_count
    FROM transactions_clean
    GROUP BY
        client_id,
        use_chip
),
ranked_channels AS 
(
    SELECT
        client_id,
        payment_channel,
        transaction_count,
        ROW_NUMBER() OVER (PARTITION BY client_id ORDER BY transaction_count DESC) AS channel_rank
    FROM customer_channels
)

SELECT
    payment_channel,
    COUNT(*) AS customers,
    ROUND(COUNT(*) * 100.0 /(SELECT COUNT(DISTINCT client_id) FROM transactions_clean),2) AS customer_percentage
FROM ranked_channels
WHERE channel_rank = 1
GROUP BY payment_channel
ORDER BY customers DESC;



-- 8.3 Customer payment channel diversification

WITH customer_channel_count AS 
(
    SELECT
        client_id,
        COUNT(DISTINCT use_chip) AS channel_count
    FROM transactions_clean
    GROUP BY client_id
)
SELECT
    CASE
        WHEN channel_count = 1 THEN 'Single-channel'
        WHEN channel_count = 2 THEN 'Two-channel'
        WHEN channel_count = 3 THEN 'Multi-channel'
    END AS channel_usage_type,
    COUNT(*) AS customers,
    ROUND(COUNT(*) * 100.0 /(SELECT COUNT(*) FROM customer_channel_count),2 ) AS customer_percentage
FROM customer_channel_count
GROUP BY channel_count
ORDER BY channel_count;
/




-- ============================================================
-- 9. MERCHANT & CATEGORY ANALYSIS
-- ============================================================

-- 9.1 MCC transaction volume and value

SELECT
    mcc,
    COUNT(*) AS transaction_count,
    ROUND(SUM(amount), 2) AS total_transaction_value,
    ROUND(AVG(amount), 2) AS avg_transaction_value,
    COUNT(DISTINCT client_id) AS unique_customers
FROM transactions_clean
GROUP BY mcc
ORDER BY transaction_count DESC;



-- 9.2 MCC customer penetration

SELECT
    mcc,
    COUNT(DISTINCT client_id) AS unique_customers,
    ROUND(COUNT(DISTINCT client_id) * 100.0 /(SELECT COUNT(DISTINCT client_id) FROM transactions_clean),2) AS customer_penetration_percentage,
    COUNT(*) AS transaction_count,
    ROUND(SUM(amount),2) AS total_transaction_value,
    ROUND(AVG(amount),2) AS avg_transaction_value
FROM transactions_clean
GROUP BY mcc
ORDER BY customer_penetration_percentage DESC;



-- 9.3 Historical transaction value per customer by MCC

SELECT
    mcc,
    COUNT(DISTINCT client_id) AS unique_customers,
    ROUND(SUM(amount),2) AS total_transaction_value,
    ROUND(SUM(amount) /COUNT(DISTINCT client_id),2) AS value_per_customer,
    ROUND(AVG(amount),2) AS avg_transaction_value
FROM transactions_clean
GROUP BY mcc
ORDER BY value_per_customer DESC;
/




-- ============================================================
-- 10. MERCHANT-LEVEL ANALYSIS
-- ============================================================

-- 10.1 Top merchants by historical transaction value

SELECT
    merchant_id,
    COUNT(*) AS transaction_count,
    ROUND(SUM(amount), 2) AS total_transaction_value,
    ROUND(AVG(amount), 2) AS avg_transaction_value,
    COUNT(DISTINCT client_id) AS unique_customers
FROM transactions_clean
GROUP BY merchant_id
ORDER BY total_transaction_value DESC
FETCH FIRST 25 ROWS ONLY;



-- 10.2 Merchant customer concentration

SELECT
    merchant_id,
    COUNT(DISTINCT client_id) AS unique_customers,
    ROUND(SUM(amount),2) AS total_transaction_value,
    ROUND(SUM(amount) /COUNT(DISTINCT client_id),2) AS value_per_customer,
    COUNT(*) AS transaction_count,
    ROUND(AVG(amount),2 ) AS avg_transaction_value
FROM transactions_clean
GROUP BY merchant_id
HAVING COUNT(DISTINCT client_id) >= 10
ORDER BY value_per_customer DESC
FETCH FIRST 25 ROWS ONLY;



-- 10.3 Merchant customer reach

SELECT
    merchant_id,
    COUNT(DISTINCT client_id) AS unique_customers,
    ROUND(COUNT(DISTINCT client_id) * 100.0 /(SELECT COUNT(DISTINCT client_id)FROM transactions_clean),2) AS customer_reach_percentage,
    COUNT(*) AS transaction_count,
    ROUND(SUM(amount),2) AS total_transaction_value,
    ROUND(AVG(amount),2 ) AS avg_transaction_value
FROM transactions_clean
GROUP BY merchant_id
ORDER BY unique_customers DESC
FETCH FIRST 25 ROWS ONLY;
/




-- ============================================================
-- 11. CUSTOMER CONCENTRATION & VALUE CONTRIBUTION
-- ============================================================

-- 11.1 Customer value concentration by quintile

WITH customer_value AS 
(
    SELECT
        client_id,
        SUM(amount) AS total_value
    FROM transactions_clean
    GROUP BY client_id
),
customer_quintiles AS 
(
    SELECT
        client_id,
        total_value,
        NTILE(5) OVER (ORDER BY total_value DESC) AS value_quintile
    FROM customer_value
)

SELECT
    value_quintile,
    COUNT(*) AS customer_count,
    ROUND(SUM(total_value),2) AS total_value,
    ROUND(SUM(total_value) * 100.0 /(SELECT SUM(total_value)FROM customer_value),2 ) AS value_share_percentage,
    ROUND(AVG(total_value),2) AS avg_customer_value
FROM customer_quintiles
GROUP BY value_quintile
ORDER BY value_quintile;



-- 11.2 Customer value contribution by percentile

WITH customer_value AS 
(
    SELECT
        client_id,
        SUM(amount) AS total_customer_value
    FROM transactions_clean
    GROUP BY client_id
),
ranked_customers AS 
(
    SELECT
        client_id,
        total_customer_value,
        PERCENT_RANK() OVER (ORDER BY total_customer_value DESC) AS value_rank
    FROM customer_value
)

SELECT
    CASE
        WHEN value_rank <= 0.10 THEN 'Top 10%'
        WHEN value_rank <= 0.20 THEN 'Top 20%'
        WHEN value_rank <= 0.50 THEN 'Top 50%'
        ELSE 'Bottom 50%'
    END AS customer_group,
    COUNT(*) AS customer_count,
    ROUND(SUM(total_customer_value),2) AS total_customer_value,
    ROUND(SUM(total_customer_value) * 100.0 /(SELECT SUM(total_customer_value) FROM customer_value),2) AS value_share_percentage
FROM ranked_customers
GROUP BY
    CASE
        WHEN value_rank <= 0.10 THEN 'Top 10%'
        WHEN value_rank <= 0.20 THEN 'Top 20%'
        WHEN value_rank <= 0.50 THEN 'Top 50%'
        ELSE 'Bottom 50%'
    END
ORDER BY
	CASE customer_group
        WHEN 'Top 10%' THEN 1
        WHEN 'Top 20%' THEN 2
        WHEN 'Top 50%' THEN 3
        WHEN 'Bottom 50%' THEN 4
    END;
/




-- ============================================================
-- 12. FINAL CUSTOMER PROFILE
-- ============================================================

-- 12.1 Customer value profile

WITH customer_metrics AS
(
    SELECT
        client_id,
        COUNT(*) AS transaction_count,
        SUM(amount) AS total_customer_value,
        AVG(amount) AS avg_transaction_value,
        COUNT(DISTINCT TRUNC(date, 'MM')) AS active_months,
        TRUNC(DATE '2019-10-31' - TRUNC(MAX(date))) AS recency_days
    FROM transactions_clean
    GROUP BY client_id
),
customer_segments AS 
(
    SELECT
        *,
        NTILE(5) OVER (ORDER BY total_customer_value DESC) AS value_quintile
    FROM customer_metrics
)

SELECT
    value_quintile,
    COUNT(*) AS customer_count,
    ROUND(AVG(total_customer_value),2) AS avg_customer_value,
    ROUND(AVG(transaction_count),2) AS avg_transactions,
    ROUND(AVG(avg_transaction_value),2) AS avg_transaction_value,
    ROUND(AVG(active_months),2) AS avg_active_months,
    ROUND(AVG(recency_days),2) AS avg_recency_days
FROM customer_segments
GROUP BY value_quintile
ORDER BY value_quintile;
	


