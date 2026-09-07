-- =============================================================================
-- STUDENT GRADED PORTFOLIO LAB: 20 ADVANCED SQL INTERVIEW PROBLEMS
-- DATABASE: enterprise_retail_db
-- =============================================================================

USE enterprise_retail_db;


-- -----------------------------------------------------------------------------
-- PART A: JOINS, ADVANCED FILTERING & SUBQUERIES (Q1 - Q5)
-- -----------------------------------------------------------------------------

-- [Q1] Find all customers from USA who placed completed orders in Q1 2024.

SELECT 
    c.customer_name,
    o.order_id,
    o.order_date,
    SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS net_revenue
FROM customers c
JOIN orders o
    ON o.customer_id = c.customer_id
JOIN order_items oi
    ON oi.order_id = o.order_id
WHERE c.country = 'USA'
  AND o.order_status = 'Completed'
  AND o.order_date >= '2024-01-01'
  AND o.order_date < '2024-04-01'
GROUP BY c.customer_id, c.customer_name, o.order_id, o.order_date;


-- [Q2] Identify sales reps in department 2 who have never closed an order.

SELECT 
    e.employee_id,
    e.first_name,
    e.last_name
FROM employees e
LEFT JOIN orders o
    ON o.sales_rep_id = e.employee_id
    AND o.order_status = 'Completed'
WHERE e.department_id = 2
  AND o.order_id IS NULL;


-- [Q3] Find products that have never been ordered.

SELECT 
    p.product_id,
    p.product_name
FROM products p
LEFT JOIN order_items oi
    ON oi.product_id = p.product_id
WHERE oi.order_item_id IS NULL;


-- [Q4] Find employees earning more than their department average salary.

SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    d.department_name,
    e.salary,
    da.avg_department_salary
FROM employees e
JOIN departments d
    ON d.department_id = e.department_id
JOIN (
    SELECT 
        department_id,
        AVG(salary) AS avg_department_salary
    FROM employees
    GROUP BY department_id
) da
    ON da.department_id = e.department_id
WHERE e.salary > da.avg_department_salary;


-- [Q5] Find customer segments with more than $30,000 net revenue.

SELECT 
    c.segment,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) AS net_revenue
FROM customers c
JOIN orders o
    ON o.customer_id = c.customer_id
    AND o.order_status = 'Completed'
JOIN order_items oi
    ON oi.order_id = o.order_id
GROUP BY c.segment
HAVING SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)) > 30000
ORDER BY net_revenue DESC;



-- -----------------------------------------------------------------------------
-- PART B: COMMON TABLE EXPRESSIONS (CTEs) & COMPLEX LOGIC (Q6 - Q8)
-- -----------------------------------------------------------------------------

-- [Q6] Calculate total spend per customer and classify them into brackets.

WITH customer_spend AS (
    SELECT 
        c.customer_id,
        COALESCE(
            SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct)),
            0
        ) AS total_spend
    FROM customers c
    LEFT JOIN orders o
        ON o.customer_id = c.customer_id
        AND o.order_status = 'Completed'
    LEFT JOIN order_items oi
        ON oi.order_id = o.order_id
    GROUP BY c.customer_id
),
spend_brackets AS (
    SELECT 
        CASE
            WHEN total_spend >= 20000 THEN 'High Spender'
            WHEN total_spend >= 5000 THEN 'Mid Spender'
            ELSE 'Low Spender'
        END AS spending_bracket
    FROM customer_spend
)
SELECT 
    spending_bracket,
    COUNT(*) AS customer_count
FROM spend_brackets
GROUP BY spending_bracket;


-- [Q7] Find customers with more than one completed order.

SELECT 
    c.customer_id,
    c.customer_name,
    MIN(o.order_date) AS first_order_date,
    MAX(o.order_date) AS most_recent_order_date
FROM customers c
JOIN orders o
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(*) > 1;


-- [Q8] Generate dates from 2024-01-01 to 2024-01-10 and count orders.

WITH RECURSIVE calendar_dates AS (
    SELECT DATE('2024-01-01') AS calendar_date

    UNION ALL

    SELECT calendar_date + INTERVAL 1 DAY
    FROM calendar_dates
    WHERE calendar_date < '2024-01-10'
)
SELECT 
    cd.calendar_date,
    COUNT(o.order_id) AS order_count
FROM calendar_dates cd
LEFT JOIN orders o
    ON o.order_date = cd.calendar_date
GROUP BY cd.calendar_date
ORDER BY cd.calendar_date;



-- -----------------------------------------------------------------------------
-- PART C: RANKING WINDOW FUNCTIONS (Q9 - Q12)
-- -----------------------------------------------------------------------------

-- [Q9] Find the highest paid employee in each department.

WITH ranked_employees AS (
    SELECT 
        e.employee_id,
        e.first_name,
        e.last_name,
        e.department_id,
        e.salary,
        DENSE_RANK() OVER (
            PARTITION BY e.department_id
            ORDER BY e.salary DESC
        ) AS salary_rank
    FROM employees e
)
SELECT 
    CONCAT(re.first_name, ' ', re.last_name) AS employee_name,
    d.department_name,
    re.salary
FROM ranked_employees re
JOIN departments d
    ON d.department_id = re.department_id
WHERE re.salary_rank = 1;


-- [Q10] Pick the earliest order for each customer.

WITH numbered_orders AS (
    SELECT 
        o.*,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY order_date ASC, order_id ASC
        ) AS row_num
    FROM orders o
)
SELECT 
    order_id,
    customer_id,
    order_date,
    order_status
FROM numbered_orders
WHERE row_num = 1;


-- [Q11] Divide products into 4 price quartiles.

