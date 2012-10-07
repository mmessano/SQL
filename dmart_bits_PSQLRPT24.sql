USE PA_DMart
GO
SELECT SourceDB
      , [Status]
      , Beta
      , SSISInstanceID AS SSISIID
      , LoadStageDBStartDate
      , LoadStageDBEndDate
      , CONVERT(VARCHAR(12), DATEADD(ms,
                                     DATEDIFF(ms, LoadStageDBStartDate,
                                              LoadStageDBEndDate), 0), 114) AS StageLoadTime
      , LoadReportDBStartDate
      , LoadReportDBEndDate
      , CONVERT(VARCHAR(12), DATEADD(ms,
                                     DATEDIFF(ms, LoadReportDBStartDate,
                                              LoadReportDBEndDate), 0), 114) AS ReportLoadTime
FROM    ClientConnection
GROUP BY Beta, Status, SSISInstanceID, SourceDB, LoadStageDBStartDate, LoadStageDBEndDate, LoadReportDBStartDate, LoadReportDBEndDate
ORDER BY Status ASC
	, SSISInstanceID ASC
	, Beta ASC
	, LoadStageDBStartDate ASC
-------------------------------------------
/*
UPDATE ClientConnection
SET Beta = '0'
WHERE Beta IN ( '0', '1', '2', '3', '4', '5' )
WHERE SourceDB IN ('Dupont', 'MidMinnesota', 'SFFCU', 'Weyerhaeuser', 'WESTconsinCU', 'ABECU32', 'XceedFinancialCU', 'ArizonaStateCU')

UPDATE ClientConnection
SET Beta = '6', SSISInstanceID = '6'
WHERE SourceDB = 'DMartTemplate'
*/
-- Sum of clients in each status by Beta number
SELECT  CASE WHEN Beta IS NULL THEN 'Total' ELSE Beta END Beta
	, SUM(Status0) AS Status0
	, SUM(Status1) AS Status1
	, SUM(Status2) AS Status2
	, SUM(Status3) AS Status3
	, SUM(Status4) AS Status4
FROM
(
SELECT CONVERT(VARCHAR, Beta) AS Beta 
	, COUNT ( CASE WHEN Status = 0 THEN Status ELSE NULL END ) AS Status0
	, COUNT ( CASE WHEN Status = 1 THEN Status ELSE NULL END ) AS Status1
	, COUNT ( CASE WHEN Status = 2 THEN Status ELSE NULL END ) AS Status2
	, COUNT ( CASE WHEN Status = 3 THEN Status ELSE NULL END ) AS Status3
	, COUNT ( CASE WHEN Status = 4 THEN Status ELSE NULL END ) AS Status4
FROM dbo.ClientConnection
GROUP BY Beta
) AS StatusMatrix
GROUP BY Beta WITH ROLLUP
----------------------------------------------
/*
TRUNCATE TABLE DMartLogging
*/
SELECT * FROM DMartLogging
--WHERE TaskName NOT LIKE '%Kill%Active%'
ORDER BY ErrorDateTime desc

SELECT  *
FROM    DMartLogging
WHERE   DATEPART(day, ErrorDateTime) = DATEPART(day, GETDATE())
        AND DATEPART(month, ErrorDateTime) = DATEPART(month, GETDATE())
        AND DATEPART(year, ErrorDateTime) = DATEPART(year, GETDATE())
ORDER BY ErrorDateTime DESC
-------------------------------------------
SELECT  *
FROM    dbo.DMartComponentLogging
WHERE   DATEPART(day, ErrorDateTime) = DATEPART(day, GETDATE())
        AND DATEPART(month, ErrorDateTime) = DATEPART(month, GETDATE())
        AND DATEPART(year, ErrorDateTime) = DATEPART(year, GETDATE())
--AND TaskName = 'Data Flow Task br_liability'
GROUP BY TaskName
      , ErrorDateTime
      , PackageName
      , DestDB
      , DestServer
      , SourceDB
      , SourceServer
      , ID
      , ClientId
      , ErrorMessage
ORDER BY ErrorDateTime DESC
-------------------------------------------
DECLARE @ReportDate DATETIME

SELECT @ReportDate = GETDATE() - 3;

