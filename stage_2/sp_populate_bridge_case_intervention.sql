CREATE OR ALTER PROCEDURE dbo.sp_populate_bridge_case_intervention
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID('tempdb..#src_bridge') IS NOT NULL
        DROP TABLE #src_bridge;

    CREATE TABLE #src_bridge
    (
        case_id INT NOT NULL,
        master_intervention_key NVARCHAR(100) NOT NULL,
        PRIMARY KEY (case_id, master_intervention_key)
    );

    -- Parse linked_work_orders from fact_case
    -- Assuming comma-separated values in linked_work_orders field (e.g., "WR3741442,WR3741443")
    -- Match against fact_interventions.master_intervention_key format: "Maintenance-CHILT-WR3741442-20240718"
    -- Extract WR number from linked_work_orders and match with third segment of master_intervention_key
    INSERT INTO #src_bridge (case_id, master_intervention_key)
    SELECT DISTINCT
        fc.case_id,
        fi.master_intervention_key AS intervention_key
    FROM dbo.fact_case AS fc
    CROSS APPLY STRING_SPLIT(fc.linked_work_orders, ',') AS intervention
    INNER JOIN dbo.fact_interventions AS fi
        ON fi.master_intervention_key LIKE '%-%-' + LTRIM(RTRIM(intervention.value)) + '-%'
    WHERE fc.linked_work_orders IS NOT NULL
        AND LTRIM(RTRIM(fc.linked_work_orders)) <> N''
        AND LTRIM(RTRIM(intervention.value)) <> N'';

    -- Parse RFS field from fact_case
    -- RFS field contains comma-separated values like "RFS-3312, RFS-4581" or "RFS00142"
    -- Strip "RFS-" or "RFS" prefix and join to UnifiedIntervention.Intervention_ID
    -- Use Intervention_Key from UnifiedIntervention as master_intervention_key
    INSERT INTO #src_bridge (case_id, master_intervention_key)
    SELECT DISTINCT
        fc.case_id,
        ui.Intervention_Key as intervention_key
    FROM dbo.fact_case AS fc
    CROSS APPLY STRING_SPLIT(fc.rfs, ',') AS rfs_value
    INNER JOIN dbo.UnifiedInterventions AS ui
        ON ui.Intervention_ID = CASE
            WHEN LTRIM(RTRIM(rfs_value.value)) LIKE 'RFS-%'
                THEN STUFF(LTRIM(RTRIM(rfs_value.value)), 1, 4, '')
            WHEN LTRIM(RTRIM(rfs_value.value)) LIKE 'RFS%'
                THEN STUFF(LTRIM(RTRIM(rfs_value.value)), 1, 3, '')
            ELSE LTRIM(RTRIM(rfs_value.value))
        END
    WHERE fc.rfs IS NOT NULL
        AND LTRIM(RTRIM(fc.rfs)) <> N''
        AND LTRIM(RTRIM(rfs_value.value)) <> N'';

    BEGIN TRY
        BEGIN TRAN;

        MERGE dbo.bridge_case_intervention AS tgt
        USING #src_bridge AS src
            ON tgt.case_id = src.case_id
           AND tgt.master_intervention_key = src.master_intervention_key

        WHEN NOT MATCHED BY TARGET
        THEN INSERT (case_id, master_intervention_key)
            VALUES (src.case_id, src.master_intervention_key)

        WHEN NOT MATCHED BY SOURCE
        THEN DELETE;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH

    IF OBJECT_ID('tempdb..#src_bridge') IS NOT NULL
        DROP TABLE #src_bridge;
END;
