/*
select * from filespacestats
order by dbname

exec dbm_filespacestats

*/
------------------------------------------------------------------------------

Declare @dbname varchar(32)
Declare @dataname varchar(48)
Declare @datafile varchar(260)
Declare @logname varchar(48)
Declare @logfile varchar(260)
Declare @sql varchar(1024)

DECLARE db_cursor CURSOR FOR SELECT DISTINCT dbname FROM filespacestats
	WHERE name not in ('dbamaint','master','model','msdb','OPS')

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
			' FOR ATTACH' + char(13) +
			'GO'

print(@sql)

FETCH NEXT FROM db_cursor INTO @dbname

END

CLOSE db_cursor
DEALLOCATE db_cursor

