USE PA_DMart
GO
SELECT	SourceDB
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
FROM	ClientConnection
GROUP BY Beta
	  , Status
	  , SSISInstanceID
	  , SourceDB
	  , LoadStageDBStartDate
	  , LoadStageDBEndDate
	  , LoadReportDBStartDate
	  , LoadReportDBEndDate
ORDER BY Status ASC
	  , SSISInstanceID ASC
	  , Beta ASC
	  , LoadStageDBStartDate ASC

--UPDATE ClientConnection
--	SET Beta = '0'
--WHERE sourcedb = 'BankofCascades'

USE PA_DMart

SELECT	ClientID
	  , Status
	  , Beta
	  , DMartComponentLogging
	  , CDCExtractServer
	  , CDCExtractDB
	  , CDCReportServer
	  , CDCReportDB
	  , StartTimeExtract
	  , EndTimeExtract
	  , CONVERT(VARCHAR(12), DATEADD(ms,
									 DATEDIFF(ms, StartTimeExtract,
											  EndTimeExtract), 0), 114) AS LoadTime
	  , LoanCurrentEndDate
	  , LoanMasterEndDate
	  , LoanSecondaryEndDate
	  , addl_loan_dataEndDate
	  , borrower_EndDate
	  , br_liability_EndDate
	  , br_income_EndDate
FROM	dbo.ClientConnectionCDC
ORDER BY Beta
	  , CDCExtractDB


UPDATE ClientConnectionCDC
SET Beta = 1
where Clientid IN ('99999', '10024')
--WHERE beta = 1
--WHERE SourceDB IN ('BankofCascades','FirstMidAmericaCU','LangleyFCU','PeoplesBank','RoyalCU','Solarity','UnitedPrairieBank')

--WHERE SSISInstanceID = 2

--UPDATE [dbo].[ClientConnectionCDC]
--	SET [DMartComponentLogging] = 1
--WHERE Beta = 1
--WHERE [dbo].[ClientConnectionCDC].[ClientID] IN ('99999')

--DELETE FROM dbo.ClientConnection
--WHERE Sourcedb = 'RoyalCU'
----------------------------------------------------------------
SELECT	*
FROM	DMartLogging
WHERE	DATEPART(day, ErrorDateTime) = DATEPART(day, GETDATE())
		AND DATEPART(month, ErrorDateTime) = DATEPART(month, GETDATE())
		AND DATEPART(year, ErrorDateTime) = DATEPART(year, GETDATE())
		AND ErrorDateTime > '2013-07-08 15:28:55.580'
ORDER BY ErrorDateTime DESC
----------------------------------------------------------------
/*
DECLARE @3AM datetime
SET @3AM = (SELECT CAST(CAST(GETDATE()-1 AS DATE) AS VARCHAR(12)) + ' 03:00:00.000') --GetDate() -- 2 

UPDATE ClientConnection
SET LoadStageDBStartDate = @3AM
,LoadStageDBEndDate = @3AM
,LoadReportDBStartDate = @3AM
,LoadReportDBEndDate = @3AM
,Status = 4
WHERE Beta = '1'
----------------------------------------------------------------
DECLARE @1900 datetime
SET @1900 = '1902-01-01'

UPDATE ClientConnection_test
	SET StartTimeExtract = @1900
		,  EndTimeExtract = @1900
		, LoanCurrentStartDate = @1900
		, LoanCurrentEndDate = @1900
		, LoanMasterStartDate = @1900
		, LoanMasterEndDate = @1900
		, LoanSecondaryStartDate = @1900
		, LoanSecondaryEndDate = @1900
		, Status = 4
WHERE Beta = '1'
*/
----------------------------------------------------------------
;
WITH	dmartTimes
		  AS ( SELECT	SourceDB
					  , PackageName
					  , TaskName
					  , MIN(ErrorDateTime) AS [StartTime]
					  , MAX(ErrorDateTime) AS [EndTime]
			   FROM		dbo.DMartComponentLogging
						JOIN dbo.ClientConnectionCDC cc ON dbo.DMartComponentLogging.ClientId = cc.ClientID
														   AND dbo.DMartComponentLogging.ErrorDateTime BETWEEN cc.StartTimeExtract
															  AND
															  cc.EndTimeExtract
			   GROUP BY	SourceDB
					  , PackageName
					  , TaskName
			 )
	SELECT	SourceDB
		  , PackageName
		  , TaskName
		  , CONVERT(VARCHAR(12), DATEADD(ms,
										 DATEDIFF(Millisecond, StartTime,
												  EndTime), 0), 114) AS [TimeTaken]
	FROM	dmartTimes
	GROUP BY PackageName
		  , TaskName
		  , SourceDB
		  , StartTime
		  , EndTime
	ORDER BY [TimeTaken] DESC
