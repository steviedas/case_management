USE [frp];
GO

/* -----------------------------
   fact_engine_idling_episode
   ----------------------------- */

/* Period-based path (period dropdown) */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_fie_period_filters'
      AND object_id = OBJECT_ID('dbo.fact_engine_idling_episode')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fie_period_filters
    ON dbo.fact_engine_idling_episode (
        period_sort_id,
        toc_id,
        class_id,
        unit_id,
        vehicle_id
    )
    INCLUDE (
        episode_start_time,
        episode_duration_seconds,
        episode_duration_minutes,
        gps_lat,
        gps_lon,
        location_025km
    );
END
GO

/* Date-range path (start/end date) */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_fie_date_filters'
      AND object_id = OBJECT_ID('dbo.fact_engine_idling_episode')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fie_date_filters
    ON dbo.fact_engine_idling_episode (
        toc_id,
        episode_start_time,
        class_id,
        unit_id,
        vehicle_id
    )
    INCLUDE (
        period_sort_id,
        episode_duration_seconds,
        episode_duration_minutes,
        gps_lat,
        gps_lon,
        location_025km
    );
END
GO

/* -----------------------------
   fact_engine_idling_metrics
   ----------------------------- */

/* Period-based metrics (KPI + top-five idle %) */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_fim_period_filters'
      AND object_id = OBJECT_ID('dbo.fact_engine_idling_metrics')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fim_period_filters
    ON dbo.fact_engine_idling_metrics (
        period_sort_id,
        toc_id,
        unit_id,
        vehicle_id
    )
    INCLUDE (
        date_id,
        daily_engine_run_minutes,
        daily_engine_idling_minutes
    );
END
GO

/* Date-based metrics (when using start/end dates) */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_fim_date_filters'
      AND object_id = OBJECT_ID('dbo.fact_engine_idling_metrics')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fim_date_filters
    ON dbo.fact_engine_idling_metrics (
        toc_id,
        date_id,
        unit_id,
        vehicle_id
    )
    INCLUDE (
        period_sort_id,
        daily_engine_run_minutes,
        daily_engine_idling_minutes
    );
END
GO