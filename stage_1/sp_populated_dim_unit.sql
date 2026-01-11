CREATE OR ALTER PROCEDURE dbo.sp_populate_dim_unit
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID('tempdb..#src_unit') IS NOT NULL
        DROP TABLE #src_unit;

    CREATE TABLE #src_unit
    (
        unit_name NVARCHAR(10)    NOT NULL PRIMARY KEY,
        vehicles  NVARCHAR(MAX)   NULL,
        row_hash AS CONVERT(VARBINARY(32),
            HASHBYTES('SHA2_256',
                CONCAT_WS(N'|',
                    COALESCE(unit_name, N''),
                    COALESCE(vehicles,  N'')
                )
            )
        ) PERSISTED
    );

    INSERT INTO #src_unit (unit_name, vehicles)
    SELECT 
        Unit AS unit_name,
        JSON_QUERY(
            N'[' + STRING_AGG(
                CASE WHEN Vehicle IS NULL THEN N'null'
                    ELSE N'"' + REPLACE(Vehicle, N'"', N'\"') + N'"'
                END,
                N','
            ) WITHIN GROUP (ORDER BY Vehicle)
            + N']'
        ) AS vehicles
    FROM (
        SELECT DISTINCT Unit, Vehicle
        FROM dbo.EngineAutoCoding
        WHERE Unit IS NOT NULL
    ) AS d
    GROUP BY Unit;

    BEGIN TRY
        BEGIN TRAN;

        ;WITH tgt_hashed AS
        (
            SELECT
                u.*,
                CONVERT(VARBINARY(32),
                    HASHBYTES('SHA2_256',
                        CONCAT_WS(N'|',
                            COALESCE(u.unit_name, N''),
                            COALESCE(u.vehicles,  N'')
                        )
                    )
                ) AS row_hash
            FROM dbo.dim_unit AS u
        )
        MERGE dbo.dim_unit AS tgt
        USING #src_unit    AS src
        ON tgt.unit_name = src.unit_name

        WHEN MATCHED
            AND (SELECT th.row_hash FROM tgt_hashed AS th WHERE th.unit_name = tgt.unit_name) <> src.row_hash
        THEN UPDATE SET
            tgt.vehicles = src.vehicles

        WHEN NOT MATCHED BY TARGET
        THEN INSERT (unit_name, vehicles)
            VALUES (src.unit_name, src.vehicles)

        WHEN NOT MATCHED BY SOURCE
        THEN DELETE;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH

    IF OBJECT_ID('tempdb..#src_unit') IS NOT NULL
        DROP TABLE #src_unit;
END;
