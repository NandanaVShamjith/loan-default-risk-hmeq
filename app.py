import streamlit as st
import pandas as pd
import numpy as np
import shap
import matplotlib.pyplot as plt
from PIL import Image
import json
import joblib
import tensorflow as tf
import io
from tensorflow.keras.models import load_model

# Safe model loader to fix pop error
def safe_load_model(path):
    try:
        tf.keras.backend.clear_session()
    except:
        pass
    return load_model(path, compile=False)

# Load model & preprocessor
best_model = safe_load_model("best_model.keras")
preprocessor = joblib.load("preprocessor.pkl")

# Load feature names
with open("feature_names.json", "r") as f:
    clean_feature_names = json.load(f)

# SHAP background setup
df = pd.read_csv("C:/Users/nandana/Downloads/hmeq.csv")
df = df.dropna(subset=['BAD'])
X = df.drop('BAD', axis=1)
Y = df['BAD']

from sklearn.model_selection import train_test_split
from imblearn.over_sampling import SMOTE

X_train_raw, _, Y_train, _ = train_test_split(X, Y, test_size=0.2, random_state=42)
X_train_processed = preprocessor.transform(X_train_raw)
sm = SMOTE(random_state=42)
X_train_bal, Y_train_bal = sm.fit_resample(X_train_processed, Y_train)
background = X_train_bal[:100]
explainer = shap.KernelExplainer(best_model.predict, background)

# UI Setup
image = Image.open("C:/Users/nandana/Desktop/loan_prediction/loan.jfif")
image = image.crop(image.getbbox())
image = image.resize((100, 100))
col1, col2, col3 = st.columns([4, 1, 4])
with col2:
    st.image(image)

st.title("Loan Default Prediction App")
st.sidebar.header("Applicant Information")

# Dataset description
with st.expander("📘 About the Dataset"):
    st.markdown("""
| Column     | Meaning                            |
|------------|-------------------------------------|
| **LOAN**   | Requested loan amount               |
| **MORTDUE**| Current mortgage due                |
| **VALUE**  | Property value                      |
| **YOJ**    | Years at current job                |
| **DEROG**  | Major negative credit reports       |
| **DELINQ** | Delinquent credit lines             |
| **CLAGE**  | Oldest credit line (months)         |
| **NINQ**   | Recent credit inquiries             |
| **CLNO**   | Total number of credit lines        |
| **DEBTINC**| Debt-to-income ratio                |
| **REASON** | Loan reason: DebtCon or HomeImp     |
| **JOB**    | Job type: Mgr, ProfExe, etc.        |
| **BAD**    | 1 = Defaulted, 0 = No Default       |
""")

# Sidebar inputs
def get_user_input():
    LOAN = st.sidebar.number_input("Loan Amount", value=10000)
    MORTDUE = st.sidebar.number_input("Mortgage Due", value=80000)
    VALUE = st.sidebar.number_input("Property Value", value=110000)
    YOJ = st.sidebar.number_input("Years at Job", value=10)
    DEROG = st.sidebar.number_input("Derogatory Reports", value=0)
    DELINQ = st.sidebar.number_input("Delinquencies", value=1)
    CLAGE = st.sidebar.number_input("Credit Age", value=150)
    NINQ = st.sidebar.number_input("Recent Credit Inquiries", value=1)
    CLNO = st.sidebar.number_input("Number of Credit Lines", value=20)
    DEBTINC = st.sidebar.number_input("Debt to Income Ratio", value=30.0)
    REASON = st.sidebar.selectbox("Reason", ["DebtCon", "HomeImp"])
    JOB = st.sidebar.selectbox("Job Type", ["Mgr", "Office", "Other", "ProfExe", "Sales", "Self"])

    return pd.DataFrame({
        'LOAN': [LOAN], 'MORTDUE': [MORTDUE], 'VALUE': [VALUE], 'YOJ': [YOJ], 'DEROG': [DEROG],
        'DELINQ': [DELINQ], 'CLAGE': [CLAGE], 'NINQ': [NINQ], 'CLNO': [CLNO], 'DEBTINC': [DEBTINC],
        'REASON': [REASON], 'JOB': [JOB]
    })

input_df = get_user_input()
sample_processed = preprocessor.transform(input_df)
if hasattr(sample_processed, "toarray"):
    sample_processed = sample_processed.toarray()

# Predict
if st.button("Predict"):
    prob = best_model.predict(sample_processed)[0][0]
    prediction = int(prob > 0.5)

    st.subheader(" Prediction Result")
    st.write(f"**Predicted probability of default:** {prob:.2%}")
    st.progress(int(prob * 100))

    confidence = abs(prob - 0.5) * 2
    st.markdown(f"**Model Confidence:** {confidence:.2%}")
    if confidence > 0.75:
        st.success("🟢 High confidence in prediction")
    elif confidence > 0.5:
        st.info("🟡 Moderate confidence in prediction")
    else:
        st.warning("🔴 Low confidence — borderline case")

    if prediction == 0:
        st.success("✅ **Result:** Loan can be granted (Good borrower)")
    else:
        st.error("❌ **Result:** High risk of default (Loan not recommended)")

    # SHAP
    st.markdown("###  Why did the model predict this?")
    st.markdown("""
This SHAP waterfall chart breaks down the impact of each feature:
- 🔵 *Blue bars*: Reduced the risk
- 🔴 *Red bars*: Increased the risk
""")

    shap_vals = explainer.shap_values(sample_processed)[0].flatten()
    base_value = explainer.expected_value
    input_features = sample_processed[0].flatten()

    expl = shap.Explanation(
        values=shap_vals,
        base_values=base_value,
        data=input_features,
        feature_names=clean_feature_names
    )

    fig = plt.figure(figsize=(12, 6))
    shap.plots.waterfall(expl, show=False)
    plt.tight_layout()
    st.pyplot(fig)

    # Most influential features
    st.markdown(f" **Most positive factor:** `{clean_feature_names[np.argmax(shap_vals)]}`")
    st.markdown(f" **Most negative factor:** `{clean_feature_names[np.argmin(shap_vals)]}`")

    top_n = 5
    top_pos = np.argsort(shap_vals)[-top_n:][::-1]
    top_neg = np.argsort(shap_vals)[:top_n]

    positive_explanations = [f"- 🔴 **{clean_feature_names[i]}** increased the risk" for i in top_pos if shap_vals[i] > 0]
    negative_explanations = [f"- 🔵 **{clean_feature_names[i]}** reduced the risk" for i in top_neg if shap_vals[i] < 0]

    if prediction == 1:
        st.markdown("The model predicted **High Risk of Default** due to:")
    else:
        st.markdown("The model predicted **Low Risk of Default** due to:")

    for reason in positive_explanations + negative_explanations:
        st.markdown(reason)

    # Downloadable report
    report = f"""
Loan Default Prediction Report
==============================

Prediction: {'❌ High Risk of Default' if prediction else '✅ Loan Can Be Granted'}
Probability of Default: {prob:.2%}
Model Confidence: {confidence:.2%}

Top Risk Increasing Factors:
{chr(10).join(positive_explanations)}

Top Risk Reducing Factors:
{chr(10).join(negative_explanations)}

Input Data:
{input_df.iloc[0].to_string()}
    """

    st.download_button(
        label=" Download Report",
        data=report,
        file_name="loan_prediction_report.txt",
        mime="text/plain"
    )