SELECT 
    product_name,
    unit_price,
    NTILE(4) OVER (
        ORDER BY unit_price
    ) AS price_quartile
FROM products;


-- [Q12] Rank products by price within each category.

SELECT 
    p.product_name,
    c.category_name,
    p.unit_price,
    RANK() OVER (
        PARTITION BY p.category_id
        ORDER BY p.unit_price DESC
    ) AS price_rank,
    DENSE_RANK() OVER (
        PARTITION BY p.category_id
        ORDER BY p.unit_price DESC
    ) AS dense_price_rank
FROM products p
JOIN categories c
    ON p.category_id = c.category_id;



-- -----------------------------------------------------------------------------
-- PART D: OFFSET FUNCTIONS: LAG & LEAD (Q13 - Q15)
-- -----------------------------------------------------------------------------

-- [Q13] Calculate monthly revenue and month-over-month dollar growth.

WITH monthly_revenue AS (
    SELECT 
        DATE_FORMAT(o.order_date, '%Y-%m-01') AS month_start,
        SUM(
            oi.quantity * oi.unit_price * (1 - oi.discount_pct)
        ) AS net_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m-01')
),
revenue_with_previous AS (
    SELECT 
        month_start,
        net_revenue,
        LAG(net_revenue) OVER (
            ORDER BY month_start
        ) AS previous_month_revenue
    FROM monthly_revenue
)
SELECT 
    month_start,
    net_revenue,
    previous_month_revenue,
    net_revenue - previous_month_revenue AS mom_dollar_growth
FROM revenue_with_previous;


-- [Q14] Calculate days elapsed since each customer's previous order.

WITH customer_orders AS (
    SELECT 
        customer_id,
        order_id,
        order_date,
        LAG(order_date) OVER (
            PARTITION BY customer_id
            ORDER BY order_date, order_id
        ) AS previous_order_date
    FROM orders
)
SELECT 
    customer_id,
    order_id,
    order_date,
    previous_order_date,
    DATEDIFF(
        order_date,
        previous_order_date
    ) AS days_since_previous_order
FROM customer_orders
ORDER BY customer_id, order_date;


-- [Q15] Show the next order date for each customer.

SELECT 
    order_id,
    customer_id,
    order_date,
    LEAD(order_date) OVER (
        PARTITION BY customer_id
        ORDER BY order_date, order_id
    ) AS next_order_date
FROM orders;



-- -----------------------------------------------------------------------------
-- PART E: AGGREGATE WINDOW FUNCTIONS & FRAMES (Q16 - Q20)
-- -----------------------------------------------------------------------------

-- [Q16] Calculate running cumulative net revenue.

WITH order_revenue AS (
    SELECT 
        o.order_id,
        o.order_date,
        SUM(
            oi.quantity * oi.unit_price * (1 - oi.discount_pct)
        ) AS net_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY o.order_id, o.order_date
)
SELECT 
    order_id,
    order_date,
    net_revenue,
    SUM(net_revenue) OVER (
        ORDER BY order_date, order_id
    ) AS running_net_revenue
FROM order_revenue;


-- [Q17] Calculate daily revenue and a 3-day moving average.

WITH daily_revenue AS (
    SELECT 
        o.order_date,
        SUM(
            oi.quantity * oi.unit_price * (1 - oi.discount_pct)
        ) AS daily_net_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY o.order_date
)
SELECT 
    order_date,
    daily_net_revenue,
    AVG(daily_net_revenue) OVER (
        ORDER BY order_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS three_day_moving_average
FROM daily_revenue;


-- [Q18] Calculate each product's percentage of its category revenue.

WITH product_revenue AS (
    SELECT 
        p.product_name,
        c.category_id,
        c.category_name,
        SUM(
            oi.quantity * oi.unit_price * (1 - oi.discount_pct)
        ) AS product_revenue
    FROM products p
    JOIN categories c
        ON p.category_id = c.category_id
    JOIN order_items oi
        ON p.product_id = oi.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'Completed'
    GROUP BY p.product_name, c.category_id, c.category_name
)
SELECT 
    product_name,
    category_name,
    product_revenue,
    ROUND(
        product_revenue * 100 /
        SUM(product_revenue) OVER (
            PARTITION BY category_id
        ),
        2
    ) AS percentage_of_category_revenue
FROM product_revenue;


-- [Q19] Find the difference between employee salary and department maximum.

SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    d.department_name,
    e.salary,
    MAX(e.salary) OVER (
        PARTITION BY e.department_id
    ) AS highest_department_salary,
    MAX(e.salary) OVER (
        PARTITION BY e.department_id
    ) - e.salary AS difference_from_highest
FROM employees e
JOIN departments d
    ON e.department_id = d.department_id;


-- [Q20] Find customers who placed orders in two consecutive months in 2024.

WITH customer_months AS (
    SELECT DISTINCT 
        customer_id,
        DATE_FORMAT(order_date, '%Y-%m-01') AS month_start
    FROM orders
    WHERE order_status = 'Completed'
      AND order_date >= '2024-01-01'
      AND order_date < '2025-01-01'
),
month_check AS (
    SELECT 
        customer_id,
        month_start,
        LAG(month_start) OVER (
            PARTITION BY customer_id
            ORDER BY month_start
        ) AS previous_month
    FROM customer_months
)
SELECT DISTINCT 
    c.customer_id,
    c.customer_name
FROM month_check mc
JOIN customers c
    ON mc.customer_id = c.customer_id
WHERE TIMESTAMPDIFF(
    MONTH,
    previous_month,
    month_start
) = 1;


-- =============================================================================
-- END OF DAY 2 SQL ADVANCED JOINS, SUBQUERIES & CTES SCRIPT
-- =============================================================================
