USE PA_DMart
GO
SELECT  
		Client_ID, SourceDB, [Status], Beta,
		LoadStageDBStartDate, LoadStageDBEndDate,
		CONVERT(varchar(12), DATEADD(ms, DATEDIFF(ms, LoadStageDBStartDate, LoadStageDBEndDate), 0), 114) AS StageLoadTime,
		LoadReportDBStartDate, LoadReportDBEndDate,
		CONVERT(varchar(12), DATEADD(ms, DATEDIFF(ms, LoadReportDBStartDate, LoadReportDBEndDate), 0), 114) AS ReportLoadTime
FROM ClientConnection
--WHERE Beta != '2'
--WHERE Beta = '1'
ORDER BY Beta,2

UPDATE ClientConnection
SET Beta = '2'
where Client_id IN ('10070', '136', '10055', '10079', '195')
WHERE SourceDB IN ('PADemoDU')
-- Dupont, PATrain, PADemoDU, RLC
-------------------------------------------
-------------------------------------------
/*
DECLARE @3AM datetime
SET @3AM = (SELECT CAST(CAST(GETDATE() AS DATE) AS VARCHAR(12)) + ' 03:00:00.000') --GetDate() -- 2 

UPDATE ClientConnection
SET LoadStageDBStartDate = @3AM
,LoadStageDBEndDate = @3AM
,LoadReportDBStartDate = @3AM
,LoadReportDBEndDate = @3AM
,Status = 4
where Client_ID = 1031
WHERE Beta='1'
*/
----------------------------------------------
/*
TRUNCATE TABLE DMartLogging
*/
----------------------------------------------
SELECT * FROM DMartLogging
--WHERE DATEPART(day,ErrorDateTime) = DATEPART(day,GetDate())
--AND DATEPART(month,ErrorDateTime) = DATEPART(month,GetDate())
--AND DATEPART(year,ErrorDateTime) = DATEPART(year,GetDate())
ORDER BY ErrorDateTime DESC
----------------------------------------------
SELECT * FROM DMartLogging
WHERE DATEPART(day,ErrorDateTime) = DATEPART(day,GetDate())
AND DATEPART(month,ErrorDateTime) = DATEPART(month,GetDate())
AND DATEPART(year,ErrorDateTime) = DATEPART(year,GetDate())
ORDER BY ErrorDateTime desc
----------------------------------------------
SELECT * FROM dbo.DMartComponentLogging
WHERE DATEPART(day,ErrorDateTime) = DATEPART(day,GetDate())
AND DATEPART(month,ErrorDateTime) = DATEPART(month,GetDate())
AND DATEPART(year,ErrorDateTime) = DATEPART(year,GetDate())
--AND TaskName = 'Data Flow Task br_liability'
GROUP BY TaskName, ErrorDateTime, PackageName, DestDB, DestServer, SourceDB, SourceServer, ID, ClientId, ErrorMessage
ORDER BY ErrorDateTime DESC
----------------------------------------------
DECLARE @ReportDate DATETIME

SELECT @ReportDate = GETDATE() - 3;

EXEC sel_DMartComponentLogByClient --@ReportDate
EXEC sel_DMartComponentLogByTaskName --@ReportDate
----------------------------------------------
--SELECT name from sys.databases
--WHERE Name LIKE '%Stage%'
----------------------------------------------
--SELECT name from sys.databases
--WHERE Name LIKE '%Data%'
----------------------------------------------
--EXEC sel_dmart_clients @Beta = '1'
----------------------------------------------
SELECT * FROM opsinfo.ops.dbo.clients
WHERE client_name LIKE ('%XCeed%')
----------------------------------------------
ins_ClientConnection @Client_id = '10081'
					, @SourceServer = 'STGSQL615'
					, @SourceDB = 'XceedFinancialCU'
----------------------------------------------
/*
UPDATE ClientConnection
SET LoadStageDBStartDate = '2010-03-09 01:10:33.200'
,LoadStageDBEndDate = '2010-03-09 01:15:20.393'
,LoadReportDBStartDate = '2010-03-09 02:55:12.807'
,LoadReportDBEndDate = '2010-03-09 02:59:33.627'
,Status = 4
WHERE Beta='1'
*/
----------------------------------------------------------------
USE PA_DMart
GO
SELECT  Client_id, SourceServer, SourceDB, Status, Beta, StageServer, StageDB, ReportServer, ReportDB, 
		LoadStageDBStartDate, LoadStageDBEndDate, 
		DATEDIFF(minute,LoadStageDBStartDate, LoadStageDBEndDate) AS StageLoadTime,
		LoadReportDBStartDate, LoadReportDBEndDate,
		DATEDIFF(minute,LoadReportDBStartDate, LoadReportDBEndDate) AS ReportLoadTime
FROM ClientConnection
--WHERE ReportServer = 'PSQLRPT22'
ORDER BY Beta,3
----------------------------------------------------------------
/*
DECLARE @1DayAgo datetime
SET @1DayAgo = GetDate() - 1 

UPDATE ClientConnection
SET LoadStageDBStartDate = @1DayAgo
,LoadStageDBEndDate = @1DayAgo
,LoadReportDBStartDate = @1DayAgo
,LoadReportDBEndDate = @1DayAgo
,Status = 4
WHERE Beta='0'
*/
USE PA_DMart
GO
SELECT  *
FROM ClientConnection
--WHERE ReportServer = 'PSQLRPT22'
ORDER BY Beta,3 --DESC
----------------
USE PA_DMart
GO
SELECT  Client_ID, SourceServer, SourceDB, StageServer, StageDB, ReportServer, ReportDB, Status, Beta
FROM ClientConnection
ORDER BY Beta,3 --DESC
----------------

--DECLARE @1DayAgo datetime
--SET @1DayAgo = GetDate() - 1 

--UPDATE ClientConnection
--SET LoadStageDBStartDate = @1DayAgo
--,LoadStageDBEndDate = @1DayAgo
--,LoadReportDBStartDate = @1DayAgo
--,LoadReportDBEndDate = @1DayAgo
--,Status = '0'
--WHERE Beta='0'
----------------------------------------------------------------


DELETE FROM ClientConnection
WHERE SourceDB IN ('AddisonAve32'
					, 'Chevron'
					, 'Ent'
					, 'CommunityFirstCU'
					, 'CUWest'
					, 'GeorgiaTelco'
					, 'CitizensFirst'
					, 'LGECCU'
					)

