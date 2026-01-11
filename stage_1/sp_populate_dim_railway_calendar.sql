CREATE OR ALTER PROCEDURE dbo.sp_populate_dim_railway_calendar
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID('tempdb..#src_railway_calendar') IS NOT NULL
        DROP TABLE #src_railway_calendar;

    CREATE TABLE #src_railway_calendar
    (
        [date]                      DATE          NOT NULL PRIMARY KEY,
        period_display_short_name   NVARCHAR(10)  NULL,
        period_sort_id              INT           NULL,
        row_hash AS CONVERT(VARBINARY(32),
            HASHBYTES('SHA2_256',
                CONCAT_WS(N'|',
                    COALESCE(CONVERT(NVARCHAR(30), [date], 126), N''),
                    COALESCE(period_display_short_name,          N''),
                    COALESCE(CONVERT(NVARCHAR(30), period_sort_id), N'')
                )
            )
        ) PERSISTED
    );

    INSERT INTO #src_railway_calendar ([date], period_display_short_name, period_sort_id)
    SELECT 
        [Date] AS [date],
        Period_Display_Short_Name AS period_display_short_name,
        Period_Sort_ID AS period_sort_id
    FROM dbo.RailwayCalendar;

    CREATE INDEX IX_src_sort ON #src_railway_calendar(period_sort_id);

    BEGIN TRY
        BEGIN TRAN;

        MERGE dbo.dim_railway_calendar AS tgt
        USING #src_railway_calendar AS src
        ON tgt.[date] = src.[date]

        WHEN MATCHED
            AND CONVERT(VARBINARY(32), HASHBYTES('SHA2_256',
                    CONCAT_WS(N'|',
                        COALESCE(CONVERT(NVARCHAR(30), tgt.[date], 126), N''),
                        COALESCE(tgt.period_display_short_name,         N''),
                        COALESCE(CONVERT(NVARCHAR(30), tgt.period_sort_id), N'')
                    )
                )
            ) <> src.row_hash
        THEN UPDATE SET
            tgt.period_display_short_name = src.period_display_short_name,
            tgt.period_sort_id            = src.period_sort_id

        WHEN NOT MATCHED BY TARGET
        THEN INSERT ([date], period_display_short_name, period_sort_id)
        VALUES (src.[date], src.period_display_short_name, src.period_sort_id)

        WHEN NOT MATCHED BY SOURCE
        THEN DELETE;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH

    IF OBJECT_ID('tempdb..#src_railway_calendar') IS NOT NULL
        DROP TABLE #src_railway_calendar;
END;
