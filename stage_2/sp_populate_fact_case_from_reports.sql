CREATE OR ALTER PROCEDURE dbo.sp_populate_fact_case_from_reports
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID('tempdb..#src_case') IS NOT NULL
        DROP TABLE #src_case;

    CREATE TABLE #src_case
    (
        report_snapshot_row_id INT NOT NULL PRIMARY KEY,
        priority_id INT NULL,
        status_id INT NULL,
        rfs NVARCHAR(MAX) NULL,
        title NVARCHAR(500) NULL,
        description NVARCHAR(MAX) NULL,
        system_id INT NULL,
        linked_work_orders NVARCHAR(MAX) NULL,
        created_at DATETIME2 NULL,
        updated_at DATETIME2 NULL,
        updated_by VARCHAR(100) NULL,
        toc_id INT NULL,
        class_id INT NULL,
        depot_id INT NULL,
        vehicle_id INT NULL,
        delay_prevented FLOAT NULL,
        labour_hours FLOAT NULL,
        symptom_code_id INT NULL,
        root_code_id INT NULL,
        row_hash AS CONVERT(VARBINARY(32),
            HASHBYTES('SHA2_256',
                CAST(report_snapshot_row_id AS NVARCHAR(20)) + N'|' +
                COALESCE(title, N'') + N'|' +
                COALESCE(CAST(priority_id AS NVARCHAR(10)), N'') + N'|' +
                COALESCE(CAST(status_id AS NVARCHAR(10)), N'') + N'|' +
                COALESCE(CAST(system_id AS NVARCHAR(10)), N'') + N'|' +
                COALESCE(CONVERT(NVARCHAR(30), created_at, 121), N'')
            )
        ) PERSISTED
    );

    INSERT INTO #src_case (
        report_snapshot_row_id,
        priority_id,
        status_id,
        rfs,
        title,
        description,
        system_id,
        linked_work_orders,
        created_at,
        updated_at,
        updated_by,
        toc_id,
        class_id,
        depot_id,
        vehicle_id,
        delay_prevented,
        labour_hours,
        symptom_code_id,
        root_code_id
    )
    SELECT
        drsr.report_snapshot_row_id,
        dp.priority_id,
        ds.status_id,
        NULL AS rfs,
        LEFT(LTRIM(RTRIM(rc.title)), 500) AS title,
        rc.description AS description,
        sys.system_id,
        NULL AS linked_work_orders,
        rc.created_at,
        rc.updated_at,
        LEFT(LTRIM(RTRIM(rc.updated_by)), 100) AS updated_by,
        dt.toc_id,
        dc.class_id,
        dd.depot_id,
        dv.vehicle_id,
        NULL AS delay_prevented,
        NULL AS labour_hours,
        NULL AS symptom_code_id,
        NULL AS root_code_id
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
      AND drsr.report_snapshot_row_id IS NOT NULL;

    BEGIN TRY
        BEGIN TRAN;

        ;WITH tgt_hashed AS
        (
            SELECT
                fc.*,
                CONVERT(VARBINARY(32),
                    HASHBYTES('SHA2_256',
                        CAST(fc.report_snapshot_row_id AS NVARCHAR(20)) + N'|' +
                        COALESCE(fc.title, N'') + N'|' +
                        COALESCE(CAST(fc.priority_id AS NVARCHAR(10)), N'') + N'|' +
                        COALESCE(CAST(fc.status_id AS NVARCHAR(10)), N'') + N'|' +
                        COALESCE(CAST(fc.system_id AS NVARCHAR(10)), N'') + N'|' +
                        COALESCE(CONVERT(NVARCHAR(30), fc.created_at, 121), N'')
                    )
                ) AS row_hash
            FROM dbo.fact_case AS fc
            WHERE fc.report_snapshot_row_id IS NOT NULL
        )
        MERGE dbo.fact_case AS tgt
        USING #src_case AS src
            ON tgt.report_snapshot_row_id = src.report_snapshot_row_id

        WHEN MATCHED
            AND (SELECT th.row_hash FROM tgt_hashed AS th
                 WHERE th.report_snapshot_row_id = tgt.report_snapshot_row_id) <> src.row_hash
        THEN UPDATE SET
            tgt.priority_id = src.priority_id,
            tgt.status_id = src.status_id,
            tgt.rfs = src.rfs,
            tgt.title = src.title,
            tgt.description = src.description,
            tgt.system_id = src.system_id,
            tgt.linked_work_orders = src.linked_work_orders,
            tgt.updated_at = src.updated_at,
            tgt.updated_by = src.updated_by,
            tgt.toc_id = src.toc_id,
            tgt.class_id = src.class_id,
            tgt.depot_id = src.depot_id,
            tgt.vehicle_id = src.vehicle_id,
            tgt.delay_prevented = src.delay_prevented,
            tgt.labour_hours = src.labour_hours,
            tgt.symptom_code_id = src.symptom_code_id,
            tgt.root_code_id = src.root_code_id

        WHEN NOT MATCHED BY TARGET
        THEN INSERT (
            priority_id,
            status_id,
            rfs,
            title,
            description,
            system_id,
            linked_work_orders,
            created_at,
            updated_at,
            updated_by,
            toc_id,
            class_id,
            depot_id,
            vehicle_id,
            delay_prevented,
            labour_hours,
            symptom_code_id,
            root_code_id,
            report_snapshot_row_id
        )
        VALUES (
            src.priority_id,
            src.status_id,
            src.rfs,
            src.title,
            src.description,
            src.system_id,
            src.linked_work_orders,
            src.created_at,
            src.updated_at,
            src.updated_by,
            src.toc_id,
            src.class_id,
            src.depot_id,
            src.vehicle_id,
            src.delay_prevented,
            src.labour_hours,
            src.symptom_code_id,
            src.root_code_id,
            src.report_snapshot_row_id
        );

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH

    IF OBJECT_ID('tempdb..#src_case') IS NOT NULL
        DROP TABLE #src_case;
END;
