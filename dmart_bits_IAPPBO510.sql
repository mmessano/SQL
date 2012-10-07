USE PA_DMart
GO
SELECT  --SourceServer,
		Client_ID, SourceDB, [Status], Beta,
		LoadStageDBStartDate, LoadStageDBEndDate,
		CONVERT(varchar(12), DATEADD(ms, DATEDIFF(ms, LoadStageDBStartDate, LoadStageDBEndDate), 0), 114) AS StageLoadTime,
		LoadReportDBStartDate, LoadReportDBEndDate,
		CONVERT(varchar(12), DATEADD(ms, DATEDIFF(ms, LoadReportDBStartDate, LoadReportDBEndDate), 0), 114) AS ReportLoadTime
FROM ClientConnection
--WHERE Beta != '2'
--WHERE Beta = '1'
ORDER BY Beta,2


--UPDATE ClientConnection
--SET Beta = '1'
--where Client_id = '141'
--WHERE SourceDB = 'RLC'
-------------------------------------------
/*
DECLARE @1DayAgo datetime
SET @1DayAgo = GetDate() - 2 

UPDATE ClientConnection
SET LoadStageDBStartDate = @1DayAgo
,LoadStageDBEndDate = @1DayAgo
,LoadReportDBStartDate = @1DayAgo
,LoadReportDBEndDate = @1DayAgo
,Status = 4
WHERE Beta='1'
WHERE SourceDB = 'MembersMortgage'
*/
----------------------------------------------
/*
TRUNCATE TABLE DMartLogging
*/
SELECT * FROM DMartLogging
ORDER BY ErrorDateTime desc
----------------------------------------------
SELECT * FROM DMartLogging
WHERE DATEPART(day,ErrorDateTime) = DATEPART(day,GetDate())
AND DATEPART(month,ErrorDateTime) = DATEPART(month,GetDate())
AND DATEPART(year,ErrorDateTime) = DATEPART(year,GetDate())
ORDER BY ErrorDateTime DESC
----------------------------------------------
SELECT * FROM dbo.DMartComponentLogging
WHERE DATEPART(day,ErrorDateTime) = DATEPART(day,GetDate())
AND DATEPART(month,ErrorDateTime) = DATEPART(month,GetDate())
AND DATEPART(year,ErrorDateTime) = DATEPART(year,GetDate())
AND TaskName = 'Data Flow Task br_liability'
GROUP BY TaskName, ErrorDateTime, PackageName, DestDB, DestServer, SourceDB, SourceServer, ID, ClientId, ErrorMessage
ORDER BY ErrorDateTime ASC
----------------------------------------------
SELECT name from sys.databases
WHERE Name LIKE '%Stage%'
----------------------------------------------
SELECT name from sys.databases
WHERE Name LIKE '%Data%'
----------------------------------------------
EXEC sel_dmart_clients @Beta = '1'
----------------------------------------------
SELECT * FROM opsinfo.ops.dbo.clients
WHERE client_name = 'DenverPublicSchools'

--@Client_id				int,
--@SourceServer			varchar(50),
--@SourceDB				varchar(50)
--ins_ClientConnection '10028','STGSQL511','DenverPublicSchools'
----------------------------------------------
/*
DECLARE @NOW datetime 
SET @NOW = GetDate()

UPDATE ClientConnection
SET LoadStageDBStartDate = '2010-03-09 01:10:33.200'
,LoadStageDBEndDate = '2010-03-09 01:15:20.393'
,LoadReportDBStartDate = '2010-03-09 02:55:12.807'
,LoadReportDBEndDate = '2010-03-09 02:59:33.627'
,Status = 4
--where client_id = '266'
WHERE Beta='1'
*/

--SELECT * FROM ClientConnection
----DELETE FROM ClientConnection
--WHERE SourceDB = 'FirstTech'


--UPDATE ClientConnection
--SET Status = 4, LoadReportDBEndDate = '2010-04-09 05:45:01.887'
--WHERE Client_ID = 198
--SET StageServer = ''

--DELETE FROM ClientConnection
--WHERE Client_ID = '10028'


----------------------------------------------------------------
USE PA_DMart
GO
SELECT  *
FROM ClientConnection
WHERE Beta != '2'
ORDER BY 3 --DESC

----------------------------------------------------------------
----------------
USE PA_DMart
GO
SELECT  *
FROM ClientConnection
--WHERE ReportServer = 'PSQLRPT22'
ORDER BY Beta,3
----------------
USE PA_DMart
GO
SELECT  Client_id, SourceServer, SourceDB, Status, Beta, StageServer, StageDB, ReportServer, ReportDB, 
		LoadStageDBStartDate, LoadStageDBEndDate, 
		DATEDIFF(minute,LoadStageDBStartDate, LoadStageDBEndDate) AS StageLoadTime,
		LoadReportDBStartDate, LoadReportDBEndDate,
		DATEDIFF(minute,LoadReportDBStartDate, LoadReportDBEndDate) AS ReportLoadTime
FROM ClientConnection
ORDER BY Beta,3
----------------
/*
DECLARE @1DayAgo datetime
SET @1DayAgo = GetDate() - 1 

UPDATE ClientConnection
SET LoadStageDBStartDate = @1DayAgo
,LoadStageDBEndDate = @1DayAgo
,LoadReportDBStartDate = @1DayAgo
,LoadReportDBEndDate = @1DayAgo
,Status = 4
WHERE Beta='1'
*/
----------------------------------------------------------------
--DECLARE @Now datetime
--SET @Now = GetDate() 

--UPDATE ClientConnection
--SET LoadStageDBStartDate = @Now ,LoadStageDBEndDate = @Now ,Status = 2
--WHERE Beta='1'	

--UPDATE ClientConnection
--SET ReportServer = 'PSQLRPT22'
--WHERE ReportServer = 'PSLQRPT22'
---------------------------------------------
--UPDATE ClientConnection
--SET LoadStageDBStartDate = '2010-03-09 01:10:33.200'
--,LoadStageDBEndDate = '2010-03-09 01:15:20.393'
--,LoadReportDBStartDate = '2010-03-09 02:55:12.807'
--,LoadReportDBEndDate = '2010-03-09 02:59:33.627'
--where Beta = '0'

--UPDATE ClientConnection
--SET StageServer = 'PSQLRPT22', ReportServer = 'PSQLRPT22', Beta = '0'
--WHERE SourceDB = 'Boeing4'

--UPDATE ClientConnection
--SET LoadStageDBStartDate = '2010-03-09 01:10:33.200'
--,LoadStageDBEndDate = '2010-03-09 01:15:20.393'
--,LoadReportDBStartDate = '2010-03-09 02:55:12.807'
--,LoadReportDBEndDate = '2010-03-09 02:59:33.627'
--,Status = '0'
--where Beta = '0'



SELECT * FROM DMartLogging
WHERE TaskName = 'Data Flow Task br_REO'
ORDER BY ErrorDateTime desc