/*
select * from sqldatabases
where Server IN ('ISQLCBS510','ISQLDEV510','ISQLPA10','ISQLPERF510','VMdev2')
AND Recovery != 'SIMPLE'
AND FileName LIKE '%.mdf'


USE [master]
GO
ALTER DATABASE [SQL_Overview] SET RECOVERY SIMPLE WITH NO_WAIT
GO
ALTER DATABASE [SQL_Overview] SET RECOVERY SIMPLE 
GO
*/
-----------------------------------------------------------------------------

Declare @Server varchar(32)
Declare @DBName varchar(64)
Declare @cmd varchar(1024)


DECLARE server_csr CURSOR FOR select distinct Server from sqldatabases
		where Server IN ('ISQLCBS510','ISQLDEV510','ISQLPA10','ISQLPERF510','VMdev2')
		order by Server

OPEN server_csr
FETCH NEXT FROM server_csr INTO @Server

WHILE (@@fetch_status <> -1)

BEGIN

print '------------------------------------'
print 'Server = ' + @Server

	DECLARE db_csr CURSOR FOR select distinct DatabaseName from sqldatabases 
		where Server = @server AND Recovery != 'SIMPLE'

	OPEN db_csr
	FETCH NEXT FROM db_csr INTO @DBName

	WHILE (@@fetch_status <> -1)

	BEGIN

		select @cmd =	' USE [master]' + char(13) +
						' ALTER DATABASE [' + @DBName + '] SET RECOVERY SIMPLE WITH NO_WAIT ' + char(13) +
						' ALTER DATABASE [' + @DBName + '] SET RECOVERY SIMPLE ' + char(13) 

		print @cmd 

	FETCH NEXT FROM db_csr INTO @DBName

	END

	CLOSE db_csr
	DEALLOCATE db_csr

FETCH NEXT FROM server_csr INTO @Server

END

CLOSE server_csr
DEALLOCATE server_csr