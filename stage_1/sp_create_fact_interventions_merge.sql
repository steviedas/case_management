CREATE OR ALTER PROCEDURE [dbo].[sp_create_fact_interventions_merge]
WITH RECOMPILE
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE name = N'IX_EngineAutoCoding_PowerPack_PB'
        AND object_id = OBJECT_ID(N'dbo.EngineAutoCoding')
    )
    BEGIN
        CREATE NONCLUSTERED INDEX IX_EngineAutoCoding_PowerPack_PB
            ON dbo.EngineAutoCoding (
                Porterbrook_Asset ASC,
                Is_Verified ASC,
                Is_Power_Pack_Intervention ASC
            )
            INCLUDE (Intervention_Key, Master_Intervention_Key);
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM sys.indexes
        WHERE name = N'IX_EngineAutoCoding_Intervention_Key'
        AND object_id = OBJECT_ID(N'dbo.EngineAutoCoding')
    )
    BEGIN
        CREATE NONCLUSTERED INDEX IX_EngineAutoCoding_Intervention_Key
            ON dbo.EngineAutoCoding (Intervention_Key ASC)
            INCLUDE (Railway_Period, [Date], [Unit], [Vehicle]);
    END;

    IF OBJECT_ID('tempdb..#fact_interventions_src') IS NOT NULL
        DROP TABLE #fact_interventions_src;

    CREATE TABLE #fact_interventions_src
    (
        master_intervention_key      NVARCHAR(100) NOT NULL PRIMARY KEY,
        toc_id                       INT           NOT NULL,
        class_id                     INT           NOT NULL,
        depot_id                     INT           NULL,
        unit_id                      INT           NOT NULL,
        date_id                      INT           NULL,
        vehicle                      NVARCHAR(30)  NULL,
        [date]                       DATE          NULL,
        intervention_report          NVARCHAR(MAX) NULL,
        intervention_action          NVARCHAR(MAX) NULL,
        p_symptom_code_inferred      NVARCHAR(100) NULL,
        p_root_code_display          NVARCHAR(20)  NULL,
        p_root_code_display_desc     NVARCHAR(100) NULL,
        intervention_type            NVARCHAR(200) NULL,
        intervention_key             NVARCHAR(MAX) NULL,
        railway_period               NVARCHAR(50)  NULL,
        period_sort_id               INT           NULL,
        sum_total_delay_minutes      INT           NULL,
        fleet_name                   NVARCHAR(50)  NULL,
        [location]                   NVARCHAR(200) NULL,
        porterbrook_asset            BIT           NOT NULL,
        is_tin                       BIT           NULL,
        is_verified                  BIT           NOT NULL,
        count_full_cancellations     INT           NULL,
        row_hash AS CONVERT(VARBINARY(32),
            HASHBYTES('SHA2_256',
                CONCAT_WS(N'|',
                    COALESCE(CONVERT(NVARCHAR(30), toc_id),               N''),
                    COALESCE(CONVERT(NVARCHAR(30), class_id),             N''),
                    COALESCE(CONVERT(NVARCHAR(30), depot_id),             N''),
                    COALESCE(CONVERT(NVARCHAR(30), unit_id),              N''),
                    COALESCE(CONVERT(NVARCHAR(30), date_id),              N''),
                    COALESCE(vehicle,                                     N''),
                    COALESCE(CONVERT(NVARCHAR(30), [date], 126),          N''),
                    COALESCE(intervention_report,                         N''),
                    COALESCE(intervention_action,                         N''),
                    COALESCE(p_symptom_code_inferred,                     N''),
                    COALESCE(p_root_code_display,                         N''),
                    COALESCE(p_root_code_display_desc,                    N''),
                    COALESCE(intervention_type,                           N''),
                    COALESCE(intervention_key,                            N''),
                    COALESCE(railway_period,                              N''),
                    COALESCE(CONVERT(NVARCHAR(30), period_sort_id),       N''),
                    COALESCE(CONVERT(NVARCHAR(30), sum_total_delay_minutes), N''),
                    COALESCE(fleet_name,                                  N''),
                    COALESCE([location],                                  N''),
                    COALESCE(CONVERT(NVARCHAR(1), porterbrook_asset),     N''),
                    COALESCE(CONVERT(NVARCHAR(1), is_tin),                N''),
                    COALESCE(CONVERT(NVARCHAR(1), is_verified),           N''),
                    COALESCE(CONVERT(NVARCHAR(30), count_full_cancellations), N'')
                )
            )
        ) PERSISTED
    );

    ;WITH pre_transformed_eac_base_df AS (
        SELECT
            COALESCE(R2_Depot, Depot) AS Depot,
            TOC,
            Railway_Period,
            [Date],
            Fleet_Name,
            Vehicle_Class,
            Unit,
            Vehicle,
            Intervention_Type,
            Intervention_Key,
            Is_TIN,
            Intervention_Report,
            Intervention_Action,
            [Location],
            Sum_Total_Delay_Mins,
            Count_Full_Cancellations,
            Porterbrook_Asset,
            COALESCE(P_Symptom_Verified, P_Symptom_Code_Inferred) AS P_Symptom_Code,
            Is_Verified,
            COALESCE(Master_Intervention_Key, Intervention_Key) AS Master_Intervention_Key,
            COALESCE(P_Root_Code_Verified, P_Root_Code_Inferred_Tertiary) AS P_Root_Code_Display,
            COALESCE(P_Root_Code_Verified_Desc, P_Root_Code_Inferred_Tertiary_Desc) AS P_Root_Code_Display_Desc
        FROM dbo.EngineAutoCoding
        WHERE Is_Power_Pack_Intervention = 1
            AND Porterbrook_Asset = 1
    ),
    verified_keys AS (
        SELECT DISTINCT Master_Intervention_Key
        FROM pre_transformed_eac_base_df
        WHERE Is_Verified = 1
    ),
    paired_or_verified AS (
        SELECT p.*
        FROM pre_transformed_eac_base_df AS p
        WHERE EXISTS (
            SELECT 1
            FROM verified_keys vk
            WHERE vk.Master_Intervention_Key = p.Master_Intervention_Key
        )
    ),
    deduplicated_df AS (
        SELECT
            MAX(Depot) AS Depot,
            MAX(TOC) AS TOC,
            MAX(Railway_Period) AS Railway_Period,
            MAX([Date]) AS [Date],
            MAX(Fleet_Name) AS Fleet_Name,
            MAX(Vehicle_Class) AS Vehicle_Class,
            MAX(Unit) AS Unit,
            MAX(Vehicle) AS Vehicle,
            STRING_AGG(CAST(Intervention_Type AS nvarchar(max)), ' *** ')
                WITHIN GROUP (ORDER BY [Date] DESC) AS Intervention_Type,
            STRING_AGG(CAST(Intervention_Key AS nvarchar(max)), ' *** ')
                WITHIN GROUP (ORDER BY [Date] DESC) AS Intervention_Key,
            CAST(MAX(CAST(Is_TIN AS tinyint)) AS bit) AS Is_TIN,
            STRING_AGG(CAST(Intervention_Report AS nvarchar(max)), ' *** ')
                WITHIN GROUP (ORDER BY [Date] DESC) AS Intervention_Report,
            STRING_AGG(CAST(Intervention_Action AS nvarchar(max)), ' *** ')
                WITHIN GROUP (ORDER BY [Date] DESC) AS Intervention_Action,
            STRING_AGG(CAST([Location] AS nvarchar(max)), ' *** ')
                WITHIN GROUP (ORDER BY [Date] DESC) AS [Location],
            SUM(COALESCE(Sum_Total_Delay_Mins, 0)) AS Sum_Total_Delay_Mins,
            SUM(COALESCE(Count_Full_Cancellations, 0)) AS Count_Full_Cancellations,
            CAST(MAX(CAST(Porterbrook_Asset AS tinyint)) AS bit) AS Porterbrook_Asset,
            MAX(P_Symptom_Code_Inferred) AS P_Symptom_Code_Inferred,
            CAST(MAX(CAST(Is_Verified AS tinyint)) AS bit) AS Is_Verified,
            v.Master_Intervention_Key,
            MAX(P_Root_Code_Display) AS P_Root_Code_Display,
            MAX(P_Root_Code_Display_Desc) AS P_Root_Code_Display_Desc
        FROM paired_or_verified AS v
        GROUP BY v.Master_Intervention_Key
    ),
    unverified_df AS (
        SELECT p.*
        FROM pre_transformed_eac_base_df AS p
        WHERE NOT EXISTS (
            SELECT 1
            FROM paired_or_verified pov
            WHERE pov.Master_Intervention_Key = p.Master_Intervention_Key
        )
    ),
    eac_deduplicated AS (
        SELECT * FROM deduplicated_df
        UNION ALL
        SELECT * FROM unverified_df
    ),
    fact_interventions_src AS (
        SELECT
            toc.toc_id,
            class.class_id,
            depot.depot_id,
            unit.unit_id,
            rail_cal.date_id,
            CAST(eac.Vehicle AS NVARCHAR(30)) AS vehicle,
            CAST(eac.[Date] AS DATE) AS [date],
            eac.Intervention_Report AS intervention_report,
            eac.Intervention_Action AS intervention_action,
            CAST(eac.P_Symptom_Code_Inferred AS NVARCHAR(100)) AS p_symptom_code_inferred,
            CAST(eac.P_Root_Code_Display AS NVARCHAR(20)) AS p_root_code_display,
            CAST(eac.P_Root_Code_Display_Desc AS NVARCHAR(100)) AS p_root_code_display_desc,
            eac.Intervention_Type AS intervention_type,
            eac.Intervention_Key AS intervention_key,
            CAST(eac.Railway_Period AS NVARCHAR(50)) AS railway_period,
            rail_cal.period_sort_id AS period_sort_id,
            eac.Sum_Total_Delay_Mins AS sum_total_delay_minutes,
            CAST(eac.Fleet_Name AS NVARCHAR(50)) AS fleet_name,
            eac.[Location] AS [location],
            CAST(eac.Porterbrook_Asset AS bit) AS porterbrook_asset,
            CAST(eac.Is_TIN AS bit) AS is_tin,
            CAST(eac.Is_Verified AS bit) AS is_verified,
            CAST(eac.Master_Intervention_Key AS NVARCHAR(100)) AS master_intervention_key,
            eac.Count_Full_Cancellations AS count_full_cancellations
        FROM eac_deduplicated AS eac
        LEFT JOIN dim_toc               AS toc      ON eac.TOC           = toc.toc_name
        LEFT JOIN dim_class             AS class    ON eac.Vehicle_Class = class.class_name
        LEFT JOIN dim_depot             AS depot    ON eac.Depot         = depot.depot_name
        LEFT JOIN dim_unit              AS unit     ON eac.Unit          = unit.unit_name
        INNER JOIN dim_railway_calendar AS rail_cal ON eac.[Date]        = rail_cal.[date]
    )
    INSERT INTO #fact_interventions_src (
        master_intervention_key, toc_id, class_id, depot_id, unit_id, date_id,
        vehicle, [date], intervention_report, intervention_action,
        p_symptom_code_inferred, p_root_code_display, p_root_code_display_desc,
        intervention_type, intervention_key, railway_period, period_sort_id,
        sum_total_delay_minutes, fleet_name, [location],
        porterbrook_asset, is_tin, is_verified, count_full_cancellations
    )
    SELECT
        master_intervention_key, toc_id, class_id, depot_id, unit_id, date_id,
        vehicle, [date], intervention_report, intervention_action,
        p_symptom_code_inferred, p_root_code_display, p_root_code_display_desc,
        intervention_type, intervention_key, railway_period, period_sort_id,
        sum_total_delay_minutes, fleet_name, [location],
        porterbrook_asset, is_tin, is_verified, count_full_cancellations
    FROM fact_interventions_src
    OPTION (RECOMPILE);

    CREATE INDEX IX_src_period ON #fact_interventions_src(period_sort_id);

    BEGIN TRY
        BEGIN TRAN;

        MERGE dbo.fact_interventions AS tgt
        USING #fact_interventions_src AS src
            ON tgt.master_intervention_key = src.master_intervention_key

        WHEN MATCHED
            AND CONVERT(VARBINARY(32), HASHBYTES('SHA2_256',
                    CONCAT_WS(N'|',
                        COALESCE(CONVERT(NVARCHAR(30), tgt.toc_id),               N''),
                        COALESCE(CONVERT(NVARCHAR(30), tgt.class_id),             N''),
                        COALESCE(CONVERT(NVARCHAR(30), tgt.depot_id),             N''),
                        COALESCE(CONVERT(NVARCHAR(30), tgt.unit_id),              N''),
                        COALESCE(CONVERT(NVARCHAR(30), tgt.date_id),              N''),
                        COALESCE(tgt.vehicle,                                     N''),
                        COALESCE(CONVERT(NVARCHAR(30), tgt.[date], 126),          N''),
                        COALESCE(tgt.intervention_report,                         N''),
                        COALESCE(tgt.intervention_action,                         N''),
                        COALESCE(tgt.p_symptom_code_inferred,                     N''),
                        COALESCE(tgt.p_root_code_display,                         N''),
                        COALESCE(tgt.p_root_code_display_desc,                    N''),
                        COALESCE(tgt.intervention_type,                           N''),
                        COALESCE(tgt.intervention_key,                            N''),
                        COALESCE(tgt.railway_period,                              N''),
                        COALESCE(CONVERT(NVARCHAR(30), tgt.period_sort_id),       N''),
                        COALESCE(CONVERT(NVARCHAR(30), tgt.sum_total_delay_minutes), N''),
                        COALESCE(tgt.fleet_name,                                  N''),
                        COALESCE(tgt.[location],                                  N''),
                        COALESCE(CONVERT(NVARCHAR(1), tgt.porterbrook_asset),     N''),
                        COALESCE(CONVERT(NVARCHAR(1), tgt.is_tin),                N''),
                        COALESCE(CONVERT(NVARCHAR(1), tgt.is_verified),           N''),
                        COALESCE(CONVERT(NVARCHAR(30), tgt.count_full_cancellations), N'')
                    )
                )
            ) <> src.row_hash
        THEN UPDATE SET
            toc_id                   = src.toc_id,
            class_id                 = src.class_id,
            depot_id                 = src.depot_id,
            unit_id                  = src.unit_id,
            date_id                  = src.date_id,
            vehicle                  = src.vehicle,
            [date]                   = src.[date],
            intervention_report      = src.intervention_report,
            intervention_action      = src.intervention_action,
            p_symptom_code_inferred  = src.p_symptom_code_inferred,
            p_root_code_display      = src.p_root_code_display,
            p_root_code_display_desc = src.p_root_code_display_desc,
            intervention_type        = src.intervention_type,
            intervention_key         = src.intervention_key,
            railway_period           = src.railway_period,
            period_sort_id           = src.period_sort_id,
            sum_total_delay_minutes  = src.sum_total_delay_minutes,
            fleet_name               = src.fleet_name,
            [location]               = src.[location],
            porterbrook_asset        = src.porterbrook_asset,
            is_tin                   = src.is_tin,
            is_verified              = src.is_verified,
            count_full_cancellations = src.count_full_cancellations

        WHEN NOT MATCHED BY TARGET
        THEN INSERT (
            master_intervention_key, toc_id, class_id, depot_id, unit_id, date_id,
            vehicle, [date], intervention_report, intervention_action,
            p_symptom_code_inferred, p_root_code_display, p_root_code_display_desc,
            intervention_type, intervention_key, railway_period, period_sort_id,
            sum_total_delay_minutes, fleet_name, [location],
            porterbrook_asset, is_tin, is_verified, count_full_cancellations
        )
        VALUES (
            src.master_intervention_key, src.toc_id, src.class_id, src.depot_id, src.unit_id, src.date_id,
            src.vehicle, src.[date], src.intervention_report, src.intervention_action,
            src.p_symptom_code_inferred, src.p_root_code_display, src.p_root_code_display_desc,
            src.intervention_type, src.intervention_key, src.railway_period, src.period_sort_id,
            src.sum_total_delay_minutes, src.fleet_name, src.[location],
            src.porterbrook_asset, src.is_tin, src.is_verified, src.count_full_cancellations
        )

        WHEN NOT MATCHED BY SOURCE
        THEN DELETE
        OPTION (RECOMPILE);

        ;WITH latest AS (
            SELECT
                ul.primary_key_value,
                ul.column_name,
                ul.new_value,
                ROW_NUMBER() OVER (
                    PARTITION BY ul.primary_key_value, ul.column_name
                    ORDER BY ul.changed_at DESC, ul.log_id DESC
                ) AS rn
            FROM dbo.updates_log AS ul
            WHERE ul.target_table = N'fact_interventions'
            AND ul.column_name IN (N'intervention_report', N'intervention_action')
        ),
        pivoted AS (
            SELECT
                primary_key_value,
                MAX(CASE WHEN column_name = N'intervention_report' THEN new_value END) AS intervention_report_new,
                MAX(CASE WHEN column_name = N'intervention_action' THEN new_value END) AS intervention_action_new
            FROM latest
            WHERE rn = 1
            GROUP BY primary_key_value
        )
        UPDATE fi
        SET
            fi.intervention_report = COALESCE(TRY_CONVERT(NVARCHAR(MAX), p.intervention_report_new), fi.intervention_report),
            fi.intervention_action = COALESCE(TRY_CONVERT(NVARCHAR(MAX), p.intervention_action_new), fi.intervention_action)
        FROM dbo.fact_interventions AS fi
        JOIN pivoted AS p
        ON p.primary_key_value = fi.master_intervention_key;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH

END
