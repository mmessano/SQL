/*
USE dbamaint 
GO
dbm_PermissionsAll


SELECT * FROM DBUsers
WHERE ServerLogin like '%Orphaned%'
AND DataBaseUserID NOT IN ('guest','INFORMATION_SCHEMA','sys','cdc','BUILTIN\Administrators')
ORDER BY 1,3,4,6
*/

Declare @ServerName varchar(64)
Declare @dbname varchar(64)
Declare @DatabaseuserID varchar(128)
Declare @cmd varchar(8000)

declare dbname cursor for 
	select ServerName, DBName, DatabaseuserID from DBUsers
		where ServerLogin = '** Orphaned **'
		AND DatabaseUserID NOT IN ('guest','INFORMATION_SCHEMA','sys','cdc','BUILTIN\Administrators')
		--AND DatabaseUserID = 'HOME_OFFICE\Dex Imp Service'
		order by 1
	
open dbname 
	fetch next from dbname into @ServerName, @dbname, @DatabaseuserID 
	while @@fetch_status=0 
begin 


select @cmd = 
'
-- ' + @ServerName + '
USE [' + @dbname + ']
GO
DROP SCHEMA [' + @DatabaseuserID + ']
GO
DROP USER [' + @DatabaseuserID + ']
GO
'

print @cmd
--exec(@cmd)

fetch next from dbname into @ServerName, @dbname, @DatabaseuserID 
end
 
CLOSE dbname 
DEALLOCATE dbname 

print char(10)
print
'IF  EXISTS (SELECT * FROM sys.server_principals WHERE name = N''' + @DatabaseuserID + ''')
DROP LOGIN [' + @DatabaseuserID + ']
GO'