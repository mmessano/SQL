--Description : This script reorganizes and rebuilds the index if the fragmentation level is higher the given threshold
-- You can define the threshold for reorganize as well as for rebuild and script will work accordingly
-- INPUTS : @fillfactor - While rebuilding index what would be FILLFACTOR for new index
-- @FragmentationThresholdForReorganizeTableLowerLimit - Fragmentation Level lower threshold to check for reorganizing the table, if the fragmentation is higher than this level, it will be considered for reorganize
-- @@FragmentationThresholdForRebuildTableLowerLimit - Fragmentation Level lower threshold to check for rebuilding the table, if the fragmentation is higher than this level, it will be considered for rebuild
-- NOTES : PRINT statements are all queued up and don't show up until the entire script is printed. However, there is an alternative to PRINTing messages. 
-- You can raise an error that isn't really an error (code of 0) and you'll get the same effect--message will be printed immediately.
DECLARE @cmd NVARCHAR(1000) 
DECLARE @Table VARCHAR(255) 
DECLARE @SchemaName VARCHAR(255)
DECLARE @IndexName VARCHAR(255)
DECLARE @AvgFragmentationInPercent DECIMAL
DECLARE @fillfactor INT 
DECLARE @FragmentationThresholdForReorganizeTableLowerLimit VARCHAR(10)
DECLARE @FragmentationThresholdForRebuildTableLowerLimit VARCHAR(10)
DECLARE @Message VARCHAR(1000)

SET NOCOUNT ON

--You can specify your customized value for reorganize and rebuild indexes, the default values
--of 10 and 30 means index will be reorgnized if the fragmentation level is more than equal to 10 
--and less than 30, if the fragmentation level is more than equal to 30 then index will be rebuilt
SET @fillfactor = 90 
SET @FragmentationThresholdForReorganizeTableLowerLimit = '10.0' -- Percent
SET @FragmentationThresholdForRebuildTableLowerLimit = '30.0' -- Percent

BEGIN TRY

-- ensure the temporary table does not exist
IF (SELECT OBJECT_ID('tempdb..#FramentedTableList')) IS NOT NULL
DROP TABLE #FramentedTableList;

SET @Message = 'DATE : ' + CONVERT(VARCHAR, GETDATE()) + ' - Retrieving indexes with high fragmentation from ' + DB_NAME() + ' database.'
RAISERROR(@Message, 0, 1) WITH NOWAIT

SELECT OBJECT_NAME(IPS.OBJECT_ID) AS [TableName], avg_fragmentation_in_percent, SI.name [IndexName], 
schema_name(ST.schema_id) AS [SchemaName], 0 AS IsProcessed INTO #FramentedTableList
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL , NULL) IPS
JOIN sys.tables ST WITH (nolock) ON IPS.OBJECT_ID = ST.OBJECT_ID
JOIN sys.indexes SI WITH (nolock) ON IPS.OBJECT_ID = SI.OBJECT_ID AND IPS.index_id = SI.index_id
WHERE ST.is_ms_shipped = 0 AND SI.name IS NOT NULL
AND avg_fragmentation_in_percent >= CONVERT(DECIMAL, @FragmentationThresholdForReorganizeTableLowerLimit) 
ORDER BY avg_fragmentation_in_percent DESC

SET @Message = 'DATE : ' + CONVERT(VARCHAR, GETDATE()) + ' - Retrieved indexes with high fragmentation from ' + DB_NAME() + ' database.'

RAISERROR(@Message, 0, 1) WITH NOWAIT
RAISERROR('', 0, 1) WITH NOWAIT

WHILE EXISTS ( SELECT 1 FROM #FramentedTableList WHERE IsProcessed = 0 )
BEGIN

  SELECT TOP 1 @Table = TableName, @AvgFragmentationInPercent = avg_fragmentation_in_percent, 
  @SchemaName = SchemaName, @IndexName = IndexName
  FROM #FramentedTableList
  WHERE IsProcessed = 0

  --Reorganizing the index
  IF((@AvgFragmentationInPercent >= @FragmentationThresholdForReorganizeTableLowerLimit) AND (@AvgFragmentationInPercent < @FragmentationThresholdForRebuildTableLowerLimit))
  BEGIN
    SET @Message = 'DATE : ' + CONVERT(VARCHAR, GETDATE()) + ' - Reorganizing Index for [' + @Table + '] which has avg_fragmentation_in_percent = ' + CONVERT(VARCHAR, @AvgFragmentationInPercent) + '.'
    RAISERROR(@Message, 0, 1) WITH NOWAIT
    SET @cmd = 'ALTER INDEX ' + @IndexName + ' ON [' + RTRIM(LTRIM(@SchemaName)) + '].[' + RTRIM(LTRIM(@Table)) + '] REORGANIZE' 
    EXEC (@cmd)
    --PRINT @cmd 
    SET @Message = 'DATE : ' + CONVERT(VARCHAR, GETDATE()) + ' - Reorganize Index completed successfully for [' + @Table + '].' 
    RAISERROR(@Message, 0, 1) WITH NOWAIT
    RAISERROR('', 0, 1) WITH NOWAIT
  END
  --Rebuilding the index
  ELSE IF (@AvgFragmentationInPercent >= @FragmentationThresholdForRebuildTableLowerLimit )
  BEGIN
    SET @Message = 'DATE : ' + CONVERT(VARCHAR, GETDATE()) + ' - Rebuilding Index for [' + @Table + '] which has avg_fragmentation_in_percent = ' + CONVERT(VARCHAR, @AvgFragmentationInPercent) + '.'
    RAISERROR(@Message, 0, 1) WITH NOWAIT
    SET @cmd = 'ALTER INDEX ' + @IndexName + ' ON [' + RTRIM(LTRIM(@SchemaName)) + '].[' + RTRIM(LTRIM(@Table)) + '] REBUILD WITH (FILLFACTOR = ' + CONVERT(VARCHAR(3),@fillfactor) + ', STATISTICS_NORECOMPUTE = OFF)' 
    EXEC (@cmd)
    --PRINT @cmd
    SET @Message = 'DATE : ' + CONVERT(VARCHAR, GETDATE()) + ' - Rebuild Index completed successfully for [' + @Table + '].'
    RAISERROR(@Message, 0, 1) WITH NOWAIT
    RAISERROR('', 0, 1) WITH NOWAIT
  END

  UPDATE #FramentedTableList
  SET IsProcessed = 1 
  WHERE TableName = @Table
  AND IndexName = @IndexName
END

DROP TABLE #FramentedTableList 

END TRY

BEGIN CATCH
  PRINT 'DATE : ' + CONVERT(VARCHAR, GETDATE()) + ' There is some run time exception.'
  PRINT 'ERROR CODE : ' + CONVERT(VARCHAR, ERROR_NUMBER()) 
  PRINT 'ERROR MESSAGE : ' + ERROR_MESSAGE()
END CATCH 