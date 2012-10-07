-- xsqlutil19.Performance
SELECT CreateIndexStatement
	, TableName
	, '' AS TotalAdds
	, ABECU32, AddisonAve32, AEA, AltaOne, AmericaFirst32, AmericanAirlines, ArizonaStateCU, Baxter, Bayfederal, Bellco32, BethPage40, Boeing4, Chetco, Chevron, CitizensFirst, CityCounty32, Clarity, Columbia32, CommunityFirstCU, ConsumersCU, CornellFingerLake, CUAnswers, CUMA, CUWest, Delta, DenverPublicSchools, DexmaSites, Dupont, EdcheckupProd, EDCO, ENT, FileCount, FinancialPrtCU, FinancialPrtCU_NdxTest, FirstAtlantic, FirstTech, GEAUCentralP3, GeorgiaTelco, GeReporting, GTE32, HiwayCU, HomeownersMtg, Hutchinson, IBMSouthEast, IISLogs, Kern32, Kinecta, Lockheed32, McDillAFB, MembersMortgage, Merchants, Meriwest32, merrimack, MetLife, MidMinnesota, MidwestLoan32, MissionFed40, NASA, Numerica, NuVision, OPS, OrangeCounty32, ORNL, OTCCU, PADemoDU, Patelco32, PATrain, PeoplesTrust, PremierAmerica, Purdue, Redwood, Rivermark, RLC, SDCCU32, SecurityServices, SFEFCU, SFFCU, SouthCarolina32, StarOne, Status, Suncoast32, Thrivent, TIB, Tower32, Travis40, UsBank, Vandenberg32, Verity, Visions, Vystar, Weichert, Weokie, Wescom, Weyerhaeuser, WrightPatt32
	FROM (
		SELECT DISTINCT CreateIndexStatement
			, DBName
			, TableName
		FROM SQLIndicesMissing 
		WHERE DBName IN ('ABECU32', 'AddisonAve32', 'AEA', 'AltaOne', 'AmericaFirst32', 'AmericanAirlines', 'ArizonaStateCU', 'Baxter', 'Bayfederal', 'Bellco32', 'BethPage40', 'Boeing4', 'Chetco', 'Chevron', 'CitizensFirst', 'CityCounty32', 'Clarity', 'Columbia32', 'CommunityFirstCU', 'ConsumersCU', 'CornellFingerLake', 'CUAnswers', 'CUMA', 'CUWest', 'Delta', 'DenverPublicSchools', 'DexmaSites', 'Dupont', 'EdcheckupProd', 'EDCO', 'ENT', 'FileCount', 'FinancialPrtCU', 'FinancialPrtCU_NdxTest', 'FirstAtlantic', 'FirstTech', 'GEAUCentralP3', 'GeorgiaTelco', 'GeReporting', 'GTE32', 'HiwayCU', 'HomeownersMtg', 'Hutchinson', 'IBMSouthEast', 'IISLogs', 'Kern32', 'Kinecta', 'Lockheed32', 'McDillAFB', 'MembersMortgage', 'Merchants', 'Meriwest32', 'merrimack', 'MetLife', 'MidMinnesota', 'MidwestLoan32', 'MissionFed40', 'NASA', 'Numerica', 'NuVision', 'OPS', 'OrangeCounty32', 'ORNL', 'OTCCU', 'PADemoDU', 'Patelco32', 'PATrain', 'PeoplesTrust', 'PremierAmerica', 'Purdue', 'Redwood', 'Rivermark', 'RLC', 'SDCCU32', 'SecurityServices', 'SFEFCU', 'SFFCU', 'SouthCarolina32', 'StarOne', 'Status', 'Suncoast32', 'Thrivent', 'TIB', 'Tower32', 'Travis40', 'UsBank', 'Vandenberg32', 'Verity', 'Visions', 'Vystar', 'Weichert', 'Weokie', 'Wescom', 'Weyerhaeuser', 'WrightPatt32')) AS SourceTable
	PIVOT
	(COUNT(DBName)
	FOR DBName IN 
	(ABECU32, AddisonAve32, AEA, AltaOne, AmericaFirst32, AmericanAirlines, ArizonaStateCU, Baxter, Bayfederal, Bellco32, BethPage40, Boeing4, Chetco, Chevron, CitizensFirst, CityCounty32, Clarity, Columbia32, CommunityFirstCU, ConsumersCU, CornellFingerLake, CUAnswers, CUMA, CUWest, Delta, DenverPublicSchools, DexmaSites, Dupont, EdcheckupProd, EDCO, ENT, FileCount, FinancialPrtCU, FinancialPrtCU_NdxTest, FirstAtlantic, FirstTech, GEAUCentralP3, GeorgiaTelco, GeReporting, GTE32, HiwayCU, HomeownersMtg, Hutchinson, IBMSouthEast, IISLogs, Kern32, Kinecta, Lockheed32, McDillAFB, MembersMortgage, Merchants, Meriwest32, merrimack, MetLife, MidMinnesota, MidwestLoan32, MissionFed40, NASA, Numerica, NuVision, OPS, OrangeCounty32, ORNL, OTCCU, PADemoDU, Patelco32, PATrain, PeoplesTrust, PremierAmerica, Purdue, Redwood, Rivermark, RLC, SDCCU32, SecurityServices, SFEFCU, SFFCU, SouthCarolina32, StarOne, Status, Suncoast32, Thrivent, TIB, Tower32, Travis40, UsBank, Vandenberg32, Verity, Visions, Vystar, Weichert, Weokie, Wescom, Weyerhaeuser, WrightPatt32)) AS PivotTable
	GROUP BY CreateIndexStatement, TableName, ABECU32, AddisonAve32, AEA, AltaOne, AmericaFirst32, AmericanAirlines, ArizonaStateCU, Baxter, Bayfederal, Bellco32, BethPage40, Boeing4, Chetco, Chevron, CitizensFirst, CityCounty32, Clarity, Columbia32, CommunityFirstCU, ConsumersCU, CornellFingerLake, CUAnswers, CUMA, CUWest, Delta, DenverPublicSchools, DexmaSites, Dupont, EdcheckupProd, EDCO, ENT, FileCount, FinancialPrtCU, FinancialPrtCU_NdxTest, FirstAtlantic, FirstTech, GEAUCentralP3, GeorgiaTelco, GeReporting, GTE32, HiwayCU, HomeownersMtg, Hutchinson, IBMSouthEast, IISLogs, Kern32, Kinecta, Lockheed32, McDillAFB, MembersMortgage, Merchants, Meriwest32, merrimack, MetLife, MidMinnesota, MidwestLoan32, MissionFed40, NASA, Numerica, NuVision, OPS, OrangeCounty32, ORNL, OTCCU, PADemoDU, Patelco32, PATrain, PeoplesTrust, PremierAmerica, Purdue, Redwood, Rivermark, RLC, SDCCU32, SecurityServices, SFEFCU, SFFCU, SouthCarolina32, StarOne, Status, Suncoast32, Thrivent, TIB, Tower32, Travis40, UsBank, Vandenberg32, Verity, Visions, Vystar, Weichert, Weokie, Wescom, Weyerhaeuser, WrightPatt32
