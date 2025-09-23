/* scripts/load_data.sql
   Reload all CSVs into existing Logplan tables.
   SERVICE is loaded via a staging table with FORMAT='CSV' + FIELDQUOTE to prevent
   description text from bleeding into EQUIPMENT_REQUIRED.
*/

------------------------------------------------------------
-- 0) Ensure we're in the right DB and schema exists
------------------------------------------------------------
USE Logplan;

IF OBJECT_ID('dbo.CLIENT','U') IS NULL OR
   OBJECT_ID('dbo.EMPLOYEE','U') IS NULL OR
   OBJECT_ID('dbo.AIRPORT','U') IS NULL OR
   OBJECT_ID('dbo.PROJECT','U') IS NULL OR
   OBJECT_ID('dbo.EQUIPMENT','U') IS NULL OR
   OBJECT_ID('dbo.[SERVICE]','U') IS NULL OR
   OBJECT_ID('dbo.SERVICE_EQUIPMENT','U') IS NULL OR
   OBJECT_ID('dbo.PS_DETAIL','U') IS NULL OR
   OBJECT_ID('dbo.PE_DETAIL','U') IS NULL
BEGIN
    RAISERROR('One or more tables are missing. Run scripts/create_tables.sql first.', 16, 1);
    RETURN;
END

------------------------------------------------------------
-- 1) Config: folder path + line endings
------------------------------------------------------------
DECLARE @data_path NVARCHAR(4000) = N'C:\Users\12rru\Downloads\SQL-Logplan-Database\data\';
-- If CSVs use Windows line endings, set @rt = N'\r\n'
DECLARE @rt        NVARCHAR(20)   = N'0x0a';   -- LF
DECLARE @sql       NVARCHAR(MAX);

-- Common BULK options (UTF-8) for non-quoted/simple CSVs
DECLARE @bulk NVARCHAR(MAX) = N'
WITH (
  FIELDTERMINATOR = '','',
  ROWTERMINATOR   = ''' + @rt + N''',
  FIRSTROW        = 2,
  CODEPAGE        = ''65001'',
  DATAFILETYPE    = ''char'',
  TABLOCK
);';

------------------------------------------------------------
-- 2) Clear existing rows (child -> parent)
------------------------------------------------------------
PRINT 'Clearing tables (child -> parent)...';

TRUNCATE TABLE dbo.PE_DETAIL;
TRUNCATE TABLE dbo.PS_DETAIL;
TRUNCATE TABLE dbo.SERVICE_EQUIPMENT;

DELETE FROM dbo.[SERVICE];
DELETE FROM dbo.EQUIPMENT;
DELETE FROM dbo.PROJECT;
DELETE FROM dbo.AIRPORT;
DELETE FROM dbo.EMPLOYEE;
DELETE FROM dbo.CLIENT;

------------------------------------------------------------
-- 3) Load base/reference tables
------------------------------------------------------------
PRINT 'Loading CLIENT...';
SET @sql = N'BULK INSERT dbo.CLIENT FROM ''' + @data_path + N'clientDATA.csv''' + @bulk;    EXEC (@sql);

PRINT 'Loading EMPLOYEE...';
SET @sql = N'BULK INSERT dbo.EMPLOYEE FROM ''' + @data_path + N'employeeDATA.csv''' + @bulk; EXEC (@sql);

PRINT 'Loading AIRPORT...';
SET @sql = N'BULK INSERT dbo.AIRPORT FROM ''' + @data_path + N'airportDATA.csv''' + @bulk;  EXEC (@sql);

PRINT 'Loading PROJECT...';
SET @sql = N'BULK INSERT dbo.PROJECT FROM ''' + @data_path + N'project.csv''' + @bulk;      EXEC (@sql);

PRINT 'Loading EQUIPMENT...';
SET @sql = N'BULK INSERT dbo.EQUIPMENT FROM ''' + @data_path + N'equipmentDATA.csv''' + @bulk; EXEC (@sql);

------------------------------------------------------------
-- 4) Robust load for SERVICE via staging (prevents column bleed)
------------------------------------------------------------
PRINT 'Loading SERVICE (staged with FIELDQUOTE)...';

-- Stage raw rows as NVARCHAR to preserve text exactly
IF OBJECT_ID('tempdb..#svc_raw') IS NOT NULL DROP TABLE #svc_raw;
CREATE TABLE #svc_raw (
    SERVICE_ID          NVARCHAR(50),
    SERVICE_LEVEL       NVARCHAR(200),
    SERVICE_NAME        NVARCHAR(200),
    SERVICE_COST        NVARCHAR(50),
    SERVICE_DESCRIPTION NVARCHAR(MAX),
    EQUIPMENT_REQUIRED  NVARCHAR(200)
);

