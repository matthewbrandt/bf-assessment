# Assessment Handbook

This page describes the submitted work for the assessment. It is worded concisely and partially LLM-generated - final review was done by the author. VS Code, with the assistance of CoPilot, was used in the development of this project, and the dbt CLI was used to run and test the models.

## Executive Summary
- The project cleans the raw data strictly and defensively, not surfacing it to reporting at all.
- The revenue mart is incremental on append-only, performant, and efficient. This is because orders cannot be changed after they are completed, and the mart is built on a monthly grain.
- The solution is documented and tested end-to-end, with concise and precise explanations of the data processing decisions, intermediate model design, incremental strategy, complex metric choice, and testing approach in the following sections.

## 1. How to Run the Project

From the project root, run:
```bash
DBT_PROFILES_DIR=. dbt seed && dbt run && dbt test
```

Notes:
- This uses the local DuckDB profile defined in the repository.
- If seed data needs to be regenerated, you can also run:

```bash
python scripts/generate_seed_data.py
```

## 2. Data Processing Decisions

### 📦 orders
#### Dates & Times
Invalid (non-date formatted) and future dates were treated as unusable for the business because they would distort period-based reporting. Dates cannot be "assumed" and thus those rows were discarded entirely.

#### Quality & Consistency
Orders with missing, zero or zero-like amounts are exempt from revenue aggregation so the mart reflects only economically meaningful transactions. Duplicate order ids were also removed to avoid double-counting. Orders that have not been completed or have been erroneous are also excluded due to their lack of economic significance.

Additionally, duplicate order ids were removed to avoid double-counting. Since an order could be updated at a later time, the most recent record for each order was considered during deduplication.

### 🧑‍🦳 customers
#### Uniqueness & Validity
Customer ID is unique and non-null, so no additional cleaning was required. However, email is not unique across customers so in order to avoid possible later-stage quality issues, records with duplicate emails were flagged in the table (on all affected rows) to allow for later usage.

### 🛍️ products
#### Validation & Type Conversion
The unit_price field was converted to a decimal type to ensure that it is treated as a numeric.

## 3. Intermediate Model Design

`int_orders_enriched` was implemented as an intermediate model to join the cleaned orders and customer data together, as well as add a few additional fields to support downstream analysis. The model is designed to be a stable, reusable foundation for the revenue mart and other potential downstream models.

## 4. Incremental Strategy
The monthly revenue mart is built incrementally so that only new or changed records are processed. Initially, a full refresh can be performed to build the mart from scratch. Subsequently, only new or updated records are processed. This keeps the model efficient and avoids unnecessary recomputation while still preserving a consistent, historical view of revenue by country and month.

## 5. Complex Metric Choice

### Chosen metric & reasoning
**Month-over-month growth**: each country's revenue is compared to the prior month (using a LAG function) to surface trends and growth patterns. This metric is useful for business reporting because it provides insight into how revenue is changing over time, allowing stakeholders to identify growth opportunities or areas of concern. Every market behaves differently, so this metric allows for a more granular understanding of performance across different regionsLimitations

### Limitations
This approach assumes that the data is complete and accurate for each month. If there are missing or delayed records, the month-over-month growth calculation may be skewed. Additionally, this metric does not account for seasonality or other external factors that may influence revenue trends. The first month of data will not have a prior month to compare against, so the growth metric will be null for that period. Lastly, this is based on calendar months, which may not align with the business's fiscal reporting periods or with the timing of marketing campaigns or other initiatives that could impact revenue.

## 6. Testing Approach

### Key Tests
  - relationship test for `orders.customer_id` to `customers.id`
  - data quality tests for completed orders and valid revenue values
  - a business rule test to ensure that no products have a zero or null unit_price

### Why These Tests
  - they validate referential integrity so every orders.customer_id exists in customers and alert when orphaned orders appear
  - they enforce business rules such as only counting orders that are fulfilled and within the reporting period, and that revenue is > 0
  - they catch data-entry or ETL regressions like duplicate order_id insertion, unit_price <= 0 on products, or order_date values in the future so analysts aren't misled by bad source data

N.B. Some of these tests are implemented as dbt built-in tests, while others are implemented as custom SQL tests. The custom tests are located in the `tests` directory and are run automatically with `dbt test`. This is to ensure that the project is fully tested end-to-end and that any data quality issues are surfaced immediately, with the native model tests providing a first line of defense and the custom tests providing additional business rule coverage, with some overlap.
