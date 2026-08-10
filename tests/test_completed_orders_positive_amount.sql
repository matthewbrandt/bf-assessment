-- Singular test: Completed orders should have positive total_amount
-- Fails if any completed order has amount <= 0

select
    id,
    amount,
    status
from
    {{ ref('stg_orders') }}
where
    status = 'completed'
    and (amount <= 0 or amount is null)
