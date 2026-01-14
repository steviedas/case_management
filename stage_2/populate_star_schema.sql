-- Step 1: Populate all dimension tables with no FK dependencies
EXEC sp_populate_dim_priority;
EXEC sp_populate_dim_status;
EXEC sp_populate_dim_system;
EXEC sp_populate_dim_toc;
EXEC sp_populate_dim_depot;
EXEC sp_populate_dim_class;
EXEC sp_populate_dim_delphi_unit;
EXEC sp_populate_dim_alert_status;

-- Step 2: Populate dim_vehicle (depends on dim_delphi_unit)
EXEC sp_populate_dim_vehicle;

-- Step 3: Populate fact_alert_trace_reference (no FK dependencies)
-- EXEC sp_populate_fact_alert_trace_reference;

-- Step 4: Populate fact_alert (depends on dim_alert_status, dim_vehicle, fact_alert_trace_reference)
-- EXEC sp_populate_fact_alert;

-- Step 5: Populate fact_interventions (if exists - referenced by bridge_case_intervention)
-- EXEC sp_populate_fact_interventions;

-- Step 6: Populate fact_case (depends on dim_priority, dim_status, dim_system, dim_toc, dim_class, dim_depot, dim_vehicle)
-- EXEC sp_populate_fact_case;

-- Step 7: Populate fact_record (depends on fact_case)
-- EXEC sp_populate_fact_record;

-- Step 8: Populate bridge tables (all depend on fact_case)
-- EXEC sp_populate_bridge_case_intervention;  -- Also depends on fact_interventions
-- EXEC sp_populate_bridge_case_alert;         -- Also depends on fact_alert
-- EXEC sp_populate_bridge_case_delphi_unit;   -- Also depends on dim_delphi_unit (already populated)
