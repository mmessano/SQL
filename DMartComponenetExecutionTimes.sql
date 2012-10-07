--CONVERT(varchar(12), DATEADD(ms, DATEDIFF(ms, LoadStageDBStartDate, LoadStageDBEndDate), 0), 114) AS StageLoadTime,
/*
DECLARE @ReportDate DATETIME = GETDATE()

SET @ReportDate = GETDATE() - 2

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
*/
-----------------------------------------
-- PIVOT 1
BEGIN
SET NOCOUNT ON

DECLARE @TaskNames NVARCHAR(MAX)
		, @SQL NVARCHAR(MAX)
		, @ReportDate DATETIME = GETDATE()

SELECT @TaskNames = COALESCE(@TaskNames + '], [', '') + TaskName
--SELECT @TaskNames = COALESCE(@TaskNames + '], [TaskStartTime], [TaskEndTime], [TaskTimeTaken], [', '') + TaskName
	FROM dbo.DMartComponentLogging
	GROUP BY TaskName
	ORDER BY TaskName
SELECT @TaskNames = '['	 + @TaskNames + ']'
-- PRINT @TaskNames

DECLARE @Day NVARCHAR(2)
		, @Month NVARCHAR(2)
		, @Year NVARCHAR(4)

SELECT @Day = DATEPART(day,@ReportDate)
SELECT @Month = DATEPART(month,@ReportDate)
SELECT @Year = DATEPART(year,@ReportDate )

SELECT @SQL =
'
SELECT SourceServer
		, SourceDB
		, ' + @TaskNames + '
		, ''' + CAST(@ReportDate AS NVARCHAR)  + ''' AS ReportDate
FROM
(
	SELECT SourceServer
            , SourceDB
            , TaskName
            , CONVERT(VARCHAR(12), DATEADD(ms, DATEDIFF(ms, 
				MAX(CASE WHEN ErrorMessage LIKE ''%Validation phase is beginning.%'' THEN ErrorDateTime ELSE 0 END)
				, MAX(CASE WHEN ErrorMessage LIKE ''%Cleanup phase is beginning.%'' THEN ErrorDateTime ELSE 0 END)), 0), 114) AS TaskTimeTaken
	FROM dbo.DMartComponentLogging
	WHERE	DATEPART(day,ErrorDateTime)			= ''' + @Day + '''
			AND DATEPART(month,ErrorDateTime)	= ''' + @Month + '''
			AND DATEPART(year,ErrorDateTime)	= ''' + @Year + '''
	GROUP BY SourceDB
            , TaskName
            , SourceServer
) AS Source
PIVOT
(
MAX(TaskTimeTaken)
FOR TaskName IN (
' + @TaskNames + '
)
) AS PivotTable;
'

PRINT @SQL
EXEC sp_executesql @SQL;
END
-----------------------------------------
-- PIVOT 2
BEGIN
SET NOCOUNT ON

DECLARE @ClientNames NVARCHAR(MAX)
		, @SQL NVARCHAR(MAX)
		, @ReportDate DATETIME = GETDATE()

SELECT @ClientNames = COALESCE(@ClientNames + '], [', '') + SourceDB
--SELECT @ClientNames = COALESCE(@ClientNames + '], [TaskStartTime], [TaskEndTime], [TaskTimeTaken], [', '') + TaskName
	FROM dbo.DMartComponentLogging
	GROUP BY SourceDB
	ORDER BY SourceDB
SELECT @ClientNames = '['	 + @ClientNames + ']'
-- PRINT @ClientNames

DECLARE @Day NVARCHAR(2)
		, @Month NVARCHAR(2)
		, @Year NVARCHAR(4)

SELECT @Day = DATEPART(day,@ReportDate)
SELECT @Month = DATEPART(month,@ReportDate)
SELECT @Year = DATEPART(year,@ReportDate )

SELECT @SQL =
'
SELECT TaskName
		, ''' + CAST(@ReportDate AS NVARCHAR)  + ''' AS ReportDate
		, ' + @ClientNames + '
FROM
(
	SELECT SourceDB
            , TaskName
            , CONVERT(VARCHAR(12), DATEADD(ms, DATEDIFF(ms, 
				MAX(CASE WHEN ErrorMessage LIKE ''%Validation phase is beginning.%'' THEN ErrorDateTime ELSE 0 END)
				, MAX(CASE WHEN ErrorMessage LIKE ''%Cleanup phase is beginning.%'' THEN ErrorDateTime ELSE 0 END)), 0), 114) AS TaskTimeTaken
	FROM dbo.DMartComponentLogging
	WHERE	DATEPART(day,ErrorDateTime)			= ''' + @Day + '''
			AND DATEPART(month,ErrorDateTime)	= ''' + @Month + '''
			AND DATEPART(year,ErrorDateTime)	= ''' + @Year + '''
	GROUP BY SourceDB
            , TaskName
            , SourceServer
) AS Source
PIVOT
(
MAX(TaskTimeTaken)
FOR SourceDB IN (
' + @ClientNames + '
)
) AS PivotTable;
'

PRINT @SQL
EXEC sp_executesql @SQL
END