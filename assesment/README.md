# SaaS Customer Churn --- Business Insights & Exploratory Data Analysis

## 📌 Project Overview

This project performs a business-focused Exploratory Data Analysis (EDA)
of customer churn for **CloudPulse**, a fictional enterprise B2B SaaS
platform.

CloudPulse is experiencing an increase in customer churn over the last
two quarters. With a **Customer Acquisition Cost (CAC) of \$450** and an
**Average Annual Contract Value (ACV) of \$1,200**, understanding why
customers leave is important for improving retention and protecting
customer lifetime value.

The analysis uses a synthetic customer lifecycle dataset and follows a
structured EDA workflow to identify high-risk customer profiles, churn
drivers, behavioral patterns, and actionable retention opportunities.

## 🎯 Business Objectives

The analysis aims to:

1.  Identify demographic, contractual, and behavioral profiles of
    at-risk customers.
2.  Determine key inflection points such as tenure and support-ticket
    volume where churn accelerates.
3.  Explore relationships between contract type, technical support,
    pricing, customer tenure, and churn.
4.  Engineer features that can act as early-warning indicators of churn.
5.  Translate analytical findings into practical Customer Success
    interventions.

## 📊 Dataset

The notebook generates a synthetic dataset named `saas_churn_data.csv`
containing **1,200 customer records and 9 original columns**.

### Original Features

  -----------------------------------------------------------------------
  Feature                             Description
  ----------------------------------- -----------------------------------
  `Customer_ID`                       Unique customer identifier

  `Tenure_Months`                     Number of months the customer has
                                      been with the company

  `Contract_Type`                     Month-to-Month, One-Year, or
                                      Two-Year contract

  `Payment_Method`                    Electronic Check, Bank Transfer, or
                                      Credit Card

  `Tech_Support`                      Whether the customer has technical
                                      support, including `No internet`

  `Support_Tickets`                   Number of support tickets raised by
                                      the customer

  `Monthly_Charges`                   Monthly customer charges

  `Total_Charges`                     Estimated total customer charges
                                      over the relationship

  `Churn`                             Target variable indicating whether
                                      the customer churned
  -----------------------------------------------------------------------

The synthetic data is generated with a fixed random seed (`42`) to make
the analysis reproducible.

## 🔬 Analysis Workflow

The notebook is organized into the following stages:

### 1. Business Context & Problem Framing

Defines the CloudPulse business problem, analytical objectives, and
structured EDA workflow.

### 2. Data Profiling & Structural Health Audit

Includes:

-   Dataset dimensions and data types
-   Missing-value analysis
-   Descriptive statistics
-   Categorical cardinality
-   Category-level balance

The initial audit identifies **15 missing values in `Total_Charges`
(1.25%)**.

### 3. Univariate Analysis

Examines individual variables using visualizations such as:

-   Churn distribution
-   Monthly-charge histogram and KDE
-   Support-ticket frequency
-   Customer-tenure distribution

### 4. Bivariate Analysis

Investigates relationships between pairs of variables, including:

-   Tenure vs. churn
-   Contract type + technical support vs. churn
-   Monthly charges vs. total charges
-   Pearson and Spearman correlations

### 5. Multivariate Analysis & Segmentation

Uses:

-   Correlation heatmaps
-   Multi-dimensional customer segmentation
-   Contract type
-   Monthly charges
-   Support-ticket activity
-   Churn status

### 6. Missing Value & Outlier Treatment

`Total_Charges` missing values are estimated using:

`Tenure_Months × Monthly_Charges`

This approach preserves customer-specific information instead of
assigning the same mean or median value to every missing observation.

Support-ticket outliers are identified using the **IQR method**.

### 7. Hypothesis-Driven Feature Engineering

Two additional features are created:

#### `Ticket_Velocity`

Measures support-ticket activity relative to customer tenure:

`Support_Tickets / (Tenure_Months + 1)`

#### `High_Risk_Flag`

Flags customers who simultaneously have:

-   A `Month-to-Month` contract
-   `No` technical support

## 💡 Key Business Insights

### 1. Early Lifecycle Customers Are at Higher Risk

Churned customers have a lower median tenure than retained customers.
The notebook identifies the first year of the customer relationship as
an important period for retention.

**Recommended action:**\
Strengthen onboarding, conduct regular early-life customer check-ins,
and collect feedback during the first 12 months.

### 2. Month-to-Month Contracts Are the Highest-Risk Segment

Month-to-Month customers represent the largest contract segment and show
substantially higher churn than customers on longer-term contracts.

