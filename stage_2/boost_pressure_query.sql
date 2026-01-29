WITH WeeklyStats AS (
    SELECT 
        vehicle_id,
        AVG(alert_value) AS latest_weekly_avg_value
    FROM fact_alert
    WHERE title = 'Average charge air pressure'
      -- Filters for the 7 days prior to the most recent alert in the whole table
      AND alert_timestamp >= DATEADD(day, -7, (SELECT MAX(alert_timestamp) FROM fact_alert))
    GROUP BY vehicle_id
)
SELECT
    dv.vehicle,
    ddu.unit,
    CAST(fa.alert_timestamp AS date) AS [date],
    fa.alert_value AS boost_pressure,
    AVG(fa.alert_value) OVER(PARTITION BY CAST(fa.alert_timestamp AS date)) AS fleet_average_per_day,
    ws.latest_weekly_avg_value AS latest_weekly_average,
    -- Threshold now calculated against the weekly average
    CASE 
        WHEN ws.latest_weekly_avg_value < 2300 THEN 'Red'
        WHEN ws.latest_weekly_avg_value < 2400 THEN 'Amber'
        WHEN ws.latest_weekly_avg_value < 2500 THEN 'Yellow'
        ELSE 'Normal'
    END AS threshold,
    latest_rec.record AS latest_record
FROM fact_alert fa
JOIN dim_vehicle dv
    ON fa.vehicle_id = dv.vehicle_id
JOIN dim_delphi_unit ddu
    ON dv.unit_id = ddu.unit_id
LEFT JOIN WeeklyStats ws
    ON fa.vehicle_id = ws.vehicle_id
LEFT JOIN (
    SELECT
        fc.vehicle_id,
        fr.record,
        ROW_NUMBER() OVER (PARTITION BY fc.vehicle_id ORDER BY fr.created_at DESC) AS rn
    FROM fact_record fr
    JOIN fact_case fc ON fr.case_id = fc.case_id
    WHERE fc.vehicle_id IS NOT NULL
) latest_rec
    ON latest_rec.vehicle_id = fa.vehicle_id
    AND latest_rec.rn = 1
WHERE fa.title = 'Average charge air pressure'
ORDER BY
    ddu.unit,
    dv.vehicle,
    fa.alert_timestamp
OPTION (RECOMPILE);