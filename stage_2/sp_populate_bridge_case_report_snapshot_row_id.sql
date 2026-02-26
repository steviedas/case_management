CREATE OR ALTER PROCEDURE dbo.sp_populate_bridge_case_report_snapshot_row_id
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID('tempdb..#src_case') IS NOT NULL
        DROP TABLE #src_case;
    IF OBJECT_ID('tempdb..#src_bridge') IS NOT NULL
        DROP TABLE #src_bridge;

    CREATE TABLE #src_case
    (
        report_snapshot_row_id INT NOT NULL PRIMARY KEY,
        row_hash VARBINARY(32) NOT NULL
    );

    ;WITH src_case AS
    (
        SELECT
            drsr.report_snapshot_row_id,
            dp.priority_id,
            ds.status_id,
            LEFT(LTRIM(RTRIM(rc.title)), 500) AS title,
            sys.system_id,
            rc.created_at,
            dt.toc_id,
            dc.class_id,
            dd.depot_id,
            dv.vehicle_id
        FROM dbo.ReportCase AS rc
        LEFT JOIN dbo.dim_priority AS dp
            ON dp.priority_name = NULLIF(LTRIM(RTRIM(rc.priority_name)), N'')
        JOIN dbo.dim_status AS ds
            ON ds.status_name = LTRIM(RTRIM(rc.status_name))
        LEFT JOIN dbo.dim_system AS sys
            ON sys.system_name = COALESCE(NULLIF(LTRIM(RTRIM(rc.system_name)), N''), N'Engine')
        LEFT JOIN dbo.RakeHistory AS rh_vehicle
            ON rh_vehicle.Vehicle = LTRIM(RTRIM(CAST(rc.vehicle AS NVARCHAR(100))))
        LEFT JOIN (
            SELECT
                Unit,
                MAX(TOC) AS TOC,
                MAX(Vehicle_Class) AS Vehicle_Class,
                MAX(R2_Depot) AS R2_Depot
            FROM dbo.RakeHistory
            WHERE Unit IS NOT NULL
            GROUP BY Unit
        ) AS rh_unit
            ON rh_unit.Unit = LTRIM(RTRIM(rc.unit))
        LEFT JOIN dbo.dim_toc AS dt
            ON dt.toc_name = COALESCE(
                LTRIM(RTRIM(rh_vehicle.TOC)),
                LTRIM(RTRIM(rh_unit.TOC))
            )
        LEFT JOIN dbo.dim_class AS dc
            ON dc.class_name = COALESCE(
                LTRIM(RTRIM(rh_vehicle.Vehicle_Class)),
                LTRIM(RTRIM(rh_unit.Vehicle_Class))
            )
        LEFT JOIN dbo.dim_depot AS dd
            ON dd.depot_name = COALESCE(
                LTRIM(RTRIM(rh_vehicle.R2_Depot)),
                LTRIM(RTRIM(rh_unit.R2_Depot))
            )
        LEFT JOIN dbo.dim_vehicle AS dv
            ON dv.vehicle = LTRIM(RTRIM(CAST(rc.vehicle AS NVARCHAR(100))))
        LEFT JOIN dbo.dim_report_snapshot_row AS drsr
            ON drsr.row_uid = rc._UID
        WHERE rc._UID IS NOT NULL
          AND LTRIM(RTRIM(rc._UID)) <> N''
          AND drsr.report_snapshot_row_id IS NOT NULL
    )
    INSERT INTO #src_case (report_snapshot_row_id, row_hash)
    SELECT
        src.report_snapshot_row_id,
        CONVERT(VARBINARY(32),
            HASHBYTES('SHA2_256',
                COALESCE(src.title, N'') + N'|' +
                COALESCE(CAST(src.priority_id AS NVARCHAR(10)), N'') + N'|' +
                COALESCE(CAST(src.status_id AS NVARCHAR(10)), N'') + N'|' +
                COALESCE(CAST(src.system_id AS NVARCHAR(10)), N'') + N'|' +
                COALESCE(CONVERT(NVARCHAR(30), src.created_at, 121), N'') + N'|' +
                COALESCE(CAST(src.toc_id AS NVARCHAR(10)), N'') + N'|' +
                COALESCE(CAST(src.class_id AS NVARCHAR(10)), N'') + N'|' +
                COALESCE(CAST(src.depot_id AS NVARCHAR(10)), N'') + N'|' +
                COALESCE(CAST(src.vehicle_id AS NVARCHAR(10)), N'')
            )
        ) AS row_hash
    FROM src_case AS src;

    CREATE TABLE #src_bridge
    (
        case_id INT NOT NULL,
        report_snapshot_row_id INT NOT NULL,
        PRIMARY KEY (case_id, report_snapshot_row_id)
    );

    -- Prefer existing bridge mapping for stable case_id reuse.
    INSERT INTO #src_bridge (case_id, report_snapshot_row_id)
    SELECT
        existing.case_id,
        src.report_snapshot_row_id
    FROM #src_case AS src
    INNER JOIN (
        SELECT
            report_snapshot_row_id,
            MIN(case_id) AS case_id
        FROM dbo.bridge_case_report_snapshot_row_id
        GROUP BY report_snapshot_row_id
    ) AS existing
        ON existing.report_snapshot_row_id = src.report_snapshot_row_id;

    -- For new report rows, resolve to the matching case using the same hash as fact_case_from_reports.
    ;WITH fact_case_hash AS
    (
        SELECT
            fc.case_id,
            CONVERT(VARBINARY(32),
                HASHBYTES('SHA2_256',
                    COALESCE(fc.title, N'') + N'|' +
                    COALESCE(CAST(fc.priority_id AS NVARCHAR(10)), N'') + N'|' +
                    COALESCE(CAST(fc.status_id AS NVARCHAR(10)), N'') + N'|' +
                    COALESCE(CAST(fc.system_id AS NVARCHAR(10)), N'') + N'|' +
                    COALESCE(CONVERT(NVARCHAR(30), fc.created_at, 121), N'') + N'|' +
                    COALESCE(CAST(fc.toc_id AS NVARCHAR(10)), N'') + N'|' +
                    COALESCE(CAST(fc.class_id AS NVARCHAR(10)), N'') + N'|' +
                    COALESCE(CAST(fc.depot_id AS NVARCHAR(10)), N'') + N'|' +
                    COALESCE(CAST(fc.vehicle_id AS NVARCHAR(10)), N'')
                )
            ) AS row_hash
        FROM dbo.fact_case AS fc
    ),
    unresolved AS
    (
        SELECT
            src.report_snapshot_row_id,
            MIN(fh.case_id) AS case_id
        FROM #src_case AS src
        INNER JOIN fact_case_hash AS fh
            ON fh.row_hash = src.row_hash
        LEFT JOIN #src_bridge AS b
            ON b.report_snapshot_row_id = src.report_snapshot_row_id
        WHERE b.report_snapshot_row_id IS NULL
        GROUP BY src.report_snapshot_row_id
    )
    INSERT INTO #src_bridge (case_id, report_snapshot_row_id)
    SELECT
        u.case_id,
        u.report_snapshot_row_id
    FROM unresolved AS u
    WHERE u.case_id IS NOT NULL;

    BEGIN TRY
        BEGIN TRAN;

        MERGE dbo.bridge_case_report_snapshot_row_id AS tgt
        USING #src_bridge AS src
            ON tgt.case_id = src.case_id
           AND tgt.report_snapshot_row_id = src.report_snapshot_row_id
        WHEN NOT MATCHED BY TARGET
        THEN INSERT (case_id, report_snapshot_row_id)
            VALUES (src.case_id, src.report_snapshot_row_id);

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH

    IF OBJECT_ID('tempdb..#src_case') IS NOT NULL
        DROP TABLE #src_case;
    IF OBJECT_ID('tempdb..#src_bridge') IS NOT NULL
        DROP TABLE #src_bridge;
END;
