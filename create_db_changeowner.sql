-- comment the GO lines for SQL 2005
USE master

Declare @dbname varchar(42)
Declare @cmd varchar(8000)
Declare @user varchar(32)

Select @user = 'sa'

declare dbname cursor for 
select name from sysdatabases where name not in ('master','msdb','model','tempdb')
	order by name

open dbname 
	fetch next from dbname into @dbname 
	while @@fetch_status=0 
begin 

select @cmd =	'USE [' + @dbname + ']' + char(13) +
				--'GO ' + char(13) +
				'exec sp_changedbowner ''' + @user + '''' + char(13)-- +
				--'GO ' + char(13)

--print(@cmd)
exec(@cmd)

fetch next from dbname into @dbname 
end
 
CLOSE dbname 
DEALLOCATE dbname


--sp_helplogins

