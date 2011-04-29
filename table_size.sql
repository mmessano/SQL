DECLARE @SQL VARCHAR(255)
SET @SQL = 'DBCC UPDATEUSAGE (' + DB_NAME() + ')'

EXEC(@SQL)

DECLARE @Foo TABLE (
	name VARCHAR(255),
	rows INT ,
	reserved varchar(255),
	data varchar(255),
	index_size varchar(255),
	unused varchar(255)
)


INSERT INTO @Foo
EXEC sp_MSForEachtable 'sp_spaceused ''?'''

SELECT *
FROM @Foo
ORDER BY rows DESC
