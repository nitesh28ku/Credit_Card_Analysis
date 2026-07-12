-- ==============================================================================
-- Project: Credit Card Financial & Customer Analytics
-- Author: Nitesh Kumar (https://github.com/nitesh28ku)
-- Description: Core database schema definition and data loading pipelines
-- ==============================================================================

-- -----------------------------------------------------------------------------
-- 1. Create table: cc_detail (Credit Card Transaction & Account Details)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS cc_detail;
CREATE TABLE cc_detail (
    Client_Num             INT,
    Card_Category          VARCHAR(20),
    Annual_Fees            INT,
    Activation_30_Days     INT,
    Customer_Acq_Cost      INT,
    Week_Start_Date        DATE,
    Week_Num               VARCHAR(20),
    Qtr                    VARCHAR(10),
    current_year           INT,
    Credit_Limit           DECIMAL(10, 2),
    Total_Revolving_Bal    INT,
    Total_Trans_Amt        INT,
    Total_Trans_Ct         INT,
    Avg_Utilization_Ratio  DECIMAL(10, 3),
    Use_Chip               VARCHAR(10),
    Exp_Type               VARCHAR(50),
    Interest_Earned        DECIMAL(10, 3),
    Delinquent_Acc         VARCHAR(5)
);

-- -----------------------------------------------------------------------------
-- 2. Create table: cust_detail (Customer Demographic & Profile Details)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS cust_detail;
CREATE TABLE cust_detail (
    Client_Num              INT,
    Customer_Age            INT,
    Gender                  VARCHAR(5),
    Dependent_Count         INT,
    Education_Level         VARCHAR(50),
    Marital_Status          VARCHAR(20),
    State_cd                VARCHAR(50),
    Zipcode                 VARCHAR(20),
    Car_Owner               VARCHAR(5),
    House_Owner             VARCHAR(5),
    Personal_Loan           VARCHAR(5),
    Contact                 VARCHAR(50),
    Customer_Job            VARCHAR(50),
    Income                  INT,
    Cust_Satisfaction_Score INT
);

-- -----------------------------------------------------------------------------
-- 3. Bulk Data Loading Pipelines (PostgreSQL COPY)
-- -----------------------------------------------------------------------------

-- Import base transactions dataset
COPY cc_detail
FROM 'credit_card.csv' 
DELIMITER ',' 
CSV HEADER;

-- Import base customer demographics dataset
COPY cust_detail
FROM 'customer.csv' 
DELIMITER ',' 
CSV HEADER;

-- -----------------------------------------------------------------------------
-- 4. Incremental Weekly Data Ingestion (e.g. Week 53 updates)
-- -----------------------------------------------------------------------------

-- Ingest incremental transaction updates
COPY cc_detail
FROM 'cc_add.csv' 
DELIMITER ',' 
CSV HEADER;

-- Ingest incremental customer profile updates
COPY cust_detail
FROM 'cust_add.csv' 
DELIMITER ',' 
CSV HEADER;
