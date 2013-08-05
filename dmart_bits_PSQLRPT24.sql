USE PA_DMart
GO
SELECT SourceServer, SourceDB
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
GROUP BY Beta
      , Status
      , SSISInstanceID
      , SourceDB
      , LoadStageDBStartDate
      , LoadStageDBEndDate
      , LoadReportDBStartDate
      , LoadReportDBEndDate
      , SourceServer
ORDER BY SourceDB, Status ASC
      , Beta ASC
      , SSISInstanceID ASC
      , LoadStageDBStartDate ASC
      , SourceServer
-------------------------------------------
SELECT  ClientID
      , Status
      , Beta
      , SourceServer
      , SourceDB
      , CDCReportServer
      , CDCReportDB
      , LSNPrevious
      , LSNMax
      , LSNFromPrevious
      , LSNFrom
      , StartTimeExtract
      , EndTimeExtract
      , LoanCurrentStartDate
      , LoanCurrentEndDate
      , LoanMasterStartDate
      , LoanMasterEndDate
      , LoanSecondaryStartDate
      , LoanSecondaryEndDate
FROM ClientConnection_test
ORDER BY Beta, SourceDB

--SELECT *
--FROM dbo.ClientConnection_test
----------------------------------------------
SELECT  *
FROM    DMartLogging
WHERE   DATEPART(day, ErrorDateTime) = DATEPART(day, GETDATE())
        AND DATEPART(month, ErrorDateTime) = DATEPART(month, GETDATE())
        AND DATEPART(year, ErrorDateTime) = DATEPART(year, GETDATE())
ORDER BY ErrorDateTime DESC
----------------------------------------------
/*
UPDATE ClientConnection
SET Beta = '1'
--WHERE SourceDB IN ( 'DMartTemplate' )
WHERE SourceDB IN ('Lockheed32')

--America First
Chevron
ENT
ORNL (CU Community)
Patelco
PADemoDU
PATrain
RLC

UPDATE ClientConnection
SET Status = 2
WHERE Beta = 1

UPDATE ClientConnection
SET Beta = '5', SSISInstanceID = '5'
WHERE SourceDB = 'DMartTemplate'

UPDATE ClientConnection
SET Status = '2'
where SourceDB = 'Bethpage40'
*/
SELECT  CASE WHEN SSISInstanceID IS NULL THEN 'Total' ELSE SSISInstanceID END SSISInstanceID
	, SUM(Status0) AS Status0
	, SUM(Status1) AS Status1
	, SUM(Status2) AS Status2
	, SUM(Status3) AS Status3
	, SUM(Status4) AS Status4
FROM
(
SELECT CONVERT(VARCHAR, SSISInstanceID) AS SSISInstanceID 
	, COUNT ( CASE WHEN Status = 0 THEN Status ELSE NULL END ) AS Status0
	, COUNT ( CASE WHEN Status = 1 THEN Status ELSE NULL END ) AS Status1
	, COUNT ( CASE WHEN Status = 2 THEN Status ELSE NULL END ) AS Status2
	, COUNT ( CASE WHEN Status = 3 THEN Status ELSE NULL END ) AS Status3
	, COUNT ( CASE WHEN Status = 4 THEN Status ELSE NULL END ) AS Status4
FROM dbo.ClientConnectionCDC
GROUP BY SSISInstanceID
) AS StatusMatrix
GROUP BY SSISInstanceID WITH ROLLUP
----------------------------------------------
-- Sum of clients in each status by Beta number
SELECT  CASE WHEN SSISInstanceID IS NULL THEN 'Total' ELSE SSISInstanceID END SSISInstanceID
	, SUM(Status0) AS Status0
	, SUM(Status1) AS Status1
	, SUM(Status2) AS Status2
	, SUM(Status3) AS Status3
	, SUM(Status4) AS Status4
