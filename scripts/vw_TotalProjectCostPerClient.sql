/* queries/vw_TotalProjectCostPerClient.sql */
USE Logplan;
GO

IF OBJECT_ID('dbo.vw_TotalProjectCostPerClient','V') IS NOT NULL
    DROP VIEW dbo.vw_TotalProjectCostPerClient;
GO

CREATE VIEW dbo.vw_TotalProjectCostPerClient AS
SELECT
    C.CLIENT_ID,
    C.FIRST_NAME + ' ' + C.LAST_NAME AS CLIENT_NAME,
    SUM(P.PROJECT_BUDGET) AS TOTAL_BUDGET
FROM dbo.CLIENT C
JOIN dbo.PROJECT P ON P.CLIENT_ID = C.CLIENT_ID
GROUP BY C.CLIENT_ID, C.FIRST_NAME, C.LAST_NAME;
GO

-- quick peek
SELECT TOP 20 * FROM dbo.vw_TotalProjectCostPerClient ORDER BY TOTAL_BUDGET DESC;
