/* PROJECT : FRAUD DETECTION - USING SYNTHETIC FINANCIAL DATASET */

CREATE DATABASE bank;
USE bank;

CREATE TABLE transactions ( 
step INT, type VARCHAR(20), 
amount DECIMAL(15,2), 
nameOrig VARCHAR(20), 
oldbalanceOrg DECIMAL(15,2), 
newbalanceOrig DECIMAL(15,2), 
nameDest VARCHAR(20), 
oldbalanceDest DECIMAL(15,2), 
newbalanceDest DECIMAL(15,2), 
isFraud TINYINT, 
isFlaggedFraud TINYINT );

DESC transactions;
SELECT count(*) FROM transactions;

-- -----------------------------------------------------------------------------

## DATA EXPLPRATION ##

# Problem 1: Count the number of transactions by type.

SELECT type, COUNT(*) AS transaction_count
FROM transactions
GROUP BY type;

-- -----------------------------------------------------------------------------

# Problem 2: Calculate the total amount of money involved 
-- in each type of transaction.

SELECT type, SUM(amount) AS total_amount
FROM transactions
GROUP BY type;

-- -----------------------------------------------------------------------------

# Problem 3: Find the average transaction amount for each type of transaction.

SELECT type, AVG(amount) AS average_amount
FROM transactions
GROUP BY type;

-- -----------------------------------------------------------------------------

# Problem 4: Identify the top 5 transactions with the highest amounts.

SELECT *
FROM transactions
ORDER BY amount DESC
LIMIT 5;

-- -----------------------------------------------------------------------------

# Problem 5: Calculate the total number of fraudulent transactions.

SELECT COUNT(*) AS total_fraud_transactions
FROM transactions
WHERE isFraud = 1;

-- -----------------------------------------------------------------------------

# Problem 6: Calculate the total amount of money involved in 
-- fraudulent transactions for each type of transaction.

SELECT type, SUM(amount) AS total_fraud_amount
FROM transactions
WHERE isFraud = 1
GROUP BY type;

-- -----------------------------------------------------------------------------

# Problem 7: Identify the customers (nameOrig) who have initiated 
-- the highest number of fraudulent transactions.

SELECT nameOrig, COUNT(*) AS fraud_count
FROM transactions
WHERE isFraud = 1
GROUP BY nameOrig
ORDER BY fraud_count DESC
LIMIT 10;

-- -----------------------------------------------------------------------------

# Problem 8: Calculate the average balance change for the originator (nameOrig) 
-- in fraudulent transactions.

SELECT AVG(newbalanceOrig - oldbalanceOrg) AS average_balance_change
FROM transactions
WHERE isFraud = 1;


-- -----------------------------------------------------------------------------

# Problem 9: Find the top 5 recipients (nameDest) who received the 
-- highest amounts in fraudulent transactions.

SELECT nameDest, SUM(amount) AS total_received
FROM transactions
WHERE isFraud = 1
GROUP BY nameDest
ORDER BY total_received DESC
LIMIT 5;


/*-------------------------------------------------------------------------------------------------*/


## Fraud Detection ##

# Problem 1: List all transactions where the transaction amount is significantly higher than 
-- the originator’s initial balance (e.g., more than twice the old balance).

SELECT *
FROM transactions
WHERE amount > 2 * oldbalanceOrg;

-- -----------------------------------------------------------------------------

# Problem 2: Identify transactions where the originator’s balance did 
-- not change after a large transaction (e.g., amount > 10,000).

SELECT *
FROM transactions
WHERE amount > 10000 AND oldbalanceOrg = newbalanceOrig;

-- -----------------------------------------------------------------------------

# Problem 3: Find transactions where the recipient’s balance did 
-- not change after receiving a large amount (e.g., amount > 10,000).

SELECT *
FROM transactions
WHERE amount > 10000 AND oldbalanceDest = newbalanceDest;

-- -----------------------------------------------------------------------------

# Problem 4: Calculate the average transaction amount for fraudulent 
-- transactions and compare it to non-fraudulent transactions.

SELECT 
    AVG(
		CASE 
			WHEN isFraud = 1 
			THEN amount 
			ELSE NULL 
        END) AS avg_fraud_amount,
    AVG(
		CASE 
			WHEN isFraud = 0 
			THEN amount 
			ELSE NULL 
        END) AS avg_non_fraud_amount
FROM transactions;

          -- -----------------------------------------------------

-- USING CTE 
WITH fraud_stats AS (
    SELECT 
        AVG(CASE WHEN isFraud = 1 THEN amount ELSE NULL END) AS avg_fraud_amount,
        AVG(CASE WHEN isFraud = 0 THEN amount ELSE NULL END) AS avg_non_fraud_amount
    FROM transactions
)
SELECT * FROM fraud_stats;

-- -----------------------------------------------------------------------------

# Problem 5:Identify the top 10 originators with 
-- the highest total amount of fraudulent transactions.

