USE PA_DMart
GO
SELECT  --SourceServer,
		Client_ID, SourceDB, [Status], Beta,
		LoadStageDBStartDate, LoadStageDBEndDate,
		DATEDIFF(minute,LoadStageDBStartDate, LoadStageDBEndDate) AS StageLoadTime,
		LoadReportDBStartDate, LoadReportDBEndDate,
		DATEDIFF(minute,LoadReportDBStartDate, LoadReportDBEndDate) AS ReportLoadTime
FROM ClientConnection
--WHERE Beta != '2'
--WHERE Beta = '1'
ORDER BY Beta,2

--UPDATE ClientConnection
--SET Beta = '0'
--where Client_id IN ('1031') -- PADemoDU
--WHERE SourceDB = 'Thrivent'
-------------------------------------------
--UPDATE ClientConnection
--SET Beta = '1'
--WHERE SourceDB IN ('AddisonAve32','Chevron','Boeing4','Ent','GeorgiaTelco','HiwayCU','PADemoDU')
--WHERE Client_ID <= 1025 -- Hutchinson, number 30 when sorted by client_id

--UPDATE ClientConnection
--SET Beta = '0'
--WHERE Client_ID = '9999999' --> 1025
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
*/
----------------------------------------------
/*
TRUNCATE TABLE DMartLogging
*/
SELECT * FROM DMartLogging
--WHERE DATEPART(day,ErrorDateTime) = DATEPART(day,GetDate())
--AND DATEPART(month,ErrorDateTime) = DATEPART(month,GetDate())
ORDER BY ErrorDateTime desc
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
WHERE client_name IN ('thrivent')
----------------------------------------------
ins_ClientConnection @Client_id = '10073'
					, @SourceServer = 'STGSQL610'
					, @SourceDB = 'Thrivent'

dbamaint.dbo.dbm_DMartDRRecovery 'Thrivent'
--client_id	client_name	client_pa
--1013	GeorgiaTelco	1
--10069	CommunityFirstCU	1
--10070	FinancialPrtCU	1
--10071	CitizensFirst	1

--STGSQL511	CommunityFirstCU
--STGSQL610	GeorgiaTelco
--STGSQL511	FinancialPrtCU
--STGSQL610	CitizensFirst



--@Client_id				int,
--@SourceServer			varchar(50),
--@SourceDB				varchar(50)
--ins_ClientConnection '10028','STGSQL511','DenverPublicSchools'
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

--SELECT * FROM ClientConnection
----DELETE FROM ClientConnection
--WHERE SourceDB = 'FirstTech'


--UPDATE ClientConnection
--SET Status = 4, LoadReportDBEndDate = '2010-04-09 05:45:01.887'
--WHERE Client_ID = 198
--SET StageServer = ''

--DELETE FROM ClientConnection
--WHERE Client_ID = '999999'


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

---------------------------------------------
--update clientconnection set StageServer = 'STGSQLDOC710', ReportServer = 'STGSQLDOC710', SourceServer = 'STGSQL511'
--where SourceDB IN ('AddisonAve32','Chevron','EDCO','ConstructionLoanCompany','Delta','Dupont','Kern32','MembersMortgage','Suncoast32','Wescom')
--WHERE Beta = '0'

--UPDATE ClientConnection
--SET LoadStageDBStartDate = '2010-03-09 01:10:33.200'
--,LoadStageDBEndDate = '2010-03-09 01:15:20.393'
--,LoadReportDBStartDate = '2010-03-09 02:55:12.807'
--,LoadReportDBEndDate = '2010-03-09 02:59:33.627'
--where Beta = '0'


--UPDATE ClientConnection
--SET LoadStageDBStartDate = '2010-03-09 01:10:33.200'
--,LoadStageDBEndDate = '2010-03-09 01:15:20.393'
--,LoadReportDBStartDate = '2010-03-09 02:55:12.807'
--,LoadReportDBEndDate = '2010-03-09 02:59:33.627'
--,Status = '0'
--where Beta = '0'


--UPDATE ClientConnection
--SET Beta = '0'
--SET Client_ID = '228'
--WHERE SourceDB = 'Boeing4'

