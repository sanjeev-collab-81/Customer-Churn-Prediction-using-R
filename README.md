# Customer Churn Prediction Model

A machine learning project in R that predicts which customers are likely to leave a service. It trains and compares two classification models, evaluates them with ROC/AUC, identifies the main drivers of churn, and presents the results in a polished R Markdown report.

## Problem Statement

Subscription and service businesses lose revenue when customers cancel, but many only notice churn after it happens. Without an early-warning system, retention efforts are reactive and poorly targeted. This project predicts churn risk for each customer and shows which factors (contract type, tenure, pricing, support usage) push customers to leave.

## Objectives

1. Clean and prepare customer account data for modeling.
2. Train and compare a logistic regression model and a random forest classifier.
3. Evaluate models using a confusion matrix, ROC curve, and AUC score.
4. Identify the top features that drive churn.
5. Turn the findings into practical retention recommendations.

## Tech Stack

| Purpose | Tool |
|---|---|
| Language | R |
| Data wrangling | `dplyr`, `tidyr` |
| Modeling | `tidymodels` (or `caret`), `randomForest` |
| Evaluation | `yardstick`, `pROC` |
| Visualization | `ggplot2` |
| Reporting | R Markdown (`rmarkdown`, `knitr`) |

## Project Structure

```
customer-churn-prediction/
├── data/
│   └── churn_data.csv        # Synthetic dataset (~2,000 customers)
├── R/
│   ├── data_prep.R           # Cleaning, encoding, train/test split
│   └── train_model.R         # Model training and evaluation
├── models/
│   └── model.rds             # Saved final model
├── churn_report.Rmd          # R Markdown report source
├── churn_report.html         # Final knitted report
├── screenshots/              # Report screenshots
└── README.md
```

## Dataset

The dataset is synthetic and mimics the well-known Telco Customer Churn data, with ~2,000 customers.

| Column | Description |
|---|---|
| `customer_id` | Unique customer ID |
| `tenure_months` | Months as a customer |
| `contract_type` | Month-to-month, One year, Two year |
| `monthly_charges` | Monthly bill amount |
| `total_charges` | Total amount billed |
| `internet_service` | DSL, Fiber optic, None |
| `tech_support` | Yes / No |
| `payment_method` | Payment type |
| `senior_citizen` | Yes / No |
| `partner` | Yes / No |
| `dependents` | Yes / No |
| `churn` | Target variable (Yes / No) |

Built-in patterns: month-to-month contracts, no tech support, and high monthly charges raise churn probability, while long tenure and two-year contracts lower it. Random noise keeps the data realistic.

## Methodology

1. **Data preparation:** clean missing values, encode categorical variables, split into training and test sets.
2. **Model training:** fit logistic regression and random forest models.
3. **Evaluation:** compare models using accuracy, precision, recall, confusion matrix, ROC curve, and AUC.
4. **Feature importance:** rank the variables that most influence churn.
5. **Reporting:** summarize the results and recommendations in R Markdown.

## How to Run

**1. Install the required packages** (run once in R):

```r
install.packages(c("tidyverse", "tidymodels", "randomForest", "yardstick",
                   "pROC", "rmarkdown", "knitr"))
```

**2. Prepare the data and train the models:**

```r
source("R/data_prep.R")
source("R/train_model.R")
```

**3. Knit the report:**

```r
rmarkdown::render("churn_report.Rmd")
```

Open `churn_report.html` in your browser to view the result.

## Results

> Fill this in after you run the project, using your real numbers. Example format:
> | Model | Accuracy | AUC |
> |---|---|---|
> | Logistic Regression | XX% | 0.XX |
> | Random Forest | XX% | 0.XX |
>
> **Top churn drivers:** contract type, tenure, monthly charges.

## Business Recommendations

- Offer retention deals to month-to-month customers, who are the highest-risk group.
- Bundle tech support for high-risk customers.
- Run early-engagement campaigns for new customers in their first months.
- Review pricing for high monthly-charge segments.

## Screenshots

> Add your report screenshots here, e.g.:
> `![ROC Curve](screenshots/roc_curve.png)`
> `![Feature Importance](screenshots/feature_importance.png)`

## Skills Demonstrated

- Data cleaning and preprocessing
- Supervised machine learning (classification)
- Model evaluation with ROC/AUC and confusion matrices
- Feature importance analysis
- Reproducible reporting with R Markdown

## Author

**sanjeev-collab-81**
GitHub: [@sanjeev-collab-81](https://github.com/sanjeev-collab-81)
