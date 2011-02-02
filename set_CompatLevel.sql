
DECLARE @dbname varchar(128)
DECLARE @cmd varchar(8000)

DECLARE dbname CURSOR FOR select name from sys.databases where name LIKE '%_repl'

OPEN dbname
FETCH NEXT FROM dbname INTO @dbname

WHILE (@@fetch_status <> -1)

BEGIN

SELECT @cmd = '
USE [master]
GO
ALTER DATABASE [' + @dbname + '] SET COMPATIBILITY_LEVEL = 100
GO'

PRINT @cmd

FETCH NEXT FROM dbname INTO @dbname

END

CLOSE dbname
DEALLOCATE dbname