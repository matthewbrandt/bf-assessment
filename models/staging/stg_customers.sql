WITH
raw AS (
    SELECT
        customer_id AS id,
        LOWER(email) AS email,
        country AS country_code,
        created_at
    FROM
        {{ ref('customers') }}
),

flag_duplicates AS (
    SELECT
        id,
        --identify duplicate emails across customer ids
        COUNT(*) OVER (PARTITION BY email) AS has_duplicate_email
    FROM
        raw
)

SELECT 
    rw.*,
    CASE 
        WHEN fd.has_duplicate_email > 1 THEN TRUE 
        ELSE FALSE 
    END AS has_duplicate_email 
FROM 
    raw AS rw
LEFT JOIN 
    flag_duplicates AS fd USING(id)
