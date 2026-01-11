CREATE OR ALTER PROCEDURE dbo.sp_populate_dim_alert_status
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID('tempdb..#src_alert_status') IS NOT NULL
        DROP TABLE #src_alert_status;

    CREATE TABLE #src_alert_status
    (
        alert_status_name NVARCHAR(50) NOT NULL PRIMARY KEY,
        row_hash AS CONVERT(VARBINARY(32),
            HASHBYTES('SHA2_256', COALESCE(alert_status_name, N''))
        ) PERSISTED
    );

    INSERT INTO #src_alert_status (alert_status_name)
    VALUES (N'Accepted'), (N'Rejected');

    BEGIN TRY
        BEGIN TRAN;

        ;WITH tgt_hashed AS
        (
            SELECT
                a.*,
                CONVERT(VARBINARY(32),
                    HASHBYTES('SHA2_256', COALESCE(a.alert_status_name, N''))
                ) AS row_hash
            FROM dbo.dim_alert_status AS a
        )
        MERGE dbo.dim_alert_status AS tgt
        USING #src_alert_status    AS src
            ON tgt.alert_status_name = src.alert_status_name

        WHEN MATCHED
            AND (SELECT th.row_hash FROM tgt_hashed AS th WHERE th.alert_status_name = tgt.alert_status_name) <> src.row_hash
        THEN UPDATE SET
            tgt.alert_status_name = src.alert_status_name

        WHEN NOT MATCHED BY TARGET
        THEN INSERT (alert_status_name)
            VALUES (src.alert_status_name)

        WHEN NOT MATCHED BY SOURCE
        THEN DELETE;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH

    IF OBJECT_ID('tempdb..#src_alert_status') IS NOT NULL
        DROP TABLE #src_alert_status;
END;
