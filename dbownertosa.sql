--select Server, DatabaseName, Owner from sqldatabases
--where owner != 'sa'

------------------------------------------------------------------------
/*
--BELLATRIX
USE [Dmart_Click_Data]
exec sp_changedbowner 'sa'

USE [Dmart_Click_Stage]
exec sp_changedbowner 'sa'
*/
USE Status

Declare @Server varchar(32)
Declare @DBName varchar(64)
Declare @owner varchar(2)
Declare @cmd varchar(1024)

SET @owner = 'sa'

DECLARE server_csr CURSOR FOR select distinct Server from sqldatabases
		where owner != 'sa' --AND FileName LIKE '%.mdf' 
		AND Server NOT IN ('XSQLUTIL10','ZABIT','XVSS2')
		order by Server

OPEN server_csr
FETCH NEXT FROM server_csr INTO @Server

WHILE (@@fetch_status <> -1)

BEGIN

print '------------------------------------'
print 'Server = ' + @Server

	DECLARE db_csr CURSOR FOR select Distinct DatabaseName from sqldatabases 
		where Server = @server AND owner != 'sa'

	OPEN db_csr
	FETCH NEXT FROM db_csr INTO @DBName

	WHILE (@@fetch_status <> -1)

	BEGIN

		select @cmd =	' USE [' + @DBName + ']' + char(13) +
						' exec sp_changedbowner ''' + @owner + ''''

		print @cmd 

	FETCH NEXT FROM db_csr INTO @DBName

	END

	CLOSE db_csr
	DEALLOCATE db_csr

FETCH NEXT FROM server_csr INTO @Server

END

CLOSE server_csr
DEALLOCATE server_csr