----------------------------------------------------------------
-- Sum of clients in each status by Beta number
SELECT	CASE WHEN SSISInstanceID IS NULL THEN 'Total'
			 ELSE SSISInstanceID
		END SSISInstanceID
	  , SUM(OldStatus4) AS OldStatus4
	  , SUM(Status0) AS Status0
	  , SUM(Status1) AS Status1
	  , SUM(Status2) AS Status2
	  , SUM(Status3) AS Status3
	  , SUM(Status4) AS Status4
	  , SUM(OldStatus4 + Status0 + Status1 + Status2 + Status3 + Status4) AS InstanceTotal
FROM	( SELECT	CONVERT(VARCHAR, SSISInstanceID) AS SSISInstanceID
				  , COUNT(CASE WHEN Status = 4
									AND CONVERT(DATE, LoadReportDBEndDate) < CONVERT(DATE, GETDATE())
							   THEN Status
							   ELSE NULL
						  END) AS OldStatus4
				  , COUNT(CASE WHEN Status = 0 THEN Status
							   ELSE NULL
						  END) AS Status0
				  , COUNT(CASE WHEN Status = 1 THEN Status
							   ELSE NULL
						  END) AS Status1
				  , COUNT(CASE WHEN Status = 2 THEN Status
							   ELSE NULL
						  END) AS Status2
				  , COUNT(CASE WHEN Status = 3 THEN Status
							   ELSE NULL
						  END) AS Status3
	--, COUNT ( CASE WHEN Status = 4 THEN Status ELSE NULL END ) AS Status4
				  , COUNT(CASE WHEN Status = 4
									AND DATEPART(DAY, LoadReportDBEndDate) = DATEPART(DAY,
															  GETDATE())
							   THEN Status
							   ELSE NULL
						  END) AS Status4
		  FROM		dbo.ClientConnection
		  GROUP BY	SSISInstanceID
		) AS StatusMatrix
GROUP BY SSISInstanceID
		WITH ROLLUP
-------------------------------------------------------------------
SELECT	CASE WHEN SSISInstanceID IS NULL THEN 'Total'
			 ELSE SSISInstanceID
		END SSISInstanceID
	  , SUM(OldStatus4) AS OldStatus4
	  , SUM(Status0) AS Status0
	  , SUM(Status1) AS Status1
	  , SUM(Status2) AS Status2
	  , SUM(Status3) AS Status3
	  , SUM(Status4) AS Status4
	  , SUM(OldStatus4 + Status0 + Status1 + Status2 + Status3 + Status4) AS InstanceTotal
FROM	( SELECT	CONVERT(VARCHAR, SSISInstanceID) AS SSISInstanceID
				  , COUNT(CASE WHEN Status = 4
									AND CONVERT(DATE, EndTimeExtract) < CONVERT(DATE, GETDATE())
							   THEN Status
							   ELSE NULL
						  END) AS OldStatus4
				  , COUNT(CASE WHEN Status = 0 THEN Status
							   ELSE NULL
						  END) AS Status0
				  , COUNT(CASE WHEN Status = 1 THEN Status
							   ELSE NULL
						  END) AS Status1
				  , COUNT(CASE WHEN Status = 2 THEN Status
							   ELSE NULL
						  END) AS Status2
				  , COUNT(CASE WHEN Status = 3 THEN Status
							   ELSE NULL
						  END) AS Status3
				  , COUNT(CASE WHEN Status = 4
									AND DATEPART(DAY, EndTimeExtract) = DATEPART(DAY,
															  GETDATE())
							   THEN Status
							   ELSE NULL
						  END) AS Status4
		  FROM		dbo.ClientConnectionCDC
		  GROUP BY	SSISInstanceID
		) AS StatusMatrix
GROUP BY GROUPING SETS(( SSISInstanceID ), ( ));
/*
TRUNCATE TABLE DMartLogging
*/
-------------------------------------------------------------------
SELECT	*
FROM	DMartLogging
WHERE	DATEPART(day, ErrorDateTime) = DATEPART(day, GETDATE())
		AND DATEPART(month, ErrorDateTime) = DATEPART(month, GETDATE())
		AND DATEPART(year, ErrorDateTime) = DATEPART(year, GETDATE())
