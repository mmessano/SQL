-- Generates a list of server/database modify statements for any database
-- not owned by SA that is found in the SQL_OverView..DatabaseOwners table

USE master

Declare @servername varchar(16)
Declare @dbname varchar(42)
Declare @cmd varchar(8000)
Declare @user varchar(32)

Select @user = 'sa'

Declare servername cursor for
Select Distinct server_name from SQL_Overview..DatabaseOwners 
		where sys_databases_owner != 'sa'
		AND server_name NOT IN ('XSQLUTIL10','ZABIT')
	order by Server_Name

open servername
	fetch next from servername into @servername
	while @@fetch_status=0
begin	
print('--' + @servername)
	declare dbname cursor for 
	select database_name
		from SQL_Overview..DatabaseOwners 
		where sys_databases_owner != 'sa'
		AND server_name = @servername
	order by database_name

	open dbname 
		fetch next from dbname into @dbname 
		while @@fetch_status=0 
	begin 

	select @cmd =	'USE [' + @dbname + ']' + char(13) +
					--'GO ' + char(13) +
					'exec sp_changedbowner ''' + @user + '''' + char(13)-- +
					--'GO ' + char(13)

	print(@cmd)
	--exec(@cmd)

	fetch next from dbname into @dbname 
	end
	 
	CLOSE dbname 
	DEALLOCATE dbname

fetch next from servername into @servername
end

CLOSE servername
DEALLOCATE servername