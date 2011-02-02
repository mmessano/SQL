DECLARE @db varchar(64)

DECLARE dbname cursor FOR
	--SELECT name  from sysdatabases -- 2000
	SELECT name  from sys.databases -- 2005+
	WHERE name NOT IN ('master','model','msdb','tempdb','distribution')
	ORDER BY name

open dbname 
	fetch next from dbname into @db 
	while @@fetch_status=0 

BEGIN 

-- Do stuff
--exec sp_dboption @dbname = @db, @optname = 'autoshrink', @optvalue = 'FALSE'
--exec sp_dboption @dbname = @db, @optname = 'torn page detection', @optvalue = 'TRUE'
--exec sp_dboption @dbname = @db, @optname = 'auto create statistics', @optvalue = 'TRUE'
--exec sp_dboption @dbname = @db, @optname = 'auto update statistics', @optvalue = 'TRUE'

USE master;
ALTER DATABASE '@db'
	SET AUTO_SHRINK OFF;
	SET PAGE_VERIFY TORN_PAGE_DETECTION; -- new option, can also be CHECKSUM(SET PAGE_VERIFY CHECKSUM)
	SET AUTO_CREATE_STATISTICS ON;
	SET AUTO_UPDATE_STATISTICS ON;
GO
--print @db

fetch next from dbname into @db 
end
 
CLOSE dbname 
DEALLOCATE dbname 