EXEC sel_DMartComponentLogByClient --@ReportDate
EXEC sel_DMartComponentLogByTaskName --@ReportDate
-------------------------------------------
/*
DECLARE @3AM DATETIME
SET @3AM = ( SELECT CAST(CAST(GETDATE() -1 AS DATE) AS VARCHAR(12))
                    + ' 03:00:00.000'
           )
 --GetDate() -- 2 

UPDATE  ClientConnection
SET     LoadStageDBStartDate = @3AM
      , LoadStageDBEndDate = @3AM
      , LoadReportDBStartDate = @3AM
      , LoadReportDBEndDate = @3AM
      , Status = 4
WHERE   SourceDB = 'MissionFed40' Beta = '6'
*/
----------------------------------------------
USE PA_DMart
GO
SELECT  Client_id, SourceServer, SourceDB, Status, Beta, StageServer, StageDB, ReportServer, ReportDB, 
		LoadStageDBStartDate, LoadStageDBEndDate, 
		CONVERT(varchar(12), DATEADD(ms, DATEDIFF(ms, LoadStageDBStartDate, LoadStageDBEndDate), 0), 114) AS StageLoadTime,
		LoadReportDBStartDate, LoadReportDBEndDate,
		CONVERT(varchar(12), DATEADD(ms, DATEDIFF(ms, LoadReportDBStartDate, LoadReportDBEndDate), 0), 114) AS ReportLoadTime
FROM ClientConnection
--WHERE ReportServer = 'PSQLRPT22'
--WHERE SourceServer = 'STGSQL511'
--WHERE Beta = 2
ORDER BY Beta,3
----------------------------------------------

----------------------------------------------
EXEC sel_dmart_clients @Beta = '1'
----------------------------------------------
--SELECT * FROM opsinfo.ops.dbo.clients
--WHERE client_name LIKE '%Merrimack%'
----------------------------------------------
--ins_ClientConnection @Client_id = '120000'
--					, @SourceServer = 'PSQLDLS31'
--					, @SourceDB = 'WrightPatt_SSISTest'
					
--dbamaint.dbo.dbm_DMartDRRecovery 'Thrivent'
----------------------------------------------
exec sel_DMART_Failure
----------------------------------------------

---------------------------------------------

USE PA_DMart
GO
SELECT  SUM(StageLoadTime) AS TotalStageLoadTime
      , SUM(ReportLoadTime) AS TotalReportLoadTime
FROM    ( SELECT    Client_ID
                  , SourceDB
                  , [Status]
                  , Beta
                  , LoadStageDBStartDate
                  , LoadStageDBEndDate
                  , DATEDIFF(minute, LoadStageDBStartDate, LoadStageDBEndDate) AS StageLoadTime
                  , LoadReportDBStartDate
                  , LoadReportDBEndDate
                  , DATEDIFF(minute, LoadReportDBStartDate,
                             LoadReportDBEndDate) AS ReportLoadTime
          FROM      ClientConnection
          WHERE     Beta != '2'
        ) AS t

--UPDATE dbo.ClientConnection
--	SET SSISInstanceID = 0
--	WHERE SourceServer = 'PSQLDLS30'

--UPDATE dbo.ClientConnection
--	SET SSISInstanceID = 1
--	WHERE SourceServer ='PSQLDLS31'

--UPDATE dbo.ClientConnection
--	SET SSISInstanceID = 2
--	WHERE SourceServer = 'PSQLDLS32'

--UPDATE dbo.ClientConnection
--	SET SSISInstanceID = 3
--	WHERE SourceServer = 'PSQLDLS33'

--UPDATE dbo.ClientConnection
--	SET SSISInstanceID = 4
--	WHERE SourceServer = 'PSQLDLS34'

--UPDATE dbo.ClientConnection
--	SET SSISInstanceID = 5
--	WHERE SourceServer = 'PSQLDLS35'


--UPDATE dbo.ClientConnection
--	SET Beta = 0
--	WHERE SourceServer = 'PSQLDLS30'

--UPDATE dbo.ClientConnection
--	SET Beta = 1
--	WHERE SourceServer ='PSQLDLS31'

--UPDATE dbo.ClientConnection
--	SET Beta = 2
--	WHERE SourceServer = 'PSQLDLS32'

--UPDATE dbo.ClientConnection
--	SET Beta = 3
--	WHERE SourceServer = 'PSQLDLS33'

--UPDATE dbo.ClientConnection
--	SET Beta = 4
--	WHERE SourceServer = 'PSQLDLS34'

--UPDATE dbo.ClientConnection
--	SET Beta = 5
--	WHERE SourceServer = 'PSQLDLS35'

--UPDATE dbo.ClientConnection
--	SET SSISinstanceID = 5
--	WHERE SourceDB = 'DMartTemplate'	