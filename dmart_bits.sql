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
--SET Beta = '1'
--where Client_id = '10069'
--WHERE SourceDB IN ('AmericaFirst32')
-------------------------------------------
--UPDATE ClientConnection
--SET Beta = '0'
--WHERE SourceDB IN ('AddisonAve32','Chevron','EDCO','ConstructionLoanCompany','Delta','Dupont','Kern32','MembersMortgage','Suncoast32','Wescom')
--WHERE Client_ID <= 1025 -- Hutchinson, number 30 when sorted by client_id

--UPDATE ClientConnection
--SET Beta = '0'
--WHERE Client_ID IN ( '10024', '1031' )--> 1025
-------------------------------------------
--DECLARE @1DayAgo datetime
--SET @1DayAgo = GetDate() - 2 

--UPDATE ClientConnection
--SET LoadStageDBStartDate = @1DayAgo
--,LoadStageDBEndDate = @1DayAgo
--,LoadReportDBStartDate = @1DayAgo
--,LoadReportDBEndDate = @1DayAgo
--,Status = 4
--WHERE Beta='1'
--WHERE SourceDB = 'MembersMortgage'
----------------------------------------------
/*
TRUNCATE TABLE DMartLogging
*/
SELECT * FROM DMartLogging
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
WHERE client_name LIKE '%America%'
----------------------------------------------
ins_ClientConnection @Client_id = '189', @SourceServer = 'PSQLDLS31', @SourceDB = 'AmericaFirst32'
----------------------------------------------
exec sel_DMART_Failure
--@Client_id				int,
--@SourceServer			varchar(50),
--@SourceDB				varchar(50)
--ins_ClientConnection '10028','STGSQL511','DenverPublicSchools'
----------------------------------------------
/*
DECLARE @NOW datetime 
SET @NOW = GetDate()

UPDATE ClientConnection
SET LoadStageDBStartDate = '2010-08-27 01:30:05.943'
,LoadStageDBEndDate = '2010-08-27 01:30:05.943'
,LoadReportDBStartDate = '2010-08-27 01:30:05.943'
,LoadReportDBEndDate = '2010-08-27 01:30:05.943'
,Status = 4
--where client_id = '141'
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
--WHERE SourceServer = 'STGSQL511'
--WHERE Beta = 2
ORDER BY Beta,3
----------------

----------------------------------------------------------------

----------------
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
--WHERE ReportServer = 'PSQLRPT22'
ORDER BY Beta,3 --DESC
----------------

--DECLARE @1DayAgo datetime
--SET @1DayAgo = GetDate() - 1 

--UPDATE ClientConnection
--SET LoadStageDBStartDate = @1DayAgo
--,LoadStageDBEndDate = @1DayAgo
--,LoadReportDBStartDate = @1DayAgo
--,LoadReportDBEndDate = @1DayAgo
--,Status = 4
--WHERE Beta='1'
----------------------------------------------------------------


--UPDATE ClientConnection
--SET Status = '0' 
--where Client_ID = '1037'
--WHERE Beta = '1' 


--DECLARE @Now datetime
--SET @Now = GetDate() 

--UPDATE ClientConnection
--SET LoadStageDBStartDate = @Now ,LoadStageDBEndDate = @Now ,Status = 2
--WHERE Beta='1'	

--UPDATE ClientConnection
--SET ReportServer = 'PSQLRPT22'
--WHERE ReportServer = 'PSLQRPT22'

---------------------------------------------
--update clientconnection set StageServer = 'PSQLRPT22'
--where SourceDB IN ('AddisonAve32','Chevron','EDCO','ConstructionLoanCompany','Delta','Dupont','Kern32','MembersMortgage','Suncoast32','Wescom')
--WHERE Beta = '0'

--UPDATE ClientConnection
--SET LoadStageDBStartDate = '2010-03-09 01:10:33.200'
--,LoadStageDBEndDate = '2010-03-09 01:15:20.393'
--,LoadReportDBStartDate = '2010-03-09 02:55:12.807'
--,LoadReportDBEndDate = '2010-03-09 02:59:33.627'
--where Beta = '0'



--UPDATE ClientConnection
--SET StageServer = 'PSQLRPT22', ReportServer = 'PSQLRPT22', Beta = '0'
--WHERE SourceDB = 'Redwood'

--UPDATE ClientConnection
--SET SourceServer = 'STGSQL610'
--WHERE SourceDB = 'GeorgiaTelco'


--UPDATE ClientConnection
--SET LoadStageDBStartDate = '2010-03-09 01:10:33.200'
--,LoadStageDBEndDate = '2010-03-09 01:15:20.393'
--,LoadReportDBStartDate = '2010-03-09 02:55:12.807'
--,LoadReportDBEndDate = '2010-03-09 02:59:33.627'
--,Status = '0'
--where Beta = '0'


--UPDATE ClientConnection
--SET Beta = '1'
--SET Client_ID = '228'
--WHERE SourceDB = 'RLC'


--UPDATE ClientConnection
--SET LoadStageDBStartDate = GetDate()
--,LoadStageDBEndDate = GetDate()
--,LoadReportDBStartDate = GetDate()
--,LoadReportDBEndDate = GetDate()
--WHERE Beta = '1'


