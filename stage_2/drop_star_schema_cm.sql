IF OBJECT_ID('dbo.case_alert', 'U') IS NOT NULL
    DROP TABLE dbo.case_alert;

IF OBJECT_ID('dbo.case_intervention', 'U') IS NOT NULL
    DROP TABLE dbo.case_intervention;

IF OBJECT_ID('dbo.fact_records', 'U') IS NOT NULL
    DROP TABLE dbo.fact_records;

IF OBJECT_ID('dbo.fact_cases', 'U') IS NOT NULL
    DROP TABLE dbo.fact_cases;

IF OBJECT_ID('dbo.fact_alert', 'U') IS NOT NULL
    DROP TABLE dbo.fact_alert;

IF OBJECT_ID('dbo.fact_alert_trace_reference', 'U') IS NOT NULL
    DROP TABLE dbo.fact_alert_trace_reference;

IF OBJECT_ID('dbo.dim_vehicle', 'U') IS NOT NULL
    DROP TABLE dbo.dim_vehicle;

IF OBJECT_ID('dbo.dim_alert_status', 'U') IS NOT NULL
    DROP TABLE dbo.dim_alert_status;

IF OBJECT_ID('dbo.dim_delphi_unit', 'U') IS NOT NULL
    DROP TABLE dbo.dim_delphi_unit;

IF OBJECT_ID('dbo.dim_system', 'U') IS NOT NULL
    DROP TABLE dbo.dim_system;

IF OBJECT_ID('dbo.dim_status', 'U') IS NOT NULL
    DROP TABLE dbo.dim_status;

IF OBJECT_ID('dbo.dim_priority', 'U') IS NOT NULL
    DROP TABLE dbo.dim_priority;
