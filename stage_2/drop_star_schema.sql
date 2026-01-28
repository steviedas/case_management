IF OBJECT_ID('dbo.bridge_case_delphi_unit', 'U') IS NOT NULL
    DROP TABLE dbo.bridge_case_delphi_unit;

IF OBJECT_ID('dbo.bridge_case_alert', 'U') IS NOT NULL
    DROP TABLE dbo.bridge_case_alert;

IF OBJECT_ID('dbo.bridge_case_intervention', 'U') IS NOT NULL
    DROP TABLE dbo.bridge_case_intervention;

IF OBJECT_ID('dbo.fact_record', 'U') IS NOT NULL
    DROP TABLE dbo.fact_record;

IF OBJECT_ID('dbo.fact_alert', 'U') IS NOT NULL
    DROP TABLE dbo.fact_alert;

IF OBJECT_ID('dbo.fact_case', 'U') IS NOT NULL
    DROP TABLE dbo.fact_case;

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

IF OBJECT_ID('dbo.dim_record_type', 'U') IS NOT NULL
    DROP TABLE dbo.dim_record_type;

IF OBJECT_ID('dbo.dim_code', 'U') IS NOT NULL
    DROP TABLE dbo.dim_code;
