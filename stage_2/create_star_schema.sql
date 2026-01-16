-- dim_priority
IF OBJECT_ID('dbo.dim_priority', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.dim_priority (
        priority_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_dim_priority PRIMARY KEY,
        priority_name NVARCHAR(50) NOT NULL
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_dim_priority_priority_name'
      AND object_id = OBJECT_ID('dbo.dim_priority')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX IX_dim_priority_priority_name
    ON dbo.dim_priority (priority_name);
END;


-- dim_status
IF OBJECT_ID('dbo.dim_status', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.dim_status (
        status_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_dim_status PRIMARY KEY,
        status_name NVARCHAR(50) NOT NULL
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_dim_status_status_name'
      AND object_id = OBJECT_ID('dbo.dim_status')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX IX_dim_status_status_name
    ON dbo.dim_status (status_name);
END;


-- dim_system
IF OBJECT_ID('dbo.dim_system', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.dim_system (
        system_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_dim_system PRIMARY KEY,
        system_name NVARCHAR(100) NOT NULL
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_dim_system_system_name'
      AND object_id = OBJECT_ID('dbo.dim_system')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX IX_dim_system_system_name
    ON dbo.dim_system (system_name);
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
        class_name NVARCHAR(10) NOT NULL
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
        unit_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_dim_delphi_unit PRIMARY KEY,
        unit NVARCHAR(50) NOT NULL,
        number_of_vehicles INT NOT NULL CONSTRAINT DF_dim_delphi_unit_number_of_vehicles DEFAULT 0
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


-- dim_alert_status
IF OBJECT_ID('dbo.dim_alert_status', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.dim_alert_status (
        alert_status_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_dim_alert_status PRIMARY KEY,
        alert_status_name NVARCHAR(50) NOT NULL
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_dim_alert_status_alert_status_name'
      AND object_id = OBJECT_ID('dbo.dim_alert_status')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX IX_dim_alert_status_alert_status_name
    ON dbo.dim_alert_status (alert_status_name);
END;


-- dim_vehicle
IF OBJECT_ID('dbo.dim_vehicle', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.dim_vehicle (
        vehicle_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_dim_vehicle PRIMARY KEY,
        vehicle NVARCHAR(100) NOT NULL,
        unit_id INT NOT NULL,
        CONSTRAINT FK_dim_vehicle_dim_delphi_unit
            FOREIGN KEY (unit_id) REFERENCES dbo.dim_delphi_unit(unit_id),
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


-- fact_alert_trace_reference
IF OBJECT_ID('dbo.fact_alert_trace_reference', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.fact_alert_trace_reference (
        id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_fact_alert_trace_reference PRIMARY KEY,
        storage_path NVARCHAR(850) NOT NULL,
        file_format NVARCHAR(50) NULL,
        date_created DATETIME2 NOT NULL DEFAULT GETDATE(),
        date_updated DATETIME2 NOT NULL DEFAULT GETDATE(),
        trace_start_time DATETIME2 NULL,
        trace_end_time DATETIME2 NULL,
        signal_count INT NULL,
        row_count INT NULL
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_alert_trace_reference_storage_path'
      AND object_id = OBJECT_ID('dbo.fact_alert_trace_reference')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_alert_trace_reference_storage_path
    ON dbo.fact_alert_trace_reference (storage_path);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_alert_trace_reference_date_created'
      AND object_id = OBJECT_ID('dbo.fact_alert_trace_reference')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_alert_trace_reference_date_created
    ON dbo.fact_alert_trace_reference (date_created);
END;


-- fact_alert
IF OBJECT_ID('dbo.fact_alert', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.fact_alert (
        alert_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_fact_alert PRIMARY KEY,
        source_alert_id NVARCHAR(100) NULL,
        title NVARCHAR(200) NULL,
        alert_timestamp DATETIME2 NULL,
        status_id INT NULL,
        date_created DATETIME2 NULL,
        date_reviewed DATETIME2 NULL,
        reviewed_by NVARCHAR(100) NULL,
        rejection_reason NVARCHAR(MAX) NULL,
        vehicle_id INT NULL,
        trace_ref_id INT NULL,
        alert_source NVARCHAR(20) NOT NULL,
        toc_id INT NULL,
        class_id INT NULL,
        depot_id INT NULL,
        CONSTRAINT FK_fact_alert_dim_alert_status
            FOREIGN KEY (status_id) REFERENCES dbo.dim_alert_status(alert_status_id),
        CONSTRAINT FK_fact_alert_dim_vehicle
            FOREIGN KEY (vehicle_id) REFERENCES dbo.dim_vehicle(vehicle_id),
        CONSTRAINT FK_fact_alert_fact_alert_trace_reference
            FOREIGN KEY (trace_ref_id) REFERENCES dbo.fact_alert_trace_reference(id),
        CONSTRAINT FK_fact_alert_dim_toc
            FOREIGN KEY (toc_id) REFERENCES dbo.dim_toc(toc_id),
        CONSTRAINT FK_fact_alert_dim_class
            FOREIGN KEY (class_id) REFERENCES dbo.dim_class(class_id),
        CONSTRAINT FK_fact_alert_dim_depot
            FOREIGN KEY (depot_id) REFERENCES dbo.dim_depot(depot_id),
        CONSTRAINT CHK_fact_alert_source
            CHECK (alert_source IN ('instrumentel', 'pb_event'))
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_alert_alert_source'
      AND object_id = OBJECT_ID('dbo.fact_alert')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_alert_alert_source
    ON dbo.fact_alert (alert_source);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_alert_title'
      AND object_id = OBJECT_ID('dbo.fact_alert')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_alert_title
    ON dbo.fact_alert (title);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_alert_status_id'
      AND object_id = OBJECT_ID('dbo.fact_alert')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_alert_status_id
    ON dbo.fact_alert (status_id);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_alert_alert_timestamp'
      AND object_id = OBJECT_ID('dbo.fact_alert')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_alert_alert_timestamp
    ON dbo.fact_alert (alert_timestamp);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_alert_vehicle_id'
      AND object_id = OBJECT_ID('dbo.fact_alert')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_alert_vehicle_id
    ON dbo.fact_alert (vehicle_id);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_alert_trace_ref_id'
      AND object_id = OBJECT_ID('dbo.fact_alert')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_alert_trace_ref_id
    ON dbo.fact_alert (trace_ref_id);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_alert_source_alert_id'
      AND object_id = OBJECT_ID('dbo.fact_alert')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_alert_source_alert_id
    ON dbo.fact_alert (source_alert_id);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_alert_toc_id'
      AND object_id = OBJECT_ID('dbo.fact_alert')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_alert_toc_id
    ON dbo.fact_alert (toc_id);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_alert_class_id'
      AND object_id = OBJECT_ID('dbo.fact_alert')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_alert_class_id
    ON dbo.fact_alert (class_id);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_alert_depot_id'
      AND object_id = OBJECT_ID('dbo.fact_alert')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_alert_depot_id
    ON dbo.fact_alert (depot_id);
END;


-- fact_case
IF OBJECT_ID('dbo.fact_case', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.fact_case (
        case_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_fact_case PRIMARY KEY,
        priority_id INT NULL,
        status_id INT NULL,
        rfs NVARCHAR(MAX) NULL,
        title NVARCHAR(500) NULL,
        description NVARCHAR(MAX) NULL,
        system_id INT NULL,
        linked_work_orders NVARCHAR(MAX) NULL,
        created_at DATETIME2 NULL,
        updated_at DATETIME2 NULL,
        updated_by VARCHAR(100) NULL,
        toc_id INT NULL,
        class_id INT NULL,
        depot_id INT NULL,
        vehicle_id INT NULL,
        CONSTRAINT FK_fact_case_dim_priority
            FOREIGN KEY (priority_id) REFERENCES dbo.dim_priority(priority_id),
        CONSTRAINT FK_fact_case_dim_status
            FOREIGN KEY (status_id) REFERENCES dbo.dim_status(status_id),
        CONSTRAINT FK_fact_case_dim_system
            FOREIGN KEY (system_id) REFERENCES dbo.dim_system(system_id),
        CONSTRAINT FK_fact_case_dim_toc
            FOREIGN KEY (toc_id) REFERENCES dbo.dim_toc(toc_id),
        CONSTRAINT FK_fact_case_dim_class
            FOREIGN KEY (class_id) REFERENCES dbo.dim_class(class_id),
        CONSTRAINT FK_fact_case_dim_depot
            FOREIGN KEY (depot_id) REFERENCES dbo.dim_depot(depot_id),
        CONSTRAINT FK_fact_case_dim_vehicle
            FOREIGN KEY (vehicle_id) REFERENCES dbo.dim_vehicle(vehicle_id)
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_case_status_id'
      AND object_id = OBJECT_ID('dbo.fact_case')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_case_status_id
    ON dbo.fact_case (status_id);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_case_priority_id'
      AND object_id = OBJECT_ID('dbo.fact_case')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_case_priority_id
    ON dbo.fact_case (priority_id);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_case_toc_id'
      AND object_id = OBJECT_ID('dbo.fact_case')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_case_toc_id
    ON dbo.fact_case (toc_id);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_case_class_id'
      AND object_id = OBJECT_ID('dbo.fact_case')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_case_class_id
    ON dbo.fact_case (class_id);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_case_depot_id'
      AND object_id = OBJECT_ID('dbo.fact_case')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_case_depot_id
    ON dbo.fact_case (depot_id);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_case_system_id'
      AND object_id = OBJECT_ID('dbo.fact_case')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_case_system_id
    ON dbo.fact_case (system_id);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_case_vehicle_id'
      AND object_id = OBJECT_ID('dbo.fact_case')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_case_vehicle_id
    ON dbo.fact_case (vehicle_id);
END;


-- fact_record
IF OBJECT_ID('dbo.fact_record', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.fact_record (
        record_id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_fact_record PRIMARY KEY,
        created_at DATETIME2 NULL,
        updated_at DATETIME2 NULL,
        record NVARCHAR(MAX) NULL,
        case_id INT NOT NULL,
        author NVARCHAR(100) NULL,
        record_type NVARCHAR(50) NULL,
        CONSTRAINT FK_fact_record_fact_case
            FOREIGN KEY (case_id) REFERENCES dbo.fact_case(case_id)
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_record_case_id'
      AND object_id = OBJECT_ID('dbo.fact_record')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_record_case_id
    ON dbo.fact_record (case_id);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_record_created_at'
      AND object_id = OBJECT_ID('dbo.fact_record')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_record_created_at
    ON dbo.fact_record (created_at);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_fact_record_record_type'
      AND object_id = OBJECT_ID('dbo.fact_record')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_fact_record_record_type
    ON dbo.fact_record (record_type);
END;


-- bridge_case_intervention
IF OBJECT_ID('dbo.bridge_case_intervention', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.bridge_case_intervention (
        case_id INT NOT NULL,
        master_intervention_key NVARCHAR(100) NOT NULL,
        CONSTRAINT PK_bridge_case_intervention PRIMARY KEY (case_id, master_intervention_key),
        CONSTRAINT FK_bridge_case_intervention_fact_case
            FOREIGN KEY (case_id) REFERENCES dbo.fact_case(case_id),
        CONSTRAINT FK_bridge_case_intervention_fact_interventions
            FOREIGN KEY (master_intervention_key) REFERENCES dbo.fact_interventions(master_intervention_key)
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_bridge_case_intervention_master_intervention_key'
      AND object_id = OBJECT_ID('dbo.bridge_case_intervention')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_bridge_case_intervention_master_intervention_key
    ON dbo.bridge_case_intervention (master_intervention_key);
END;


-- bridge_case_alert
IF OBJECT_ID('dbo.bridge_case_alert', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.bridge_case_alert (
        case_id INT NOT NULL,
        ins_alt_id INT NOT NULL,
        date_assigned DATETIME2 NULL,
        assigned_by NVARCHAR(100) NULL,
        assigned_notes NVARCHAR(500) NULL,
        alert_source NVARCHAR(20) NOT NULL,
        CONSTRAINT PK_bridge_case_alert PRIMARY KEY (case_id, ins_alt_id),
        CONSTRAINT FK_bridge_case_alert_fact_case
            FOREIGN KEY (case_id) REFERENCES dbo.fact_case(case_id),
        CONSTRAINT FK_bridge_case_alert_fact_alert
            FOREIGN KEY (ins_alt_id) REFERENCES dbo.fact_alert(alert_id)
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_bridge_case_alert_ins_alt_id'
      AND object_id = OBJECT_ID('dbo.bridge_case_alert')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_bridge_case_alert_ins_alt_id
    ON dbo.bridge_case_alert (ins_alt_id);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_bridge_case_alert_alert_source'
      AND object_id = OBJECT_ID('dbo.bridge_case_alert')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_bridge_case_alert_alert_source
    ON dbo.bridge_case_alert (alert_source);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_bridge_case_alert_date_assigned'
      AND object_id = OBJECT_ID('dbo.bridge_case_alert')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_bridge_case_alert_date_assigned
    ON dbo.bridge_case_alert (date_assigned);
END;


-- bridge_case_delphi_unit
IF OBJECT_ID('dbo.bridge_case_delphi_unit', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.bridge_case_delphi_unit (
        case_id INT NOT NULL,
        unit_id INT NOT NULL,
        CONSTRAINT PK_bridge_case_delphi_unit PRIMARY KEY (case_id, unit_id),
        CONSTRAINT FK_bridge_case_delphi_unit_fact_case
            FOREIGN KEY (case_id) REFERENCES dbo.fact_case(case_id),
        CONSTRAINT FK_bridge_case_delphi_unit_dim_delphi_unit
            FOREIGN KEY (unit_id) REFERENCES dbo.dim_delphi_unit(unit_id)
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_bridge_case_delphi_unit_unit_id'
      AND object_id = OBJECT_ID('dbo.bridge_case_delphi_unit')
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_bridge_case_delphi_unit_unit_id
    ON dbo.bridge_case_delphi_unit (unit_id);
END;