------------------------------------------------------------------------------------------------------------------------
-- XSQLUTIL18.Status
-- PIVOT on GroupNames
DECLARE @GroupNames NVARCHAR(MAX)
DECLARE @SQL NVARCHAR(MAX)

SELECT @GroupNames = COALESCE(@GroupNames + '], [', '') + GroupName
	FROM IPMonGroups
	GROUP BY GroupName
	ORDER BY GroupName
SELECT @GroupNames = '[' + @GroupNames + ']'
PRINT @GroupNames

SELECT @SQL = 
'SELECT *
	, ' + @GroupNames + '
FROM
(
SELECT DeviceID
	, imm.MonitorID AS MonitorID
	, igm.GroupID AS GroupID
	, ig.GroupName AS GroupName
	, [Address]
	, imm.Name AS Name
	, ita.monitor_category AS MonitorCategory
	, imm.TypeID AS TypeID
	, [Description]
FROM IPMonMonitors imm
	INNER JOIN IPMonTypeAssoc ita ON imm.TypeID = ita.typeid
	INNER JOIN IPMonGroupMembers igm ON imm.MonitorID = igm.MonitorID
	INNER JOIN IPMonGroups ig ON igm.GroupID = ig.GroupID
--WHERE Address = ''PSQLMET31''	
GROUP BY DeviceID
	, imm.MonitorID
	, igm.GroupID
	, ig.GroupName
	, ita.monitor_category
	, [Address]
	, [Description]
	, imm.TypeID
	, imm.Name) AS SourceTable
