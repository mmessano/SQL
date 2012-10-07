/*
SELECT * FROM SQLIndicesFragmented
ORDER BY LastUpdate DESC
*/
USE Status
GO

SET NOCOUNT ON

DECLARE @DBList NVARCHAR(MAX)
DECLARE @DBList2 NVARCHAR(MAX)
DECLARE @NullList NVARCHAR(MAX)
DECLARE @FragPercentStatement NVARCHAR(MAX)
DECLARE @DynamicPivotQuery NVARCHAR(MAX)

DECLARE @DBS TABLE (
	DBName NVARCHAR(128)
	, NullList NVARCHAR(MAX)
)

INSERT INTO @DBS
	SELECT DISTINCT DBName 
	, 'ISNULL(' + DBName + ', 0) AS ' + DBName AS NullList
	FROM SQLIndicesFragmented
	WHERE DBName NOT LIKE '%_rpt'
	AND DBName NOT LIKE 'DMart%'
	AND DBName NOT LIKE '%Management'
	AND DBName NOT LIKE '%Workflow'
	AND DBName NOT IN ('DX_PA', 'DXPRD', 'CMS', 'Journyx', 'RightFax', 'RightFax', 'SQLDataCollection', 'Performance')
	ORDER BY 1

SELECT @DBList = COALESCE(@DBList + ', ', '') + DBName
	FROM @DBS
SELECT @DBList2 = REPLACE(@DBList, ', ', ''', ''')
SELECT @NullList = COALESCE(@NullList + ', ', '') + NullList
	FROM @DBS

SELECT @DynamicPivotQuery = 
N'SELECT TableName
	, IndexName
	, ' + @NullList + '
	FROM (
		SELECT DISTINCT DBName
			, IndexName
			, TableName
			, CAST(SUM(FragPercent) AS DECIMAL(4,2)) AS FragPercent
		FROM SQLIndicesFragmented 
		WHERE DBName IN (''' + @DBList2 + ''')
		GROUP BY IndexName, DBName, TableName
	) AS SourceTable
	PIVOT
	(SUM(FragPercent)
	FOR DBName IN (' + @DBList + ')
	) AS PivotTable;'

PRINT @DynamicPivotQuery
EXEC sp_executesql @DynamicPivotQuery

