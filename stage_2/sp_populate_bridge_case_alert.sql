CREATE OR ALTER PROCEDURE dbo.sp_populate_bridge_case_alert
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID('tempdb..#src_bridge') IS NOT NULL
        DROP TABLE #src_bridge;

    CREATE TABLE #src_bridge
    (
        case_id INT NOT NULL,
        ins_alt_id INT NOT NULL,
        date_assigned DATETIME2 NULL,
        assigned_by NVARCHAR(100) NULL,
        assigned_notes NVARCHAR(500) NULL,
        alert_source NVARCHAR(20) NOT NULL,
        PRIMARY KEY (case_id, ins_alt_id)
    );

    -- Populate bridge table by matching alerts to cases
    -- Business logic: Link alerts to cases based on:
    --   1. Same vehicle
    --   2. Alert timestamp within 7 days before case was raised
    --   3. Matching system (optional)
    -- This creates automatic case-alert associations

    INSERT INTO #src_bridge (case_id, ins_alt_id, date_assigned, assigned_by, assigned_notes, alert_source)
    SELECT DISTINCT
        fc.case_id,
        fa.alert_id AS ins_alt_id,
        fa.alert_timestamp AS date_assigned,
        'auto-assignment' AS assigned_by,
        'Automatically linked based on vehicle and timestamp proximity' AS assigned_notes,
        LEFT(fa.alert_source, 20) AS alert_source
    FROM dbo.fact_case AS fc
    INNER JOIN dbo.fact_alert AS fa
        ON fa.vehicle_id = fc.vehicle_id
    WHERE fa.alert_timestamp BETWEEN DATEADD(DAY, -7, fc.created_at) AND fc.created_at
      AND fa.alert_id IS NOT NULL
      AND fc.case_id IS NOT NULL;

    BEGIN TRY
        BEGIN TRAN;

        MERGE dbo.bridge_case_alert AS tgt
        USING #src_bridge AS src
            ON tgt.case_id = src.case_id
           AND tgt.ins_alt_id = src.ins_alt_id

        WHEN MATCHED
        THEN UPDATE SET
            tgt.date_assigned = src.date_assigned,
            tgt.assigned_by = src.assigned_by,
            tgt.assigned_notes = src.assigned_notes,
            tgt.alert_source = src.alert_source

        WHEN NOT MATCHED BY TARGET
        THEN INSERT (case_id, ins_alt_id, date_assigned, assigned_by, assigned_notes, alert_source)
            VALUES (src.case_id, src.ins_alt_id, src.date_assigned, src.assigned_by, src.assigned_notes, src.alert_source)

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
