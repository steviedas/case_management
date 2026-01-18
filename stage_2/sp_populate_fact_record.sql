CREATE OR ALTER PROCEDURE dbo.sp_populate_fact_record
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID('tempdb..#src_record') IS NOT NULL
        DROP TABLE #src_record;

    CREATE TABLE #src_record
    (
        temp_id INT IDENTITY(1,1) PRIMARY KEY,
        created_at DATETIME2 NULL,
        updated_at DATETIME2 NULL,
        record NVARCHAR(MAX) NULL,
        case_id INT NOT NULL,
        author NVARCHAR(100) NULL,
        record_type_id INT NULL,
        row_hash AS CONVERT(VARBINARY(32),
            HASHBYTES('SHA2_256',
                CAST(case_id AS NVARCHAR(10)) + N'|' +
                COALESCE(record, N'') + N'|' +
                COALESCE(CAST(record_type_id AS NVARCHAR(10)), N'') + N'|' +
                COALESCE(CONVERT(NVARCHAR(30), created_at, 121), N'')
            )
        ) PERSISTED
    );

    -- Extract records from RCMCaseManagement
    -- Creates three types of records per case:
    -- 1. 'description' - from Case_Description
    -- 2. 'update' - from Case_Updates
    -- 3. 'note' - from Notes

    -- Insert description records
    INSERT INTO #src_record (created_at, updated_at, record, case_id, author, record_type_id)
    SELECT
        rcm.Date_Case_Raised AS created_at,
        rcm.Last_Update_Date AS updated_at,
        rcm.Case_Description AS record,
        fc.case_id,
        LEFT(LTRIM(RTRIM(rcm.Raised_By)), 100) AS author,
        rt.record_type_id
    FROM dbo.RCMCaseManagement AS rcm
    INNER JOIN dbo.fact_case AS fc
        ON fc.case_id = rcm.Case_ID
    INNER JOIN dbo.dim_record_type AS rt
        ON rt.type = 'description'
    WHERE rcm.Case_Description IS NOT NULL
      AND LTRIM(RTRIM(rcm.Case_Description)) <> N'';

    -- Insert update records
    INSERT INTO #src_record (created_at, updated_at, record, case_id, author, record_type_id)
    SELECT
        rcm.Last_Update_Date AS created_at,
        rcm.Last_Update_Date AS updated_at,
        rcm.Case_Updates AS record,
        fc.case_id,
        LEFT(LTRIM(RTRIM(rcm.Raised_By)), 100) AS author,
        rt.record_type_id
    FROM dbo.RCMCaseManagement AS rcm
    INNER JOIN dbo.fact_case AS fc
        ON fc.case_id = rcm.Case_ID
    INNER JOIN dbo.dim_record_type AS rt
        ON rt.type = 'update'
    WHERE rcm.Case_Updates IS NOT NULL
      AND LTRIM(RTRIM(rcm.Case_Updates)) <> N'';

    -- Insert note records
    INSERT INTO #src_record (created_at, updated_at, record, case_id, author, record_type_id)
    SELECT
        rcm.Last_Update_Date AS created_at,
        rcm.Last_Update_Date AS updated_at,
        rcm.Notes AS record,
        fc.case_id,
        LEFT(LTRIM(RTRIM(rcm.Raised_By)), 100) AS author,
        rt.record_type_id
    FROM dbo.RCMCaseManagement AS rcm
    INNER JOIN dbo.fact_case AS fc
        ON fc.case_id = rcm.Case_ID
    INNER JOIN dbo.dim_record_type AS rt
        ON rt.type = 'note'
    WHERE rcm.Notes IS NOT NULL
      AND LTRIM(RTRIM(rcm.Notes)) <> N'';

    BEGIN TRY
        BEGIN TRAN;

        ;WITH tgt_hashed AS
        (
            SELECT
                fr.*,
                CONVERT(VARBINARY(32),
                    HASHBYTES('SHA2_256',
                        CAST(fr.case_id AS NVARCHAR(10)) + N'|' +
                        COALESCE(fr.record, N'') + N'|' +
                        COALESCE(CAST(fr.record_type_id AS NVARCHAR(10)), N'') + N'|' +
                        COALESCE(CONVERT(NVARCHAR(30), fr.created_at, 121), N'')
                    )
                ) AS row_hash
            FROM dbo.fact_record AS fr
        )
        MERGE dbo.fact_record AS tgt
        USING #src_record AS src
            ON tgt.case_id = src.case_id
           AND tgt.record_type_id = src.record_type_id
           AND (SELECT th.row_hash FROM tgt_hashed AS th
                WHERE th.record_id = tgt.record_id) = src.row_hash

        WHEN NOT MATCHED BY TARGET
        THEN INSERT (
            created_at,
            updated_at,
            record,
            case_id,
            author,
            record_type_id
        )
        VALUES (
            src.created_at,
            src.updated_at,
            src.record,
            src.case_id,
            src.author,
            src.record_type_id
        )

        WHEN NOT MATCHED BY SOURCE
        THEN DELETE;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH

    IF OBJECT_ID('tempdb..#src_record') IS NOT NULL
        DROP TABLE #src_record;
END;
