/* load_data.sql — BULK INSERT all CSVs into existing tables */

USE Logplan;
GO

-- 🔧 Configure your CSV folder + line endings
DECLARE @data_path NVARCHAR(4000) = N'C:\Users\12rru\Downloads\SQL-Logplan-Database\data\';
DECLARE @rt        NVARCHAR(20)   = N'0x0a'; -- if needed, switch to N'\r\n'
DECLARE @sql       NVARCHAR(MAX);

-- (Optional) Clear existing rows to avoid duplicates
-- TRUNCATE TABLE dbo.PE_DETAIL;
-- TRUNCATE TABLE dbo.PS_DETAIL;
-- TRUNCATE TABLE dbo.SERVICE_EQUIPMENT;
-- TRUNCATE TABLE dbo.[SERVICE];
-- TRUNCATE TABLE dbo.EQUIPMENT;
-- TRUNCATE TABLE dbo.PROJECT;
-- TRUNCATE TABLE dbo.AIRPORT;
-- TRUNCATE TABLE dbo.EMPLOYEE;
-- TRUNCATE TABLE dbo.CLIENT;

-- Helper macro for bulk insert
DECLARE @bulkTemplate NVARCHAR(MAX) = N'
BULK INSERT {TABLE}
FROM ''{FILE}''
WITH (
    FIELDTERMINATOR = '','',
    ROWTERMINATOR   = ''' + @rt + N''',
    FIRSTROW        = 2,
    CODEPAGE        = ''65001'',
    DATAFILETYPE    = ''char'',
    TABLOCK
);';

-- CLIENT
SET @sql = REPLACE(REPLACE(@bulkTemplate, '{TABLE}', 'dbo.CLIENT'),
                   '{FILE}', @data_path + N'clientDATA.csv');
BEGIN TRY EXEC(@sql); PRINT 'CLIENT loaded OK'; END TRY
BEGIN CATCH SELECT 'CLIENT' AS Src, ERROR_NUMBER() AS ErrNum, ERROR_MESSAGE() AS ErrMsg; END CATCH;

-- EMPLOYEE
SET @sql = REPLACE(REPLACE(@bulkTemplate, '{TABLE}', 'dbo.EMPLOYEE'),
                   '{FILE}', @data_path + N'employeeDATA.csv');
BEGIN TRY EXEC(@sql); PRINT 'EMPLOYEE loaded OK'; END TRY
BEGIN CATCH SELECT 'EMPLOYEE' AS Src, ERROR_NUMBER() AS ErrNum, ERROR_MESSAGE() AS ErrMsg; END CATCH;

-- AIRPORT
SET @sql = REPLACE(REPLACE(@bulkTemplate, '{TABLE}', 'dbo.AIRPORT'),
                   '{FILE}', @data_path + N'airportDATA.csv');
BEGIN TRY EXEC(@sql); PRINT 'AIRPORT loaded OK'; END TRY
BEGIN CATCH SELECT 'AIRPORT' AS Src, ERROR_NUMBER() AS ErrNum, ERROR_MESSAGE() AS ErrMsg; END CATCH;

-- PROJECT
SET @sql = REPLACE(REPLACE(@bulkTemplate, '{TABLE}', 'dbo.PROJECT'),
                   '{FILE}', @data_path + N'project.csv');
BEGIN TRY EXEC(@sql); PRINT 'PROJECT loaded OK'; END TRY
BEGIN CATCH SELECT 'PROJECT' AS Src, ERROR_NUMBER() AS ErrNum, ERROR_MESSAGE() AS ErrMsg; END CATCH;

-- EQUIPMENT
SET @sql = REPLACE(REPLACE(@bulkTemplate, '{TABLE}', 'dbo.EQUIPMENT'),
                   '{FILE}', @data_path + N'equipmentDATA.csv');
BEGIN TRY EXEC(@sql); PRINT 'EQUIPMENT loaded OK'; END TRY
BEGIN CATCH SELECT 'EQUIPMENT' AS Src, ERROR_NUMBER() AS ErrNum, ERROR_MESSAGE() AS ErrMsg; END CATCH;

-- SERVICE  (your fixed CSV name)
SET @sql = REPLACE(REPLACE(@bulkTemplate, '{TABLE}', 'dbo.[SERVICE]'),
                   '{FILE}', @data_path + N'SERVICEDATA_FINAL.csv');
BEGIN TRY EXEC(@sql); PRINT 'SERVICE loaded OK'; END TRY
BEGIN CATCH SELECT 'SERVICE' AS Src, ERROR_NUMBER() AS ErrNum, ERROR_MESSAGE() AS ErrMsg; END CATCH;

-- SERVICE_EQUIPMENT
SET @sql = REPLACE(REPLACE(@bulkTemplate, '{TABLE}', 'dbo.SERVICE_EQUIPMENT'),
                   '{FILE}', @data_path + N'Service_equipment.csv');
BEGIN TRY EXEC(@sql); PRINT 'SERVICE_EQUIPMENT loaded OK'; END TRY
BEGIN CATCH SELECT 'SERVICE_EQUIPMENT' AS Src, ERROR_NUMBER() AS ErrNum, ERROR_MESSAGE() AS ErrMsg; END CATCH;

-- PS_DETAIL
SET @sql = REPLACE(REPLACE(@bulkTemplate, '{TABLE}', 'dbo.PS_DETAIL'),
                   '{FILE}', @data_path + N'ps_detail_test.csv');
BEGIN TRY EXEC(@sql); PRINT 'PS_DETAIL loaded OK'; END TRY
BEGIN CATCH SELECT 'PS_DETAIL' AS Src, ERROR_NUMBER() AS ErrNum, ERROR_MESSAGE() AS ErrMsg; END CATCH;

-- PE_DETAIL
SET @sql = REPLACE(REPLACE(@bulkTemplate, '{TABLE}', 'dbo.PE_DETAIL'),
                   '{FILE}', @data_path + N'PE_DETAIL.csv');
BEGIN TRY EXEC(@sql); PRINT 'PE_DETAIL loaded OK'; END TRY
BEGIN CATCH SELECT 'PE_DETAIL' AS Src, ERROR_NUMBER() AS ErrNum, ERROR_MESSAGE() AS ErrMsg; END CATCH;

-- Verify counts
SELECT 'CLIENT' AS Tbl, COUNT(*) AS Rows FROM dbo.CLIENT UNION ALL
SELECT 'EMPLOYEE', COUNT(*) FROM dbo.EMPLOYEE UNION ALL
SELECT 'AIRPORT', COUNT(*) FROM dbo.AIRPORT UNION ALL
SELECT 'PROJECT', COUNT(*) FROM dbo.PROJECT UNION ALL
SELECT 'EQUIPMENT', COUNT(*) FROM dbo.EQUIPMENT UNION ALL
SELECT 'SERVICE', COUNT(*) FROM dbo.[SERVICE] UNION ALL
SELECT 'SERVICE_EQUIPMENT', COUNT(*) FROM dbo.SERVICE_EQUIPMENT UNION ALL
SELECT 'PS_DETAIL', COUNT(*) FROM dbo.PS_DETAIL UNION ALL
SELECT 'PE_DETAIL', COUNT(*) FROM dbo.PE_DETAIL;
