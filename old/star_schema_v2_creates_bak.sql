-- dim_unit
IF OBJECT_ID('dbo.dim_unit', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.dim_unit (
        id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_dim_unit PRIMARY KEY,
        unit NVARCHAR(10) NOT NULL
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_dim_unit_unit'
      AND object_id = OBJECT_ID('dbo.dim_unit')
)
BEGIN
    CREATE UNIQUE NONCLUSTERED INDEX IX_dim_unit_unit
    ON dbo.dim_unit (unit);
END;

-- dim_vehicle
IF OBJECT_ID('dbo.dim_vehicle', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.dim_vehicle
    (
        id INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_dim_vehicle PRIMARY KEY,
        vehicle NVARCHAR(50) NOT NULL,
        unit_id INT NOT NULL,
        CONSTRAINT FK_dim_vehicle_dim_unit
            FOREIGN KEY (unit_id) REFERENCES dbo.dim_unit(id),
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
