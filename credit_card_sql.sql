-- ==============================================================================
-- Project: Credit Card Financial & Customer Analytics
-- Author: Nitesh Kumar (https://github.com/nitesh28ku)
-- Description: Database schema creation and data import queries
-- ==============================================================================

-- 1. Create cc_detail table
DROP TABLE IF EXISTS cc_detail;
CREATE TABLE cc_detail (
    Client_Num INT,
    Card_Category VARCHAR(20),
    Annual_Fees INT,
    Activation_30_Days INT,
    Customer_Acq_Cost INT,
    Week_Start_Date DATE,
    Week_Num VARCHAR(20),
    Qtr VARCHAR(10),
    current_year INT,
    Credit_Limit DECIMAL(10,2),
    Total_Revolving_Bal INT,
    Total_Trans_Amt INT,
    Total_Trans_Ct INT,
    Avg_Utilization_Ratio DECIMAL(10,3),
    Use_Chip VARCHAR(10),
    Exp_Type VARCHAR(50),
    Interest_Earned DECIMAL(10,3),
    Delinquent_Acc VARCHAR(5)
);

-- 2. Create cust_detail table
DROP TABLE IF EXISTS cust_detail;
CREATE TABLE cust_detail (
    Client_Num INT,
    Customer_Age INT,
    Gender VARCHAR(5),
    Dependent_Count INT,
    Education_Level VARCHAR(50),
    Marital_Status VARCHAR(20),
    State_cd VARCHAR(50),
    Zipcode VARCHAR(20),
    Car_Owner VARCHAR(5),
    House_Owner VARCHAR(5),
    Personal_Loan VARCHAR(5),
    Contact VARCHAR(50),
    Customer_Job VARCHAR(50),
    Income INT,
    Cust_Satisfaction_Score INT
);

-- 3. Import initial batch data from CSV files
COPY cc_detail
FROM 'credit_card.csv' 
DELIMITER ',' 
CSV HEADER;

COPY cust_detail
FROM 'customer.csv' 
DELIMITER ',' 
CSV HEADER;

-- 4. Import weekly incremental data updates (Week 53)
COPY cc_detail
FROM 'cc_add.csv' 
DELIMITER ',' 
CSV HEADER;

COPY cust_detail
FROM 'cust_add.csv' 
DELIMITER ',' 
CSV HEADER;

-- ==============================================================================
-- 5. Core Business Analytical Queries
-- ==============================================================================

-- 5.1 Overall Portfolio KPIs
SELECT 
    COUNT(DISTINCT Client_Num) AS total_customers,
    SUM(Total_Trans_Amt + Interest_Earned + Annual_Fees) AS total_revenue,
    SUM(Total_Trans_Amt) AS total_transaction_amount,
    SUM(Total_Trans_Ct) AS total_transaction_count,
    SUM(Interest_Earned) AS total_interest_earned,
    SUM(Customer_Acq_Cost) AS total_cac,
    ROUND(AVG(Avg_Utilization_Ratio) * 100, 2) AS avg_utilization_percentage
FROM cc_detail;

-- 5.2 Card Category Performance
SELECT 
    Card_Category,
    COUNT(DISTINCT Client_Num) AS customer_count,
    SUM(Total_Trans_Amt + Interest_Earned + Annual_Fees) AS total_revenue,
    SUM(Total_Trans_Ct) AS total_transactions,
    ROUND(AVG(Credit_Limit), 2) AS avg_credit_limit
FROM cc_detail
GROUP BY Card_Category
ORDER BY total_revenue DESC;

-- 5.3 Demographic Analysis (Age Groups)
SELECT 
    CASE 
        WHEN c.Customer_Age < 30 THEN '20-30'
        WHEN c.Customer_Age BETWEEN 30 AND 39 THEN '30-40'
        WHEN c.Customer_Age BETWEEN 40 AND 49 THEN '40-50'
        WHEN c.Customer_Age BETWEEN 50 AND 59 THEN '50-60'
        ELSE '60+' 
    END AS age_group,
    COUNT(DISTINCT c.Client_Num) AS customer_count,
    SUM(cc.Total_Trans_Amt + cc.Interest_Earned + cc.Annual_Fees) AS total_revenue,
    SUM(cc.Total_Trans_Ct) AS total_transactions
FROM cust_detail c
JOIN cc_detail cc ON c.Client_Num = cc.Client_Num
GROUP BY age_group
ORDER BY total_revenue DESC;

-- 5.4 Delinquency Rate
SELECT 
    COUNT(*) AS total_accounts,
    SUM(CASE WHEN Delinquent_Acc = '1' THEN 1 ELSE 0 END) AS delinquent_accounts,
    ROUND(SUM(CASE WHEN Delinquent_Acc = '1' THEN 1.0 ELSE 0.0 END) * 100.0 / COUNT(*), 2) AS delinquency_rate_pct
FROM cc_detail;
