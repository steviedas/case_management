CREATE OR ALTER PROCEDURE dbo.sp_populate_dim_depot
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID('tempdb..#src_depot') IS NOT NULL
        DROP TABLE #src_depot;

    CREATE TABLE #src_depot
    (
        depot_name NVARCHAR(50) NOT NULL PRIMARY KEY
    );

    INSERT INTO #src_depot (depot_name)
    SELECT DISTINCT
        NULLIF(LTRIM(RTRIM(R2_Depot)), N'')
    FROM (
        SELECT DISTINCT R2_Depot
        FROM dbo.EngineAutoCoding
        WHERE R2_Depot IS NOT NULL
          AND LTRIM(RTRIM(R2_Depot)) <> N''

        UNION

        SELECT DISTINCT R2_Depot
        FROM dbo.RakeHistory
        WHERE R2_Depot IS NOT NULL
          AND LTRIM(RTRIM(R2_Depot)) <> N''
    ) AS combined_depot;

    BEGIN TRY
        BEGIN TRAN;

        MERGE dbo.dim_depot AS tgt
        USING #src_depot     AS src
        ON tgt.depot_name = src.depot_name

        WHEN NOT MATCHED BY TARGET
        THEN INSERT (depot_name) VALUES (src.depot_name)

        WHEN NOT MATCHED BY SOURCE
        THEN DELETE;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH

    IF OBJECT_ID('tempdb..#src_depot') IS NOT NULL
        DROP TABLE #src_depot;
END;