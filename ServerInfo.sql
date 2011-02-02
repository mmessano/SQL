/***********************************************************************
** Script  : DocSQL
** Author  : Carlos Eduardo Abramo Pinto - DBACorp Brasil
** E-mail  : ceapinto@hotmail.com
** Date    : 22/04/2003
** Function: Basic documentation of the SQL Server
** Version : 1.02
************************************************************************/
set nocount on
set dateformat dmy

use master
go

print '***************************************************************'
print '                    MANUAL ACTIVITIES                          '
print '                                                               '
print ' A. See database startup parameters                            '
print ' B. See SQL Server Error Log and NT Event Viewer               '
print ' C. See authentication mode ( NATIVE or MIXED )                '
print ' D. See SQL Server and SQL Agent services account startup      '
print ' E. See SQL Mail configuration 			              '
print ' F. See backup politic ( full and transaction )                '
print '***************************************************************'

print ''
print '1. General Info'
print '*********************'
print ''

print 'Server Name...............: ' + convert(varchar(30),@@SERVERNAME)        
print 'Instance..................: ' + convert(varchar(30),@@SERVICENAME)       
print 'Current Date Time.........: ' + convert(varchar(30),getdate(),113)
print 'User......................: ' + USER_NAME()
go

print ''
print '1.1  Database and Operational System versions.'
print '----------------------------------------------'
print ''

select @@version
go

exec master..xp_msver
go

print ''
print '1.2  Miscellaneous'
print '---------------------------'
print ''

select convert(varchar(30),login_time,109) as 'Server Initialization ' from master..sysprocesses where spid = 1

print 'Number of connections..: ' + convert(varchar(30),@@connections)        
print 'Language...............: ' + convert(varchar(30),@@language)          
print 'Language Id............: ' + convert(varchar(30),@@langid)            
print 'Lock Timeout...........: ' + convert(varchar(30),@@LOCK_TIMEOUT)      
print 'Maximum of connections.: ' + convert(varchar(30),@@MAX_CONNECTIONS)   
print 'Server Name............: ' + convert(varchar(30),@@SERVERNAME)        
print 'Instance...............: ' + convert(varchar(30),@@SERVICENAME)       
print ''
print 'CPU Busy...........: ' + convert(varchar(30),@@CPU_BUSY/1000)        
print 'CPU Idle...........: ' + convert(varchar(30),@@IDLE/1000)
print 'IO Busy............: ' + convert(varchar(30),@@IO_BUSY/1000)
print 'Packets received...: ' + convert(varchar(30),@@PACK_RECEIVED)
print 'Packets sent.......: ' + convert(varchar(30),@@PACK_SENT)
print 'Packets w errors...: ' + convert(varchar(30),@@PACKET_ERRORS)
print 'TimeTicks..........: ' + convert(varchar(30),@@TIMETICKS)
print 'IO Errors..........: ' + convert(varchar(30),@@TOTAL_ERRORS)
print 'Total Read.........: ' + convert(varchar(30),@@TOTAL_READ)
print 'Total Write........: ' + convert(varchar(30),@@TOTAL_WRITE)
go

----------------------------------------------------------------------------------------------------------
print ''
print '2. Server Parameters'
print '*************************'
print ''

--exec sp_configure 'show advanced options',1
exec sp_configure
go
----------------------------------------------------------------------------------------------------------
print ''
print '3. Databases parameters'
print '***************************'
print ''

exec sp_helpdb
go

