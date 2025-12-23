SELECT COUNT(*) AS Total_Rows FROM hmeq;

-- Primary Key
ALTER TABLE hmeq
ADD loan_id INT IDENTITY(1,1);

ALTER TABLE hmeq
ADD CONSTRAINT pk_hmeq PRIMARY KEY (loan_id);


-- veryfying data
EXEC sp_help hmeq;


-- creating indexex
CREATE INDEX idx_hmeq_bad ON hmeq(BAD);
CREATE INDEX idx_hmeq_debtinc ON hmeq(DEBTINC);
CREATE INDEX idx_hmeq_delinqu ON hmeq(DELINQ);

--data checks
SELECT COUNT(*) AS Total_Rows FROM hmeq;
SELECT TOP 10 * FROM hmeq;
SELECT TOP 10 * FROM hmeq;
SELECT
    SUM(CASE WHEN DEBTINC IS NULL THEN 1 ELSE 0 END) AS Missing_DTI,
    SUM(CASE WHEN YOJ IS NULL THEN 1 ELSE 0 END) AS Missing_YOJ,
    SUM(CASE WHEN CLNO IS NULL THEN 1 ELSE 0 END) AS Missing_CLNO
FROM hmeq;

-- checking distribution
SELECT BAD, COUNT(*) AS Count
FROM hmeq
GROUP BY BAD;

-- checking primary key
SELECT 
    tc.constraint_name,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'hmeq'
  AND tc.constraint_type = 'PRIMARY KEY';

  -- Business quries

  --Combined Risk Impact 

-- 1. How does default rate change when High DTI + Delinquency + High Inquiries occur together?

SELECT
    CASE 
        WHEN DEBTINC > 40 
             AND DELINQ > 0 
             AND NINQ >= 3 THEN 'High Combined Risk'
        ELSE 'Other Borrowers'
    END AS Risk_Group,
    COUNT(*) AS Total_Loans,
    SUM(BAD) AS Defaults,
    ROUND(100.0 * SUM(BAD) / COUNT(*), 2) AS Default_Rate_Pct
FROM hmeq
WHERE DEBTINC IS NOT NULL
GROUP BY 
    CASE 
        WHEN DEBTINC > 40 
             AND DELINQ > 0 
             AND NINQ >= 3 THEN 'High Combined Risk'
        ELSE 'Other Borrowers'
    END;

--Insight

--Borrowers who simultaneously have high DTI, prior delinquency, and multiple credit inquiries default at ~5.6× the rate of normal borrowers.
	
	--2.Unexpected Defaults (Low-Risk Profiles That Still Default)

-- Which borrowers defaulted despite low apparent risk?

SELECT
    COUNT(*) AS Unexpected_Defaults
FROM hmeq
WHERE BAD = 1
  AND DEBTINC < 30
  AND DELINQ = 0
  AND DEROG = 0;
  -- comparison
  SELECT
    CASE 
        WHEN DEBTINC < 30 AND DELINQ = 0 AND DEROG = 0 THEN 'Low Risk'
        ELSE 'Other'
    END AS Risk_Type,
    COUNT(*) AS Loans,
    SUM(BAD) AS Defaults
FROM hmeq
GROUP BY
    CASE 
        WHEN DEBTINC < 30 AND DELINQ = 0 AND DEROG = 0 THEN 'Low Risk'
        ELSE 'Other'
    END;
--Insight

-- Even “clean” borrowers can default — risk is not fully captured by traditional metrics.

-- 3. Exact DTI Threshold Where Default Rises (NOT Bands)

-- At what DTI range does default spike?

SELECT
    FLOOR(DEBTINC / 5) * 5 AS DTI_Range_Start,
    COUNT(*) AS Loans,
    SUM(BAD) AS Defaults,
    ROUND(100.0 * SUM(BAD) / COUNT(*), 2) AS Default_Rate_Pct
FROM hmeq
WHERE DEBTINC IS NOT NULL
GROUP BY FLOOR(DEBTINC / 5) * 5
ORDER BY DTI_Range_Start;
--Insight
-- Default risk accelerates sharply after ~40% DTI, suggesting a true cutoff point.


-- 4. Default Risk with Negative / Low Home Equity

-- Do borrowers with low or negative home equity default more?

SELECT
    CASE 
        WHEN (VALUE - MORTDUE) <= 0 THEN 'Negative / No Equity'
        WHEN (VALUE - MORTDUE) < 20000 THEN 'Low Equity'
        ELSE 'Healthy Equity'
    END AS Equity_Group,
    COUNT(*) AS Loans,
    SUM(BAD) AS Defaults,
    ROUND(100.0 * SUM(BAD) / COUNT(*), 2) AS Default_Rate_Pct
FROM hmeq
WHERE VALUE IS NOT NULL AND MORTDUE IS NOT NULL
GROUP BY
    CASE 
        WHEN (VALUE - MORTDUE) <= 0 THEN 'Negative / No Equity'
        WHEN (VALUE - MORTDUE) < 20000 THEN 'Low Equity'
        ELSE 'Healthy Equity'
    END;
--Insight
-- Lower or negative home equity strongly correlates with higher default risk.

-- 5. Loan-to-Value (LTV) vs Default

-- Is default driven more by LTV than loan amount?

SELECT
    CASE
        WHEN LOAN / VALUE >= 0.8 THEN 'High LTV'
        WHEN LOAN / VALUE >= 0.6 THEN 'Medium LTV'
        ELSE 'Low LTV'
    END AS LTV_Category,
    COUNT(*) AS Loans,
    SUM(BAD) AS Defaults,
    ROUND(100.0 * SUM(BAD) / COUNT(*), 2) AS Default_Rate_Pct
