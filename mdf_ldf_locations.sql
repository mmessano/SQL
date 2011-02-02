Declare @dbname varchar(64)
Declare @CMD varchar(64)

DECLARE DB_cursor CURSOR FOR SELECT name FROM master.dbo.sysdatabases
	WHERE name not in ('master','model','msdb')

OPEN DB_cursor
FETCH NEXT FROM DB_cursor INTO @dbname

WHILE (@@fetch_status <> -1)

Begin
	
	select @CMD = 'USE [' + @dbname + ']'+ char(13) + char(10)
	select @CMD = @CMD + 'exec sp_helpfile'
	exec(@CMD)
	--print(@CMD)

FETCH NEXT FROM DB_cursor INTO @dbname 

End

CLOSE DB_cursor
DEALLOCATE DB_cursor