ORDER BY ErrorDateTime DESC
-------------------------------------------------------------------
--SELECT * FROM dbo.DMartComponentLogging
--ORDER BY ErrorDateTime ASC
-------------------------------------------------------------------
SELECT	*
FROM	dbo.DMartComponentLogging
WHERE	DATEPART(day, ErrorDateTime) = DATEPART(day, GETDATE())
		AND DATEPART(month, ErrorDateTime) = DATEPART(month, GETDATE())
		AND DATEPART(year, ErrorDateTime) = DATEPART(year, GETDATE())
	--AND TaskName = 'Data Flow Task br_liability'
--GROUP BY TaskName, ErrorDateTime, PackageName, DestDB, DestServer, SourceDB, SourceServer, ID, ClientId, ErrorMessage
ORDER BY ErrorDateTime DESC
----------------------------------------------------------------
--DECLARE @ReportDate DATETIME
--SELECT @ReportDate = GETDATE() - 3;
--PRINT @ReportDate

--EXEC sel_DMart_ComponentLogByClient --@ReportDate
--EXEC sel_DMart_DataComponentLogByClient
--EXEC sel_DMart_StageComponentLogByClient
--EXEC sel_DMart_ComponentLogByTaskName --@ReportDate
--EXEC sel_DMart_DataComponentLogByTaskName '2012-11-14 01:53:37.990'
--EXEC sel_DMart_StageComponentLogByTaskName
-------------------------------------------------------------------
EXEC sel_dmart_clients_CDC @Beta = '1'
-------------------------------------------------------------------
SELECT	*
FROM	OPSINFO.ops.dbo.Clients
WHERE	client_name LIKE '%BankofCascades%'

--UPDATE dbo.ClientConnection
--	SET SSISInstanceID = '2'
--WHERE Client_id = '10089'

--ins_ClientConnection '10095'
--						,'PSQLDLS30'
--						,'BankofCascades'
						
--ins_ClientConnection @Client_id = '10024'
--					, @SourceServer = 'STGSQL615'
--					, @SourceDB = 'RLC'
-------------------------------------------------------------------
USE PA_DMart
GO
SELECT	Client_id
	  , SourceServer
	  , SourceDB
	  , Status
	  , Beta
	  , StageServer
	  , StageDB
	  , ReportServer
	  , ReportDB
	  , LoadStageDBStartDate
	  , LoadStageDBEndDate
	  , DATEDIFF(minute, LoadStageDBStartDate, LoadStageDBEndDate) AS StageLoadTime
	  , LoadReportDBStartDate
	  , LoadReportDBEndDate
	  , DATEDIFF(minute, LoadReportDBStartDate, LoadReportDBEndDate) AS ReportLoadTime
FROM	ClientConnection
--WHERE ReportServer = 'PSQLRPT22'
ORDER BY Beta
	  , 3
-------------------------------------------------------------------
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
-------------------------------------------------------------------------------------
--UPDATE ClientConnection
--	SET SSISInstanceID = 0 
--	WHERE SourceDB IN ('ArizonaStateCU', 'ArkansasFCU', 'Boeing4')

--UPDATE ClientConnection
--	SET SSISInstanceID = 1 
--	WHERE SourceDB IN ('DMartTemplate', 'FinancialPrtCU', 'HiwayCU')
	
--UPDATE ClientConnection
--	SET SSISInstanceID = 2 
--	WHERE SourceDB IN ('CornellFingerlake', Merrimack', 'Metro1stMortgage', 'ORNL')

--UPDATE ClientConnection
--	SET SSISInstanceID = 3 
--	WHERE SourceDB IN ('PeoplesBank')
	
--UPDATE ClientConnection
--	SET SSISInstanceID = 4 
--	WHERE SourceDB IN ('UnitedPrairieBank', 'WESTconsinCU', 'XceedFinancialCU')	

--UPDATE ClientConnection
--	SET SSISInstanceID = 5 
--	WHERE SourceDB IN ('EliLillyFCU', 'Solarity')

--UPDATE dbo.ClientConnection
--	SET StageDB = 'DMart_Landmark_Stage'
--	, ReportDB = 'DMart_Landmark_Data'
--WHERE SourceDB = 'Landmark'


--INSERT INTO ClientConnection_test
--	(ClientID, SourceServer, SourceDB, StageServer, StageDB, CDCReportServer, CDCReportDB, LSNPrevious, LSNMax, LSNFromPrevious, LSNFrom, StartTimeExtract, EndTimeExtract, StartTimeTransform, EndTimeTransform, TransformEnabled, Status, Beta)
--VALUES
--	(10024, 'STGSQL615', 'RLC', 'STGSQLDOC710', 'DMart_RLC_Stage', 'STGSQLDOC710', 'DMart_CDCTest_Data', '', '', '', '', '', '', '', '', '', 4, 1)


