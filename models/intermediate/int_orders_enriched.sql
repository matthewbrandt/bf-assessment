-- Adds customer attributes to order records and enforces revenue recognition rules
-- All marts pull information from here for integrity and consistency
-- Using LEFT JOIN to avoid dropping orders with missing customer records (e.g. GDPR deletion)

WITH 
orders AS (
    SELECT
        id,
        customer_id,
        created_at,
        DATE_TRUNC('MONTH', created_at)::DATE AS created_year_month,
        CASE 
            WHEN updated_at != created_at 
                AND updated_at > created_at
                    THEN TRUE 
                ELSE FALSE
        END AS has_post_creation_update,  
        status,
        amount,
        currency,
        updated_at
    FROM 
        {{ ref('stg_orders') }}

),

customers AS (
    SELECT
        id,
        country_code,
        email,
        has_duplicate_email
    FROM
        {{ ref('stg_customers') }}

)

SELECT
    od.*,
    ct.* EXCLUDE (id),
    (od.status IN ('completed', 'shipped')) AS is_revenue_recognizable
FROM 
    orders AS od
LEFT JOIN customers AS ct
    ON od.customer_id = ct.id