PIVOT
(
SUM(GroupID)
FOR GroupName IN (
' + @GroupNames + '
)
) AS PivotTable;'	


PRINT @SQL
EXEC sp_executesql @SQL
-----------------------------------------------------------------------------

USE AdventureWorks;
GO
-- Pivot table with one row and five columns
SELECT 'AverageCost' AS Cost_Sorted_By_Production_Days, 
[0], [1], [2], [3], [4]
FROM
(SELECT DaysToManufacture, StandardCost 
    FROM Production.Product) AS SourceTable
PIVOT
(
AVG(StandardCost)
FOR DaysToManufacture IN ([0], [1], [2], [3], [4])
) AS PivotTable

-----------------------------------------------------------

USE AdventureWorks;
GO
SELECT VendorID, [164] AS Emp1, [198] AS Emp2, [223] AS Emp3, [231] AS Emp4, [233] AS Emp5
FROM 
(SELECT PurchaseOrderID, EmployeeID, VendorID
FROM Purchasing.PurchaseOrderHeader) p
PIVOT
(
COUNT (PurchaseOrderID)
FOR EmployeeID IN
( [164], [198], [223], [231], [233] )
) AS pvt
ORDER BY VendorID

----------------------------------------------------------------------------

SELECT  *
FROM    (
        SELECT  DISTINCT clients.ClientID, clients.serviceID
        FROM    clients
        ) e 
PIVOT   (
        COUNT(serviceID)
        FOR serviceID in ([1],[2])
        ) p
        
----------------------------------------------------------------------------

USE [Performance]
GO
/****** Object:  StoredProcedure [DexPerf].[sp_PivotPerformanceData]    Script Date: 10/24/2011 10:37:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		mmessano
-- Create date: 6/20/2011
-- Description:	Pivots the Perfmon counters on the Date.
-- =============================================
ALTER PROCEDURE [DexPerf].[sp_PivotPerformanceData] 
	@BeginDate DATETIME = NULL
	, @EndDate DATETIME = NULL
	, @NumDays INT = 1
	, @CounterName NVARCHAR(128)

AS
BEGIN

SET NOCOUNT ON;

SET @BeginDate = COALESCE(@BeginDate, GETDATE())
SET @EndDate = COALESCE(@EndDate, GETDATE())
DECLARE @DynamicPivotQuery NVARCHAR(MAX)
DECLARE @DateList NVARCHAR(MAX)

-- this works too
--SELECT @DateList =
--STUFF
--((
--	SELECT ', [' + CONVERT(VARCHAR, date_stamp), ']'
--	FROM [dexperf].[dm_os_performance_counters]
--	WHERE date_stamp BETWEEN GETDATE() - @NumDays AND GETDATE()
--	AND [counter_name] = 'Buffer cache hit ratio'
--	FOR XML PATH('')
--), 1, 1, '')

SELECT @DateList = COALESCE(@DateList + '], [', '') + CAST(date_stamp AS nvarchar) --AS [Date]
		FROM [dexperf].[dm_os_performance_counters]
		WHERE date_stamp BETWEEN @BeginDate - @NumDays AND @EndDate
		--WHERE date_stamp BETWEEN GETDATE() - @NumDays AND GETDATE()
		GROUP BY date_stamp
		ORDER BY date_stamp
SELECT @DateList = '[' + @DateList + ']'

SELECT @DynamicPivotQuery =
	N'SELECT [CounterName], ' + @DateList + '
	FROM (SELECT DISTINCT counter_name AS [CounterName]
		, SUM([cntr_value])	AS [SummedCounterValue]
		, CONVERT(VARCHAR, date_stamp) AS [Date]
	FROM [dexperf].[dm_os_performance_counters]
	WHERE counter_name IN ('''+ @CounterName +''')
	GROUP BY date_stamp, [cntr_value], [counter_name]
	) AS SourceTable
	PIVOT
	(SUM(SummedCounterValue)
	FOR [Date] IN
	(' + @DateList + ')) AS PivotTable;'

EXEC sp_executesql @DynamicPivotQuery
PRINT @DynamicPivotQuery
END
