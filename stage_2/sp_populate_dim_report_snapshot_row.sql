CREATE OR ALTER PROCEDURE dbo.sp_populate_dim_report_snapshot_row
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID('tempdb..#src_rows') IS NOT NULL
        DROP TABLE #src_rows;

    CREATE TABLE #src_rows
    (
        snapshot_id INT NOT NULL,
        row_uid VARCHAR(64) NOT NULL,
        report_date DATETIME2 NOT NULL,
        unit_id INT NULL,
        vehicle_id INT NULL,
        PRIMARY KEY (snapshot_id, row_uid)
    );

    INSERT INTO #src_rows (snapshot_id, row_uid, report_date, unit_id, vehicle_id)
    SELECT
        frs.snapshot_id,
        rsr.row_uid,
        CAST(rsr.report_date AS DATETIME2) AS report_date,
        ddu.unit_id,
        dv.vehicle_id
    FROM dbo.ReportSnapshotRow AS rsr
    INNER JOIN dbo.fact_report AS fr
        ON LTRIM(RTRIM(rsr.report_name)) = fr.title
    INNER JOIN dbo.fact_report_snapshot AS frs
        ON frs.report_id = fr.report_id
       AND fr.title IN ('air_leak', 'weekly_boost_pressure', 'coolant_temperature')
       AND rsr.report_date = CAST(frs.start_time AS DATE)
    LEFT JOIN dbo.dim_delphi_unit AS ddu
        ON ddu.unit = rsr.unit
    LEFT JOIN dbo.dim_vehicle AS dv
        ON dv.vehicle = rsr.vehicle
       AND (ddu.unit_id IS NULL OR dv.unit_id = ddu.unit_id)
    WHERE rsr.row_uid IS NOT NULL
      AND LTRIM(RTRIM(rsr.row_uid)) <> N'';

    BEGIN TRY
        BEGIN TRAN;

        MERGE dbo.dim_report_snapshot_row AS tgt
        USING #src_rows AS src
            ON tgt.snapshot_id = src.snapshot_id
           AND tgt.row_uid = src.row_uid

        WHEN MATCHED
            AND (
                tgt.unit_id IS NULL
                OR tgt.vehicle_id IS NULL
            )
        THEN UPDATE SET
            tgt.unit_id = COALESCE(tgt.unit_id, src.unit_id),
            tgt.vehicle_id = COALESCE(tgt.vehicle_id, src.vehicle_id)

        WHEN NOT MATCHED BY TARGET
        THEN INSERT (snapshot_id, row_uid, report_date, unit_id, vehicle_id)
             VALUES (src.snapshot_id, src.row_uid, src.report_date, src.unit_id, src.vehicle_id);

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH

    IF OBJECT_ID('tempdb..#src_rows') IS NOT NULL
        DROP TABLE #src_rows;
END;
