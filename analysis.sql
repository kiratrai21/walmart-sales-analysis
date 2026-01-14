/* =====================================================
   Walmart Project Queries — MS SQL Server
   ===================================================== */

SELECT * FROM walmart_sales;
GO

/* -----------------------------------------------------
   Basic Checks
   ----------------------------------------------------- */

-- Count total records
SELECT COUNT(*) AS total_records
FROM walmart_sales;
GO

-- Count distinct branches
SELECT COUNT(DISTINCT branch) AS total_branches
FROM walmart_sales;
GO

-- Minimum quantity sold
SELECT MIN(quantity) AS min_quantity
FROM walmart_sales

/* -----------------------------------------------------
   Q1: Payment Method Analysis
   ----------------------------------------------------- */

SELECT
    payment_method,
    COUNT(*) AS no_payments,
    SUM(quantity) AS no_qty_sold
FROM walmart_sales
GROUP BY payment_method;
GO

/* -----------------------------------------------------
   Q2: Highest-Rated Category per Branch
   ----------------------------------------------------- */

SELECT branch, category, avg_rating
FROM (
    SELECT
        branch,
        category,
        AVG(rating) AS avg_rating,
        RANK() OVER (
            PARTITION BY branch
            ORDER BY AVG(rating) DESC
        ) AS rank
    FROM walmart_sales
    GROUP BY branch, category
) ranked
WHERE rank = 1;
GO

/* -----------------------------------------------------
   Q3: Busiest Day per Branch
   ----------------------------------------------------- */

SELECT branch, day_name, no_transactions
FROM (
    SELECT
        branch,
        DATENAME(WEEKDAY, CONVERT(date, [date], 103)) AS day_name,
        COUNT(*) AS no_transactions,
        RANK() OVER (
            PARTITION BY branch
            ORDER BY COUNT(*) DESC
        ) AS rank
    FROM walmart_sales
    GROUP BY
        branch,
        DATENAME(WEEKDAY, CONVERT(date, [date], 103))
) ranked
WHERE rank = 1;
GO

/* -----------------------------------------------------
   Q4: Total Quantity Sold per Payment Method
   ----------------------------------------------------- */

SELECT
    payment_method,
    SUM(quantity) AS no_qty_sold
FROM walmart_sales
GROUP BY payment_method;
GO

/* -----------------------------------------------------
   Q5: Rating Statistics by City and Category
   ----------------------------------------------------- */

SELECT
    city,
    category,
    MIN(rating) AS min_rating,
    MAX(rating) AS max_rating,
    AVG(rating) AS avg_rating
FROM walmart_sales
GROUP BY city, category;
GO

/* -----------------------------------------------------
   Q6: Total Profit by Category
   ----------------------------------------------------- */

SELECT
    category,
    SUM(unit_price * quantity * profit_margin) AS total_profit
FROM walmart_sales
GROUP BY category
ORDER BY total_profit DESC;
GO

/* -----------------------------------------------------
   Q7: Most Common Payment Method per Branch
   ----------------------------------------------------- */

WITH cte AS (
    SELECT
        branch,
        payment_method,
        COUNT(*) AS total_trans,
        RANK() OVER (
            PARTITION BY branch
            ORDER BY COUNT(*) DESC
        ) AS rank
    FROM walmart_sales
    GROUP BY branch, payment_method
)
SELECT
    branch,
    payment_method AS preferred_payment_method
FROM cte
WHERE rank = 1;
GO

/* -----------------------------------------------------
   Q8: Sales by Time of Day (Shift Analysis)
   ----------------------------------------------------- */

SELECT
    branch,
    CASE
        WHEN DATEPART(HOUR, CAST([time] AS time)) < 12 THEN 'Morning'
        WHEN DATEPART(HOUR, CAST([time] AS time)) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS shift,
    COUNT(*) AS num_invoices
FROM walmart_sales
GROUP BY
    branch,
    CASE
        WHEN DATEPART(HOUR, CAST([time] AS time)) < 12 THEN 'Morning'
        WHEN DATEPART(HOUR, CAST([time] AS time)) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END
ORDER BY branch, num_invoices DESC;
GO

/* -----------------------------------------------------
   Q9: Top 5 Branches with Highest Revenue Decrease
        (2022 vs 2023)
   ----------------------------------------------------- */

WITH revenue_2022 AS (
    SELECT
        branch,
        SUM(total_price) AS revenue
    FROM walmart_sales
    WHERE YEAR([date]) = 2022
    GROUP BY branch
),
revenue_2023 AS (
    SELECT
        branch,
        SUM(total_price) AS revenue
    FROM walmart_sales
    WHERE YEAR([date]) = 2023
    GROUP BY branch
)
SELECT TOP 5
    r22.branch,
    r22.revenue AS last_year_revenue,
    r23.revenue AS current_year_revenue,
    ROUND(
        ((r22.revenue - r23.revenue) * 100.0 / r22.revenue),
        2
    ) AS revenue_decrease_ratio