SELECT LEFT(name,30) AS DB, 
        SUBSTRING(CASE status & 1 WHEN 0 THEN '' ELSE ',autoclose' END + 
        CASE status & 4 WHEN 0 THEN '' ELSE ',select into/bulk copy' END + 
        CASE status & 8 WHEN 0 THEN '' ELSE ',trunc. log on chkpt' END + 
        CASE status & 16 WHEN 0 THEN '' ELSE ',torn page detection' END + 
        CASE status & 32 WHEN 0 THEN '' ELSE ',loading' END + 
        CASE status & 64 WHEN 0 THEN '' ELSE ',pre-recovery' END + 
        CASE status & 128 WHEN 0 THEN '' ELSE ',recovering' END + 
        CASE status & 256 WHEN 0 THEN '' ELSE ',not recovered' END + 
        CASE status & 512 WHEN 0 THEN '' ELSE ',offline' END + 
        CASE status & 1024 WHEN 0 THEN '' ELSE ',read only' END + 
        CASE status & 2048 WHEN 0 THEN '' ELSE ',dbo USE only' END + 
        CASE status & 4096 WHEN 0 THEN '' ELSE ',single user' END + 
        CASE status & 32768 WHEN 0 THEN '' ELSE ',emergency mode' END + 
        CASE status & 4194304 WHEN 0 THEN '' ELSE ',autoshrink' END + 
        CASE status & 1073741824 WHEN 0 THEN '' ELSE ',cleanly shutdown' END + 
        CASE status2 & 16384 WHEN 0 THEN '' ELSE ',ANSI NULL default' END + 
        CASE status2 & 65536 WHEN 0 THEN '' ELSE ',concat NULL yields NULL' END + 
        CASE status2 & 131072 WHEN 0 THEN '' ELSE ',recursive triggers' END + 
        CASE status2 & 1048576 WHEN 0 THEN '' ELSE ',default TO local cursor' END + 
        CASE status2 & 8388608 WHEN 0 THEN '' ELSE ',quoted identifier' END + 
        CASE status2 & 33554432 WHEN 0 THEN '' ELSE ',cursor CLOSE on commit' END + 
        CASE status2 & 67108864 WHEN 0 THEN '' ELSE ',ANSI NULLs' END + 
        CASE status2 & 268435456 WHEN 0 THEN '' ELSE ',ANSI warnings' END + 
        CASE status2 & 536870912 WHEN 0 THEN '' ELSE ',full text enabled' END, 
2,8000) AS Descr 
FROM master..sysdatabases 
go
----------------------------------------------------------------------------------------------------------
print ''
print '4. LOG utilization'
print '****************************'
print ''

dbcc sqlperf(logspace)
go
----------------------------------------------------------------------------------------------------------
print ''
print '5. Datafiles list'
print '***********************'
print ''

if exists (select [id] from tempdb..sysobjects where [id] = OBJECT_ID ('tempdb..#TempForFileStats '))
DROP TABLE #TempForFileStats 

if exists (select [id] from tempdb..sysobjects where [id] = OBJECT_ID ('tempdb..#TempForDataFile'))
DROP TABLE #TempForDataFile

if exists (select [id] from tempdb..sysobjects where [id] = OBJECT_ID ('tempdb..#TempForLogFile'))
DROP TABLE #TempForLogFile

DECLARE @DBName nvarchar(20)
DECLARE @SQLString nvarchar (2000)
DECLARE c_db CURSOR FOR
    SELECT name
    FROM master.dbo.sysdatabases
    WHERE status&512 = 0 

CREATE TABLE #TempForFileStats([Server Name]          nvarchar(40),
                               [Database Name]        nvarchar(20),
                               [File Name]            nvarchar(128),
                               [Usage Type]           varchar (6),
                               [Size (MB)]            real, 
                               [Space Used (MB)]      real,
                               [MaxSize (MB)]         real,
                               [Next Allocation (MB)] real, 
                               [Growth Type]          varchar (12),
                               [File Id]              smallint,
                               [Group Id]             smallint,
                               [Physical File]        nvarchar (260),
                               [Date Checked]         datetime) 

CREATE TABLE #TempForDataFile ([File Id]             smallint,
                               [Group Id]            smallint,
                               [Total Extents]       int,
                               [Used Extents]        int,
                               [File Name]           nvarchar(128),
                               [Physical File]       nvarchar(260))

CREATE TABLE #TempForLogFile  ([File Id]             int, 
                               [Size (Bytes)]        real, 
                               [Start Offset]        varchar(30), 
                               [FSeqNo]              int, 
                               [Status]              int, 
                               [Parity]              smallint, 
                               [CreateTime]          varchar(20))   

