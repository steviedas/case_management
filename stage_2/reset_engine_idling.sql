IF OBJECT_ID('dbo.EngineIdlingEpisodes', 'U') IS NOT NULL
    DROP TABLE dbo.EngineIdlingEpisodes;

IF OBJECT_ID('dbo.EngineIdlingMetrics', 'U') IS NOT NULL
    DROP TABLE dbo.EngineIdlingMetrics;

IF OBJECT_ID('dbo.fact_engine_idling_episode', 'U') IS NOT NULL
    DROP TABLE dbo.fact_engine_idling_episode;

IF OBJECT_ID('dbo.fact_engine_idling_metrics', 'U') IS NOT NULL
    DROP TABLE dbo.fact_engine_idling_metrics;