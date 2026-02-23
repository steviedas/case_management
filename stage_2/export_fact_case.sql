DECLARE @sep NVARCHAR(1) = NCHAR(10);

WITH unit_map AS (
    SELECT
        bcu.case_id,
        STRING_AGG(du.unit, ', ') WITHIN GROUP (ORDER BY du.unit) AS units
    FROM dbo.bridge_case_delphi_unit AS bcu
    INNER JOIN dbo.dim_delphi_unit AS du
        ON du.unit_id = bcu.unit_id
    GROUP BY bcu.case_id
),
record_history AS (
    SELECT
        fr.case_id,
        STRING_AGG(
            CONVERT(NVARCHAR(MAX),
                CONCAT(
                    CONVERT(NVARCHAR(19), fr.created_at, 120),
                    ' [',
                    COALESCE(dr.type, 'record'),
                    '] ',
                    fr.record,
                    CASE WHEN fr.author IS NOT NULL AND LTRIM(RTRIM(fr.author)) <> ''
                        THEN CONCAT(' (', fr.author, ')')
                        ELSE ''
                    END
                )
            ),
            @sep
        ) WITHIN GROUP (ORDER BY fr.created_at, fr.record_id) AS record_history
    FROM dbo.fact_record AS fr
    LEFT JOIN dbo.dim_record_type AS dr
        ON dr.record_type_id = fr.record_type_id
    GROUP BY fr.case_id
),
alert_history AS (
    SELECT
        bca.case_id,
        STRING_AGG(
            CONVERT(NVARCHAR(MAX),
                CONCAT(
                    'Alert ',
                    CAST(fa.alert_id AS NVARCHAR(20)),
                    ': ',
                    COALESCE(fa.title, ''),
                    ' | ',
                    CONVERT(NVARCHAR(19), fa.alert_timestamp, 120),
                    ' | ',
                    COALESCE(das.alert_status_name, ''),
                    CASE WHEN fa.alert_source IS NOT NULL THEN CONCAT(' | ', fa.alert_source) ELSE '' END,
                    CASE WHEN dv.vehicle IS NOT NULL THEN CONCAT(' | vehicle ', dv.vehicle) ELSE '' END,
                    CASE WHEN du.unit IS NOT NULL THEN CONCAT(' | unit ', du.unit) ELSE '' END
                )
            ),
            @sep
        ) WITHIN GROUP (ORDER BY fa.alert_timestamp, fa.alert_id) AS alerts_attached
    FROM dbo.bridge_case_alert AS bca
    INNER JOIN dbo.fact_alert AS fa
        ON fa.alert_id = bca.ins_alt_id
    LEFT JOIN dbo.dim_alert_status AS das
        ON das.alert_status_id = fa.status_id
    LEFT JOIN dbo.dim_vehicle AS dv
        ON dv.vehicle_id = fa.vehicle_id
    LEFT JOIN dbo.dim_delphi_unit AS du
        ON du.unit_id = dv.unit_id
    GROUP BY bca.case_id
),
intervention_history AS (
    SELECT
        bci.case_id,
        STRING_AGG(
            CONVERT(NVARCHAR(MAX),
                CONCAT(
                    fi.master_intervention_key,
                    ' | ',
                    COALESCE(fi.intervention_type, ''),
                    CASE WHEN fi.intervention_action IS NOT NULL THEN CONCAT(' | ', fi.intervention_action) ELSE '' END,
                    CASE WHEN fi.intervention_report IS NOT NULL THEN CONCAT(' | ', fi.intervention_report) ELSE '' END,
                    CASE WHEN fi.[date] IS NOT NULL THEN CONCAT(' | ', CONVERT(NVARCHAR(10), fi.[date], 120)) ELSE '' END,
                    CASE WHEN fi.[location] IS NOT NULL THEN CONCAT(' | ', fi.[location]) ELSE '' END,
                    CASE WHEN fi.sum_total_delay_minutes IS NOT NULL THEN CONCAT(' | delay ', fi.sum_total_delay_minutes) ELSE '' END
                )
            ),
            @sep
        ) WITHIN GROUP (ORDER BY fi.[date], fi.master_intervention_key) AS interventions_attached
    FROM dbo.bridge_case_intervention AS bci
    INNER JOIN dbo.fact_interventions AS fi
        ON fi.master_intervention_key = bci.master_intervention_key
    GROUP BY bci.case_id
)
SELECT
    fc.case_id,
    fc.title AS case_title,
    fc.description AS case_description,
    fc.rfs,
    fc.linked_work_orders,
    fc.created_at,
    fc.updated_at,
    fc.updated_by,
    dp.priority_name AS priority,
    ds.status_name AS status,
    dsys.system_name AS system_name,
    dt.toc_name AS toc,
    dc.class_name AS class_name,
    dd.depot_name AS depot_name,
    dv.vehicle AS vehicle,
    COALESCE(um.units, dv_unit.unit) AS units,
    fc.delay_prevented,
    fc.labour_hours,
    sc.code_short AS symptom_code_short,
    sc.code_long AS symptom_code_long,
    rc.code_short AS root_code_short,
    rc.code_long AS root_code_long,
    fr.title AS report_title,
    fr.description AS report_description,
    fr.report_frequency,
    fr.storage_path AS report_storage_path,
    fr.partitioned_by AS report_partitioned_by,
    frs.title AS report_snapshot_title,
    frs.start_time AS report_snapshot_start_time,
    frs.end_time AS report_snapshot_end_time,
    drsr.report_date AS report_date,
    drsr.row_uid AS report_row_uid,
    rh.record_history,
    ah.alerts_attached,
    ih.interventions_attached
FROM dbo.fact_case AS fc
LEFT JOIN dbo.dim_priority AS dp
    ON dp.priority_id = fc.priority_id
LEFT JOIN dbo.dim_status AS ds
    ON ds.status_id = fc.status_id
LEFT JOIN dbo.dim_system AS dsys
    ON dsys.system_id = fc.system_id
LEFT JOIN dbo.dim_toc AS dt
    ON dt.toc_id = fc.toc_id
LEFT JOIN dbo.dim_class AS dc
    ON dc.class_id = fc.class_id
LEFT JOIN dbo.dim_depot AS dd
    ON dd.depot_id = fc.depot_id
LEFT JOIN dbo.dim_vehicle AS dv
    ON dv.vehicle_id = fc.vehicle_id
LEFT JOIN dbo.dim_delphi_unit AS dv_unit
    ON dv_unit.unit_id = dv.unit_id
LEFT JOIN unit_map AS um
    ON um.case_id = fc.case_id
LEFT JOIN dbo.dim_code AS sc
    ON sc.code_id = fc.symptom_code_id
LEFT JOIN dbo.dim_code AS rc
    ON rc.code_id = fc.root_code_id
LEFT JOIN dbo.dim_report_snapshot_row AS drsr
    ON drsr.report_snapshot_row_id = fc.report_snapshot_row_id
LEFT JOIN dbo.fact_report_snapshot AS frs
    ON frs.snapshot_id = drsr.snapshot_id
LEFT JOIN dbo.fact_report AS fr
    ON fr.report_id = frs.report_id
LEFT JOIN record_history AS rh
    ON rh.case_id = fc.case_id
LEFT JOIN alert_history AS ah
    ON ah.case_id = fc.case_id
LEFT JOIN intervention_history AS ih
    ON ih.case_id = fc.case_id
ORDER BY fc.case_id;