OPEN c_db
FETCH NEXT FROM c_db INTO @DBName
WHILE @@FETCH_STATUS = 0
   BEGIN
      SET @SQLString = 'SELECT @@SERVERNAME                     as  ''ServerName'', '          + 
                       '''' + @DBName + '''' + '                as  ''Database'', '            +  
                       '        f.name, '                                                      +
                       '       CASE '                                                          +
                       '          WHEN (64 & f.status) = 64 THEN ''Log'' '                     +
                       '          ELSE ''Data'' '                                              + 
                       '       END                              as ''Usage Type'', '           +
                       '        f.size*8/1024.00                as ''Size (MB)'', '            +
                       '        NULL                            as ''Space Used (MB)'', '      +
                       '        CASE f.maxsize '                                               +
                       '           WHEN -1 THEN  -1 '                                        +
                       '           WHEN  0 THEN  f.size*8/1024.00  '                           +
                       '           ELSE          f.maxsize*8/1024.00 '                         +
                       '        END                             as ''Max Size (MB)'', '        +
                       '        CASE '                                                         +
                       '           WHEN (1048576&f.status) = 1048576 THEN (growth/100.00)*(f.size*8/1024.00) ' + 
                       '           WHEN f.growth =0                 THEN 0 '                +
                       '           ELSE                                   f.growth*8/1024.00 ' +
                       '        END                             as ''Next Allocation (MB)'', ' +
                       '       CASE  '                                                         +
                       '          WHEN (1048576&f.status) = 1048576 THEN ''Percentage'' '      +
                       '          ELSE ''Pages'' '                                             +
                       '       END                              as ''Usage Type'', '           +
                       '       f.fileid, '                                                     +
                       '       f.groupid, '                                                    +
                       '       filename, '                                                     +
                       '       getdate() '                                                     +
                       ' FROM ' + @DBName + '.dbo.sysfiles f' 
      INSERT #TempForFileStats 
      EXECUTE(@SQLString)
      ------------------------------------------------------------------------
      SET @SQLString = 'USE ' + @DBName + ' DBCC SHOWFILESTATS'
      INSERT #TempForDataFile
      EXECUTE(@SQLString)
      --
      UPDATE #TempForFileStats
      SET [Space Used (MB)] = s.[Used Extents]*64/1024.00
      FROM #TempForFileStats f,
           #TempForDataFile  s
      WHERE f.[File Id]       = s.[File Id]
        AND f.[Group Id]      = s.[Group Id]
        AND f.[Database Name] = @DBName
      --
      TRUNCATE TABLE #TempForDataFile
      -------------------------------------------------------------------------
      SET @SQLString = 'USE ' + @DBName + ' DBCC LOGINFO'
      INSERT #TempForLogFile
      EXECUTE(@SQLString)      
      --
      UPDATE #TempForFileStats 
      SET [Space Used (MB)] = (SELECT (MIN(l.[Start Offset]) + 
                                       SUM(CASE 
                                              WHEN l.Status <> 0 THEN  l.[Size (Bytes)] 
                                              ELSE           0 
                                           END))/1048576.00
                               FROM #TempForLogFile l
                               WHERE l.[File Id] = f.[File Id])
      FROM #TempForFileStats f
      WHERE f.[Database Name] = @DBName
        AND f.[Usage Type]    = 'Log'
      --
      TRUNCATE TABLE #TempForLogFile 
      -------------------------------------------------------------------------
      FETCH NEXT FROM c_db INTO @DBName
   END
DEALLOCATE c_db

SELECT * FROM #TempForFileStats
------------
DROP TABLE #TempForFileStats 
DROP TABLE #TempForDataFile
DROP TABLE #TempForLogFile
go
----------------------------------------------------------------------------------------------------------
print ''
print '6. IO per datafile'
print '******************'
print ''


if exists (select [id] from tempdb..sysobjects where [id] = OBJECT_ID ('tempdb..#TBL_DATABASEFILES'))
   DROP TABLE #TBL_DATABASEFILES


if exists (select [id] from tempdb..sysobjects where [id] = OBJECT_ID ('tempdb..#TBL_FILESTATISTICS'))
   DROP TABLE #TBL_FILESTATISTICS


DECLARE @INT_LOOPCOUNTER INTEGER
DECLARE @INT_MAXCOUNTER INTEGER
DECLARE @INT_DBID INTEGER
DECLARE @INT_FILEID INTEGER
DECLARE @SNM_DATABASENAME SYSNAME
DECLARE @SNM_FILENAME SYSNAME
DECLARE @NVC_EXECUTESTRING NVARCHAR(500)

DECLARE @MTB_DATABASES TABLE ( 
ID INT IDENTITY,
DBID INT,
DBNAME SYSNAME )

