CREATE OR ALTER PROCEDURE dbo.sp_populate_dim_status
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID('tempdb..#src_status') IS NOT NULL
        DROP TABLE #src_status;

    CREATE TABLE #src_status
    (
        name NVARCHAR(50) NOT NULL PRIMARY KEY,
        row_hash AS CONVERT(VARBINARY(32),
            HASHBYTES('SHA2_256', COALESCE(name, N''))
        ) PERSISTED
    );

    INSERT INTO #src_status (name)
    SELECT DISTINCT
        rcm.Status
    FROM dbo.RCMCaseManagement AS rcm
    WHERE rcm.Status IS NOT NULL;

    BEGIN TRY
        BEGIN TRAN;

        ;WITH tgt_hashed AS
        (
            SELECT
                s.*,
                CONVERT(VARBINARY(32),
                    HASHBYTES('SHA2_256', COALESCE(s.name, N''))
                ) AS row_hash
            FROM dbo.dim_status AS s
        )
        MERGE dbo.dim_status AS tgt
        USING #src_status    AS src
            ON tgt.name = src.name

        WHEN MATCHED
            AND (SELECT th.row_hash FROM tgt_hashed AS th WHERE th.name = tgt.name) <> src.row_hash
        THEN UPDATE SET
            tgt.name = src.name

        WHEN NOT MATCHED BY TARGET
        THEN INSERT (name)
            VALUES (src.name)

        WHEN NOT MATCHED BY SOURCE
        THEN DELETE;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH

    IF OBJECT_ID('tempdb..#src_status') IS NOT NULL
        DROP TABLE #src_status;
END;