FROM
(
SELECT CONVERT(VARCHAR, SSISInstanceID) AS SSISInstanceID 
	, COUNT ( CASE WHEN Status = 0 THEN Status ELSE NULL END ) AS Status0
	, COUNT ( CASE WHEN Status = 1 THEN Status ELSE NULL END ) AS Status1
	, COUNT ( CASE WHEN Status = 2 THEN Status ELSE NULL END ) AS Status2
	, COUNT ( CASE WHEN Status = 3 THEN Status ELSE NULL END ) AS Status3
	, COUNT ( CASE WHEN Status = 4 THEN Status ELSE NULL END ) AS Status4
FROM dbo.ClientConnection
GROUP BY SSISInstanceID
) AS StatusMatrix
GROUP BY SSISInstanceID WITH ROLLUP
----------------------------------------------
SELECT  CASE WHEN InstanceID IS NULL THEN 'Total' ELSE InstanceID END InstanceID
	, SUM(OldStatus4) AS OldStatus4
	, SUM(Status0) AS Status0
	, SUM(Status1) AS Status1
	, SUM(Status2) AS Status2
	, SUM(Status3) AS Status3
	, SUM(Status4) AS Status4
	, SUM(OldStatus4 + Status0 + Status1 + Status2 + Status3 + Status4) AS InstanceTotal
FROM
(
SELECT CONVERT(VARCHAR, SSISInstanceID) AS InstanceID
	, COUNT ( CASE WHEN Status = 4 AND CONVERT(DATE, EndTimeExtract) < CONVERT(DATE, GETDATE() ) THEN Status ELSE NULL END ) AS OldStatus4
	, COUNT ( CASE WHEN Status = 0 THEN Status ELSE NULL END ) AS Status0
	, COUNT ( CASE WHEN Status = 1 THEN Status ELSE NULL END ) AS Status1
	, COUNT ( CASE WHEN Status = 2 THEN Status ELSE NULL END ) AS Status2
	, COUNT ( CASE WHEN Status = 3 THEN Status ELSE NULL END ) AS Status3
	, COUNT ( CASE WHEN Status = 4 AND DATEPART(DAY, EndTimeExtract) = DATEPART(DAY, GETDATE()) THEN Status ELSE NULL END ) AS Status4
FROM dbo.ClientConnectionCDC
GROUP BY SSISInstanceID
) AS StatusMatrix
GROUP BY GROUPING SETS( ( InstanceID ), () );
----------------------------------------------
SELECT  CASE WHEN InstanceID IS NULL THEN 'Total' ELSE InstanceID END InstanceID
	, SUM(OldStatus4) AS OldStatus4
	, SUM(Status0) AS Status0
	, SUM(Status1) AS Status1
	, SUM(Status2) AS Status2
	, SUM(Status3) AS Status3
	, SUM(Status4) AS Status4
	, SUM(OldStatus4 + Status0 + Status1 + Status2 + Status3 + Status4) AS InstanceTotal
FROM
(
SELECT CONVERT(VARCHAR, SSISInstanceID) AS InstanceID
	, COUNT ( CASE WHEN Status = 4 AND CONVERT(DATE, LoadReportDBEndDate) < CONVERT(DATE, GETDATE() ) THEN Status ELSE NULL END ) AS OldStatus4
	, COUNT ( CASE WHEN Status = 0 THEN Status ELSE NULL END ) AS Status0
	, COUNT ( CASE WHEN Status = 1 THEN Status ELSE NULL END ) AS Status1
	, COUNT ( CASE WHEN Status = 2 THEN Status ELSE NULL END ) AS Status2
	, COUNT ( CASE WHEN Status = 3 THEN Status ELSE NULL END ) AS Status3
	, COUNT ( CASE WHEN Status = 4 AND DATEPART(DAY, LoadReportDBEndDate) = DATEPART(DAY, GETDATE()) THEN Status ELSE NULL END ) AS Status4
FROM dbo.ClientConnection
GROUP BY SSISInstanceID
) AS StatusMatrix
GROUP BY GROUPING SETS( ( InstanceID ), () );
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
PRINT @ReportDate

