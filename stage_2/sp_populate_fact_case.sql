CREATE OR ALTER PROCEDURE dbo.sp_populate_fact_case
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID('tempdb..#src_case') IS NOT NULL
        DROP TABLE #src_case;

    CREATE TABLE #src_case
    (
        source_case_id INT NOT NULL PRIMARY KEY,
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
        row_hash AS CONVERT(VARBINARY(32),
            HASHBYTES('SHA2_256',
                CAST(source_case_id AS NVARCHAR(10)) + N'|' +
                COALESCE(title, N'') + N'|' +
                COALESCE(CAST(priority_id AS NVARCHAR(10)), N'') + N'|' +
                COALESCE(CAST(status_id AS NVARCHAR(10)), N'') + N'|' +
                COALESCE(CAST(system_id AS NVARCHAR(10)), N'') + N'|' +
                COALESCE(CONVERT(NVARCHAR(30), created_at, 121), N'')
            )
        ) PERSISTED
    );

    -- Load data from RCMCaseManagement table
    INSERT INTO #src_case (
        source_case_id,
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
        vehicle_id
    )
    SELECT
        rcm.Case_ID AS source_case_id,
        p.priority_id,
        s.status_id,
        rcm.Liked_RFS AS rfs,
        LEFT(LTRIM(RTRIM(rcm.Case_Title)), 500) AS title,
        rcm.Case_Description AS description,
        sys.system_id,
        rcm.Associated_Intervention_IDs AS linked_work_orders,
        rcm.Date_Case_Raised AS created_at,
        rcm.Last_Update_Date AS updated_at,
        LEFT(LTRIM(RTRIM(rcm.Raised_By)), 100) AS updated_by,
        toc.toc_id,
        c.class_id,
        d.depot_id,
        v.vehicle_id
    FROM dbo.RCMCaseManagement AS rcm

    -- Join to dim_priority to get priority_id
    LEFT JOIN dbo.dim_priority AS p
        ON p.priority_name = LTRIM(RTRIM(rcm.Priority))

    -- Map status values and join to dim_status to get status_id
    -- RCMCaseManagement has: NULL, 'Completed', 'Monitored, NFF', 'Open', 'Re-opened'
    -- dim_status has: 'Completed', 'Open', 'Rejected'
    LEFT JOIN dbo.dim_status AS s
        ON s.status_name = CASE
            WHEN rcm.Status IS NULL THEN 'Open'
            WHEN LOWER(LTRIM(RTRIM(rcm.Status))) = 'completed' THEN 'Completed'
            WHEN LOWER(LTRIM(RTRIM(rcm.Status))) = 'monitored, nff' THEN 'Completed'
            WHEN LOWER(LTRIM(RTRIM(rcm.Status))) = 'open' THEN 'Open'
            WHEN LOWER(LTRIM(RTRIM(rcm.Status))) = 're-opened' THEN 'Open'
            ELSE NULL
        END

    -- Map Symptom codes to dim_system to get system_id
    -- A* codes = AIR SYSTEM → Brakes
    -- D* codes = DIESEL ENGINE → Engine
    -- L* codes = LUB.OIL/FUEL → Engine
    -- Q* codes = COOLING/HYDROSTATICS → Cooling
    -- T* codes = TRANSMISSION → Transmission
    -- E*, M*, N*, Z*, OS codes = NULL (no clear match)
    LEFT JOIN dbo.dim_system AS sys
        ON sys.system_name = CASE
            WHEN LTRIM(RTRIM(rcm.Symptom)) LIKE 'A%' THEN 'Brakes'
            WHEN LTRIM(RTRIM(rcm.Symptom)) LIKE 'D%' THEN 'Engine'
            WHEN LTRIM(RTRIM(rcm.Symptom)) LIKE 'L%' THEN 'Engine'
            WHEN LTRIM(RTRIM(rcm.Symptom)) LIKE 'Q%' THEN 'Cooling'
            WHEN LTRIM(RTRIM(rcm.Symptom)) LIKE 'T%' THEN 'Transmission'
            ELSE NULL
        END

    -- Join to dim_toc to get toc_id
    LEFT JOIN dbo.dim_toc AS toc
        ON toc.toc_name = LTRIM(RTRIM(rcm.TOC))

    -- Join to dim_vehicle to get vehicle_id
    LEFT JOIN dbo.dim_vehicle AS v
        ON v.vehicle = LTRIM(RTRIM(rcm.Vehicle))

    -- Join to RakeHistory to get Class and Depot based on Vehicle and date
    LEFT JOIN dbo.RakeHistory AS rh
        ON rh.Vehicle = LTRIM(RTRIM(rcm.Vehicle))
        -- AND CAST(rh.Date AS DATE) = rcm.Date_Case_Raised

    -- Join to dim_class to get class_id
    LEFT JOIN dbo.dim_class AS c
        ON c.class_name = LTRIM(RTRIM(rh.Vehicle_Class))

    -- Join to dim_depot to get depot_id
    LEFT JOIN dbo.dim_depot AS d
        ON d.depot_name = LTRIM(RTRIM(rh.R2_Depot))

    WHERE rcm.Case_ID IS NOT NULL;

    BEGIN TRY
        BEGIN TRAN;

        ;WITH tgt_hashed AS
        (
            SELECT
                fc.*,
                CONVERT(VARBINARY(32),
                    HASHBYTES('SHA2_256',
                        CAST(fc.case_id AS NVARCHAR(10)) + N'|' +
                        COALESCE(fc.title, N'') + N'|' +
                        COALESCE(CAST(fc.priority_id AS NVARCHAR(10)), N'') + N'|' +
                        COALESCE(CAST(fc.status_id AS NVARCHAR(10)), N'') + N'|' +
                        COALESCE(CAST(fc.system_id AS NVARCHAR(10)), N'') + N'|' +
                        COALESCE(CONVERT(NVARCHAR(30), fc.created_at, 121), N'')
                    )
                ) AS row_hash
            FROM dbo.fact_case AS fc
        )
        MERGE dbo.fact_case AS tgt
        USING #src_case AS src
            ON tgt.case_id = src.source_case_id

        WHEN MATCHED
            AND (SELECT th.row_hash FROM tgt_hashed AS th
                 WHERE th.case_id = tgt.case_id) <> src.row_hash
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
            tgt.vehicle_id = src.vehicle_id

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
            vehicle_id
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
            src.vehicle_id
        )

        WHEN NOT MATCHED BY SOURCE
        THEN DELETE;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH

    IF OBJECT_ID('tempdb..#src_case') IS NOT NULL
        DROP TABLE #src_case;
END;
