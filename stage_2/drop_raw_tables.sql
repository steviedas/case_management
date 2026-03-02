IF OBJECT_ID('dbo.Alerts', 'U') IS NOT NULL
    DROP TABLE dbo.Alerts;

IF OBJECT_ID('dbo.AlertTraceReference', 'U') IS NOT NULL
    DROP TABLE dbo.AlertTraceReference;

IF OBJECT_ID('dbo.EngineIdlingEpisodes', 'U') IS NOT NULL
    DROP TABLE dbo.EngineIdlingEpisodes;

IF OBJECT_ID('dbo.EngineIdlingMetrics', 'U') IS NOT NULL
    DROP TABLE dbo.EngineIdlingMetrics;

IF OBJECT_ID('dbo.fact_engine_idling_episode', 'U') IS NOT NULL
    DROP TABLE dbo.fact_engine_idling_episode;

IF OBJECT_ID('dbo.fact_engine_idling_metrics', 'U') IS NOT NULL
    DROP TABLE dbo.fact_engine_idling_metrics;

IF OBJECT_ID('dbo.Report', 'U') IS NOT NULL
    DROP TABLE dbo.Report;

IF OBJECT_ID('dbo.ReportCase', 'U') IS NOT NULL
    DROP TABLE dbo.ReportCase;

IF OBJECT_ID('dbo.ReportSnapshot', 'U') IS NOT NULL
    DROP TABLE dbo.ReportSnapshot;

IF OBJECT_ID('dbo.ReportSnapshotRow', 'U') IS NOT NULL
    DROP TABLE dbo.ReportSnapshotRow;

IF OBJECT_ID('dbo.RCMCaseManagement', 'U') IS NOT NULL
    DROP TABLE dbo.RCMCaseManagement;
