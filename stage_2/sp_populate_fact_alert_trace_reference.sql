CREATE OR ALTER PROCEDURE dbo.sp_populate_fact_alert_trace_reference
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID('tempdb..#src_trace_ref') IS NOT NULL
        DROP TABLE #src_trace_ref;

    CREATE TABLE #src_trace_ref
    (
        temp_id INT IDENTITY(1,1) PRIMARY KEY,
        storage_path NVARCHAR(850) NOT NULL UNIQUE,
        file_format NVARCHAR(50) NULL,
        date_created DATETIME2 NOT NULL,
        date_updated DATETIME2 NOT NULL,
        row_hash AS CONVERT(VARBINARY(32),
            HASHBYTES('SHA2_256',
                COALESCE(storage_path, N'') + N'|' +
                COALESCE(file_format, N'') + N'|' +
                CONVERT(NVARCHAR(30), date_created, 121) + N'|' +
                CONVERT(NVARCHAR(30), date_updated, 121)
            )
        ) PERSISTED
    );

    -- Load data from staging table (populated by Databricks)
    INSERT INTO #src_trace_ref (storage_path, file_format, date_created, date_updated)
    SELECT DISTINCT
        LTRIM(RTRIM(storage_path)) AS storage_path,
        LTRIM(RTRIM(file_format)) AS file_format,
        date_created,
        date_updated
    FROM dbo.AlertTraceReference
    WHERE storage_path IS NOT NULL
      AND LTRIM(RTRIM(storage_path)) <> N'';

    BEGIN TRY
        BEGIN TRAN;

        ;WITH tgt_hashed AS
        (
            SELECT
                tr.*,
                CONVERT(VARBINARY(32),
                    HASHBYTES('SHA2_256',
                        COALESCE(tr.storage_path, N'') + N'|' +
                        COALESCE(tr.file_format, N'') + N'|' +
                        CONVERT(NVARCHAR(30), tr.date_created, 121) + N'|' +
                        CONVERT(NVARCHAR(30), tr.date_updated, 121)
                    )
                ) AS row_hash
            FROM dbo.fact_alert_trace_reference AS tr
        )
        MERGE dbo.fact_alert_trace_reference AS tgt
        USING #src_trace_ref AS src
            ON tgt.storage_path = src.storage_path

        WHEN MATCHED
            AND (SELECT th.row_hash FROM tgt_hashed AS th
                 WHERE th.storage_path = tgt.storage_path) <> src.row_hash
        THEN UPDATE SET
            tgt.file_format = src.file_format,
            tgt.date_updated = src.date_updated

        WHEN NOT MATCHED BY TARGET
        THEN INSERT (storage_path, file_format, date_created, date_updated)
            VALUES (src.storage_path, src.file_format, src.date_created, src.date_updated)

        WHEN NOT MATCHED BY SOURCE
        THEN DELETE;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH

    IF OBJECT_ID('tempdb..#src_trace_ref') IS NOT NULL
        DROP TABLE #src_trace_ref;
END;
