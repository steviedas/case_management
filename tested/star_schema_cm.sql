-- =============================================
-- Case Management Star Schema DDL
-- Tables ordered for optimal data population
-- =============================================

-- =============================================
-- PHASE 1: LOOKUP DIMENSION TABLES
-- Load these first - reference/master data
-- =============================================

-- dim_status
IF OBJECT_ID('dbo.dim_status', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.dim_status (
        id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_dim_status PRIMARY KEY,
        name NVARCHAR(50) NOT NULL
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_dim_status_name'
      AND object_id = OBJECT_ID('dbo.dim_status')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX IX_dim_status_name
    ON dbo.dim_status (name);
END;


-- dim_system
IF OBJECT_ID('dbo.dim_system', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.dim_system (
        id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_dim_system PRIMARY KEY,
        system NVARCHAR(100) NOT NULL
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_dim_system_system'
      AND object_id = OBJECT_ID('dbo.dim_system')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX IX_dim_system_system
    ON dbo.dim_system (system);
END;


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


-- dim_depot
IF OBJECT_ID('dbo.dim_depot', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.dim_depot (
        depot_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_dim_depot PRIMARY KEY,
        depot_name NVARCHAR(100) NOT NULL
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_dim_depot_depot_name'
      AND object_id = OBJECT_ID('dbo.dim_depot')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX IX_dim_depot_depot_name
    ON dbo.dim_depot (depot_name);
END;


-- dim_class
IF OBJECT_ID('dbo.dim_class', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.dim_class (
        class_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_dim_class PRIMARY KEY,
        class_name NVARCHAR(100) NOT NULL
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_dim_class_class_name'
      AND object_id = OBJECT_ID('dbo.dim_class')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX IX_dim_class_class_name
    ON dbo.dim_class (class_name);
END;


-- dim_delphi_unit
IF OBJECT_ID('dbo.dim_delphi_unit', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.dim_delphi_unit (
        id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_dim_delphi_unit PRIMARY KEY,
        unit NVARCHAR(50) NOT NULL
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_dim_delphi_unit_unit'
      AND object_id = OBJECT_ID('dbo.dim_delphi_unit')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX IX_dim_delphi_unit_unit
    ON dbo.dim_delphi_unit (unit);
END;


-- =============================================
-- PHASE 2: DEPENDENT DIMENSION TABLES
-- Load after Phase 1 (depends on dim_delphi_unit)
-- =============================================

-- dim_vehicle
IF OBJECT_ID('dbo.dim_vehicle', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.dim_vehicle (
        id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_dim_vehicle PRIMARY KEY,
        vehicle NVARCHAR(100) NOT NULL,
        unit_id INT NOT NULL,
        CONSTRAINT FK_dim_vehicle_dim_delphi_unit
            FOREIGN KEY (unit_id) REFERENCES dbo.dim_delphi_unit(id),
        CONSTRAINT UQ_dim_vehicle_unit_vehicle
            UNIQUE (unit_id, vehicle)
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_dim_vehicle_unit_id'
      AND object_id = OBJECT_ID('dbo.dim_vehicle')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_dim_vehicle_unit_id
    ON dbo.dim_vehicle (unit_id);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'UX_dim_vehicle_unit_vehicle'
      AND object_id = OBJECT_ID('dbo.dim_vehicle')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX UX_dim_vehicle_unit_vehicle
    ON dbo.dim_vehicle (unit_id, vehicle);
END;


-- =============================================
-- PHASE 3: STANDALONE FACT REFERENCE TABLES
-- Load after Phase 1-2 (no dependencies on other facts)
-- =============================================

-- fact_instrumentel_alert
IF OBJECT_ID('dbo.fact_instrumentel_alert', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.fact_instrumentel_alert (
        id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_fact_instrumentel_alert PRIMARY KEY,
        name NVARCHAR(200) NULL
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_instrumentel_alert_name'
      AND object_id = OBJECT_ID('dbo.fact_instrumentel_alert')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_instrumentel_alert_name
    ON dbo.fact_instrumentel_alert (name);
END;


-- fact_pb_event
IF OBJECT_ID('dbo.fact_pb_event', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.fact_pb_event (
        id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_fact_pb_event PRIMARY KEY,
        name NVARCHAR(200) NULL,
        start_time NVARCHAR(50) NULL,
        end_time NVARCHAR(50) NULL
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_pb_event_name'
      AND object_id = OBJECT_ID('dbo.fact_pb_event')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_pb_event_name
    ON dbo.fact_pb_event (name);
END;


-- =============================================
-- PHASE 4: CORE FACT TABLE
-- Load after Phase 1-3 (the main entity)
-- =============================================

-- fact_cases
IF OBJECT_ID('dbo.fact_cases', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.fact_cases (
        id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_fact_cases PRIMARY KEY,
        priority INT NULL,
        status INT NULL,
        rfs NVARCHAR(MAX) NULL,
        title NVARCHAR(500) NULL,
        system NVARCHAR(100) NULL,
        date DATE NULL,
        toc_id INT NULL,
        class_id INT NULL,
        depot_id INT NULL,
        vehicle_id INT NULL,
        CONSTRAINT FK_fact_cases_dim_status
            FOREIGN KEY (status) REFERENCES dbo.dim_status(id),
        CONSTRAINT FK_fact_cases_dim_toc
            FOREIGN KEY (toc_id) REFERENCES dbo.dim_toc(toc_id),
        CONSTRAINT FK_fact_cases_dim_class
            FOREIGN KEY (class_id) REFERENCES dbo.dim_class(class_id),
        CONSTRAINT FK_fact_cases_dim_depot
            FOREIGN KEY (depot_id) REFERENCES dbo.dim_depot(depot_id)
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_cases_status'
      AND object_id = OBJECT_ID('dbo.fact_cases')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_cases_status
    ON dbo.fact_cases (status);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_cases_date'
      AND object_id = OBJECT_ID('dbo.fact_cases')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_cases_date
    ON dbo.fact_cases (date);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_cases_toc_id'
      AND object_id = OBJECT_ID('dbo.fact_cases')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_cases_toc_id
    ON dbo.fact_cases (toc_id);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_cases_class_id'
      AND object_id = OBJECT_ID('dbo.fact_cases')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_cases_class_id
    ON dbo.fact_cases (class_id);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_cases_depot_id'
      AND object_id = OBJECT_ID('dbo.fact_cases')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_cases_depot_id
    ON dbo.fact_cases (depot_id);
END;


-- =============================================
-- PHASE 5: CASE-RELATED FACT TABLES
-- Load after Phase 4 (depends on fact_cases)
-- =============================================

-- fact_records
IF OBJECT_ID('dbo.fact_records', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.fact_records (
        id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_fact_records PRIMARY KEY,
        date DATE NULL,
        record NVARCHAR(MAX) NULL,
        case_id INT NOT NULL,
        author NVARCHAR(100) NULL,
        record_type NVARCHAR(50) NULL,
        CONSTRAINT FK_fact_records_fact_cases
            FOREIGN KEY (case_id) REFERENCES dbo.fact_cases(id)
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_records_case_id'
      AND object_id = OBJECT_ID('dbo.fact_records')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_records_case_id
    ON dbo.fact_records (case_id);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_records_date'
      AND object_id = OBJECT_ID('dbo.fact_records')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_records_date
    ON dbo.fact_records (date);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_records_record_type'
      AND object_id = OBJECT_ID('dbo.fact_records')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_records_record_type
    ON dbo.fact_records (record_type);
END;


-- =============================================
-- PHASE 6: BRIDGE/JUNCTION TABLES
-- Load last (depends on multiple tables)
-- =============================================

-- case_unit
IF OBJECT_ID('dbo.case_unit', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.case_unit (
        case_id INT NOT NULL,
        unit_id INT NOT NULL,
        CONSTRAINT PK_case_unit PRIMARY KEY (case_id, unit_id),
        CONSTRAINT FK_case_unit_fact_cases
            FOREIGN KEY (case_id) REFERENCES dbo.fact_cases(id),
        CONSTRAINT FK_case_unit_dim_delphi_unit
            FOREIGN KEY (unit_id) REFERENCES dbo.dim_delphi_unit(id)
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_case_unit_unit_id'
      AND object_id = OBJECT_ID('dbo.case_unit')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_case_unit_unit_id
    ON dbo.case_unit (unit_id);
END;


-- case_intervention
IF OBJECT_ID('dbo.case_intervention', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.case_intervention (
        case_id INT NOT NULL,
        intervention_id INT NOT NULL,
        CONSTRAINT PK_case_intervention PRIMARY KEY (case_id, intervention_id),
        CONSTRAINT FK_case_intervention_fact_cases
            FOREIGN KEY (case_id) REFERENCES dbo.fact_cases(id)
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_case_intervention_intervention_id'
      AND object_id = OBJECT_ID('dbo.case_intervention')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_case_intervention_intervention_id
    ON dbo.case_intervention (intervention_id);
END;


-- case_instrumentel_alert
IF OBJECT_ID('dbo.case_instrumentel_alert', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.case_instrumentel_alert (
        case_id INT NOT NULL,
        ins_alt_id INT NOT NULL,
        CONSTRAINT PK_case_instrumentel_alert PRIMARY KEY (case_id, ins_alt_id),
        CONSTRAINT FK_case_instrumentel_alert_fact_cases
            FOREIGN KEY (case_id) REFERENCES dbo.fact_cases(id),
        CONSTRAINT FK_case_instrumentel_alert_fact_instrumentel_alert
            FOREIGN KEY (ins_alt_id) REFERENCES dbo.fact_instrumentel_alert(id)
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_case_instrumentel_alert_ins_alt_id'
      AND object_id = OBJECT_ID('dbo.case_instrumentel_alert')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_case_instrumentel_alert_ins_alt_id
    ON dbo.case_instrumentel_alert (ins_alt_id);
END;


-- case_pb_alert
IF OBJECT_ID('dbo.case_pb_alert', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.case_pb_alert (
        case_id INT NOT NULL,
        pb_alt_id INT NOT NULL,
        CONSTRAINT PK_case_pb_alert PRIMARY KEY (case_id, pb_alt_id),
        CONSTRAINT FK_case_pb_alert_fact_cases
            FOREIGN KEY (case_id) REFERENCES dbo.fact_cases(id),
        CONSTRAINT FK_case_pb_alert_fact_pb_event
            FOREIGN KEY (pb_alt_id) REFERENCES dbo.fact_pb_event(id)
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_case_pb_alert_pb_alt_id'
      AND object_id = OBJECT_ID('dbo.case_pb_alert')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_case_pb_alert_pb_alt_id
    ON dbo.case_pb_alert (pb_alt_id);
END;
