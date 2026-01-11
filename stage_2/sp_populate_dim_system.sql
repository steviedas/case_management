CREATE OR ALTER PROCEDURE dbo.sp_populate_dim_system
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID('tempdb..#src_system') IS NOT NULL
        DROP TABLE #src_system;

    CREATE TABLE #src_system
    (
        system_name NVARCHAR(100) NOT NULL PRIMARY KEY,
        row_hash AS CONVERT(VARBINARY(32),
            HASHBYTES('SHA2_256', COALESCE(system_name, N''))
        ) PERSISTED
    );

    -- Seed predefined system values
    INSERT INTO #src_system (system_name)
    VALUES
        (N'Engine'),
        (N'Transmission'),
        (N'Brakes'),
        (N'Cooling');

    BEGIN TRY
        BEGIN TRAN;

        ;WITH tgt_hashed AS
        (
            SELECT
                s.*,
                CONVERT(VARBINARY(32),
                    HASHBYTES('SHA2_256', COALESCE(s.system_name, N''))
                ) AS row_hash
            FROM dbo.dim_system AS s
        )
        MERGE dbo.dim_system AS tgt
        USING #src_system    AS src
            ON tgt.system_name = src.system_name

        WHEN MATCHED
            AND (SELECT th.row_hash FROM tgt_hashed AS th WHERE th.system_name = tgt.system_name) <> src.row_hash
        THEN UPDATE SET
            tgt.system_name = src.system_name

        WHEN NOT MATCHED BY TARGET
        THEN INSERT (system_name)
            VALUES (src.system_name)

        WHEN NOT MATCHED BY SOURCE
        THEN DELETE;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH

    IF OBJECT_ID('tempdb..#src_system') IS NOT NULL
        DROP TABLE #src_system;
END;
