/* functions/fn_ServicesByProject.sql */
USE Logplan;
GO

IF OBJECT_ID('dbo.fn_ServicesByProject','IF') IS NOT NULL
    DROP FUNCTION dbo.fn_ServicesByProject;
GO

CREATE FUNCTION dbo.fn_ServicesByProject (@ProjectID INT)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        S.SERVICE_ID,
        S.SERVICE_NAME,
        S.SERVICE_LEVEL,
        S.SERVICE_COST,
        S.EQUIPMENT_REQUIRED
    FROM dbo.[SERVICE] AS S
    INNER JOIN dbo.PS_DETAIL AS PS
        ON PS.SERVICE_ID = S.SERVICE_ID
    WHERE PS.PROJECT_ID = @ProjectID
);
GO

-- sample usage
 SELECT * FROM dbo.fn_ServicesByProject(50002);