-- Use SQL Server CSV parser with quotes
SET @sql = N'
BULK INSERT #svc_raw
FROM ''' + @data_path + N'SERVICEDATA_FINAL.csv''
WITH (
    FORMAT          = ''CSV'',
    FIELDTERMINATOR = '','',
    FIELDQUOTE      = ''"'',
    ROWTERMINATOR   = ''' + @rt + N''',
    FIRSTROW        = 2,
    CODEPAGE        = ''65001'',
    DATAFILETYPE    = ''char'',
    TABLOCK
);';
EXEC (@sql);

-- Replace table contents with cleaned/typed rows
DELETE FROM dbo.[SERVICE];

INSERT dbo.[SERVICE] (
    SERVICE_ID,
    SERVICE_LEVEL,
    SERVICE_NAME,
    SERVICE_COST,
    SERVICE_DESCRIPTION,
    EQUIPMENT_REQUIRED
)
SELECT
    TRY_CONVERT(INT, SERVICE_ID)                                          AS SERVICE_ID,
    NULLIF(LTRIM(RTRIM(SERVICE_LEVEL)), N'')                              AS SERVICE_LEVEL,
    NULLIF(LTRIM(RTRIM(SERVICE_NAME)),  N'')                              AS SERVICE_NAME,
    TRY_CONVERT(FLOAT, SERVICE_COST)                                      AS SERVICE_COST,
    /* strip outer quotes if present, and collapse doubled quotes "" -> " */
    CASE
        WHEN SERVICE_DESCRIPTION IS NULL THEN NULL
        WHEN LEFT(SERVICE_DESCRIPTION,1) = '"' AND RIGHT(SERVICE_DESCRIPTION,1) = '"'
            THEN REPLACE(SUBSTRING(SERVICE_DESCRIPTION,2,LEN(SERVICE_DESCRIPTION)-2), '""','"')
        ELSE REPLACE(SERVICE_DESCRIPTION, '""','"')
    END                                                                   AS SERVICE_DESCRIPTION,
    CASE
        WHEN TRIM(EQUIPMENT_REQUIRED) LIKE 'Yes%' THEN N'Yes'
        WHEN TRIM(EQUIPMENT_REQUIRED) LIKE 'No%'  THEN N'No'
        ELSE TRIM(EQUIPMENT_REQUIRED)
    END                                                                   AS EQUIPMENT_REQUIRED
FROM #svc_raw;

-- quick sanity check
PRINT 'SERVICE sample after clean:';
SELECT TOP 10 SERVICE_ID, SERVICE_NAME, LEFT(SERVICE_DESCRIPTION, 80) AS SERVICE_PREVIEW, EQUIPMENT_REQUIRED
FROM dbo.[SERVICE]
ORDER BY SERVICE_ID;

------------------------------------------------------------
-- 5) Load detail tables
------------------------------------------------------------
PRINT 'Loading SERVICE_EQUIPMENT...';
SET @sql = N'BULK INSERT dbo.SERVICE_EQUIPMENT FROM ''' + @data_path + N'Service_equipment.csv''' + @bulk; EXEC (@sql);

PRINT 'Loading PS_DETAIL...';
SET @sql = N'BULK INSERT dbo.PS_DETAIL FROM ''' + @data_path + N'ps_detail_test.csv''' + @bulk; EXEC (@sql);

PRINT 'Loading PE_DETAIL...';
SET @sql = N'BULK INSERT dbo.PE_DETAIL FROM ''' + @data_path + N'PE_DETAIL.csv''' + @bulk;   EXEC (@sql);

------------------------------------------------------------
-- 6) Verify row counts
------------------------------------------------------------
PRINT 'Row counts after load:';
SELECT 'CLIENT' AS Tbl, COUNT(*) AS Rows FROM dbo.CLIENT UNION ALL
SELECT 'EMPLOYEE', COUNT(*) FROM dbo.EMPLOYEE UNION ALL
SELECT 'AIRPORT', COUNT(*) FROM dbo.AIRPORT UNION ALL
SELECT 'PROJECT', COUNT(*) FROM dbo.PROJECT UNION ALL
SELECT 'EQUIPMENT', COUNT(*) FROM dbo.EQUIPMENT UNION ALL
SELECT 'SERVICE', COUNT(*) FROM dbo.[SERVICE] UNION ALL
SELECT 'SERVICE_EQUIPMENT', COUNT(*) FROM dbo.SERVICE_EQUIPMENT UNION ALL
SELECT 'PS_DETAIL', COUNT(*) FROM dbo.PS_DETAIL UNION ALL
SELECT 'PE_DETAIL', COUNT(*) FROM dbo.PE_DETAIL;
