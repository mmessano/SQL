Declare @dbname varchar(128)
Declare @cmd varchar(8000)

declare dbname cursor for 
select name from sysdatabases where name NOT LIKE '%Temp%'
	--and name NOT like '%tage'

open dbname 
	fetch next from dbname into @dbname 
	while @@fetch_status=0 
begin 

select @cmd =	'mkdir e:\mssql\bak\' + @dbname

--print(@cmd)
EXEC xp_cmdshell @cmd

fetch next from dbname into @dbname 
end
 
CLOSE dbname 
DEALLOCATE dbname