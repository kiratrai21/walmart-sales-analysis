Walmart Sales Analysis (SQL Server)
Overview

This project analyzes Walmart retail sales data using Microsoft SQL Server, with data cleaning and feature engineering performed in pandas. The analysis progresses from basic exploratory queries to time-series performance evaluation, focusing on branch-level growth and stability.

Objectives

Understand sales distribution across branches, categories, and payment methods

Identify high-performing and underperforming branches

Analyze revenue and profit trends over time

Evaluate month-over-month growth and revenue volatility

Tools & Technologies

Python (pandas) – data cleaning, date/time normalization, feature engineering

Microsoft SQL Server – analytical querying

SQL features used: CTEs, window functions (RANK, LAG), aggregations

Key Analyses

Exploratory Analysis

Payment method usage and sales quantity

Highest-rated categories by branch

Busiest days and time-of-day sales patterns

Profit contribution by product category

Time-Series Analysis

Monthly revenue and profit by branch

Month-over-month (MoM) revenue growth

Average MoM growth to classify growing vs declining branches

Revenue volatility to assess branch stability

Key Insights

Some high-revenue branches show negative or inconsistent MoM growth, indicating potential performance risks

Revenue growth patterns vary significantly by branch, highlighting uneven operational performance

Volatility analysis reveals branches with unstable revenue trends, which may require closer monitoring