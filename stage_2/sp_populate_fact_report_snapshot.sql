CREATE OR ALTER PROCEDURE dbo.sp_populate_fact_report_snapshot
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID('tempdb..#src_report_snapshot') IS NOT NULL
        DROP TABLE #src_report_snapshot;

    CREATE TABLE #src_report_snapshot
    (
        temp_id INT IDENTITY(1,1) PRIMARY KEY,
        report_id INT NOT NULL,
        title NVARCHAR(255) NOT NULL,
        date_created DATETIME2 NOT NULL,
        start_time DATETIME2 NOT NULL,
        end_time DATETIME2 NOT NULL,
        date_updated DATETIME2 NOT NULL,
        row_hash AS CONVERT(VARBINARY(32),
            HASHBYTES('SHA2_256',
                CAST(report_id AS NVARCHAR(10)) + N'|' +
                COALESCE(title, N'') + N'|' +
                COALESCE(CONVERT(NVARCHAR(30), date_created, 121), N'') + N'|' +
                COALESCE(CONVERT(NVARCHAR(30), start_time, 121), N'') + N'|' +
                COALESCE(CONVERT(NVARCHAR(30), end_time, 121), N'') + N'|' +
                COALESCE(CONVERT(NVARCHAR(30), date_updated, 121), N'')
            )
        ) PERSISTED,
        UNIQUE (report_id, start_time, end_time)
    );

    -- Load data from staging table (populated by Databricks)
    INSERT INTO #src_report_snapshot (
        report_id,
        title,
        date_created,
        start_time,
        end_time,
        date_updated
    )
    SELECT DISTINCT
        fr.report_id,
        ct.clean_title AS title,
        rs.date_created,
        rs.start_time,
        rs.end_time,
        rs.date_updated
    FROM dbo.ReportSnapshot AS rs
    OUTER APPLY (
        SELECT LTRIM(RTRIM(rs.title)) AS clean_title
    ) AS ct
    OUTER APPLY (
        SELECT
            CASE
                WHEN CHARINDEX(N'_to_', ct.clean_title) > 0
                    THEN LEFT(ct.clean_title, CHARINDEX(N'_to_', ct.clean_title) - 1)
                ELSE NULL
            END AS pre_range
    ) AS pr
    OUTER APPLY (
        SELECT
            CASE
                WHEN CHARINDEX(N' w/c ', ct.clean_title) > 0
                    THEN LEFT(ct.clean_title,
                              CHARINDEX(N' w/c ', ct.clean_title) - 1)
                WHEN CHARINDEX(N'_to_', ct.clean_title) > 0
                    THEN CASE
                        WHEN LEN(pr.pre_range) > 11
                            THEN LEFT(pr.pre_range, LEN(pr.pre_range) - 11)
                        ELSE pr.pre_range
                    END
                ELSE ct.clean_title
            END AS base_title
    ) AS bt
    INNER JOIN dbo.fact_report AS fr
        ON fr.title = bt.base_title
    WHERE rs.title IS NOT NULL
      AND LTRIM(RTRIM(rs.title)) <> N'';

    BEGIN TRY
        BEGIN TRAN;

        ;WITH tgt_hashed AS
        (
            SELECT
                frs.*,
                CONVERT(VARBINARY(32),
                    HASHBYTES('SHA2_256',
                        CAST(frs.report_id AS NVARCHAR(10)) + N'|' +
                        COALESCE(frs.title, N'') + N'|' +
                        COALESCE(CONVERT(NVARCHAR(30), frs.date_created, 121), N'') + N'|' +
                        COALESCE(CONVERT(NVARCHAR(30), frs.start_time, 121), N'') + N'|' +
                        COALESCE(CONVERT(NVARCHAR(30), frs.end_time, 121), N'') + N'|' +
                        COALESCE(CONVERT(NVARCHAR(30), frs.date_updated, 121), N'')
                    )
                ) AS row_hash
            FROM dbo.fact_report_snapshot AS frs
        )
        MERGE dbo.fact_report_snapshot AS tgt
        USING #src_report_snapshot AS src
            ON tgt.report_id = src.report_id
           AND tgt.start_time = src.start_time
           AND tgt.end_time = src.end_time

        WHEN MATCHED
            AND (SELECT th.row_hash FROM tgt_hashed AS th
                 WHERE th.snapshot_id = tgt.snapshot_id) <> src.row_hash
        THEN UPDATE SET
            tgt.title = src.title,
            tgt.date_created = src.date_created,
            tgt.date_updated = src.date_updated

        WHEN NOT MATCHED BY TARGET
        THEN INSERT (
            report_id,
            title,
            date_created,
            start_time,
            end_time,
            date_updated
        )
        VALUES (
            src.report_id,
            src.title,
            src.date_created,
            src.start_time,
            src.end_time,
            src.date_updated
        )

        WHEN NOT MATCHED BY SOURCE
        THEN DELETE;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH

    IF OBJECT_ID('tempdb..#src_report_snapshot') IS NOT NULL
        DROP TABLE #src_report_snapshot;
END;
