-- Singular test: Ensure fct_monthly_revenue has unique and non-null country_code and created_year_month combinations.
-- Fails if there are duplicate country_code/created_year_month combinations or null values in either column.

WITH 
dupes AS (
  SELECT
    country_code,
    created_year_month
  FROM 
    {{ ref('fct_monthly_revenue') }}
  GROUP BY 
    country_code, 
    created_year_month
  HAVING 
    COUNT(*) > 1
),

null_values AS (
  SELECT 
    country_code,
    created_year_month
  FROM 
    {{ ref('fct_monthly_revenue') }}
  WHERE 
    country_code IS NULL
    OR created_year_month IS NULL
)

SELECT *
FROM dupes

UNION ALL

SELECT *
FROM null_values