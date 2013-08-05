/*
select * from filespacestats
order by dbname

exec dbm_filespacestats
*/

Declare @dbname varchar(32)
Declare @dataname varchar(48)
Declare @datafile varchar(260)
Declare @logname varchar(48)
Declare @logfile varchar(260)
Declare @sql varchar(1024)

DECLARE db_cursor CURSOR FOR SELECT DISTINCT dbname FROM filespacestats
	WHERE name not in ('dbamaint','master','model','msdb','OPS','tempdb')

OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @dbname

WHILE (@@fetch_status <> -1)

BEGIN

--print @dbname
SET @datafile = (SELECT Filename from filespacestats where dbname =  @dbname  and FileID = '1')
SET @dataname = (SELECT Name from filespacestats where dbname =  @dbname and FileID = '1')
SET @logfile = (SELECT Filename from filespacestats where dbname =  @dbname  and FileID = '2')
SET @logname = (SELECT Name from filespacestats where dbname =  @dbname  and FileID = '2')

select @sql = 'CREATE DATABASE ' + @dbname + ' ON ' + char(13) +
			char(9) + '(NAME = ''' + @dataname + ''', FILENAME = ''' + @datafile + '''),'  + char(13) +
			char(9) + '(NAME = ''' + RTRIM(@logname) + ''', FILENAME = ''' + RTRIM(@logfile) + ''')' + char(13) +
			' FOR ATTACH' + char(13)

print(@sql)

FETCH NEXT FROM db_cursor INTO @dbname

END

CLOSE db_cursor
DEALLOCATE db_cursor

-------------------------------------------------------------------------------------

 
 DECLARE @DatabaseDetails TABLE (
	DBName NVARCHAR(64)
	, File_LogicalName NVARCHAR(64)
	, File_type_desc NVARCHAR(10)
	, physical_name SYSNAME
 )
 
 INSERT @DatabaseDetails
 SELECT DB_NAME(mf.DATABASE_ID)                  AS DBName
       , name                                    AS File_LogicalName
       , CASE
           WHEN type_desc = 'LOG' THEN '_Log'
           WHEN type_desc = 'ROWS' THEN '_Data'
           ELSE type_desc
         END                                     AS File_type_desc
       , mf.physical_name
FROM   SYS.DM_IO_VIRTUAL_FILE_STATS(NULL, NULL) AS divfs
       JOIN SYS.MASTER_FILES AS mf
         ON mf.DATABASE_ID = divfs.DATABASE_ID
            AND mf.FILE_ID = divfs.FILE_ID
ORDER  BY 4 --num_of_reads DESC  
-------------------------------------
	SELECT DBName
			, File_LogicalName
			, File_type_desc
			, physical_name
	FROM @DatabaseDetails
	WHERE DBName NOT IN ('tempdb', 'model', 'master', 'msdb')
		--AND File_logicalName NOT LIKE '%_Data' AND File_type_desc = '_Data'
		--AND File_logicalName NOT LIKE '%_Log' AND File_type_desc = '_Log'
		--AND physical_name NOT LIKE '%_Data.mdf' AND File_type_desc = '_Data'
		--AND physical_name NOT LIKE '%_Log' AND File_type_desc = '_Log.ldf'
	ORDER BY DBName, File_LogicalName
-------------------------------------
/*
--ALTER DATABASE [AddisonAve32_rpt] MODIFY FILE (NAME=N'AddisonAve32_rpt'
--	, NEWNAME=N'AddisonAve32_rpt_Data')
--GO

--When permanently moving the db files
alter database Boeing4_rpt modify file (name=Boeing4_rpt
	, FILENAME='E:\MSSQL10.MSSQLSERVER\MSSQL\DATA\Boeing4_rpt.mdf');
alter database Boeing4_rpt modify file (name=Boeing4_rpt_Log
	, FILENAME='E:\MSSQL10.MSSQLSERVER\MSSQL\LDF\Boeing4_rpt_Log.ldf');
*/
	SELECT DBName
			, CASE 
					WHEN ( File_type_desc = '_Data' AND File_LogicalName NOT LIKE '%_Data' ) OR ( File_type_desc = '_Log' AND File_LogicalName NOT LIKE '%_Log' )
						THEN 'ALTER DATABASE [' + DBName + '] MODIFY FILE (NAME=N''' + File_LogicalName + ''', NEWNAME=N''' + File_LogicalName + '' + File_type_desc + ''');''' 
					--WHEN File_type_desc = '_Log' AND File_LogicalName NOT LIKE '%_Log' 
					--	THEN 'ALTER DATABASE [' + DBName + '] MODIFY FILE (NAME=N''' + File_LogicalName + ''', NEWNAME=N''AddisonAve32_rpt_Log'');''' 
				--ELSE ''
			END AS IncorrectLogicalName
						
			, CASE 
					WHEN ( File_type_desc = '_Data' AND physical_name NOT LIKE '%_Data.mdf' ) OR ( File_type_desc = '_Log' AND physical_name NOT LIKE DBName + '%_Log.ldf' )
						THEN 'ALTER DATABASE [' + DBName + '] MODIFY FILE (NAME=N''' + File_LogicalName + ''', FILENAME=N''E:\MSSQL10.MSSQLSERVER\MSSQL\' + SUBSTRING(File_type_desc,2,LEN(File_type_desc)) + '\' + DBName + File_type_desc + ( CASE WHEN File_type_desc = '_Data' THEN '.mdf' ELSE '.ldf' END) + ' '');'
				--ELSE ''
			END AS IncorrectPhysicalName
			, File_LogicalName
			, File_type_desc
			, physical_name
	FROM @DatabaseDetails
	WHERE DBName NOT IN ('tempdb', 'model', 'master', 'msdb')
	--GROUP BY IncorrectLogicalName 
	ORDER BY IncorrectLogicalName DESC, physical_name DESC, DBName ASC
-------------------------------------
