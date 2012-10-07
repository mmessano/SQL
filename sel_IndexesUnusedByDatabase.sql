/*
SELECT * FROM SQLINDICESUNUSED
WHERE TABLENAME NOT LIKE '%_CT'
AND DBNAME NOT IN ('DX_PA', 'DXPRD')
ORDER BY TABLENAME, INDEXNAME, DBNAME
*/
--USE Status
--GO

--SET NOCOUNT ON

---------------------------------------------------------------------------
DECLARE @DBList NVARCHAR(MAX)
DECLARE @DBList2 NVARCHAR(MAX)
DECLARE @DropIndexStatement NVARCHAR(MAX)
DECLARE @DynamicPivotQuery NVARCHAR(MAX)

DECLARE @DBS TABLE (
	DBName NVARCHAR(128)
)

INSERT INTO @DBS
	SELECT DISTINCT DBName FROM SQLIndicesUnused
	WHERE DBName NOT LIKE '%_rpt'
	AND DBName NOT LIKE 'DMart%'
	AND DBName NOT LIKE '%Management'
	AND DBName NOT LIKE '%Workflow'
	AND DBName NOT IN ('DX_PA', 'DXPRD', 'CMS', 'Journyx', 'RightFax', 'RightFax', 'SQLDataCollection', 'Performance')
	ORDER BY 1

SELECT @DBList = COALESCE(@DBList + ', ', '') + DBName
	FROM @DBS
SELECT @DBList2 = REPLACE(@DBList, ', ', ''', ''')

SELECT @DynamicPivotQuery = 
N'SELECT DropIndexStatement
	, TableName
	, IndexName
	, '''' AS TotalDrops
	, ' + @DBList + '
	FROM (
		SELECT DISTINCT DropIndexStatement
			, DBName
			, TableName
			, IndexName
			, COUNT(DBName) AS [RowCount]
		FROM SQLIndicesUnused 
		WHERE DBName IN (''' + @DBList2 + ''')
		AND TableName NOT LIKE (''dbo%_CT'')
		GROUP BY DropIndexStatement, DBName, TableName, IndexName	
	) AS SourceTable
	PIVOT
	(COUNT(DBName)
	FOR DBName IN 
	(' + @DBList + ')) AS PivotTable
	ORDER BY 1,2,3;'

PRINT @DynamicPivotQuery
EXEC sp_executesql @DynamicPivotQuery
---------------------------------------------------------------------------

--SELECT DISTINCT DropIndexStatement
--	, siu.DBName
--	, TableName
--	, IndexName
--	, SUM(Rows) AS SummedRows
--FROM SQLIndicesUnused siu 
--	INNER JOIN @DBS dbs ON siu.DBName = dbs.DBName
--WHERE DropIndexStatement = @DropIndexStatement
--GROUP BY DropIndexStatement, siu.DBName, TableName, IndexName
--ORDER BY siu.DBName
