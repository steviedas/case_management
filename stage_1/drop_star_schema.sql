IF OBJECT_ID('dbo.fact_interventions', 'U') IS NOT NULL
    DROP TABLE dbo.fact_interventions;

IF OBJECT_ID('dbo.dim_railway_calendar', 'U') IS NOT NULL
    DROP TABLE dbo.dim_railway_calendar;

IF OBJECT_ID('dbo.dim_unit', 'U') IS NOT NULL
    DROP TABLE dbo.dim_unit;

IF OBJECT_ID('dbo.dim_depot', 'U') IS NOT NULL
    DROP TABLE dbo.dim_depot;

IF OBJECT_ID('dbo.dim_class', 'U') IS NOT NULL
    DROP TABLE dbo.dim_class;

IF OBJECT_ID('dbo.dim_toc', 'U') IS NOT NULL
    DROP TABLE dbo.dim_toc;