CREATE TABLE  #TBL_DATABASEFILES (
ID INT IDENTITY,
DBID INT,
FILEID INT,
FILENAME SYSNAME,
DATABASENAME SYSNAME)

INSERT INTO @MTB_DATABASES (DBID,DBNAME) SELECT DBID,NAME FROM MASTER.DBO.SYSDATABASES ORDER BY DBID
SET @INT_LOOPCOUNTER = 1
SELECT @INT_MAXCOUNTER=MAX(ID) FROM @MTB_DATABASES
WHILE @INT_LOOPCOUNTER <= @INT_MAXCOUNTER
BEGIN
   SELECT @INT_DBID = DBID,@SNM_DATABASENAME=DBNAME FROM @MTB_DATABASES WHERE ID = @INT_LOOPCOUNTER
   SET @NVC_EXECUTESTRING = 'INSERT INTO #TBL_DATABASEFILES(DBID,FILEID,FILENAME,DATABASENAME) SELECT '+STR(@INT_DBID)+',FILEID,NAME,'''+@SNM_DATABASENAME+''' AS DATABASENAME FROM ['+@SNM_DATABASENAME+'].DBO.SYSFILES'
   EXEC SP_EXECUTESQL @NVC_EXECUTESTRING
   SET @INT_LOOPCOUNTER = @INT_LOOPCOUNTER + 1
END
--'OK WE NOW HAVE ALL THE DATABASES AND FILENAMES ETC....

CREATE TABLE #TBL_FILESTATISTICS (
ID INT IDENTITY,
DBID INT,
FILEID INT,
DATABASENAME SYSNAME,
FILENAME SYSNAME,
SAMPLETIME DATETIME,
NUMBERREADS BIGINT,
NUMBERWRITES BIGINT,
BYTESREAD BIGINT,
BYTESWRITTEN BIGINT,
IOSTALLMS BIGINT)

SELECT @INT_MAXCOUNTER=MAX(ID) FROM #TBL_DATABASEFILES
SET @INT_LOOPCOUNTER = 1
WHILE @INT_LOOPCOUNTER <= @INT_MAXCOUNTER
BEGIN
   SELECT @INT_DBID = DBID,@INT_FILEID=FILEID,@SNM_DATABASENAME=DATABASENAME,@SNM_FILENAME=FILENAME FROM #TBL_DATABASEFILES WHERE ID = @INT_LOOPCOUNTER
   INSERT INTO #TBL_FILESTATISTICS(DBID,FILEID,SAMPLETIME,NUMBERREADS,NUMBERWRITES,BYTESREAD,BYTESWRITTEN,IOSTALLMS,DATABASENAME,FILENAME)
   SELECT DBID,FILEID,GETDATE(),NUMBERREADS,NUMBERWRITES,BYTESREAD,BYTESWRITTEN,IOSTALLMS,@SNM_DATABASENAME AS DATABASENAME,@SNM_FILENAME AS FILENAME FROM :: FN_VIRTUALFILESTATS(@INT_DBID,@INT_FILEID)
   SET @INT_LOOPCOUNTER = @INT_LOOPCOUNTER + 1
END
select * from #TBL_FILESTATISTICS

drop table #TBL_DATABASEFILES
drop table #TBL_FILESTATISTICS
go
---------------------------------------------------------------------------------------
print ''
print '7. List of last backup full''s'
print '*************************************'
print ''

select 	SUBSTRING(s.name,1,40)			AS	'Database',
	CAST(b.backup_start_date AS char(11)) 	AS 	'Backup Date  ',
	CASE WHEN b.backup_start_date > DATEADD(dd,-1,getdate())
		THEN 'Backup is current within a day'
	     WHEN b.backup_start_date > DATEADD(dd,-7,getdate())
		THEN 'Backup is current within a week'
	     ELSE '*****CHECK BACKUP!!!*****'
		END
						AS 'Comment'

from 	master..sysdatabases	s
LEFT OUTER JOIN	msdb..backupset b
	ON s.name = b.database_name
	AND b.backup_start_date = (SELECT MAX(backup_start_date)
					FROM msdb..backupset
					WHERE database_name = b.database_name
						AND type = 'D')		-- full database backups only, not log backups
WHERE	s.name <> 'tempdb'

ORDER BY 	s.name
go
---------------------------------------------------------------------------------------------------------- 
print ''
print '8. List of logins'
print '********************'
print ''

exec sp_helplogins
go
----------------------------------------------------------------------------------------------------------
print ''
print '9. List of users per role'
print '*******************************'
print ''

exec sp_helpsrvrolemember
go
----------------------------------------------------------------------------------------------------------
print ''
print '10.List of special users per database'
print '*************************************'
print ''


declare @name sysname,
	@SQL  nvarchar(600)

if exists (select [id] from tempdb..sysobjects where [id] = OBJECT_ID ('tempdb..#tmpTable'))
	drop table #tmpTable
	
CREATE TABLE #tmpTable (
	[DATABASE_NAME] sysname NOT NULL ,
	[USER_NAME] sysname NOT NULL,
	[ROLE_NAME] sysname NOT NULL)

declare c1 cursor for 
	select name from master.dbo.sysdatabases
			
open c1
fetch c1 into @name
while @@fetch_status >= 0
begin
	select @SQL = 
		'insert into #tmpTable
		 select N'''+ @name + ''', a.name, c.name
		from ' + QuoteName(@name) + '.dbo.sysusers a 
		join ' + QuoteName(@name) + '.dbo.sysmembers b on b.memberuid = a.uid
		join ' + QuoteName(@name) + '.dbo.sysusers c on c.uid = b.groupuid
		where a.name != ''dbo'''

		/* 	Insert row for each database */
		execute (@SQL)
	fetch c1 into @name
