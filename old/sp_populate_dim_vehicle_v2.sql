CREATE OR ALTER PROCEDURE dbo.sp_populate_dim_vehicle_v2
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID('tempdb..#src_vehicle') IS NOT NULL
        DROP TABLE #src_vehicle;

    CREATE TABLE #src_vehicle
    (
        unit    NVARCHAR(10)  NOT NULL,
        vehicle NVARCHAR(50)  NOT NULL,

        row_hash AS CONVERT(VARBINARY(32),
            HASHBYTES('SHA2_256',
                CONCAT_WS(N'|',
                    COALESCE(unit,    N''),
                    COALESCE(vehicle, N'')
                )
            )
        ) PERSISTED,

        CONSTRAINT PK_src_vehicle PRIMARY KEY (unit, vehicle)
    );

    INSERT INTO #src_vehicle (unit, vehicle)
    SELECT DISTINCT
        rh.Unit    AS unit,
        rh.Vehicle AS vehicle
    FROM dbo.RakeHistory AS rh
    WHERE rh.Unit IS NOT NULL
      AND rh.Vehicle IS NOT NULL;

    BEGIN TRY
        BEGIN TRAN;

        ;WITH src AS
        (
            SELECT
                du.id       AS unit_id,
                sv.vehicle  AS vehicle,
                sv.row_hash AS row_hash
            FROM #src_vehicle sv
            INNER JOIN dbo.dim_unit du
                ON du.unit = sv.unit
        ),
        tgt_hashed AS
        (
            SELECT
                v.*,
                CONVERT(VARBINARY(32),
                    HASHBYTES('SHA2_256',
                        CONCAT_WS(N'|',
                            CONVERT(NVARCHAR(20), v.unit_id),
                            COALESCE(v.vehicle, N'')
                        )
                    )
                ) AS row_hash
            FROM dbo.dim_vehicle v
        )
        MERGE dbo.dim_vehicle AS tgt
        USING src             AS src
            ON tgt.unit_id = src.unit_id
           AND tgt.vehicle = src.vehicle

        WHEN MATCHED
            AND (SELECT th.row_hash
                 FROM tgt_hashed AS th
                 WHERE th.unit_id = tgt.unit_id
                   AND th.vehicle = tgt.vehicle) <> src.row_hash
        THEN UPDATE SET
            tgt.vehicle = src.vehicle  -- effectively a no-op; keeps the pattern consistent

        WHEN NOT MATCHED BY TARGET
        THEN INSERT (vehicle, unit_id)
            VALUES (src.vehicle, src.unit_id)

        WHEN NOT MATCHED BY SOURCE
        THEN DELETE;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH

    IF OBJECT_ID('tempdb..#src_vehicle') IS NOT NULL
        DROP TABLE #src_vehicle;
END;
