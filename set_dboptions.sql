
--  sp_MSforeachdb "print '?' EXEC sp_dboption '?'"

DECLARE @db varchar(64)

DECLARE dbname cursor FOR
	SELECT name  from sysdatabases -- 2000
	--SELECT name  from sys.databases -- 2005+
	WHERE name NOT IN ('master','model','msdb','tempdb','distribution')
	ORDER BY name

open dbname 
	fetch next from dbname into @db 
	while @@fetch_status=0 

BEGIN 

-- Do stuff
exec sp_dboption @dbname = @db, @optname = 'autoshrink', @optvalue = 'FALSE'
exec sp_dboption @dbname = @db, @optname = 'torn page detection', @optvalue = 'TRUE'
exec sp_dboption @dbname = @db, @optname = 'auto create statistics', @optvalue = 'TRUE'
exec sp_dboption @dbname = @db, @optname = 'auto update statistics', @optvalue = 'TRUE'

--print @db

fetch next from dbname into @db 
end
 
CLOSE dbname 
DEALLOCATE dbname 