end
close c1
deallocate c1
	
select * from #tmpTable

drop table #tmpTable
go
----------------------------------------------------------------------------------------------------------
print ''
print '11. Information about remote servers '
print '*****************************************'
print ''

exec sp_helplinkedsrvlogin
exec sp_helpremotelogin

go
----------------------------------------------------------------------------------------------------------
print ''
print '12. List of jobs '
print '*******************'
print ''

exec msdb..sp_help_job
go
----------------------------------------------------------------------------------------------------------

print ''
print '13. Cache Hit Ratio '
print '*******************'
print ''

select 	distinct counter_name,
	(select isnull(sum(convert(dec(15,0),B.cntr_value)),0) 
	from 	master..sysperfinfo as B (nolock) 
	where 	Lower(B.counter_name) like '%hit ratio%'
	and	A.counter_name = B.counter_name) as CurrHit,
	(select isnull(sum(convert(dec(15,0),B.cntr_value)),0) 
	from 	master..sysperfinfo as B (nolock) 
	where 	Lower(B.counter_name) like '%hit ratio base%'
	and	lower(B.counter_name) = (lower(ltrim(rtrim(A.counter_name))) + ' base')) as CurrBase,
	(select isnull(sum(convert(dec(15,0),B.cntr_value)),0) 
	from 	master..sysperfinfo as B (nolock) 
	where 	Lower(B.counter_name) like '%hit ratio%'
	and	A.counter_name = B.counter_name) / 
	(select isnull(sum(convert(dec(15,0),B.cntr_value)),0) 
	from 	master..sysperfinfo as B (nolock) 
	where 	Lower(B.counter_name) like '%hit ratio base%'
	and	lower(B.counter_name) = (lower(ltrim(rtrim(A.counter_name))) + ' base')) as HitRatio
from 	master..sysperfinfo as A (nolock) 
where 	Lower(A.counter_name) like '%hit ratio%'
and 	Lower(A.counter_name) not like '%hit ratio base%' 

-- Audit list as a double verification

select counter_name,isnull(sum(convert(dec(15,0),cntr_value)),0) as Value
from 	master..sysperfinfo (nolock) 
where 	Lower(counter_name) like '%hit ratio%'
or 	Lower(counter_name) like '%hit ratio base%' 
group by counter_name

go
----------------------------------------------------------------------------------------------------------

print ''
print '14. SP_WHO '
print '***********'
print ''
exec sp_who
exec sp_who2
go

----------------------------------------------------------------------------------------------------------

print ''
print '14. SP_LOCKS '
print '***********'
print ''
exec sp_locks

go

print '******************************************************************'
print '                              FIM                                 ' 
print '******************************************************************'
----------------------------------------------------------------------------------------------------------
set nocount off

