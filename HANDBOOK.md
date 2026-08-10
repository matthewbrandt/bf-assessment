# Assessment Handbook

This page describes the submitted work for the assessment. It is worded concisely and partially LLM-generated - final review was done by the author. VS Code, with the assistance of CoPilot, was used in the development of this project, and the dbt CLI was used to run and test the models.

## Executive Summary

- A concise summary of the approach:
  - the project cleans the raw data defensively,
  - the revenue mart is incremental and performant,
  - the extra metric adds analytical depth,
  - the solution is documented and tested end to end.

---

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

---

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

---

## 3. Incremental Strategy

### What was implemented
- Describe the incremental logic used in the mart.
- Mention that the model uses dbt’s incremental pattern and only processes newly updated or newly arrived records.

### Why this approach was chosen
- Explain the business and technical rationale:
  - improves runtime and avoids rebuilding the full mart on every run,
  - fits the local seed-based workflow,
  - supports repeatable updates when new data arrives.

### Implementation notes
- Mention the key logic used to determine whether a row should be reprocessed, such as:
  - comparing against an updated timestamp,
  - using a merge-style incremental strategy for the mart,
  - keeping the grain stable at the country/month level.

### Example wording
- “The monthly revenue mart is built incrementally so that only new or changed records are processed. This keeps the model efficient and avoids unnecessary recomputation while still preserving a consistent, historical view of revenue by country and month.”

---

## 4. Complex Metric Choice

### Chosen metric
- Choose one of the following and describe it clearly:
  - Month-over-month growth,
  - rolling 30-day revenue,
  - cohort analysis.

### Why this metric was chosen
- Explain why it is useful for business reporting and how it adds value beyond the base monthly revenue mart.

### SQL approach
- Summarize the SQL pattern at a high level:
  - window functions for rolling calculations,
  - self-joins or lag functions for MoM comparisons,
  - cohort grouping by first-order month and subsequent activity.

### Example wording
- “I implemented month-over-month revenue growth by comparing each country’s revenue in the current month to the prior month. The SQL uses a windowed calculation and a lag-based comparison to surface growth trends clearly.”

---

## 5. Testing Approach

### Key Tests
  - relationship test for `orders.customer_id` to `customers.id`
  - data quality tests for completed orders and valid revenue values
  - a business rule test to ensure that no products have a zero or null unit_price

### Why These Tests
  - they validate referential integrity so every orders.customer_id exists in customers and alert when orphaned orders appear
  - they enforce business rules such as only counting orders that are fulfilled and within the reporting period, and that revenue is > 0
  - they catch data-entry or ETL regressions like duplicate order_id insertion, unit_price <= 0 on products, or order_date values in the future so analysts aren't misled by bad source data.
