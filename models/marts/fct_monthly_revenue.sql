-- Incremental strategy:
-- 1) On full refresh, aggregate all valid orders from int_orders_enriched
-- 2) On incremental runs, consume only orders whose updated_at is newer than the latest max_updated_at already persisted in this mart and the country_code and created_year_month combination is unique in the mart, so we can append the new rows to the mart without needing to update existing rows

{{ config
  (
    materialized='incremental',
    incremental_strategy='append'
  ) 
}}

WITH 
source AS (
    SELECT
        country_code,
        created_year_month,
        id AS order_id,
        amount,
        updated_at
    FROM 
      {{ ref('int_orders_enriched') }}
    WHERE 
      is_revenue_recognisable
      AND country_code IS NOT NULL
      AND created_year_month IS NOT NULL
      --incremental logic check: only include rows that have been updated since the last run
      {% if is_incremental() %}
      AND updated_at > (
          SELECT COALESCE(MAX(max_updated_at), '1900-01-01') FROM {{ this }}
      )
      {% endif %}
),

aggregated AS (
    SELECT
        country_code,
        created_year_month,
        SUM(amount) as total_revenue,
        COUNT(DISTINCT order_id) as order_count,
        CASE 
          WHEN COUNT(DISTINCT order_id) = 0 THEN NULL 
          ELSE SUM(amount) / COUNT(DISTINCT order_id) 
        END AS avg_order_value,
        MAX(updated_at) AS max_updated_at
    FROM 
      source
    GROUP BY 
      country_code, 
      created_year_month
),

-- deduplicate by key, keeping the row with the latest max_updated_at
dedupe AS (
    SELECT
      country_code,
      created_year_month,
      total_revenue,
      order_count,
      avg_order_value,
      max_updated_at,
      ROW_NUMBER() OVER (PARTITION BY country_code, created_year_month ORDER BY max_updated_at DESC) AS rn
    FROM 
      aggregated
),

growth_mom AS (
    SELECT
        country_code,
        created_year_month,
        total_revenue,
        order_count,
        avg_order_value,
        max_updated_at,
        LAG(total_revenue) OVER (PARTITION BY country_code ORDER BY created_year_month) AS prev_cc_total_revenue
    FROM 
      dedupe
    WHERE 
      rn = 1
)

SELECT
    country_code,
    created_year_month,
    total_revenue,
    order_count,
    avg_order_value,
    ROUND(CASE
        WHEN prev_cc_total_revenue IS NULL OR prev_cc_total_revenue = 0 THEN NULL
        ELSE (total_revenue - prev_cc_total_revenue) / prev_cc_total_revenue
    END, 4) AS revenue_mom_growth_cc_pct,
    max_updated_at
FROM 
  growth_mom
ORDER BY 
  country_code, 
  created_year_month
