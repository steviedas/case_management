WITH filtered_rail_cal AS 

(SELECT 1 AS [group], CAST('2025-12-01' AS DATE) AS start_date, CAST('2025-12-31' AS DATE) AS end_date, (SELECT dbo.dim_railway_calendar.period_sort_id 

FROM dbo.dim_railway_calendar 

WHERE dbo.dim_railway_calendar.date = '2025-12-01') - 0 AS period_sort_id), 

episodes_by_unit AS 

(SELECT dbo.fact_engine_idling_episode.unit_id AS unit_id, count(dbo.fact_engine_idling_episode.[_UID]) AS episodes, sum(dbo.fact_engine_idling_episode.episode_duration_minutes) AS minutes 

FROM filtered_rail_cal LEFT OUTER JOIN dbo.fact_engine_idling_episode ON (filtered_rail_cal.start_date IS NOT NULL AND filtered_rail_cal.end_date IS NOT NULL AND CAST(dbo.fact_engine_idling_episode.episode_start_time AS DATE) BETWEEN filtered_rail_cal.start_date AND filtered_rail_cal.end_date OR filtered_rail_cal.start_date IS NULL AND filtered_rail_cal.end_date IS NULL AND dbo.fact_engine_idling_episode.period_sort_id = filtered_rail_cal.period_sort_id) AND dbo.fact_engine_idling_episode.toc_id IN (5, 10, 21, 26, 27, 28, 31, 32) GROUP BY dbo.fact_engine_idling_episode.unit_id), 

metrics_by_unit AS 

(SELECT metrics_with_dates.unit_id AS unit_id, sum(metrics_with_dates.daily_engine_run_minutes) AS run_minutes, sum(metrics_with_dates.daily_engine_idling_minutes) AS total_idling_minutes 

FROM filtered_rail_cal LEFT OUTER JOIN (SELECT dbo.fact_engine_idling_metrics.unit_id AS unit_id, dbo.fact_engine_idling_metrics.toc_id AS toc_id, dbo.fact_engine_idling_metrics.vehicle_id AS vehicle_id, dbo.fact_engine_idling_metrics.period_sort_id AS period_sort_id, dbo.fact_engine_idling_metrics.daily_engine_run_minutes AS daily_engine_run_minutes, dbo.fact_engine_idling_metrics.daily_engine_idling_minutes AS daily_engine_idling_minutes, CAST(dbo.dim_railway_calendar.date AS DATE) AS metric_date 

FROM dbo.fact_engine_idling_metrics LEFT OUTER JOIN dbo.dim_railway_calendar ON dbo.fact_engine_idling_metrics.date_id = dbo.dim_railway_calendar.date_id) AS metrics_with_dates ON (filtered_rail_cal.start_date IS NOT NULL AND filtered_rail_cal.end_date IS NOT NULL AND metrics_with_dates.metric_date BETWEEN filtered_rail_cal.start_date AND filtered_rail_cal.end_date OR filtered_rail_cal.start_date IS NULL AND filtered_rail_cal.end_date IS NULL AND metrics_with_dates.period_sort_id = filtered_rail_cal.period_sort_id) AND metrics_with_dates.toc_id IN (5, 10, 21, 26, 27, 28, 31, 32) GROUP BY metrics_with_dates.unit_id)

 SELECT TOP 5 dbo.dim_delphi_unit.unit AS unit, coalesce(episodes_by_unit.episodes, 0) AS episodes, round(coalesce(episodes_by_unit.minutes, 0.0), 1) AS minutes, round(CASE WHEN (metrics_by_unit.run_minutes IS NOT NULL AND metrics_by_unit.run_minutes != 0) THEN (metrics_by_unit.total_idling_minutes / CAST(metrics_by_unit.run_minutes AS FLOAT)) * 100 ELSE 0.0 END, 1) AS idle_percentage 

FROM episodes_by_unit LEFT OUTER JOIN metrics_by_unit ON metrics_by_unit.unit_id = episodes_by_unit.unit_id LEFT OUTER JOIN dbo.dim_delphi_unit ON dbo.dim_delphi_unit.unit_id = episodes_by_unit.unit_id 

WHERE episodes_by_unit.unit_id IS NOT NULL ORDER BY round(CASE WHEN (metrics_by_unit.run_minutes IS NOT NULL AND metrics_by_unit.run_minutes != 0) THEN (metrics_by_unit.total_idling_minutes / CAST(metrics_by_unit.run_minutes AS FLOAT)) * 100 ELSE 0.0 END, 1) DESC