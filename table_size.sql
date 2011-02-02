DECLARE @SQL VARCHAR(255)
SET @SQL = 'DBCC UPDATEUSAGE (' + DB_NAME() + ')'

EXEC(@SQL)

CREATE TABLE #foo
(
name VARCHAR(255),
rows INT ,
reserved varchar(255),
data varchar(255),
index_size varchar(255),
unused varchar(255)
)


INSERT into #foo
EXEC sp_MSForEachtable 'sp_spaceused ''?'''

SELECT *
FROM #foo
ORDER BY rows DESC
DROP TABLE #foo

/*

SELECT * FROM MonitorMemory
	WHERE LastUpdate < ( GetDate() - 270 )
	
	SELECT TOP 1 * FROM ConfigFileReport

SELECT TOP 100 * FROM LoanRoadmap

sp_who2 active

exec dbamaint.dbo.dbm_ConnectionSummary

*/