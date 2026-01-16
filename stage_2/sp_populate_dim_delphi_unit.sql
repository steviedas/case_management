CREATE OR ALTER PROCEDURE dbo.sp_populate_dim_delphi_unit
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID('tempdb..#src_unit') IS NOT NULL
        DROP TABLE #src_unit;

    CREATE TABLE #src_unit
    (
        unit NVARCHAR(10) NOT NULL PRIMARY KEY,
        number_of_vehicles INT NOT NULL,
        row_hash AS CONVERT(VARBINARY(32),
            HASHBYTES('SHA2_256',
                COALESCE(unit, N'') + N'|' + CAST(number_of_vehicles AS NVARCHAR(10))
            )
        ) PERSISTED
    );

    INSERT INTO #src_unit (unit, number_of_vehicles)
    SELECT
        rh.Unit,
        COUNT(DISTINCT rh.Vehicle) AS number_of_vehicles
    FROM dbo.RakeHistory AS rh
    WHERE rh.Unit IS NOT NULL
    GROUP BY rh.Unit;
    BEGIN TRY
        BEGIN TRAN;

        ;WITH tgt_hashed AS
        (
            SELECT
                u.*,
                CONVERT(VARBINARY(32),
                    HASHBYTES('SHA2_256',
                        COALESCE(u.unit, N'') + N'|' + CAST(u.number_of_vehicles AS NVARCHAR(10))
                    )
                ) AS row_hash
            FROM dbo.dim_delphi_unit AS u
        )
        MERGE dbo.dim_delphi_unit AS tgt
        USING #src_unit    AS src
            ON tgt.unit = src.unit

        WHEN MATCHED
            AND (SELECT th.row_hash FROM tgt_hashed AS th WHERE th.unit = tgt.unit) <> src.row_hash
        THEN UPDATE SET
            tgt.unit = src.unit,
            tgt.number_of_vehicles = src.number_of_vehicles

        WHEN NOT MATCHED BY TARGET
        THEN INSERT (unit, number_of_vehicles)
            VALUES (src.unit, src.number_of_vehicles)

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
