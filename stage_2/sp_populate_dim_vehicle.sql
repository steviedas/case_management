CREATE OR ALTER PROCEDURE dbo.sp_populate_dim_vehicle
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF OBJECT_ID('tempdb..#src_vehicle') IS NOT NULL
        DROP TABLE #src_vehicle;

    CREATE TABLE #src_vehicle
    (
        vehicle NVARCHAR(100) NOT NULL,
        unit_id INT NOT NULL,
        row_hash AS CONVERT(VARBINARY(32),
            HASHBYTES('SHA2_256',
                COALESCE(vehicle, N'') + N'|' + CAST(unit_id AS NVARCHAR(10))
            )
        ) PERSISTED,
        PRIMARY KEY (unit_id, vehicle)
    );

    -- Get distinct Unit/Vehicle combinations and resolve unit_id
    INSERT INTO #src_vehicle (vehicle, unit_id)
    SELECT DISTINCT
        LTRIM(RTRIM(rh.Vehicle)) AS vehicle,
        du.unit_id AS unit_id
    FROM dbo.RakeHistory AS rh
    INNER JOIN dbo.dim_delphi_unit AS du
        ON du.unit = LTRIM(RTRIM(rh.Unit))
    WHERE rh.Vehicle IS NOT NULL
      AND LTRIM(RTRIM(rh.Vehicle)) <> N''
      AND rh.Unit IS NOT NULL
      AND LTRIM(RTRIM(rh.Unit)) <> N'';

    BEGIN TRY
        BEGIN TRAN;

        ;WITH tgt_hashed AS
        (
            SELECT
                v.*,
                CONVERT(VARBINARY(32),
                    HASHBYTES('SHA2_256',
                        COALESCE(v.vehicle, N'') + N'|' + CAST(v.unit_id AS NVARCHAR(10))
                    )
                ) AS row_hash
            FROM dbo.dim_vehicle AS v
        )
        MERGE dbo.dim_vehicle AS tgt
        USING #src_vehicle    AS src
            ON tgt.unit_id = src.unit_id
           AND tgt.vehicle = src.vehicle

        WHEN MATCHED
            AND (SELECT th.row_hash FROM tgt_hashed AS th
                 WHERE th.unit_id = tgt.unit_id
                   AND th.vehicle = tgt.vehicle) <> src.row_hash
        THEN UPDATE SET
            tgt.vehicle = src.vehicle,
            tgt.unit_id = src.unit_id

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