--EXEC sel_DMart_ComponentLogByClient --@ReportDate
EXEC sel_DMart_DataComponentLogByClient
EXEC sel_DMart_StageComponentLogByClient
--EXEC sel_DMart_ComponentLogByTaskName --@ReportDate
EXEC sel_DMart_DataComponentLogByTaskName '2012-11-14 01:53:37.990'
EXEC sel_DMart_StageComponentLogByTaskName
-------------------------------------------
/*
DECLARE @3AM DATETIME
SET @3AM = ( SELECT CAST(CAST(GETDATE() -1 AS DATE) AS VARCHAR(12))
                    + ' 03:00:00.000'
           )

UPDATE  ClientConnection
SET     LoadStageDBStartDate = @3AM
      , LoadStageDBEndDate = @3AM
      , LoadReportDBStartDate = @3AM
      , LoadReportDBEndDate = @3AM
      , Status = 4
WHERE Beta = '1'
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
EXEC sel_dmart_clients_test @Beta = '0'
exec sel_DMart_Clients3 @Beta = 0, @SSISInstanceID = 1
----------------------------------------------
-- EliLillyFCU STGSQL615 10086
-- PeoplesBank STGSQL613 10090
-- Solarity STGSQL615 10091

--SELECT * FROM OPSINFO.ops.dbo.clients
--WHERE client_name LIKE '%Royal%'

--EXEC ins_ClientConnection_CDC
--	@ClientID = '228'
--	, @CDCSourceServer = 'PSQLDLS32'
--	, @CDCSourceDB = 'OrangeCounty32'

--UPDATE dbo.ClientConnectionCDC
--	SET CDCReportDB = 'Dmart_OrangeCountyCDC_Data'
--WHERE CDCReportDB = 'Dmart_OrangeCounty32CDC_Data'	

--ins_ClientConnection @Client_id = '10088'
--	, @SourceServer = 'PSQLDLS35'
--	, @SourceDB = 'RoyalCU' 	
	--DELETE	FROM dbo.ClientConnection
--WHERE	SourceDB = 'Solarity'					
--dbamaint.dbo.dbm_DMartDRRecovery 'Thrivent'
----------------------------------------------
----------------------------------------------
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
        ----------------------------------------------
USE PA_DMart
GO
SELECT  SUM(DataLoadTime) AS TotalStageLoadTime
      --, SUM(ReportLoadTime) AS TotalReportLoadTime
FROM    ( SELECT    ClientID
                  , [dbo].[ClientConnectionCDC].[CDCExtractDB]
                  , [Status]
                  , Beta
                  , [dbo].[ClientConnectionCDC].[StartTimeExtract]
                  , [dbo].[ClientConnectionCDC].[EndTimeExtract]
                  , DATEDIFF(minute, StartTimeExtract, EndTimeExtract) AS DataLoadTime
                  --, LoadReportDBStartDate
                  --, LoadReportDBEndDate
                  --, DATEDIFF(minute, LoadReportDBStartDate,
                  --           LoadReportDBEndDate) AS ReportLoadTime
          FROM      ClientConnectionCDC
          --WHERE     Beta != '2'
          WHERE Status != 0
        ) AS t
----------------------------------------------
exec sel_dmart_failure
----------------------------------------------
select * from clientconnection
order by ssisinstanceid
/*
UPDATE dbo.ClientConnection
	SET SSISinstanceID = 
		CASE SourceServer 
			WHEN 'PSQLDLS30' THEN 0
			WHEN 'PSQLDLS31' THEN 1
			WHEN 'PSQLDLS32' THEN 2
			WHEN 'PSQLDLS33' THEN 3
			WHEN 'PSQLDLS34' THEN 4
			WHEN 'PSQLDLS35' THEN 5
			WHEN 'PSQLRPT24' THEN 5	-- DMart Template
		END
*/


--SELECT *
--FROM dbo.ClientConnection
--WHERE SourceDB LIKE 'Royal%'

--UPDATE dbo.ClientConnection
--	SET Beta = 0
--WHERE SourceDB = 'RoyalCU'


