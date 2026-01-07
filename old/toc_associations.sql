WITH filtered_rake_hist AS (
    SELECT DISTINCT TOC, Unit, Vehicle_Class, Vehicle
    FROM dbo.RakeHistory
),
filtered_unified_interventions AS (
    SELECT 
        depot_id,
        R2_Depot,
        Vehicle
    FROM (
        SELECT 
            dd.depot_id,
            ui.R2_Depot,
            ui.Vehicle,
            ROW_NUMBER() OVER (
                PARTITION BY ui.Vehicle 
                ORDER BY ui.Date DESC
            ) AS rn
        FROM dbo.UnifiedInterventions ui
        LEFT JOIN dim_depot dd
          ON ui.R2_Depot = dd.depot_name
    ) AS sub
    WHERE rn = 1
),
final_query AS (
    SELECT
        dt.toc_id,
        frh.TOC AS toc_name,
        dc.class_id,
        frh.Vehicle_Class AS class_name,
        fui.depot_id,
        fui.R2_Depot AS depot_name,
        du.unit_id,
        frh.Unit AS unit,
        frh.Vehicle AS vehicle
    FROM filtered_rake_hist frh
    LEFT JOIN dim_toc dt
        ON frh.TOC = dt.toc_name
    LEFT JOIN dim_class dc
        ON frh.Vehicle_Class = dc.class_name
    LEFT JOIN filtered_unified_interventions fui
        ON frh.Vehicle = fui.Vehicle
    LEFT JOIN dim_unit du
        ON frh.Unit = du.unit_name
    WHERE dt.toc_id IS NOT NULL 
    AND dc.class_id IS NOT NULL 
    AND fui.depot_id IS NOT NULL
)
SELECT *
FROM final_query
ORDER BY unit;
