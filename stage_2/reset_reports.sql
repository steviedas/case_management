IF OBJECT_ID('dbo.bridge_case_report_snapshot_row_id', 'U') IS NOT NULL
    DROP TABLE dbo.bridge_case_report_snapshot_row_id;

IF OBJECT_ID('dbo.dim_report_snapshot_row', 'U') IS NOT NULL
    DROP TABLE dbo.dim_report_snapshot_row;

IF OBJECT_ID('dbo.fact_report_snapshot', 'U') IS NOT NULL
    DROP TABLE dbo.fact_report_snapshot;

IF OBJECT_ID('dbo.fact_report', 'U') IS NOT NULL
    DROP TABLE dbo.fact_report;

IF OBJECT_ID('dbo.Report', 'U') IS NOT NULL
    DROP TABLE dbo.Report;

IF OBJECT_ID('dbo.ReportCase', 'U') IS NOT NULL
    DROP TABLE dbo.ReportCase;

IF OBJECT_ID('dbo.ReportSnapshot', 'U') IS NOT NULL
    DROP TABLE dbo.ReportSnapshot;

IF OBJECT_ID('dbo.ReportSnapshotRow', 'U') IS NOT NULL
    DROP TABLE dbo.ReportSnapshotRow;
