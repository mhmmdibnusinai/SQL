use data_bank;
#Soal 1.1
SELECT COUNT(DISTINCT node_id) AS unique_nodes_count
FROM data_bank.customer_nodes;

#Soal 1.2
SELECT cn.region_id, r.region_name, COUNT(cn.node_id) AS nodes_per_region
FROM data_bank.customer_nodes AS cn
JOIN data_bank.regions AS r ON cn.region_id = r.region_id
GROUP BY cn.region_id, r.region_name;

#Soal 1.3
SELECT region_id, COUNT(DISTINCT customer_id) AS customers_per_region
FROM data_bank.customer_nodes
GROUP BY region_id;

#Soal 1.4
WITH ReallocationDays AS (
    SELECT customer_id,
           DATEDIFF(LEAD(start_date, 1) OVER (PARTITION BY customer_id ORDER BY start_date), end_date) AS reallocation_days
    FROM data_bank.customer_nodes
)
SELECT AVG(reallocation_days) AS average_reallocation_days
FROM ReallocationDays
WHERE reallocation_days IS NOT NULL;

#Soal 1.5

#Soal 2.1
SELECT txn_type,
       COUNT(*) as transaction_count,
       SUM(txn_amount) as total_amount
FROM data_bank.customer_transactions
GROUP BY txn_type;

#Soal 2.2
SELECT AVG(deposit_count) as avg_deposit_count,
       AVG(total_deposit_amount) as avg_deposit_amount
FROM (
    SELECT customer_id,
           COUNT(*) as deposit_count,
           SUM(txn_amount) as total_deposit_amount
    FROM data_bank.customer_transactions
    WHERE txn_type = 'deposit'
    GROUP BY customer_id
) as CustomerDeposits;

#Soal 2.3
SELECT YEAR(txn_date) as year,
       MONTH(txn_date) as month,
       COUNT(DISTINCT customer_id) as customer_count
FROM data_bank.customer_transactions
WHERE txn_type = 'deposit'
GROUP BY year, month
HAVING COUNT(DISTINCT case when txn_type = 'deposit' then customer_id else null end) > 1
   AND (COUNT(DISTINCT case when txn_type = 'purchase' then customer_id else null end) >= 1
   OR COUNT(DISTINCT case when txn_type = 'withdrawal' then customer_id else null end) >= 1);
   
   #Soal 2.4
   WITH MonthlyTransactions AS (
    SELECT customer_id,
           YEAR(txn_date) as year,
           MONTH(txn_date) as month,
           SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE 0 END) - 
           SUM(CASE WHEN txn_type IN ('purchase', 'withdrawal') THEN txn_amount ELSE 0 END) as net_amount
    FROM data_bank.customer_transactions
    GROUP BY customer_id, year, month
)
SELECT customer_id,
       year,
       month,
       SUM(net_amount) OVER (PARTITION BY customer_id ORDER BY year, month) + initial_balance as closing_balance
FROM MonthlyTransactions;

#Soal 2.5
WITH ClosingBalance AS (
    -- Use the query from Question 2.4 here
)
SELECT COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT customer_id) FROM data_bank.customer_transactions) as percentage
FROM (
    SELECT customer_id,
           LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY year, month) as previous_balance,
           closing_balance
    FROM ClosingBalance
) as MonthlyBalance
WHERE (closing_balance - previous_balance) / previous_balance > 0.05;