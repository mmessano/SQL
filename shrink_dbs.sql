SET NOCOUNT ON
DECLARE @Number int,
	@LoopID int,
	@SQLString varchar(8000)

CREATE TABLE #tempDatabases (DatabaseName varchar(255), Number int IDENTITY)
INSERT #tempDatabases
SELECT name FROM master..sysdatabases 
SELECT @Number = @@RowCount, @LoopID = 1

WHILE @Number >= @LoopID
BEGIN
	SELECT @SQLString = 'DBCC SHRINKDATABASE ([' + DatabaseName + '],4)' FROM #tempDatabases WHERE Number = @LoopID
	PRINT(@SQLString)
	--EXEC (@SQLString)
	SELECT (@SQLString)
	SELECT @LoopID = @LoopID + 1
END
drop table #tempDatabases

--------------------------------------------------------------

SET NOCOUNT ON
DECLARE @Number int,
	@LoopID int,
	@SQLString varchar(8000)

CREATE TABLE #tempDatabases (DatabaseName varchar(255), Number int IDENTITY)
INSERT #tempDatabases
	SELECT name 
	FROM master..sysdatabases 
	WHERE DBID > 4
	AND name NOT IN ('distribution')
	ORDER BY 1
SELECT @Number = @@RowCount, @LoopID = 1

WHILE @Number >= @LoopID
BEGIN
	SELECT @SQLString = '
	USE [' + DatabaseName + '];
	DBCC SHRINKFILE (N''' + DatabaseName + '_Log'',200);' 
	FROM #tempDatabases WHERE Number = @LoopID
	PRINT(@SQLString)
	--EXEC (@SQLString)
	--SELECT (@SQLString)
	SELECT @LoopID = @LoopID + 1
END
drop table #tempDatabases

--------------------------------------------------------------

Declare @db varchar(64)
Declare @dblog varchar(128)
Declare @dbdata varchar(128)
Declare @cmd varchar(256)

Set @db = 'Status'
Set @dblog = @db + '_Log'
Set @dbdata = @db + '_Data'

select @cmd = N'use ' +  quotename(@db)
	exec (@cmd)


--DBCC SHRINKFILE(@dbdata,20)
DBCC SHRINKFILE(@dblog,15)

DBCC shrinkfile(CUWest_Data,TruncateOnly)
DBCC shrinkfile(CUWest_Log,TruncateOnly)
DBCC SHRINKDATABASE(dexmasites,TruncateOnly)

----------------------------------------------------
dbcc shrinkfile('Status_Data',TruncateOnly)
dbcc shrinkfile('RightFax',TruncateOnly)
dbcc shrinkfile('RightFax',200)
dbcc shrinkfile('AmericanAirlines_Data',5)
dbcc shrinkfile('CUWest_Log',50)
