CREATE OR ALTER PROCEDURE dbo.sp_populate_dim_priority
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID('tempdb..#src_priority') IS NOT NULL
        DROP TABLE #src_priority;

    CREATE TABLE #src_priority
    (
        priority_name NVARCHAR(50) NOT NULL PRIMARY KEY,
        row_hash AS CONVERT(VARBINARY(32),
            HASHBYTES('SHA2_256', COALESCE(priority_name, N''))
        ) PERSISTED
    );

    INSERT INTO #src_priority (priority_name)
    VALUES (N'Attend at next exam'), (N'Attend at next depot visit'), (N'As soon as possible');

    BEGIN TRY
        BEGIN TRAN;

        ;WITH tgt_hashed AS
        (
            SELECT
                p.*,
                CONVERT(VARBINARY(32),
                    HASHBYTES('SHA2_256', COALESCE(p.priority_name, N''))
                ) AS row_hash
            FROM dbo.dim_priority AS p
        )
        MERGE dbo.dim_priority AS tgt
        USING #src_priority    AS src
            ON tgt.priority_name = src.priority_name

        WHEN MATCHED
            AND (SELECT th.row_hash FROM tgt_hashed AS th WHERE th.priority_name = tgt.priority_name) <> src.row_hash
        THEN UPDATE SET
            tgt.priority_name = src.priority_name

        WHEN NOT MATCHED BY TARGET
        THEN INSERT (priority_name)
            VALUES (src.priority_name)

        WHEN NOT MATCHED BY SOURCE
        THEN DELETE;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH

    IF OBJECT_ID('tempdb..#src_priority') IS NOT NULL
        DROP TABLE #src_priority;
END;