FROM hmeq
WHERE VALUE IS NOT NULL AND LOAN IS NOT NULL
GROUP BY
    CASE
        WHEN LOAN / VALUE >= 0.8 THEN 'High LTV'
        WHEN LOAN / VALUE >= 0.6 THEN 'Medium LTV'
        ELSE 'Low LTV'
    END;
--Insight
--High LTV is still risky per borrower
--Low LTV dominates portfolio volume
--Risk concentration ≠ individual risk

-- 6. Over-Approved High-Risk Segments

-- Which borrower segments get larger loans despite higher default risk?

SELECT
    REASON,
    COUNT(*) AS Loans,
    ROUND(AVG(LOAN), 0) AS Avg_Loan_Amount,
    ROUND(100.0 * SUM(BAD) / COUNT(*), 2) AS Default_Rate_Pct
FROM hmeq
GROUP BY REASON
HAVING COUNT(*) > 50
ORDER BY Default_Rate_Pct DESC;
--Insight
-- Home Improvement loans show higher default despite meaningful loan sizes.

-- 7. Defaults Without Prior Delinquency History
-- How many defaults occur without warning signs?

SELECT
    COUNT(*) AS Defaults_No_History
FROM hmeq
WHERE BAD = 1
  AND DELINQ = 0
  AND DEROG = 0;

  -- comparison
  SELECT
    CASE 
        WHEN DELINQ = 0 AND DEROG = 0 THEN 'No Prior Issues'
        ELSE 'With Prior Issues'
    END AS History_Type,
    COUNT(*) AS Defaults
FROM hmeq
WHERE BAD = 1
GROUP BY
    CASE 
        WHEN DELINQ = 0 AND DEROG = 0 THEN 'No Prior Issues'
        ELSE 'With Prior Issues'
    END;
--Insight
-- 37% of defaults occurred without prior warning signs.

	--8. Default Concentration (Pareto 80/20)
-- Do a small % of borrowers contribute most defaults?

WITH ranked_defaults AS (
    SELECT
        LOAN,
        ROW_NUMBER() OVER (ORDER BY LOAN DESC) AS rn,
        COUNT(*) OVER () AS total_defaults,
        COUNT(*) OVER (
            ORDER BY LOAN DESC 
            ROWS UNBOUNDED PRECEDING
        ) AS cumulative_defaults
    FROM hmeq
    WHERE BAD = 1
)
SELECT
    rn,
    cumulative_defaults,
    total_defaults,
    ROUND(100.0 * cumulative_defaults / total_defaults, 2) 
        AS Cumulative_Default_Pct
FROM ranked_defaults;
-- Observation
-- The first ~20% of defaulted loans do NOT account for ~80% of defaults
-- Default accumulation is spread across many borrowers
-- Pareto rule does NOT strongly hold in this dataset.

-- Insights
--Defaults are not highly concentrated among a small group of borrowers.
-- Instead, credit risk is diffuse across the portfolio, meaning:
-- Losses come from many moderate-risk borrowers
-- Not from a few extreme high-risk cases

--9. What-If Policy Rule (Preventable Defaults)
-- If loans with DTI > 40 & DELINQ > 0 were rejected, how many defaults would be avoided?

SELECT
    COUNT(*) AS Preventable_Defaults
FROM hmeq
WHERE BAD = 1
  AND DEBTINC > 40
  AND DELINQ > 0;
 -- insights
 --59 defaults could have been avoided

  --10. Does employment stability reduce default risk?
SELECT
    CASE 
        WHEN YOJ < 1 THEN 'New Job (<1 yr)'
        WHEN YOJ BETWEEN 1 AND 5 THEN 'Mid Stability (1-5 yrs)'
        ELSE 'High Stability (5+ yrs)'
    END AS Job_Stability,
    COUNT(*) AS Loans,
    SUM(BAD) AS Defaults,
    ROUND(100.0 * SUM(BAD) / COUNT(*), 2) AS Default_Rate_Pct
FROM hmeq
WHERE YOJ IS NOT NULL
GROUP BY
    CASE 
        WHEN YOJ < 1 THEN 'New Job (<1 yr)'
        WHEN YOJ BETWEEN 1 AND 5 THEN 'Mid Stability (1-5 yrs)'
        ELSE 'High Stability (5+ yrs)'
    END;

--Insight
-- Longer job tenure → lower default risk

--11. Are borrowers with many credit lines riskier?
SELECT
    CASE
        WHEN CLNO >= 15 THEN 'Very High Credit Exposure'
        WHEN CLNO BETWEEN 8 AND 14 THEN 'High Credit Exposure'
        ELSE 'Low / Moderate Exposure'
    END AS Credit_Exposure,
    COUNT(*) AS Loans,
    SUM(BAD) AS Defaults,
    ROUND(100.0 * SUM(BAD) / COUNT(*), 2) AS Default_Rate_Pct
FROM hmeq
WHERE CLNO IS NOT NULL
GROUP BY
    CASE
        WHEN CLNO >= 15 THEN 'Very High Credit Exposure'
        WHEN CLNO BETWEEN 8 AND 14 THEN 'High Credit Exposure'
        ELSE 'Low / Moderate Exposure'
    END;
--Insight
-- Moderate credit exposure is healthiest
-- Very high exposure does not always worsen risk linearly