# Analytical Database Schema Scripts

This directory contains the SQL scripts responsible for creating and populating the core analytical tables in the database. These tables are designed to pre-calculate and aggregate data, which significantly improves the performance and simplifies the logic of the downstream Python labeling scripts.


---
## 1. `district_attributes.sql`

This script is responsible for creating the **`berlin_labels.district_attributes`** table.

The purpose of this table is to store pre-calculated, static metrics for each district, eliminating the need for repeated, expensive calculations. It contains the following key metrics:

* **`area_sq_km` and `area_coefficient`**: The absolute area and a normalized coefficient to account for significant differences in the geographical size of the districts.
* **`inhabitants` and `population_coefficient`**: The total population and a normalized coefficient to account for differences in population size.

These coefficients are fundamental for the fair, scaled comparisons used in the tagging logic.

#### Area Coefficient Calculation
The `area_coefficient` is calculated based on the following formula:
`Coefficient_district = Area_district / Area_average`

#### Population Coefficient Calculation
The `population_coefficient` is calculated based on the following formula:
`Coefficient_population = Population_district / Population_average`

---
## 2. `district_features.sql`

This script is responsible for creating the central "feature table" at **`berlin_labels.district_features`**.

This table serves as the single source of truth for all pre-aggregated data needed by the Python labeling scripts. It contains a wide format with one row per district and columns representing the total count of various amenities (e.g., `bus_tram_stop_count`, `bank_count`, `num_gyms`, etc.). This approach moves heavy data processing from Python into the database, making the analytical scripts significantly faster.

### How to Contribute

If your tagging logic requires a new, calculated metric (like the count of kindergartens), you must **add the corresponding column to this central feature table**. Please update this main SQL script to include your new feature. This ensures that all calculated data is available in one consistent location for the entire project.

---
## 3. `creating_district_labels_new.sql`

This script is responsible for creating the final output table at **`berlin_labels.district_labels_new`**.

This table is designed to store the results from all individual Python labeling scripts. It uses a standardized "long" format (`district_id`, `category`, `label`) which is highly scalable. The table includes a primary key to prevent duplicate entries and a foreign key to the main `districts` table to ensure data integrity. Individual Python scripts should be configured to append their results to this central table.

