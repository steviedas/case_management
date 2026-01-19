CREATE OR ALTER PROCEDURE dbo.sp_populate_fact_alert
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Create performance indexes on staging tables if they don't exist
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.Alerts') AND name = 'IX_Alerts_SourceAlertId_Covering')
    BEGIN
        CREATE NONCLUSTERED INDEX IX_Alerts_SourceAlertId_Covering
        ON dbo.Alerts (source_alert_id)
        INCLUDE (alert_source, alert_name, alert_timestamp, date_created, vehicle, alert_status, p_date);
    END

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.AlertTraceReference') AND name = 'IX_AlertTraceReference_VehicleAlertDate')
    BEGIN
        CREATE NONCLUSTERED INDEX IX_AlertTraceReference_VehicleAlertDate
        ON dbo.AlertTraceReference (vehicle, alert_name, trace_date)
        INCLUDE (storage_path);
    END

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.RakeHistory') AND name = 'IX_RakeHistory_Vehicle')
    BEGIN
        CREATE NONCLUSTERED INDEX IX_RakeHistory_Vehicle
        ON dbo.RakeHistory (Vehicle)
        INCLUDE (TOC, Vehicle_Class, R2_Depot);
    END

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.fact_alert_trace_reference') AND name = 'IX_FactAlertTraceReference_StoragePath')
    BEGIN
        CREATE NONCLUSTERED INDEX IX_FactAlertTraceReference_StoragePath
        ON dbo.fact_alert_trace_reference (storage_path)
        INCLUDE (id);
    END

    -- Indexes on dimension tables for join performance
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.dim_vehicle') AND name = 'IX_DimVehicle_Vehicle')
    BEGIN
        CREATE NONCLUSTERED INDEX IX_DimVehicle_Vehicle
        ON dbo.dim_vehicle (vehicle)
        INCLUDE (vehicle_id);
    END

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.dim_alert_status') AND name = 'IX_DimAlertStatus_StatusName')
    BEGIN
        CREATE NONCLUSTERED INDEX IX_DimAlertStatus_StatusName
        ON dbo.dim_alert_status (alert_status_name)
        INCLUDE (alert_status_id);
    END

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.dim_toc') AND name = 'IX_DimToc_TocName')
    BEGIN
        CREATE NONCLUSTERED INDEX IX_DimToc_TocName
        ON dbo.dim_toc (toc_name)
        INCLUDE (toc_id);
    END

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.dim_class') AND name = 'IX_DimClass_ClassName')
    BEGIN
        CREATE NONCLUSTERED INDEX IX_DimClass_ClassName
        ON dbo.dim_class (class_name)
        INCLUDE (class_id);
    END

    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.dim_depot') AND name = 'IX_DimDepot_DepotName')
    BEGIN
        CREATE NONCLUSTERED INDEX IX_DimDepot_DepotName
        ON dbo.dim_depot (depot_name)
        INCLUDE (depot_id);
    END

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
    -- dim_alert_status has: 'Pending', 'Accepted', 'Rejected'
    LEFT JOIN dbo.dim_alert_status AS ast
        ON ast.alert_status_name = CASE LOWER(LTRIM(RTRIM(a.alert_status)))
            WHEN 'Open' THEN 'Pending'       -- Map open to Pending (awaiting review)
            WHEN 'Closed' THEN 'Accepted'    -- Map closed to Accepted (resolved)
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
        AND a.source_alert_id <> N'';

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
