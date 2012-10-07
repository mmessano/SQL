SELECT SPECIFIC_NAME
	, ROUTINE_CATALOG
	, ROUTINE_SCHEMA
	, ROUTINE_NAME
	, ROUTINE_DEFINITION
	, CREATED
	, LAST_ALTERED 
FROM INFORMATION_SCHEMA.ROUTINES
WHERE master.dbo.RegExpLike(ROUTINE_DEFINITION, N'(\w+)\.(\w+)\.(\w+)\.(\w+)') = 1 
--------------------------------------------------------------------------------
SELECT SPECIFIC_NAME
	, ROUTINE_CATALOG
	, ROUTINE_SCHEMA
	, ROUTINE_NAME
	, ROUTINE_DEFINITION
	, CREATED
	, LAST_ALTERED 
FROM INFORMATION_SCHEMA.ROUTINES
WHERE EXISTS (SELECT * FROM master.dbo.RegExpMatches(ROUTINE_DEFINITION,N'(\w+)\.(\w+)\.(\w+)\.(\w+)'))
ORDER BY 1
--------------------------------------------------------------------------------
/*
select ROUTINE_NAME
from INFORMATION_SCHEMA.ROUTINES
where ROUTINE_TYPE = N'PROCEDURE'
    and MASTER.dbo.RegExpLike( ROUTINE_NAME, 
        N'^usp_(Insert|Update|Delete|Select)([A-Z][a-z]+)+$' ) = 1
*/
DECLARE @Tables TABLE (
	DBName NVARCHAR(128)
	, TableName NVARCHAR(MAX)
	, CreateDate DATETIME
	, ModifyDate DATETIME
)

DECLARE @DB NVARCHAR(128)
DECLARE @SQL NVARCHAR(MAX)
DECLARE @iSQL NVARCHAR(MAX)
DECLARE @LinkedServer NVARCHAR(MAX)

DECLARE LS_cur CURSOR FOR
	SELECT server_name 
	FROM dbamaint.dbo.LinkedServers 
	WHERE server_name NOT LIKE '%_RW'
	AND server_name NOT LIKE '%_lnk'
	AND server_name LIKE '%_SA'
	ORDER BY 1

OPEN LS_cur
FETCH NEXT FROM LS_cur INTO @LinkedServer
WHILE (@@FETCH_STATUS <> -1)

BEGIN
SELECT @SQL = '
	DECLARE @DB NVARCHAR(128)
	DECLARE @iSQL NVARCHAR(MAX)
	
	DECLARE DB_cur CURSOR FOR
		SELECT name FROM ' + @LinkedServer + '.master.sys.databases
		WHERE database_id > 4
		AND master.dbo.RegExpLike(name, ''^[0-9]'') = 0
		ORDER BY 1

	OPEN DB_cur
	FETCH NEXT FROM DB_cur INTO @DB
	WHILE (@@FETCH_STATUS <> -1)

	BEGIN
		PRINT ''Checking ' + @LinkedServer + '.'' + @DB
		SELECT @iSQL = ''
			select '''''' + @DB + '''''' AS DBName
			, name 
			, create_date
			, modify_date
			from ' + @LinkedServer + '.''
		SELECT @iSQL = @iSQL + @DB + ''.sys.tables
			WHERE type = ''''U''''
			AND master.dbo.RegExpLike(name, ''''[0-9]$'''') = 1
			ORDER BY name''

		--PRINT(@iSQL)
		EXEC(@iSQL)
		PRINT ''Finished checking ' + @LinkedServer + '.'' + @DB
		
		FETCH NEXT FROM DB_cur INTO @DB
	END

	CLOSE DB_cur
	DEALLOCATE DB_cur'

--PRINT(@SQL)
INSERT INTO @Tables
EXEC(@SQL)

FETCH NEXT FROM LS_cur INTO @LinkedServer
END

CLOSE LS_cur
DEALLOCATE LS_cur

SELECT * FROM @Tables
--------------------------------------------------------------------------------
--sp_MSForEachDB '
--USE ?
SET NOCOUNT ON
DECLARE @Name NVARCHAR(128)
DECLARE @Def NVARCHAR(MAX) 

DECLARE @Results TABLE (
	[DBName] SYSNAME
	, [SprocName] NVARCHAR(128)
	, [Index] INT
	, [Length] INT
	, [Value] NVARCHAR(128)
)

DECLARE Def_cur CURSOR FOR
	SELECT SPECIFIC_NAME, ROUTINE_DEFINITION
	FROM INFORMATION_SCHEMA.ROUTINES
	
OPEN Def_cur
FETCH NEXT FROM Def_cur INTO @Name, @Def
WHILE (@@FETCH_STATUS <> -1)

BEGIN

-- 4-part names
INSERT INTO @Results
SELECT DB_NAME() AS DBName
	, @Name AS SprocName
	, * 
FROM master.dbo.RegExpMatches(@Def,N'(\w+)\.(\w+)\.(\w+)\.(\w+)')

-- 3-part names
INSERT INTO @Results
SELECT DB_NAME() AS DBName
	, @Name AS SprocName
	, * 
FROM master.dbo.RegExpMatches(@Def,N'(\w+)\.(\w+)\.(\w+)')

FETCH NEXT FROM Def_cur INTO @Name, @Def
END

CLOSE Def_cur
DEALLOCATE Def_cur

SELECT * FROM @Results
ORDER BY 2,3,5
--'
--------------------------------------------------------------------------------