FROM revenue_2022 r22
JOIN revenue_2023 r23
    ON r22.branch = r23.branch
WHERE r22.revenue > r23.revenue
ORDER BY revenue_decrease_ratio DESC;
GO


/* -----------------------------------------------------
   Q10: Monthly Revenue per Branch
   ----------------------------------------------------- */
    
WITH monthly_sales AS (
    SELECT
        branch,
        DATEFROMPARTS(YEAR([date]), MONTH([date]), 1) AS month_start,
        SUM(total_price) AS monthly_revenue
    FROM walmart_sales
    GROUP BY
        branch,
        YEAR([date]),
        MONTH([date])
)
SELECT *
FROM monthly_sales
ORDER BY branch, month_start;
GO

/* -----------------------------------------------------
   Q11: Monthly Profit per Branch
   ----------------------------------------------------- */
    
WITH monthly_profit AS (
    SELECT
        branch,
        DATEFROMPARTS(YEAR([date]), MONTH([date]), 1) AS month_start,
        SUM(unit_price * quantity * profit_margin) AS monthly_profit
    FROM walmart_sales
    GROUP BY
        branch,
        YEAR([date]),
        MONTH([date])
)
SELECT *
FROM monthly_profit
ORDER BY branch, month_start;
GO


/* -----------------------------------------------------
   Q13:Month-over-Month Growth
   ----------------------------------------------------- */
WITH monthly_sales AS (
    SELECT
        branch,
        DATEFROMPARTS(YEAR([date]), MONTH([date]), 1) AS month_start,
        SUM(total_price) AS monthly_revenue
    FROM walmart_sales
    GROUP BY
        branch,
        YEAR([date]),
        MONTH([date])
),
mom_calc AS (
    SELECT
        branch,
        month_start,
        monthly_revenue,
        LAG(monthly_revenue) OVER (
            PARTITION BY branch
            ORDER BY month_start
        ) AS prev_month_revenue
    FROM monthly_sales
)
SELECT
    branch,
    month_start,
    monthly_revenue,
    prev_month_revenue,
    ROUND(
        (monthly_revenue - prev_month_revenue) * 100.0 /
        NULLIF(prev_month_revenue, 0),
        2
    ) AS mom_growth_pct
FROM mom_calc
WHERE prev_month_revenue IS NOT NULL
ORDER BY branch, month_start;
GO
 /* -----------------------------------------------------
   Q14:Identify Growing vs Declining Branches (decision view)
   ----------------------------------------------------- */
   WITH monthly_sales AS (
    SELECT
        branch,
        DATEFROMPARTS(YEAR([date]), MONTH([date]), 1) AS month_start,
        SUM(total_price) AS monthly_revenue
    FROM walmart_sales
    GROUP BY
        branch,
        YEAR([date]),
        MONTH([date])
),
mom_calc AS (
    SELECT
        branch,
        month_start,
        monthly_revenue,
        LAG(monthly_revenue) OVER (
            PARTITION BY branch
            ORDER BY month_start
        ) AS prev_month_revenue
    FROM monthly_sales
),
mom_growth AS (
    SELECT
        branch,
        ROUND(
            (monthly_revenue - prev_month_revenue) * 100.0 /
            NULLIF(prev_month_revenue, 0),
            2
        ) AS mom_growth_pct
    FROM mom_calc
    WHERE prev_month_revenue IS NOT NULL
)
SELECT
    branch,
    ROUND(AVG(mom_growth_pct), 2) AS avg_mom_growth_pct
FROM mom_growth
GROUP BY branch
ORDER BY avg_mom_growth_pct DESC;
GO

/* -----------------------------------------------------
   Q15:Volatility / Stability
   ----------------------------------------------------- */
    
WITH monthly_sales AS (
    SELECT
        branch,
        DATEFROMPARTS(YEAR([date]), MONTH([date]), 1) AS month_start,
        SUM(total_price) AS monthly_revenue
    FROM walmart_sales
    GROUP BY
        branch,
        YEAR([date]),
        MONTH([date])
)
SELECT
    branch,
    ROUND(AVG(monthly_revenue), 2) AS avg_monthly_revenue,
    ROUND(STDEV(monthly_revenue), 2) AS revenue_volatility
FROM monthly_sales
GROUP BY branch
ORDER BY revenue_volatility DESC;
GO
