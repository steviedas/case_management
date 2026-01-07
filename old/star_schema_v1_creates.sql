-- dim_toc
IF OBJECT_ID('dbo.dim_toc', 'U') IS NULL
CREATE TABLE dbo.dim_toc (
    toc_id INT PRIMARY KEY IDENTITY(1,1),
    toc_name NVARCHAR(40) NOT NULL
);
IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_dim_toc_toc_name'
        AND object_id = OBJECT_ID('dbo.dim_toc')
)
CREATE UNIQUE NONCLUSTERED INDEX IX_dim_toc_toc_name
ON dbo.dim_toc (toc_name);


-- dim_class
IF OBJECT_ID('dbo.dim_class', 'U') IS NULL
CREATE TABLE dbo.dim_class (
    class_id INT PRIMARY KEY IDENTITY(1,1),
    class_name NVARCHAR(3)
);
IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_dim_class_class_name'
        AND object_id = OBJECT_ID('dbo.dim_class')
)
CREATE UNIQUE NONCLUSTERED INDEX IX_dim_class_class_name
ON dbo.dim_class (class_name);


-- dim_depot
IF OBJECT_ID('dbo.dim_depot', 'U') IS NULL
CREATE TABLE dbo.dim_depot (
    depot_id INT PRIMARY KEY IDENTITY(1,1),
    depot_name NVARCHAR(50) NOT NULL
);
IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_dim_depot_depot_name'
        AND object_id = OBJECT_ID('dbo.dim_depot')
)
CREATE UNIQUE NONCLUSTERED INDEX IX_dim_depot_depot_name
ON dbo.dim_depot (depot_name);


-- dim_unit
IF OBJECT_ID('dbo.dim_unit', 'U') IS NULL
CREATE TABLE dbo.dim_unit (
    unit_id INT PRIMARY KEY IDENTITY(1,1),
    unit_name NVARCHAR(10) NOT NULL,
    vehicles NVARCHAR(400)
);
IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_dim_unit_unit_name'
        AND object_id = OBJECT_ID('dbo.dim_unit')
)
CREATE UNIQUE NONCLUSTERED INDEX IX_dim_unit_unit_name
ON dbo.dim_unit (unit_name);


-- dim_railway_calendar
IF OBJECT_ID('dbo.dim_railway_calendar', 'U') IS NULL
CREATE TABLE dbo.dim_railway_calendar (
    date_id INT PRIMARY KEY IDENTITY(1,1),
    date DATE NOT NULL,
    period_display_short_name NVARCHAR(10) NOT NULL,
    period_sort_id INT NOT NULL
);

IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_dim_railway_calendar_date'
        AND object_id = OBJECT_ID('dbo.dim_railway_calendar')
)
CREATE UNIQUE NONCLUSTERED INDEX IX_dim_railway_calendar_date
ON dbo.dim_railway_calendar (date);


-- fact_interventions
IF OBJECT_ID('dbo.fact_interventions', 'U') IS NULL
CREATE TABLE fact_interventions (
    toc_id INT NULL,
    class_id INT NULL,
    depot_id INT NULL,
    unit_id INT NULL,
    date_id INT NULL,

    -- Add optional attributes below:
    vehicle NVARCHAR(30) NULL,
    [date] DATE NOT NULL,
    intervention_report NVARCHAR(MAX) NULL,
    intervention_action NVARCHAR(MAX) NULL,
    p_symptom_code_inferred NVARCHAR(30) NULL,
    p_root_code_display NVARCHAR(20) NULL,
    p_root_code_display_desc NVARCHAR(100) NULL,
    intervention_type NVARCHAR(MAX) NOT NULL,
    intervention_key NVARCHAR(MAX) NOT NULL,
    railway_period NVARCHAR(10) NOT NULL,
    period_sort_id INT NOT NULL,
    sum_total_delay_minutes INT NULL,
    fleet_name NVARCHAR(20) NULL,
    [location] NVARCHAR(200) NULL,
    porterbrook_asset BIT,
    is_tin BIT,
    is_verified BIT,
    master_intervention_key NVARCHAR(100),
    count_full_cancellations INT NULL,

    -- Foreign Keys
    FOREIGN KEY (toc_id) REFERENCES dim_toc(toc_id),
    FOREIGN KEY (class_id) REFERENCES dim_class(class_id),
    FOREIGN KEY (depot_id) REFERENCES dim_depot(depot_id),
    FOREIGN KEY (unit_id) REFERENCES dim_unit(unit_id),
    FOREIGN KEY (date_id) REFERENCES dim_railway_calendar(date_id),

    -- Primary Key
    PRIMARY KEY (master_intervention_key)
    );

IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_fact_interventions_filters'
    AND object_id = OBJECT_ID('dbo.fact_interventions')
)
CREATE NONCLUSTERED INDEX IX_fact_interventions_filters
ON dbo.fact_interventions (
    toc_id ASC, period_sort_id DESC, class_id ASC, depot_id ASC, is_verified ASC, date ASC
)
INCLUDE (sum_total_delay_minutes, p_root_code_display_desc, is_tin);

IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'idx_fact_interventions_period_toc'
    AND object_id = OBJECT_ID('dbo.fact_interventions')
)
CREATE NONCLUSTERED INDEX idx_fact_interventions_period_toc
ON dbo.fact_interventions (period_sort_id ASC, toc_id ASC);

IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_fact_interventions_trend_lookup'
    AND object_id = OBJECT_ID('dbo.fact_interventions')
)
CREATE NONCLUSTERED INDEX IX_fact_interventions_trend_lookup
ON dbo.fact_interventions (p_root_code_display_desc ASC, period_sort_id ASC)
INCLUDE (sum_total_delay_minutes);

IF NOT EXISTS (
    SELECT * FROM sys.indexes
    WHERE name = 'IX_fact_interventions_master_key'
        AND object_id = OBJECT_ID('dbo.fact_interventions')
)
CREATE UNIQUE NONCLUSTERED INDEX IX_fact_interventions_master_key
ON dbo.fact_interventions (master_intervention_key);
