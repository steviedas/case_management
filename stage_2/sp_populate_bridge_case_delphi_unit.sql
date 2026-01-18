CREATE OR ALTER PROCEDURE dbo.sp_populate_bridge_case_delphi_unit
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID('tempdb..#src_bridge') IS NOT NULL
        DROP TABLE #src_bridge;

    CREATE TABLE #src_bridge
    (
        case_id INT NOT NULL,
        unit_id INT NOT NULL,
        PRIMARY KEY (case_id, unit_id)
    );

    -- Populate bridge table by linking cases to their delphi units
    -- Logic: Get the unit from the case's vehicle
    INSERT INTO #src_bridge (case_id, unit_id)
    SELECT DISTINCT
        fc.case_id,
        v.unit_id
    FROM dbo.fact_case AS fc
    INNER JOIN dbo.dim_vehicle AS v
        ON v.vehicle_id = fc.vehicle_id
    WHERE fc.vehicle_id IS NOT NULL
      AND v.unit_id IS NOT NULL;

    BEGIN TRY
        BEGIN TRAN;

        MERGE dbo.bridge_case_delphi_unit AS tgt
        USING #src_bridge AS src
            ON tgt.case_id = src.case_id
           AND tgt.unit_id = src.unit_id

        WHEN NOT MATCHED BY TARGET
        THEN INSERT (case_id, unit_id)
            VALUES (src.case_id, src.unit_id)

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
