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
--WHERE SourceDB = 'MembersMortgage'
ORDER BY Beta, 2


--UPDATE ClientConnection
--SET Beta='1'
--SET Status = '0'
--SET LoadStageDBStartDate = GetDate() - 2
--,LoadStageDBEndDate = GetDate() - 2
--,LoadReportDBStartDate = GetDate() - 2
--,LoadReportDBEndDate = GetDate() - 2
--WHERE SourceDB = 'MembersMortgage'


USE PA_DMart
GO
SELECT  Client_ID, SourceServer, SourceDB, StageServer, StageDB, ReportServer, ReportDB, Status, Beta
FROM ClientConnection
--WHERE ReportServer = 'PSQLRPT22'
ORDER BY Beta,3 --DESC


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
----------------
/*


UPDATE ClientConnection
SET Beta = 2
--WHERE SourceDB IN ('Weyerhaeuser','Patelco32','Numerica','Lockheed32','CUAnswers','Bethpage40','TIB')
WHERE SourceDB IN ('Vandenberg32','SouthCarolina32','McDillAFB')

--DELETE FROM ClientConnection
--WHERE SourceDB IN ('AmericanAirlines','Bellco32','FirstTech','MidwestFinancial','SDCCU32','SecurityServices','Travis40')
--WHERE SourceDB = 'Purdue'

--DELETE FROM ClientConnection
--WHERE Beta = '2'
*/
SELECT * FROM DMartLogging
ORDER BY ErrorDateTime desc

ins_ClientConnection '27', 'STGSQLMET620', 'MetLifeLFC'

--UPDATE ClientConnection
--SET LoadStageDBStartDate = GetDate()
--,LoadStageDBEndDate = GetDate()
--,LoadReportDBStartDate = GetDate()
--,LoadReportDBEndDate = GetDate()
--WHERE Beta = '0'
--------------------------------------------
--UPDATE ClientConnection
--SET LoadStageDBStartDate = GetDate() - 2
--,LoadStageDBEndDate = GetDate() - 2
--,LoadReportDBStartDate = GetDate() - 2
--,LoadReportDBEndDate = GetDate() - 2
--WHERE SourceDB IN ('MissionFed40','Bellco32')
--WHERE Beta = '1'


UPDATE ClientConnection
SET StageServer = 'STGSQLMET620'
	, ReportServer = 'STGSQLMET620'