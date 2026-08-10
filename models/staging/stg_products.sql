-- TODO: Implement staging model for products.
-- See CHALLENGE.md sect 3.1. Minimal cleaning needed for this seed.
-- Replace the pass-through below with your implementation.

WITH raw AS (
    SELECT
        product_id AS id,
        name,
        category,
        TRY_CAST(unit_price AS DECIMAL(10, 2)) AS unit_price --force to decimal
    FROM {{ ref('products') }}
)
SELECT * FROM raw
