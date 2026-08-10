-- Singular test: Orders should only reference existing customer IDs.
-- Fails if any populated customer_id in staging orders does not exist in staging customers.

SELECT
    od.id AS order_id,
    od.customer_id
FROM
    {{ ref('stg_orders') }} AS od
LEFT JOIN
    {{ ref('stg_customers') }} AS ct
    ON od.customer_id = ct.id
WHERE
    od.customer_id IS NOT null
    AND ct.id IS null
