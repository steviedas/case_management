CREATE OR ALTER PROCEDURE dbo.sp_populate_fact_cases
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID('tempdb..#src_cases') IS NOT NULL
        DROP TABLE #src_cases;

    CREATE TABLE #src_cases
    (
        case_id INT NOT NULL PRIMARY KEY,
        priority INT NULL,
        status INT NULL,
        rfs NVARCHAR(MAX) NULL,
        title NVARCHAR(500) NULL,
        system NVARCHAR(100) NULL,
        date DATE NULL,
        toc_id INT NULL,
        class_id INT NULL,
        depot_id INT NULL,
        row_hash VARBINARY(32) NULL
    );

    -- Extract and transform data from RCMCaseManagement
    INSERT INTO #src_cases (
        case_id,
        priority,
        status,
        rfs,
        title,
        system,
        date,
        toc_id,
        class_id,
        depot_id,
        row_hash
    )
    SELECT
        rcm.Case_ID,
        TRY_CAST(rcm.Priority AS INT) AS priority,
        ds.id AS status,
        rcm.Liked_RFS AS rfs,
        LEFT(rcm.Case_Title, 500) AS title,
        LEFT(rcm.Symptom, 100) AS system,
        rcm.Date_Case_Raised AS date,
        dt.toc_id,
        NULL AS class_id,  -- Not available in RCMCaseManagement
        NULL AS depot_id,  -- Not available in RCMCaseManagement
        CONVERT(VARBINARY(32),
            HASHBYTES('SHA2_256',
                COALESCE(CAST(rcm.Case_ID AS NVARCHAR(10)), N'') + N'|' +
                COALESCE(rcm.Priority, N'') + N'|' +
                COALESCE(rcm.Status, N'') + N'|' +
                COALESCE(rcm.Liked_RFS, N'') + N'|' +
                COALESCE(rcm.Case_Title, N'') + N'|' +
                COALESCE(rcm.Symptom, N'') + N'|' +
                COALESCE(CAST(rcm.Date_Case_Raised AS NVARCHAR(10)), N'') + N'|' +
                COALESCE(rcm.TOC, N'')
            )
        ) AS row_hash
    FROM dbo.RCMCaseManagement AS rcm
    LEFT JOIN dbo.dim_status AS ds
        ON ds.name = LTRIM(RTRIM(rcm.Status))
    LEFT JOIN dbo.dim_toc AS dt
        ON dt.toc_name = LEFT(LTRIM(RTRIM(rcm.TOC)), 40)
    WHERE rcm.Case_ID IS NOT NULL;

    BEGIN TRY
        BEGIN TRAN;

        ;WITH tgt_hashed AS
        (
            SELECT
                fc.*,
                CONVERT(VARBINARY(32),
                    HASHBYTES('SHA2_256',
                        COALESCE(CAST(fc.id AS NVARCHAR(10)), N'') + N'|' +
                        COALESCE(CAST(fc.priority AS NVARCHAR(10)), N'') + N'|' +
                        COALESCE(CAST(fc.status AS NVARCHAR(10)), N'') + N'|' +
                        COALESCE(fc.rfs, N'') + N'|' +
                        COALESCE(fc.title, N'') + N'|' +
                        COALESCE(fc.system, N'') + N'|' +
                        COALESCE(CAST(fc.date AS NVARCHAR(10)), N'') + N'|' +
                        COALESCE(CAST(fc.toc_id AS NVARCHAR(10)), N'')
                    )
                ) AS row_hash
            FROM dbo.fact_cases AS fc
        )
        MERGE dbo.fact_cases AS tgt
        USING #src_cases    AS src
            ON tgt.id = src.case_id

        WHEN MATCHED
            AND (SELECT th.row_hash FROM tgt_hashed AS th WHERE th.id = tgt.id) <> src.row_hash
        THEN UPDATE SET
            tgt.priority = src.priority,
            tgt.status = src.status,
            tgt.rfs = src.rfs,
            tgt.title = src.title,
            tgt.system = src.system,
            tgt.date = src.date,
            tgt.toc_id = src.toc_id,
            tgt.class_id = src.class_id,
            tgt.depot_id = src.depot_id

        WHEN NOT MATCHED BY TARGET
        THEN INSERT (priority, status, rfs, title, system, date, toc_id, class_id, depot_id)
            VALUES (src.priority, src.status, src.rfs, src.title, src.system, src.date, src.toc_id, src.class_id, src.depot_id);

        -- Note: No DELETE clause - we keep historical cases even if removed from source

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH

    IF OBJECT_ID('tempdb..#src_cases') IS NOT NULL
        DROP TABLE #src_cases;
END;
