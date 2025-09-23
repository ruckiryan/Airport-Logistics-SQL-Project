/* procedures/sp_AddNewProject.sql */
USE Logplan;
GO

IF OBJECT_ID('dbo.sp_AddNewProject','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_AddNewProject;
GO

CREATE PROCEDURE dbo.sp_AddNewProject
    @ProjectID   INT,
    @ClientID    INT,
    @AirportID   INT,
    @Budget      FLOAT,
    @Status      NVARCHAR(20),
    @Description NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.PROJECT
        (PROJECT_ID, CLIENT_ID, AIRPORT_ID, PROJECT_BUDGET, PROJECT_STATUS, PROJECT_DESCRIPTION)
    VALUES
        (@ProjectID, @ClientID, @AirportID, @Budget, @Status, @Description);
END
GO

-- example:
EXEC dbo.sp_AddNewProject
     @ProjectID = 60002,
    @ClientID = 2,
    @AirportID = 10001,
    @Budget = 890000,
	@Status = N'Planned',
    @Description = N'Runway extension';

-- Check if SP worked

SELECT * 
FROM PROJECT