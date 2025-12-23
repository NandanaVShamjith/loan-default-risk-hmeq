# HMEQ Loan Default Analysis  
**SQL | Power BI | Python | Streamlit | SHAP**

---

## Project Overview
This project analyzes loan default behavior using the **HMEQ (Home Equity Loan)** dataset.  
The objective is to understand **credit risk patterns** and support **better lending decisions** using data.

The project combines:
- **Dashboard analysis** for portfolio-level understanding  
- **SQL analysis** for business logic and policy evaluation  
- **Python modeling** for default risk prediction  
- **SHAP explainability** to interpret model predictions  
- **Streamlit application** for interactive analysis  

---

## Problem Statement
Financial institutions need to:
- Identify borrowers with higher default risk  
- Avoid overly strict rules that reduce good loan approvals  
- Understand whether defaults are driven by a few extreme cases or spread across the portfolio  

This project focuses on answering these questions using data.

---

## Dataset
**Dataset:** HMEQ – Home Equity Loan Data  

Key information includes:
- Loan and collateral details  
- Borrower financial health and credit history  
- Employment stability and loan purpose  
- Target variable: **BAD** (1 = Default, 0 = Non-default)  

The dataset contains **missing values and imbalanced classes**, making it realistic for credit risk analysis.

---

## Analytical Approach

### Dashboard (Power BI)
- Analyzed overall default rate and portfolio composition  
- Identified risk distribution by loan purpose, DTI bands, delinquency, and job category  

### SQL Analysis
- Performed multi-factor risk analysis  
- Identified default risk thresholds (e.g., DTI tipping point)  
- Conducted what-if policy simulations  
- Analyzed portfolio-wide risk concentration  

### Python Modeling
- Cleaned and prepared the data  
- Built a loan default prediction model  
- Evaluated model performance using **Recall** and **ROC-AUC**  
- Identified key risk drivers influencing default behavior  

### Model Explainability (SHAP)
- Applied SHAP to interpret model predictions  
- Analyzed global feature impact on default risk  
- Explained individual borrower predictions using feature contributions  
- Improved transparency and trust in model decisions  

### Streamlit Application
- Built an interactive web app to explore the dataset and model results  
- Displayed key metrics, predictions, and SHAP explanations dynamically  
- Enabled user-driven analysis without writing SQL or Python code  

---

## Dashboard Preview
Download excel: https://docs.google.com/spreadsheets/d/1ILUQMn81NASUBZdbUJ11WxBrjMnX9Y1m/edit?usp=sharing&ouid=112297748960358732049&rtpof=true&sd=true

---

## Key Insights
- Overall default rate is **below 10%**, indicating a moderately healthy portfolio  
- Most defaults come from **medium-risk, high-volume segments**, not extreme cases  
- Default risk increases sharply beyond certain thresholds (e.g., high DTI)  
- Combining multiple risk signals is more predictive than single indicators  
- Defaults are spread across the portfolio rather than concentrated in a few borrowers  

---

## Tools Used
- **SQL Server**  
- **Python:** Pandas, Scikit-learn, SHAP  
- **Power BI**  
- **Streamlit**  

---

## Outcome
This project demonstrates how **data analytics, explainable machine learning, and interactive applications** can support credit risk decision-making by combining descriptive analysis, business logic, predictive modeling, and model transparency.

---

## Author
**Nandana V Shamjith**  
Data Analytics & Business Intelligence Portfolio Project
