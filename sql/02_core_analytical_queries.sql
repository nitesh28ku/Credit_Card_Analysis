-- ==============================================================================
-- Project: Credit Card Financial & Customer Analytics
-- Author: Nitesh Kumar (https://github.com/nitesh28ku)
-- Description: Core analytical queries and business performance metrics
-- ==============================================================================

-- -----------------------------------------------------------------------------
-- 1. Executive Summary: High-Level Portfolio KPIs
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(DISTINCT Client_Num) AS total_customers,
    SUM(Total_Trans_Amt + Interest_Earned + Annual_Fees) AS total_revenue,
    SUM(Total_Trans_Amt) AS total_transaction_amount,
    SUM(Total_Trans_Ct) AS total_transaction_count,
    SUM(Interest_Earned) AS total_interest_earned,
    SUM(Customer_Acq_Cost) AS total_cac,
    ROUND(AVG(Avg_Utilization_Ratio) * 100, 2) AS avg_utilization_percentage
FROM cc_detail;

-- -----------------------------------------------------------------------------
-- 2. Revenue Contribution by Card Category
-- -----------------------------------------------------------------------------
SELECT 
    Card_Category,
    COUNT(DISTINCT Client_Num) AS customer_count,
    SUM(Total_Trans_Amt + Interest_Earned + Annual_Fees) AS total_revenue,
    ROUND(SUM(Total_Trans_Amt + Interest_Earned + Annual_Fees) * 100.0 / 
          SUM(SUM(Total_Trans_Amt + Interest_Earned + Annual_Fees)) OVER(), 2) AS revenue_share_pct,
    SUM(Total_Trans_Ct) AS total_transactions,
    ROUND(AVG(Credit_Limit), 2) AS avg_credit_limit
FROM cc_detail
GROUP BY Card_Category
ORDER BY total_revenue DESC;

-- -----------------------------------------------------------------------------
-- 3. Revenue Breakdown by Expenditure Category
-- -----------------------------------------------------------------------------
SELECT 
    Exp_Type,
    SUM(Total_Trans_Amt + Interest_Earned + Annual_Fees) AS total_revenue,
    ROUND(SUM(Total_Trans_Amt + Interest_Earned + Annual_Fees) * 100.0 / 
          SUM(SUM(Total_Trans_Amt + Interest_Earned + Annual_Fees)) OVER(), 2) AS expenditure_share_pct,
    SUM(Total_Trans_Ct) AS total_transactions
FROM cc_detail
GROUP BY Exp_Type
ORDER BY total_revenue DESC;

-- -----------------------------------------------------------------------------
-- 4. Revenue by Transaction Method / Card Use Channel
-- -----------------------------------------------------------------------------
SELECT 
    Use_Chip AS swipe_method,
    SUM(Total_Trans_Amt + Interest_Earned + Annual_Fees) AS total_revenue,
    ROUND(SUM(Total_Trans_Amt + Interest_Earned + Annual_Fees) * 100.0 / 
          SUM(SUM(Total_Trans_Amt + Interest_Earned + Annual_Fees)) OVER(), 2) AS method_share_pct,
    SUM(Total_Trans_Ct) AS total_transactions
FROM cc_detail
GROUP BY Use_Chip
ORDER BY total_revenue DESC;

-- -----------------------------------------------------------------------------
-- 5. Customer Age Bracket Analysis
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- 6. Customer Demographics: Gender & Income Group Breakdown
-- -----------------------------------------------------------------------------
SELECT 
    c.Gender,
    CASE 
        WHEN c.Income >= 70000 THEN 'High Income'
        WHEN c.Income BETWEEN 35000 AND 69999 THEN 'Med Income'
        ELSE 'Low Income'
    END AS income_tier,
    COUNT(DISTINCT c.Client_Num) AS total_customers,
    SUM(cc.Total_Trans_Amt + cc.Interest_Earned + cc.Annual_Fees) AS total_revenue,
    ROUND(AVG(c.Cust_Satisfaction_Score), 2) AS avg_satisfaction_score
FROM cust_detail c
JOIN cc_detail cc ON c.Client_Num = cc.Client_Num
GROUP BY c.Gender, income_tier
ORDER BY total_revenue DESC;

-- -----------------------------------------------------------------------------
-- 7. Geographic Performance: Top 5 Revenue-Generating States
-- -----------------------------------------------------------------------------
SELECT 
    c.State_cd,
    COUNT(DISTINCT c.Client_Num) AS customer_count,
    SUM(cc.Total_Trans_Amt + cc.Interest_Earned + cc.Annual_Fees) AS total_revenue,
    SUM(cc.Total_Trans_Ct) AS total_transactions
FROM cust_detail c
JOIN cc_detail cc ON c.Client_Num = cc.Client_Num
GROUP BY c.State_cd
ORDER BY total_revenue DESC
LIMIT 5;

-- -----------------------------------------------------------------------------
-- 8. Portfolio Risk: Delinquency Metrics
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(*) AS total_accounts,
    SUM(CASE WHEN Delinquent_Acc = '1' THEN 1 ELSE 0 END) AS delinquent_accounts,
    ROUND(SUM(CASE WHEN Delinquent_Acc = '1' THEN 1.0 ELSE 0.0 END) * 100.0 / COUNT(*), 2) AS delinquency_rate_pct,
    ROUND(AVG(Cust_Satisfaction_Score), 2) AS overall_avg_css
FROM cc_detail cc
JOIN cust_detail c ON cc.Client_Num = c.Client_Num;
