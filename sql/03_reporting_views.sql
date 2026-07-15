-- ==============================================================================
-- Project: Credit Card Financial & Customer Analytics
-- Author: Nitesh Kumar (https://github.com/nitesh28ku)
-- Description: Performance optimization, database indexes, and reporting views
-- ==============================================================================

-- -----------------------------------------------------------------------------
-- 1. Performance Indexes
-- Optimize joins, range lookups, and aggregation performance
-- -----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_cc_client_num ON cc_detail (Client_Num);
CREATE INDEX IF NOT EXISTS idx_cust_client_num ON cust_detail (Client_Num);
CREATE INDEX IF NOT EXISTS idx_cc_card_category ON cc_detail (Card_Category);
CREATE INDEX IF NOT EXISTS idx_cc_week_start ON cc_detail (Week_Start_Date);
CREATE INDEX IF NOT EXISTS idx_cust_state ON cust_detail (State_cd);
CREATE INDEX IF NOT EXISTS idx_cc_exp_type ON cc_detail (Exp_Type);

-- -----------------------------------------------------------------------------
-- 2. View: Weekly Revenue & Week-over-Week (WoW) Growth
-- Utilizes window functions (LAG and Moving Average) for trend analysis
-- -----------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_weekly_kpis;
CREATE VIEW vw_weekly_kpis AS
WITH weekly_totals AS (
    SELECT 
        Week_Num,
        Week_Start_Date,
        current_year,
        SUM(Total_Trans_Amt + Interest_Earned + Annual_Fees) AS weekly_revenue,
        SUM(Total_Trans_Ct) AS weekly_transactions,
        SUM(Total_Trans_Amt) AS weekly_trans_volume,
        ROUND(AVG(Avg_Utilization_Ratio) * 100, 2) AS weekly_avg_utilization
    FROM cc_detail
    GROUP BY Week_Num, Week_Start_Date, current_year
)
SELECT 
    Week_Num,
    Week_Start_Date,
    current_year,
    weekly_revenue,
    weekly_transactions,
    weekly_trans_volume,
    weekly_avg_utilization,
    LAG(weekly_revenue, 1) OVER (ORDER BY Week_Start_Date) AS prior_week_revenue,
    ROUND(
        (weekly_revenue - LAG(weekly_revenue, 1) OVER (ORDER BY Week_Start_Date)) * 100.0 /
        NULLIF(LAG(weekly_revenue, 1) OVER (ORDER BY Week_Start_Date), 0),
        2
    ) AS wow_revenue_growth_pct,
    ROUND(
        AVG(weekly_revenue) OVER (
            ORDER BY Week_Start_Date 
            ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS rolling_4week_avg_revenue
FROM weekly_totals;

-- -----------------------------------------------------------------------------
-- 3. View: Consolidated Customer Portfolio Analytics Mart
-- Clean multi-table join with edge-case null handling and categorical tiers
-- -----------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_customer_portfolio_summary;
CREATE VIEW vw_customer_portfolio_summary AS
SELECT 
    c.Client_Num,
    c.Customer_Age,
    CASE 
        WHEN c.Customer_Age < 30 THEN '20-30'
        WHEN c.Customer_Age BETWEEN 30 AND 39 THEN '30-40'
        WHEN c.Customer_Age BETWEEN 40 AND 49 THEN '40-50'
        WHEN c.Customer_Age BETWEEN 50 AND 59 THEN '50-60'
        ELSE '60+' 
    END AS age_bracket,
    c.Gender,
    c.Dependent_Count,
    COALESCE(NULLIF(c.Education_Level, 'Unknown'), 'Unspecified') AS education_level,
    c.Marital_Status,
    c.State_cd,
    c.Customer_Job,
    c.Income,
    CASE 
        WHEN c.Income >= 70000 THEN 'High Income'
        WHEN c.Income BETWEEN 35000 AND 69999 THEN 'Med Income'
        ELSE 'Low Income'
    END AS income_group,
    c.Cust_Satisfaction_Score,
    c.Personal_Loan,
    cc.Card_Category,
    cc.Credit_Limit,
    cc.Total_Revolving_Bal,
    (cc.Total_Trans_Amt + cc.Interest_Earned + cc.Annual_Fees) AS total_customer_revenue,
    cc.Total_Trans_Amt,
    cc.Total_Trans_Ct,
    cc.Avg_Utilization_Ratio,
    cc.Use_Chip,
    cc.Exp_Type,
    cc.Delinquent_Acc,
    CASE 
        WHEN cc.Delinquent_Acc = '1' THEN 'At Risk' 
        ELSE 'Good Standing' 
    END AS account_risk_status
FROM cust_detail c
INNER JOIN cc_detail cc ON c.Client_Num = cc.Client_Num;

-- -----------------------------------------------------------------------------
-- 4. View: Delinquency & Credit Risk Monitoring View
-- Identifies portfolio segments with elevated delinquency rates
-- -----------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_delinquency_risk_monitor;
CREATE VIEW vw_delinquency_risk_monitor AS
SELECT 
    Card_Category,
    Exp_Type,
    COUNT(Client_Num) AS total_accounts,
    SUM(CASE WHEN Delinquent_Acc = '1' THEN 1 ELSE 0 END) AS delinquent_accounts,
    ROUND(
        SUM(CASE WHEN Delinquent_Acc = '1' THEN 1.0 ELSE 0.0 END) * 100.0 / COUNT(*),
        2
    ) AS delinquency_rate_pct,
    ROUND(AVG(Total_Revolving_Bal), 2) AS avg_revolving_balance,
    ROUND(AVG(Credit_Limit), 2) AS avg_credit_limit
FROM cc_detail
GROUP BY Card_Category, Exp_Type;
