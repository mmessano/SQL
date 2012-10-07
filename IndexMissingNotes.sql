SELECT index_handle
		, DB_NAME(database_id) AS DBName
		, OBJECT_NAME(object_id) AS ObjName
		, equality_columns
		, inequality_columns
		, included_columns
		, statement
FROM sys.dm_db_missing_index_details 
ORDER BY 2,3

----------------------------------------------------------

PRINT 'Missing Indexes: '
PRINT 'The "improvement_measure" column is an indicator of the (estimated) improvement that might '
PRINT 'be seen if the index was created.  This is a unitless number, and has meaning only relative '
PRINT 'the same number for other indexes.  The measure is a combination of the avg_total_user_cost, '
PRINT 'avg_user_impact, user_seeks, and user_scans columns in sys.dm_db_missing_index_group_stats.'
PRINT ''
PRINT '-- Missing Indexes --'
SELECT CONVERT (varchar, getdate(), 126) AS RunTime
		, mig.index_group_handle
		, mid.index_handle
		, CONVERT (decimal (28,1), migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans)) AS improvement_measure
		, 'CREATE INDEX missing_index_' + CONVERT (varchar, mig.index_group_handle) + '_' + CONVERT (varchar, mid.index_handle) 
			+ ' ON ' + mid.statement 
			+ ' (' + ISNULL (mid.equality_columns,'') 
			+ CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ',' ELSE '' END + ISNULL (mid.inequality_columns, '')
			+ ')' 
			+ ISNULL (' INCLUDE (' + mid.included_columns + ')', '') AS create_index_statement
		, migs.*
		, mid.database_id
		, mid.[object_id]
FROM sys.dm_db_missing_index_groups mig
	INNER JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle
	INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE CONVERT (decimal (28,1), migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans)) > 10
ORDER BY migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) DESC
PRINT ''
GO

---------------------------------------------------------------

SELECT stat.name AS 'Statistics'
		, OBJECT_NAME(stat.object_id) AS 'Object'
		, COL_NAME(scol.object_id, scol.column_id) AS 'Column'
FROM sys.stats AS stat (NOLOCK) 
	Join sys.stats_columns AS scol (NOLOCK) ON stat.stats_id = scol.stats_id AND stat.object_id = scol.object_id
	INNER JOIN sys.tables AS tab (NOLOCK) on tab.object_id = stat.object_id
WHERE stat.name like '_WA%'
ORDER BY stat.name
