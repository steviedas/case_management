CREATE OR ALTER PROCEDURE dbo.sp_populate_dim_class
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID('tempdb..#src_class') IS NOT NULL
        DROP TABLE #src_class;

    CREATE TABLE #src_class
    (
        class_name NVARCHAR(3) NOT NULL PRIMARY KEY
    );

    INSERT INTO #src_class (class_name)
    SELECT DISTINCT
        LEFT(NULLIF(LTRIM(RTRIM(Vehicle_Class)), N''), 3)
    FROM (
        SELECT DISTINCT Vehicle_Class
        FROM dbo.EngineAutoCoding
        WHERE Vehicle_Class IS NOT NULL
          AND LTRIM(RTRIM(Vehicle_Class)) <> N''

        UNION

        SELECT DISTINCT Vehicle_Class
        FROM dbo.RakeHistory
        WHERE Vehicle_Class IS NOT NULL
          AND LTRIM(RTRIM(Vehicle_Class)) <> N''
    ) AS combined_class;

    BEGIN TRY
        BEGIN TRAN;

        MERGE dbo.dim_class AS tgt
        USING #src_class     AS src
        ON tgt.class_name = src.class_name

        WHEN NOT MATCHED BY TARGET
        THEN INSERT (class_name) VALUES (src.class_name)

        WHEN NOT MATCHED BY SOURCE
        THEN DELETE;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH;

    IF OBJECT_ID('tempdb..#src_class') IS NOT NULL
        DROP TABLE #src_class;
END;
