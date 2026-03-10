WITH filtered_rail_cal AS 

(SELECT 1 AS [group], CAST('2026-02-26' AS DATE) AS start_date, CAST('2026-03-05' AS DATE) AS end_date, (SELECT dbo.dim_railway_calendar.period_sort_id 

FROM dbo.dim_railway_calendar 

WHERE dbo.dim_railway_calendar.date = '2026-02-26') - 0 AS period_sort_id)

 SELECT dbo.fact_engine_idling_episode.[_UID] AS episode_id, dbo.fact_engine_idling_episode.episode_start_time AS timestamp, dbo.fact_engine_idling_episode.episode_duration_seconds AS duration, dbo.dim_toc.toc_name AS toc, dbo.dim_class.class_name AS class, dbo.dim_delphi_unit.unit AS unit, dbo.dim_vehicle.vehicle AS vehicle, CASE WHEN (dbo.fact_engine_idling_episode.location_025km IS NULL AND dbo.fact_engine_idling_episode.gps_lat IS NOT NULL AND dbo.fact_engine_idling_episode.gps_lon IS NOT NULL) THEN 'Unnamed Location' ELSE dbo.fact_engine_idling_episode.location_025km END AS location, dbo.fact_engine_idling_episode.gps_lat AS gps_lat, dbo.fact_engine_idling_episode.gps_lon AS gps_lon 

FROM filtered_rail_cal LEFT OUTER JOIN dbo.fact_engine_idling_episode ON filtered_rail_cal.start_date IS NOT NULL AND filtered_rail_cal.end_date IS NOT NULL AND CAST(dbo.fact_engine_idling_episode.episode_start_time AS DATE) BETWEEN filtered_rail_cal.start_date AND filtered_rail_cal.end_date OR filtered_rail_cal.start_date IS NULL AND filtered_rail_cal.end_date IS NULL AND dbo.fact_engine_idling_episode.period_sort_id = filtered_rail_cal.period_sort_id LEFT OUTER JOIN dbo.dim_toc ON dbo.dim_toc.toc_id = dbo.fact_engine_idling_episode.toc_id LEFT OUTER JOIN dbo.dim_class ON dbo.dim_class.class_id = dbo.fact_engine_idling_episode.class_id LEFT OUTER JOIN dbo.dim_delphi_unit ON dbo.dim_delphi_unit.unit_id = dbo.fact_engine_idling_episode.unit_id LEFT OUTER JOIN dbo.dim_vehicle ON dbo.dim_vehicle.vehicle_id = dbo.fact_engine_idling_episode.vehicle_id 

WHERE dbo.fact_engine_idling_episode.toc_id IN (5, 10, 21, 26, 27, 28, 31, 32) AND dbo.fact_engine_idling_episode.episode_duration_seconds >= 60