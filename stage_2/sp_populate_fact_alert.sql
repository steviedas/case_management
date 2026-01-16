CREATE OR ALTER PROCEDURE dbo.sp_populate_fact_alert
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID('tempdb..#src_alert') IS NOT NULL
        DROP TABLE #src_alert;

    CREATE TABLE #src_alert
    (
        source_alert_id NVARCHAR(100) NOT NULL PRIMARY KEY,
        title NVARCHAR(200) NULL,
        alert_timestamp DATETIME2 NULL,
        status_id INT NULL,
        date_created DATETIME2 NULL,
        date_reviewed DATETIME2 NULL,
        reviewed_by NVARCHAR(100) NULL,
        rejection_reason NVARCHAR(MAX) NULL,
        vehicle_id INT NULL,
        trace_ref_id INT NULL,
        alert_source NVARCHAR(100) NOT NULL,
        toc_id INT NULL,
        class_id INT NULL,
        depot_id INT NULL,
        row_hash AS CONVERT(VARBINARY(32),
            HASHBYTES('SHA2_256',
                COALESCE(source_alert_id, N'') + N'|' +
                COALESCE(title, N'') + N'|' +
                COALESCE(CONVERT(NVARCHAR(30), alert_timestamp, 121), N'') + N'|' +
                COALESCE(CAST(status_id AS NVARCHAR(10)), N'') + N'|' +
                COALESCE(CAST(vehicle_id AS NVARCHAR(10)), N'') + N'|' +
                COALESCE(CAST(trace_ref_id AS NVARCHAR(10)), N'') + N'|' +
                COALESCE(alert_source, N'')
            )
        ) PERSISTED
    );

    -- Load data from Alerts table (populated by Databricks)
    INSERT INTO #src_alert (
        source_alert_id,
        title,
        alert_timestamp,
        status_id,
        date_created,
        date_reviewed,
        reviewed_by,
        rejection_reason,
        vehicle_id,
        trace_ref_id,
        alert_source,
        toc_id,
        class_id,
        depot_id
    )
    SELECT
        a.source_alert_id,
        LTRIM(RTRIM(a.alert_name)) AS title,
        a.alert_timestamp,
        ast.alert_status_id AS status_id,
        a.date_created,
        NULL AS date_reviewed,
        NULL AS reviewed_by,
        NULL AS rejection_reason,
        v.vehicle_id,
        tr.id AS trace_ref_id,
        a.alert_source,
        toc.toc_id,
        c.class_id,
        d.depot_id
    FROM dbo.Alerts AS a

    -- Map alert_status values and join to dim_alert_status to get status_id
    -- dbo.Alerts has: 'open', 'closed'
    -- dim_alert_status has: 'Accepted', 'Rejected'
    LEFT JOIN dbo.dim_alert_status AS ast
        ON ast.alert_status_name = CASE LOWER(LTRIM(RTRIM(a.alert_status)))
            WHEN 'open' THEN 'Accepted'      -- Map open to Accepted (adjust as needed)
            WHEN 'closed' THEN 'Accepted'    -- Map closed to Accepted (adjust as needed)
            ELSE NULL
        END

    -- Join to dim_vehicle to get vehicle_id
    LEFT JOIN dbo.dim_vehicle AS v
        ON v.vehicle = LTRIM(RTRIM(a.vehicle))

    -- Join to fact_alert_trace_reference to get trace_ref_id
    -- Match on vehicle, alert_name, and date from AlertTraceReference
    LEFT JOIN dbo.AlertTraceReference AS atr
        ON atr.vehicle = LTRIM(RTRIM(a.vehicle))
        AND atr.alert_name = LTRIM(RTRIM(a.alert_name))
        AND atr.trace_date = a.p_date
    LEFT JOIN dbo.fact_alert_trace_reference AS tr
        ON tr.storage_path = atr.storage_path

    -- Join to RakeHistory to get TOC, Class, Depot based on vehicle and date
    LEFT JOIN dbo.RakeHistory AS rh
        ON rh.Vehicle = LTRIM(RTRIM(a.vehicle))
        -- AND CAST(rh.Date AS DATE) = a.p_date

    -- Join to dimension tables for toc_id, class_id, depot_id
    LEFT JOIN dbo.dim_toc AS toc
        ON toc.toc_name = LTRIM(RTRIM(rh.TOC))
    LEFT JOIN dbo.dim_class AS c
        ON c.class_name = LTRIM(RTRIM(rh.Vehicle_Class))
    LEFT JOIN dbo.dim_depot AS d
        ON d.depot_name = LTRIM(RTRIM(rh.R2_Depot))

    WHERE a.source_alert_id IS NOT NULL
        AND LTRIM(RTRIM(a.source_alert_id)) <> N'';

    BEGIN TRY
        BEGIN TRAN;

        ;WITH tgt_hashed AS
        (
            SELECT
                fa.*,
                CONVERT(VARBINARY(32),
                    HASHBYTES('SHA2_256',
                        COALESCE(fa.source_alert_id, N'') + N'|' +
                        COALESCE(fa.title, N'') + N'|' +
                        COALESCE(CONVERT(NVARCHAR(30), fa.alert_timestamp, 121), N'') + N'|' +
                        COALESCE(CAST(fa.status_id AS NVARCHAR(10)), N'') + N'|' +
                        COALESCE(CAST(fa.vehicle_id AS NVARCHAR(10)), N'') + N'|' +
                        COALESCE(CAST(fa.trace_ref_id AS NVARCHAR(10)), N'') + N'|' +
                        COALESCE(fa.alert_source, N'')
                    )
                ) AS row_hash
            FROM dbo.fact_alert AS fa
        )
        MERGE dbo.fact_alert AS tgt
        USING #src_alert AS src
            ON tgt.source_alert_id = src.source_alert_id

        WHEN MATCHED
            AND (SELECT th.row_hash FROM tgt_hashed AS th
                 WHERE th.source_alert_id = tgt.source_alert_id) <> src.row_hash
        THEN UPDATE SET
            tgt.title = src.title,
            tgt.alert_timestamp = src.alert_timestamp,
            tgt.status_id = src.status_id,
            tgt.date_created = src.date_created,
            tgt.vehicle_id = src.vehicle_id,
            tgt.trace_ref_id = src.trace_ref_id,
            tgt.alert_source = src.alert_source,
            tgt.toc_id = src.toc_id,
            tgt.class_id = src.class_id,
            tgt.depot_id = src.depot_id

        WHEN NOT MATCHED BY TARGET
        THEN INSERT (
            source_alert_id,
            title,
            alert_timestamp,
            status_id,
            date_created,
            date_reviewed,
            reviewed_by,
            rejection_reason,
            vehicle_id,
            trace_ref_id,
            alert_source,
            toc_id,
            class_id,
            depot_id
        )
        VALUES (
            src.source_alert_id,
            src.title,
            src.alert_timestamp,
            src.status_id,
            src.date_created,
            src.date_reviewed,
            src.reviewed_by,
            src.rejection_reason,
            src.vehicle_id,
            src.trace_ref_id,
            src.alert_source,
            src.toc_id,
            src.class_id,
            src.depot_id
        )

        WHEN NOT MATCHED BY SOURCE
        THEN DELETE;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH

    IF OBJECT_ID('tempdb..#src_alert') IS NOT NULL
        DROP TABLE #src_alert;
END;
