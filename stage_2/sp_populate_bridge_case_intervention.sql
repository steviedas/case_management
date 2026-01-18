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

    -- Parse Associated_Intervention_IDs from RCMCaseManagement
    -- Assuming comma-separated values in Associated_Intervention_IDs field (e.g., "WR3741442,WR3741443")
    -- Match against fact_interventions.master_intervention_key format: "Maintenance-CHILT-WR3741442-20240718"
    -- Extract WR number from Associated_Intervention_IDs and match with third segment of master_intervention_key
    INSERT INTO #src_bridge (case_id, master_intervention_key)
    SELECT DISTINCT
        fc.case_id,
        fi.master_intervention_key
    FROM dbo.RCMCaseManagement AS rcm
    INNER JOIN dbo.fact_case AS fc
        ON fc.case_id = rcm.Case_ID
    CROSS APPLY STRING_SPLIT(rcm.Associated_Intervention_IDs, ',') AS intervention
    INNER JOIN dbo.fact_interventions AS fi
        ON fi.master_intervention_key LIKE '%-%-' + LTRIM(RTRIM(intervention.value)) + '-%'
    WHERE rcm.Associated_Intervention_IDs IS NOT NULL
      AND LTRIM(RTRIM(rcm.Associated_Intervention_IDs)) <> N''
      AND LTRIM(RTRIM(intervention.value)) <> N'';

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
