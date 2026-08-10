WITH
raw AS (
    SELECT
        order_id AS id,
        customer_id,
        order_date AS created_at,
        status,
        total_amount AS amount,
        currency,
        updated_at
    FROM
        {{ ref('orders') }}
    WHERE
        --dates
        (
            --invalid dates impermissible
            try_cast(order_date AS date) IS null
            --dates prior to Jan 2024 impermissible
            OR try_cast(order_date AS date) < '2024-01-01'
            --future dates beyond March 2024 impermissible
            OR try_cast(order_date AS date) >= '2024-04-01'
            --future orders impermissible)
        )
        OR
        --incorrect or invalid amounts
        total_amount IS null
        OR total_amount < 0
        OR
        --orders not (yet) executed (cancelled, pending, returned) with no value
        (
            status IN ('cancelled', 'pending', 'returned')
            AND total_amount < 1
        )
    ORDER BY order_id
),

remove_dupes AS (
    SELECT
        id,
        --identity duplicates by most recent updated_at for each order_id
        row_number() OVER (PARTITION BY id ORDER BY updated_at DESC) AS row_num
    FROM
        raw
)

SELECT
    rw.*
FROM
    raw AS rw
WHERE
    --remove duplicates by id
    rw.id NOT IN (
        SELECT id FROM remove_dupes WHERE row_num > 1
    )
