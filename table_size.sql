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

SELECT  name
      , rows
      , reserved
      , data
      , index_size
      , unused
FROM @Foo
ORDER BY rows DESC, name


--EXEC dbo.sp_trunc_Data_tables

----------------------------------------------

--Get total size of table and row count for each table

SELECT	SCHEMA_NAME(sysTab.SCHEMA_ID) AS SchemaName
	  , sysTab.NAME AS TableName
	  , parti.rows AS RowCounts
	  , SUM(alloUni.total_pages) * 8 AS TotalSpaceKB
	  , SUM(alloUni.used_pages) * 8 AS UsedSpaceKB
	  , ( SUM(alloUni.total_pages) - SUM(alloUni.used_pages) ) * 8 AS UnusedSpaceKB
FROM	sys.tables sysTab
		INNER JOIN sys.indexes ind ON sysTab.OBJECT_ID = ind.OBJECT_ID
									  AND ind.Index_ID <= 1
		INNER JOIN sys.partitions parti ON ind.OBJECT_ID = parti.OBJECT_ID
										   AND ind.index_id = parti.index_id
		INNER JOIN sys.allocation_units alloUni ON parti.partition_id = alloUni.container_id
WHERE	sysTab.is_ms_shipped = 0
		AND ind.OBJECT_ID > 255
		AND parti.rows > 0
GROUP BY sysTab.Name
	  , parti.Rows
	  , sysTab.SCHEMA_ID
ORDER BY parti.rows DESC

-------------------------------------------

SELECT	QUOTENAME(SCHEMA_NAME(sOBJ.schema_id)) + '.' + QUOTENAME(sOBJ.name) AS [TableName]
	  , SUM(sPTN.Rows) AS [RowCount]
FROM	sys.objects AS sOBJ
		INNER JOIN sys.partitions AS sPTN ON sOBJ.object_id = sPTN.object_id
WHERE	sOBJ.type = 'U'
		AND sOBJ.is_ms_shipped = 0x0
		AND index_id < 2 -- 0:Heap, 1:Clustered
GROUP BY sOBJ.schema_id
	  , sOBJ.name
ORDER BY [TableName]
GO

----------------------------------------------

SELECT
      QUOTENAME(SCHEMA_NAME(sOBJ.schema_id)) + '.' + QUOTENAME(sOBJ.name) AS [TableName]
      , SUM(sdmvPTNS.row_count) AS [RowCount]
FROM
      sys.objects AS sOBJ
      INNER JOIN sys.dm_db_partition_stats AS sdmvPTNS
            ON sOBJ.object_id = sdmvPTNS.object_id
WHERE 
      sOBJ.type = 'U'
      AND sOBJ.is_ms_shipped = 0x0
      AND sdmvPTNS.index_id < 2
GROUP BY
      sOBJ.schema_id
      , sOBJ.name
ORDER BY [TableName]
GO

---------------------------------------------------
-- index sizes (slow)

--SELECT [DatabaseName]
--      ,OBJECT_NAME([ObjectId])
--      ,[ObjectName]
--      ,[IndexId]
--      ,[IndexDescription]
--      ,CONVERT(DECIMAL(16,1)
--                ,(SUM([avg_record_size_in_bytes] * [record_count])
--                        / (1024.0 *1024))) AS  [IndexSize(MB)]
--      ,[lastupdated] AS [StatisticLastUpdated]
--      ,[AvgFragmentationInPercent] 
--FROM (SELECT 
--        DISTINCT DB_Name(Database_id) AS 'DatabaseName'
--       ,OBJECT_ID AS ObjectId, Object_Name(Object_id) AS ObjectName
--       ,Index_ID AS IndexId
--       ,Index_Type_Desc AS IndexDescription
--       ,avg_record_size_in_bytes 
--       ,record_count
--       ,STATS_DATE(object_id,index_id) AS 'lastupdated'
--       ,CONVERT([varchar](512)
--                 ,round(Avg_Fragmentation_In_Percent,3)) AS 'AvgFragmentationInPercent' 
--      FROM sys.dm_db_index_physical_stats(db_id('PM_Db'), NULL, NULL, NULL, 'detailed') 
--      WHERE OBJECT_ID IS NOT NULL 
--        AND Avg_Fragmentation_In_Percent <> 0) T 
--GROUP BY DatabaseName
--        ,ObjectId
--        ,ObjectName
--        ,IndexId
--        ,IndexDescription
--        ,lastupdated
--        ,AvgFragmentationInPercent


