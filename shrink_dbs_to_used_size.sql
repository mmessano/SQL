-- Find Log file information and save in temp file using dbcc sqlperf logspace
SET NOCOUNT ON

DECLARE @DatabaseName varchar(500)

DECLARE @LogSpace TABLE (
	DatabaseName VARCHAR(128)
	, LogSize INT
	, LogSpace INT
	, status BIT
)

DECLARE @DBSpace TABLE (
	FielId TINYINT
	, Filegroup TINYINT
	, TotalSpace INT
	, Used_Space INT
	, Name1 VARCHAR(128)
	, filename VARCHAR(900)
)
 
INSERT @LogSpace exec ('dbcc sqlperf(logspace) WITH NO_INFOMSGS') 

-- Find data file information using cursor and dbcc showfilestats
Declare curDB cursor for 
	select name 
	from master..sysdatabases 
open curDB
fetch curDB into @DatabaseName
while @@fetch_status = 0
begin
    if databasepropertyex(@DatabaseName,'Status') = 'ONLINE'
    begin
    --PRINT @Databasename
    insert into @DBSpace exec ('USE [' + @DatabaseName + ']  DBCC SHOWFILESTATS WITH NO_INFOMSGS')
    end
    fetch curDB into @DatabaseName
end
close curDB
deallocate curDB 

DECLARE @SizeOutput TABLE (
	[DatabaseName] SYSNAME
	, [DataLogicalName] SYSNAME
	, [LogLogicalName] SYSNAME
	, [DatabaseSize(MB)] DECIMAL(10,2)
	, [DataFileSpace(MB)] DECIMAL(10,2)
	, [DataFileUsedSpace(MB)] DECIMAL(10,2)
	, [DataFileFreeSpace(MB)] DECIMAL(10,2)
	, [LogFileSize(MB)] DECIMAL(10,2)
	, [LogFileSpaceUsedIn(%)] DECIMAL(10,2)
	--, [FileName] sysname
)

INSERT INTO @SizeOutput
-- Select data in tabular format with proper headings & order by
select sd.name AS 'DatabaseName'
	, dbs.Name1 AS 'DataLogicalName'
	, (SELECT name FROM master.sys.master_files WHERE file_id = 2 AND database_id = sd.dbid ) AS 'LogLogicalName'
	, (ff.[DataFileSpace(MB)])+ls.LogSize as 'DatabaseSize(MB)'
	, ff.[DataFileSpace(MB)]
	, ff.[DataFileUsedSpace(MB)]
	, ff.[DataFileFreeSpace(MB)]
	, ls.LogSize as 'LogFileSize(MB)'
	, ls.LogSpace as'LogFileSpaceUsedIn(%)'
	--, ff.name
from @DBSpace dbs 
	join master..sysdatabases sd on sd.filename = dbs.filename
	join @LogSpace ls on sd.name = ls.DatabaseName
	--JOIN master.sys.master_files mf ON mf.database_id = sd.dbid
	join (select  mf.database_id
					--, mf.name
					, sum(dbss.TotalSpace/16) as 'DataFileSpace(MB)'
					, sum(dbss.Used_Space/16) as 'DataFileUsedSpace(MB)'
					, (sum(dbss.TotalSpace/16)- sum(dbss.Used_Space/16)) as 'DataFileFreeSpace(MB)' 
			from @DBSpace dbss
				JOIN master.sys.master_files mf ON rtrim(mf.physical_name)= rtrim(dbss.filename)
			group by mf.database_id, mf.name) ff on ff.database_id = sd.dbid
order by 'DataFileFreeSpace(MB)' desc 



SELECT *
FROM @SizeOutput
ORDER BY 6 DESC

DECLARE @DBName SYSNAME
		, @DataLogicalName SYSNAME
		, @LogLogicalName SYSNAME
		, @DFUsedSpace VARCHAR(16)
		, @LFUsedSpace VARCHAR(16)
		, @DataSQLString NVARCHAR(MAX)
		, @LogSQLString NVARCHAR(MAX)

Declare curSize cursor for 
	select DatabaseName
			, DataLogicalName
			, LogLogicalName
			, CAST([DataFileUsedSpace(MB)] AS INTEGER) + 50
			, CAST([LogFileSize(MB)] AS INTEGER)
	from @SizeOutput
	WHERE [DataFileUsedSpace(MB)] > 100
	ORDER BY 1
open curSize
fetch curSize into @DBName, @DataLogicalName, @LogLogicalName, @DFUsedSpace, @LFUsedSpace
while @@fetch_status = 0
begin
    begin
    --PRINT @Databasename
    SELECT @DataSQLString = 'USE [' + @DBName + ']; DBCC SHRINKFILE (N''' + @DataLogicalName + ''',' + @DFUsedSpace + ');' + CHAR(9)
    SELECT @LogSQLString = 'USE [' + @DBName + ']; DBCC SHRINKFILE (N''' + @LogLogicalName + ''',200);' + CHAR(9)
    PRINT @DataSQLString
    PRINT @LogSQLString
    end
    fetch curSize into @DBName, @DataLogicalName, @LogLogicalName, @DFUsedSpace, @LFUsedSpace
end
close curSize
deallocate curSize 


