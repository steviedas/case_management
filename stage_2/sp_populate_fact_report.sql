CREATE OR ALTER PROCEDURE dbo.sp_populate_fact_report
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID('tempdb..#src_report') IS NOT NULL
        DROP TABLE #src_report;

    CREATE TABLE #src_report
    (
        temp_id INT IDENTITY(1,1) PRIMARY KEY,
        title NVARCHAR(255) NOT NULL,
        description NVARCHAR(500) NULL,
        report_frequency NVARCHAR(50) NOT NULL,
        storage_path NVARCHAR(850) NOT NULL,
        date_created DATETIME2 NOT NULL,
        date_updated DATETIME2 NOT NULL,
        partitioned_by NVARCHAR(255) NULL,
        row_hash AS CONVERT(VARBINARY(32),
            HASHBYTES('SHA2_256',
                COALESCE(title, N'') + N'|' +
                COALESCE(description, N'') + N'|' +
                COALESCE(report_frequency, N'') + N'|' +
                COALESCE(storage_path, N'') + N'|' +
                COALESCE(CONVERT(NVARCHAR(30), date_created, 121), N'') + N'|' +
                COALESCE(CONVERT(NVARCHAR(30), date_updated, 121), N'') + N'|' +
                COALESCE(partitioned_by, N'')
            )
        ) PERSISTED
    );

    -- Load data from staging table (populated by Databricks)
    INSERT INTO #src_report (
        title,
        description,
        report_frequency,
        storage_path,
        date_created,
        date_updated,
        partitioned_by
    )
    SELECT DISTINCT
        LTRIM(RTRIM(title)) AS title,
        NULLIF(LTRIM(RTRIM(description)), N'') AS description,
        LTRIM(RTRIM(report_frequency)) AS report_frequency,
        LTRIM(RTRIM(storage_path)) AS storage_path,
        date_created,
        date_updated,
        NULLIF(LTRIM(RTRIM(partitioned_by)), N'') AS partitioned_by
    FROM dbo.Report
    WHERE title IS NOT NULL
      AND LTRIM(RTRIM(title)) <> N'';

    BEGIN TRY
        BEGIN TRAN;

        ;WITH tgt_hashed AS
        (
            SELECT
                fr.*,
                CONVERT(VARBINARY(32),
                    HASHBYTES('SHA2_256',
                        COALESCE(fr.title, N'') + N'|' +
                        COALESCE(fr.description, N'') + N'|' +
                        COALESCE(fr.report_frequency, N'') + N'|' +
                        COALESCE(fr.storage_path, N'') + N'|' +
                        COALESCE(CONVERT(NVARCHAR(30), fr.date_created, 121), N'') + N'|' +
                        COALESCE(CONVERT(NVARCHAR(30), fr.date_updated, 121), N'') + N'|' +
                        COALESCE(fr.partitioned_by, N'')
                    )
                ) AS row_hash
            FROM dbo.fact_report AS fr
        )
        MERGE dbo.fact_report AS tgt
        USING #src_report AS src
            ON tgt.title = src.title

        WHEN MATCHED
            AND (SELECT th.row_hash FROM tgt_hashed AS th
                 WHERE th.report_id = tgt.report_id) <> src.row_hash
        THEN UPDATE SET
            tgt.description = src.description,
            tgt.report_frequency = src.report_frequency,
            tgt.storage_path = src.storage_path,
            tgt.date_updated = src.date_updated,
            tgt.partitioned_by = src.partitioned_by

        WHEN NOT MATCHED BY TARGET
        THEN INSERT (
            title,
            description,
            report_frequency,
            storage_path,
            date_created,
            date_updated,
            partitioned_by
        )
        VALUES (
            src.title,
            src.description,
            src.report_frequency,
            src.storage_path,
            src.date_created,
            src.date_updated,
            src.partitioned_by
        )

        WHEN NOT MATCHED BY SOURCE
        THEN DELETE;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH

    IF OBJECT_ID('tempdb..#src_report') IS NOT NULL
        DROP TABLE #src_report;
END;
