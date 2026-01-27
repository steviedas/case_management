CREATE OR ALTER PROCEDURE dbo.sp_populate_dim_record_type
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID('tempdb..#src_record_type') IS NOT NULL
        DROP TABLE #src_record_type;

    CREATE TABLE #src_record_type
    (
        type NVARCHAR(50) NOT NULL PRIMARY KEY,
        row_hash AS CONVERT(VARBINARY(32),
            HASHBYTES('SHA2_256', COALESCE(type, N''))
        ) PERSISTED
    );

    INSERT INTO #src_record_type (type)
    VALUES (N'description'), (N'update'), (N'note'), (N'Turbo Clean'), (N'Raft Change');

    BEGIN TRY
        BEGIN TRAN;

        ;WITH tgt_hashed AS
        (
            SELECT
                rt.*,
                CONVERT(VARBINARY(32),
                    HASHBYTES('SHA2_256', COALESCE(rt.type, N''))
                ) AS row_hash
            FROM dbo.dim_record_type AS rt
        )
        MERGE dbo.dim_record_type AS tgt
        USING #src_record_type    AS src
            ON tgt.type = src.type

        WHEN MATCHED
            AND (SELECT th.row_hash FROM tgt_hashed AS th WHERE th.type = tgt.type) <> src.row_hash
        THEN UPDATE SET
            tgt.type = src.type

        WHEN NOT MATCHED BY TARGET
        THEN INSERT (type)
            VALUES (src.type)

        WHEN NOT MATCHED BY SOURCE
        THEN DELETE;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH

    IF OBJECT_ID('tempdb..#src_record_type') IS NOT NULL
        DROP TABLE #src_record_type;
END;