The analysis reports churn rates above **84% across the Month-to-Month
technical-support groups**, with the highest rate occurring among
customers without technical support.

**Recommended action:**\
Prioritize Month-to-Month customers for retention campaigns and provide
incentives or additional benefits for moving to One-Year or Two-Year
contracts.

### 3. Very High Support-Ticket Activity Signals Severe Churn Risk

The IQR-based outlier analysis identifies an upper threshold of **6
support tickets**. Customers exceeding this threshold are classified as
ticket-volume outliers.

The notebook reports **14 such customers, with a 100% churn rate**.

**Recommended action:**\
Create an immediate Customer Success escalation for customers exceeding
the support-ticket threshold and investigate unresolved technical or
service problems.

### 4. Ticket Velocity Provides an Early-Warning Signal

Churned customers have higher support-ticket activity relative to their
tenure.

Reported averages:

-   Churned: **0.42**
-   Retained: **0.17**

The median is also higher for churned customers:

-   Churned: **0.20**
-   Retained: **0.07**

**Recommended action:**\
Use Ticket Velocity as an early-warning indicator, particularly for
customers early in their lifecycle.

### 5. Month-to-Month + No Tech Support Is the Highest-Priority Segment

The engineered `High_Risk_Flag` identifies customers who combine a
Month-to-Month contract with no technical support.

The notebook reports:

-   High-risk segment churn: **86.14%**
-   Customers without the flag: **63.99%**
-   Difference: approximately **22 percentage points**

**Recommended action:**\
Prioritize this segment for a combined intervention involving technical
support, stronger onboarding, proactive Customer Success engagement, and
incentives for longer-term contracts.

## 🛠️ Technologies Used

-   **Python 3**
-   **NumPy** --- numerical computation and synthetic data generation
-   **Pandas** --- data manipulation and analysis
-   **Matplotlib** --- data visualization
-   **Seaborn** --- statistical visualization
-   **SciPy** --- statistical analysis
-   **Google Colab / Jupyter Notebook** --- development and execution
    environment

## 📁 Project Structure

``` text
.
├── Day3_Business_Insight.pynb.ipynb
├── saas_churn_data.csv
└── README.md
```

> `saas_churn_data.csv` is generated automatically when the first
> notebook cell is executed.

## ▶️ How to Run

### Option 1 --- Google Colab

1.  Open `Day3_Business_Insight.pynb.ipynb` in Google Colab.
2.  Run the notebook from the first cell onward.
3.  The first cell generates `saas_churn_data.csv`.
4.  Execute the remaining cells sequentially to reproduce the analysis
    and visualizations.

### Option 2 --- Local Jupyter Environment

Install the required libraries:

``` bash
pip install numpy pandas matplotlib seaborn scipy jupyter
```

Then launch Jupyter:

``` bash
jupyter notebook
```

Open the notebook and run all cells in order.

## 📈 Reproducibility

The dataset generation uses:

``` python
np.random.seed(42)
```

This ensures that the synthetic customer dataset can be regenerated
consistently.

## 🚀 Recommended Strategic Interventions

Based on the analysis, CloudPulse should prioritize:

1.  **First-year retention programs**\
    Improve onboarding and increase Customer Success engagement during
    the first 12 months.

2.  **Contract migration campaigns**\
    Encourage Month-to-Month customers to move toward One-Year or
    Two-Year plans.

3.  **High-ticket escalation**\
    Automatically flag customers with unusually high support-ticket
    volume.

4.  **Behavioral churn monitoring**\
    Track Ticket Velocity as an early-warning metric.

5.  **High-risk segment targeting**\
    Combine contract type and technical-support status to prioritize
    retention resources.

## ⚠️ Notes & Limitations

-   The dataset is **synthetic** and is intended for educational,
    portfolio, and analytical demonstration purposes.
-   The relationships in the dataset are generated programmatically and
    should not be interpreted as evidence about real SaaS customers.
-   Correlation and segment-level differences indicate associations;
    they do not by themselves establish causation.
-   The notebook focuses on exploratory and business analysis rather
    than building a production churn-prediction model.

## 📌 Portfolio Summary

This project demonstrates an end-to-end, business-oriented EDA workflow:

**Business Problem → Data Generation → Data Profiling → Univariate
Analysis → Bivariate Analysis → Multivariate Segmentation → Data
Cleaning → Feature Engineering → Strategic Recommendations**

The primary goal is not just to visualize churn, but to convert customer
data into **specific, actionable retention strategies** for a Customer
Success team.
