set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go


-- =============================================
-- Author:		mmessano
-- Create date: 8/22/2007
-- Description:
-- =============================================
ALTER PROCEDURE [dbo].[sp_validate_perms]

AS
BEGIN
	SET NOCOUNT ON;
/*

Audit SQL Server user ID

Author      Simon Facer
Date        01/04/2007

This script will generate an audit of SQL Server logins, as well
as a listing of the database user ID's and the SQL Server login
that each DB user ID maps to.

In the database user ID results, [Server Login] = '** Orphaned **'
indicates that there is no matching Server login.

This script was originally designed for SQL 2000, but works just as
well in SQL 2005.
*/


IF  EXISTS (SELECT * FROM tempdb.dbo.sysobjects WHERE name = 'Users' AND type in (N'U'))
   BEGIN
      DROP TABLE Users
   END

IF  EXISTS (SELECT * FROM tempdb.dbo.sysobjects WHERE name = 'DBUsers' AND type in (N'U'))
   BEGIN
      TRUNCATE TABLE DBUsers
   END
ELSE
   BEGIN
		CREATE TABLE DBUsers (
			[server_name]	    VARCHAR(64),
			[Database]          VARCHAR(64),
			[Database_User_ID]  VARCHAR(64),
			[Server Login]      VARCHAR(64),
			[Database Role]     VARCHAR(64),
			[timestamp]	    datetime)
	END

-- ***************************************************************************
-- Declare local variables
DECLARE @DBName             VARCHAR(32)
DECLARE @SQLCmd             VARCHAR(1024)
-- ***************************************************************************

-- ***************************************************************************
-- Get the SQL Server logins
SELECT  sid,
        loginname AS [Login Name],
        dbname AS [Default Database],
        CASE isntname
            WHEN 1 THEN 'AD Login'
            ELSE 'SQL Login'
        END AS [Login Type],
        CASE
            WHEN isntgroup = 1 THEN 'AD Group'
            WHEN isntuser = 1 THEN 'AD User'
            ELSE ''
        END AS [AD Login Type],
        CASE sysadmin
            WHEN 1 THEN 'Yes'
            ELSE 'No'
        END AS [sysadmin],
        CASE [securityadmin]
            WHEN 1 THEN 'Yes'
            ELSE 'No'
        END AS [securityadmin],
        CASE [serveradmin]
            WHEN 1 THEN 'Yes'
            ELSE 'No'
        END AS [serveradmin],
        CASE [setupadmin]
            WHEN 1 THEN 'Yes'
            ELSE 'No'
        END AS [setupadmin],
        CASE [processadmin]
            WHEN 1 THEN 'Yes'
            ELSE 'No'
        END AS [processadmin],
        CASE [diskadmin]
            WHEN 1 THEN 'Yes'
            ELSE 'No'
        END AS [diskadmin],
        CASE [dbcreator]
            WHEN 1 THEN 'Yes'
            ELSE 'No'
        END AS [dbcreator],
        CASE [bulkadmin]
            WHEN 1 THEN 'Yes'
            ELSE 'No'
        END AS [bulkadmin]
INTO Users
FROM master.dbo.syslogins

SELECT  [Login Name],
        [Default Database],
        [Login Type],
        [AD Login Type],
        [sysadmin],
        [securityadmin],
        [serveradmin],
        [setupadmin],
        [processadmin],
        [diskadmin],
        [dbcreator],
        [bulkadmin]
FROM Users
ORDER BY [Login Type], [AD Login Type], [Login Name]


-- ***************************************************************************
-- Declare a cursor to loop through all the databases on the server
DECLARE csrDB CURSOR FOR
    SELECT name
        FROM master.dbo.sysdatabases
        WHERE name NOT IN ('master', 'model', 'msdb', 'tempdb')


-- ***************************************************************************
-- Open the cursor and get the first database name
OPEN csrDB
FETCH NEXT
    FROM csrDB
    INTO @DBName


-- ***************************************************************************
-- Loop through the cursor
WHILE @@FETCH_STATUS = 0
    BEGIN


-- ***************************************************************************
--
        SELECT @SQLCmd = 'INSERT DBUsers ' +
                         '  SELECT ''' + @@servername + ''' AS [Server_Name],'+
						 '			''' + @DBName + ''' AS [Database],' +
                         '       su.[name] AS [Database_User_ID], ' +
                         '       COALESCE (u.[Login Name], ''** Orphaned **'') AS [Server Login], ' +
                         '       COALESCE (sug.name, ''Public'') AS [Database Role], ' +
						 '		 GetDate() as timestamp' +
                         '    FROM [' + @DBName + '].[dbo].[sysusers] su' +
                         '        LEFT OUTER JOIN Users u' +
                         '            ON su.sid = u.sid' +
                         '        LEFT OUTER JOIN ([' + @DBName + '].[dbo].[sysmembers] sm ' +
                         '                             INNER JOIN [' + @DBName + '].[dbo].[sysusers] sug  ' +
                         '                                 ON sm.groupuid = sug.uid)' +
                         '            ON su.uid = sm.memberuid ' +
                         '    WHERE su.hasdbaccess = 1' +
                         '      AND su.[name] != ''dbo'' '

        EXEC (@SQLCmd)

-- ***************************************************************************
-- Get the next database name
        FETCH NEXT
            FROM csrDB
            INTO @DBName

-- ***************************************************************************
-- End of the cursor loop
    END

-- ***************************************************************************
-- Close and deallocate the CURSOR
CLOSE csrDB
DEALLOCATE csrDB

-- ***************************************************************************
-- Return the Database User data
SELECT *
    FROM DBUsers
    ORDER BY [Database], [Database_User_ID]

END
