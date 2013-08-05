/*
SELECT * FROM SQLIndicesMissing
ORDER BY CreateIndexStatement, DBName
*/
USE Status
GO

SET NOCOUNT ON

DECLARE @DBList NVARCHAR(MAX)
DECLARE @DBList2 NVARCHAR(MAX)
DECLARE @CreateIndexStatement NVARCHAR(MAX)
DECLARE @DynamicPivotQuery NVARCHAR(MAX)

DECLARE @DBS TABLE (
	DBName NVARCHAR(128)
)

INSERT INTO @DBS
	SELECT DISTINCT DBName FROM SQLIndicesMissing
	WHERE DBName NOT LIKE '%_rpt'
	AND DBName  LIKE 'DMart%CDC%'
	AND DBName NOT LIKE '%Management'
	AND DBName NOT LIKE '%Workflow'
	AND DBName NOT IN ('DX_PA', 'DXPRD', 'CMS', 'Journyx', 'RightFax', 'RightFax', 'SQLDataCollection', 'Performance')
	ORDER BY 1

SELECT @DBList = COALESCE(@DBList + ', ', '') + DBName
	FROM @DBS
SELECT @DBList2 = REPLACE(@DBList, ', ', ''', ''')

--SELECT * FROM @DBS
--PRINT @DBlist
SELECT @CreateIndexStatement = 'CREATE NONCLUSTERED INDEX ix_IndexName ON AFT ( [do_id],[aft_id], [ln_loan_id] ) ;'

SELECT @DynamicPivotQuery = 
N'SELECT CreateIndexStatement
	--, DBName
	, TableName
	--, DBCount
	--, SUM(Impact) AS TotalClients
	, ' + @DBList + '
	FROM (
		SELECT DISTINCT CreateIndexStatement
			, DBName
			, TableName
			, CAST(SUM(Impact) AS BIGINT) AS Impact
			, COUNT(DBName) AS DBCount
		FROM SQLIndicesMissing 
		WHERE DBName IN (''' + @DBList2 + ''')
		--AND CreateIndexStatement = (''' + @CreateIndexStatement + ''')
		GROUP BY CreateIndexStatement, DBName, TableName	
	) AS SourceTable
	PIVOT
	(COUNT(DBName)
	FOR DBName IN 
	(' + @DBList + ')) AS PivotTable
	GROUP BY CreateIndexStatement, TableName, ' + @DBList + ';'

PRINT @DynamicPivotQuery
EXEC sp_executesql @DynamicPivotQuery

