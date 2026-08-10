-- Singular test: Products should not have a zero or null unit_price
-- Fails if any product has unit_price <= 0 OR NULL

SELECT
    id,
    unit_price
FROM
    {{ ref('stg_products') }}
WHERE
    unit_price <= 0
    OR unit_price IS NULL