SELECT nameOrig, SUM(amount) AS total_fraud_amount
FROM transactions
WHERE isFraud = 1
GROUP BY nameOrig
ORDER BY total_fraud_amount DESC
LIMIT 10;

-- -----------------------------------------------------------------------------

# Problem 6:List transactions where the transaction amount is 
-- greater than the sum of the originator’s and recipient’s initial balances.

SELECT *
FROM transactions
WHERE amount > (oldbalanceOrg + oldbalanceDest);

-- -----------------------------------------------------------------------------

# Problem 7: Identify transactions where the originator’s balance decreased 
-- but the recipient’s balance did not increase by the same amount.

SELECT *
FROM transactions
WHERE (oldbalanceOrg - newbalanceOrig) <> (newbalanceDest - oldbalanceDest);

-- -----------------------------------------------------------------------------

# Problem 8: Identify transactions where the originator’s balance is 
-- significantly higher than the recipient’s balance after the transaction.
SELECT *
FROM transactions
WHERE newbalanceOrig > 10 * newbalanceDest;

-- -----------------------------------------------------------------------------

# Problem 9: Find the top 5 transactions with the largest discrepancies 
-- between the originator’s and recipient’s balances after the transaction

SELECT *, ABS(newbalanceOrig - newbalanceDest) AS balance_discrepancy
FROM transactions
ORDER BY balance_discrepancy DESC
LIMIT 5;

-- -----------------------------------------------------------------------------

# Problem 10: Identify patterns in transactions where the originator’s balance 
-- is zero after a large transaction (e.g., amount > 10,000).

SELECT 
    type, 
    COUNT(*) AS transaction_count, 
    AVG(amount) AS average_amount
FROM transactions
WHERE amount > 10000 AND newbalanceOrig = 0
GROUP BY type;

/*-------------------------------------------------------------------------------------------------*/

## COMPLEX PROBLEMS ##

# Problem 1: Identify the top 5 transactions with the highest amounts within each transaction type

SELECT *
FROM (
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY type ORDER BY amount DESC) AS rank_
    FROM transactions
) AS ranked_transactions
WHERE rank_ <= 5;

-- -----------------------------------------------------------------------------

# Problem 2: Calculate the running total of transaction amounts for each customer (nameOrig).

SELECT nameOrig, step, amount, 
       SUM(amount) OVER (PARTITION BY nameOrig ORDER BY step) AS running_total
FROM transactions;

-- -----------------------------------------------------------------------------

# Problem 3: Identify customers who have made more than or equal to 1 fraudulent transactions.

WITH fraud_counts AS (
    SELECT nameOrig, COUNT(*) AS fraud_count
    FROM transactions
    WHERE isFraud = 1
    GROUP BY nameOrig
)
SELECT nameOrig, fraud_count
FROM fraud_counts
WHERE fraud_count >=1;

-- -----------------------------------------------------------------------------

# Problem 4: Find transactions where the amount is greater than the average transaction amount.

SELECT *
FROM transactions
WHERE amount > (SELECT AVG(amount) FROM transactions);

-- -----------------------------------------------------------------------------

# Problem 5: Identify transactions where the originator’s balance is 
-- less than the average balance of all originators.

SELECT *
FROM transactions
WHERE oldbalanceOrg < (SELECT AVG(oldbalanceOrg) FROM transactions);

-- -----------------------------------------------------------------------------

# Problem 6: Find pairs of transactions where the same customer (nameOrig) 
-- made two transactions within the same hour.

SELECT t1.*, t2.*
FROM transactions t1
JOIN transactions t2 ON t1.nameOrig = t2.nameOrig AND t1.step = t2.step AND t1.type <> t2.type;

-- -----------------------------------------------------------------------------

# Problem 7: Identify transactions where the recipient (nameDest) has 
-- also made a transaction as an originator

SELECT t1.*, t2.*
FROM transactions t1
JOIN transactions t2 ON t1.nameDest = t2.nameOrig;

-- -----------------------------------------------------------------------------

# Problem 8: Calculate the total amount of fraudulent transactions for 
-- each customer (nameOrig) 

-- using a CTE and window function

WITH fraud_totals AS (
    SELECT nameOrig, SUM(amount) AS total_fraud_amount
    FROM transactions
    WHERE isFraud = 1
    GROUP BY nameOrig
)
SELECT nameOrig, total_fraud_amount,
       RANK() OVER (ORDER BY total_fraud_amount DESC) AS rank_
FROM fraud_totals;

-- -----------------------------------------------------------------------------

# Problem 9: Identify patterns in transactions where the originator’s 
-- balance is zero after a large transaction 

-- using  window function.

SELECT type, step, amount, nameOrig, oldbalanceOrg, newbalanceOrig,
       AVG(amount) OVER (PARTITION BY type) AS avg_amount,
       COUNT(*) OVER (PARTITION BY type) AS transaction_count
FROM transactions
WHERE amount > 10000 AND newbalanceOrig = 0;

/*-------------------------------------------------------------------------------------------------*/









