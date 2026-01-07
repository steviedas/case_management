CREATE OR ALTER PROCEDURE dbo.sp_populate_dim_toc_v2
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID('tempdb..#src_toc') IS NOT NULL
        DROP TABLE #src_toc;

    CREATE TABLE #src_toc
    (
        toc_name NVARCHAR(40) NOT NULL PRIMARY KEY
    );

    INSERT INTO #src_toc (toc_name)
    SELECT DISTINCT
        LEFT(NULLIF(LTRIM(RTRIM(rh.TOC)), N''), 40)
    FROM dbo.RakeHistory AS rh
    WHERE rh.TOC IS NOT NULL
      AND LTRIM(RTRIM(rh.TOC)) <> N'';

    BEGIN TRY
        BEGIN TRAN;

        MERGE dbo.dim_toc AS tgt
        USING #src_toc     AS src
            ON tgt.toc_name = src.toc_name

        WHEN NOT MATCHED BY TARGET
            THEN INSERT (toc_name)
                 VALUES (src.toc_name)

        WHEN NOT MATCHED BY SOURCE
            THEN DELETE;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH;

    IF OBJECT_ID('tempdb..#src_toc') IS NOT NULL
        DROP TABLE #src_toc;
END;
