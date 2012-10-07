--------------------------------------------------------------------
-- works, leave it alone  :)
DECLARE @ReportDate DATETIME = GETDATE()

SET @ReportDate = GETDATE()

SELECT x.*
FROM
(
	SELECT SourceServer
            , SourceDB
            , TaskName
            , MAX(CASE WHEN ErrorMessage LIKE '%Validation phase is beginning.%' THEN ErrorDateTime ELSE 0 END) AS TaskStartTime
            , MAX(CASE WHEN ErrorMessage LIKE '%Cleanup phase is beginning.%' THEN ErrorDateTime ELSE 0 END) AS TaskEndTime
            , CONVERT(VARCHAR(12), DATEADD(ms, DATEDIFF(ms, 
				MAX(CASE WHEN ErrorMessage LIKE '%Validation phase is beginning.%' THEN ErrorDateTime ELSE 0 END)
				, MAX(CASE WHEN ErrorMessage LIKE '%Cleanup phase is beginning.%' THEN ErrorDateTime ELSE 0 END)), 0), 114) AS TaskTimeTaken
	FROM dbo.DMartComponentLogging
	WHERE	DATEPART(day,ErrorDateTime)			= DATEPART(day,@ReportDate)
			AND DATEPART(month,ErrorDateTime)	= DATEPART(month,@ReportDate)
			AND DATEPART(year,ErrorDateTime)	= DATEPART(year,@ReportDate)
	GROUP BY SourceDB
            , TaskName
            , SourceServer
) x
ORDER BY SourceDB, TaskName
------------------------------------------------------------
-- PIVOT 1

SELECT SourceServer
		, SourceDB
		, [Data Flow Task br_fico_score], [Data Flow Task br_liability], [Data Flow Task br_race], [Data Flow Task comm_lending], [Data Flow Task government], [Data Flow Task LoanPurchase], [Data Flow Task Subordinations]
FROM
(
	SELECT SourceServer
            , SourceDB
            , TaskName
            , CONVERT(VARCHAR(12), DATEADD(ms, DATEDIFF(ms, 
				MAX(CASE WHEN ErrorMessage LIKE '%Validation phase is beginning.%' THEN ErrorDateTime ELSE 0 END)
				, MAX(CASE WHEN ErrorMessage LIKE '%Cleanup phase is beginning.%' THEN ErrorDateTime ELSE 0 END)), 0), 114) AS TaskTimeTaken
	FROM dbo.DMartComponentLogging
	WHERE	DATEPART(day,ErrorDateTime)			= '26'
			AND DATEPART(month,ErrorDateTime)	= '9'
			AND DATEPART(year,ErrorDateTime)	= '2012'
	GROUP BY SourceDB
            , TaskName
            , SourceServer
) AS Source
PIVOT
(
MAX(TaskTimeTaken)
FOR TaskName IN (
[Data Flow Task br_fico_score], [Data Flow Task br_liability], [Data Flow Task br_race], [Data Flow Task comm_lending], [Data Flow Task government], [Data Flow Task LoanPurchase], [Data Flow Task Subordinations]
)
) AS PivotTable;
------------------------------------------------------------
-- PIVOT 2


SELECT TaskName
		, [ABECU32], [AddisonAve32], [AmericaFirst32], [AmericanAirlines], [ArizonaStateCU], [ArkansasFCU], [Baxter], [BayFederal], [Bellco32], [Bethpage40], [Boeing4], [Chetco], [Chevron], [CitizensFirst], [CityCounty32], [CommunityFirstCU], [ConsumersCU], [CUAnswers], [CUMA], [CUWest], [Delta], [DenverPublicSchools], [Dupont], [EDCO], [Ent], [FinancialPrtCU], [FirstTech], [GeorgiaTelco], [GTE32], [HiwayCU], [Hutchinson], [Kern32], [Kinecta], [LGECCU], [Lockheed32], [McDillAFB], [MembersMortgage], [Merchants], [Merrimack], [Metro1stMortgage], [MidMinnesota], [MissionFed40], [Numerica], [NuVision], [OrangeCounty32], [ORNL], [OTCCU], [PADemoDU], [Patelco32], [PATrain], [PremierAmerica], [Purdue], [Redwood], [Rivermark], [RLC], [SDCCU32], [SecurityServices], [SFEFCU], [SFFCU], [SouthCarolina32], [StarOne], [Suncoast32], [Thrivent], [TIB], [Tower32], [Travis40], [Vandenberg32], [Wescom], [WESTconsinCU], [Weyerhaeuser], [Wrightpatt32], [XceedFinancialCU]
		, 'Sep 26 2012 10:04PM' AS ReportDate
FROM
(
	SELECT SourceDB
            , TaskName
            , CONVERT(VARCHAR(12), DATEADD(ms, DATEDIFF(ms, 
				MAX(CASE WHEN ErrorMessage LIKE '%Validation phase is beginning.%' THEN ErrorDateTime ELSE 0 END)
				, MAX(CASE WHEN ErrorMessage LIKE '%Cleanup phase is beginning.%' THEN ErrorDateTime ELSE 0 END)), 0), 114) AS TaskTimeTaken
	FROM dbo.DMartComponentLogging
	WHERE	DATEPART(day,ErrorDateTime)			= '26'
			AND DATEPART(month,ErrorDateTime)	= '9'
			AND DATEPART(year,ErrorDateTime)	= '2012'
	GROUP BY SourceDB
            , TaskName
            , SourceServer
) AS Source
PIVOT
(
MAX(TaskTimeTaken)
FOR SourceDB IN (
[ABECU32], [AddisonAve32], [AmericaFirst32], [AmericanAirlines], [ArizonaStateCU], [ArkansasFCU], [Baxter], [BayFederal], [Bellco32], [Bethpage40], [Boeing4], [Chetco], [Chevron], [CitizensFirst], [CityCounty32], [CommunityFirstCU], [ConsumersCU], [CUAnswers], [CUMA], [CUWest], [Delta], [DenverPublicSchools], [Dupont], [EDCO], [Ent], [FinancialPrtCU], [FirstTech], [GeorgiaTelco], [GTE32], [HiwayCU], [Hutchinson], [Kern32], [Kinecta], [LGECCU], [Lockheed32], [McDillAFB], [MembersMortgage], [Merchants], [Merrimack], [Metro1stMortgage], [MidMinnesota], [MissionFed40], [Numerica], [NuVision], [OrangeCounty32], [ORNL], [OTCCU], [PADemoDU], [Patelco32], [PATrain], [PremierAmerica], [Purdue], [Redwood], [Rivermark], [RLC], [SDCCU32], [SecurityServices], [SFEFCU], [SFFCU], [SouthCarolina32], [StarOne], [Suncoast32], [Thrivent], [TIB], [Tower32], [Travis40], [Vandenberg32], [Wescom], [WESTconsinCU], [Weyerhaeuser], [Wrightpatt32], [XceedFinancialCU]
)
) AS PivotTable;

