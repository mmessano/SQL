--Written By Bradley Morris
--In Query Analyzer be sure to go to
--Query -> Current Connection Options -> Advanced (Tab)
--and set Maximum characters per column
--to a high number, such as 10000, so
--that all the code will be displayed.



DECLARE @DatabaseUserName [sysname]
SET @DatabaseUserName = 'home_office\dexprosql'

SET NOCOUNT ON
DECLARE
@errStatement [varchar](8000),
@msgStatement [varchar](8000),
@DatabaseUserID [smallint],
@ServerUserName [sysname],
@RoleName [varchar](8000),
@ObjectID [int],
@ObjectName [varchar](261)

SELECT
@DatabaseUserID = [sysusers].[uid],
@ServerUserName = [master].[dbo].[syslogins].[loginname]
FROM [dbo].[sysusers]
INNER JOIN [master].[dbo].[syslogins]
ON [sysusers].[sid] = [master].[dbo].[syslogins].[sid]
WHERE [sysusers].[name] = @DatabaseUserName
IF @DatabaseUserID IS NULL
BEGIN
SET @errStatement = 'User ' + @DatabaseUserName + ' does not exist in ' + DB_NAME() + CHAR(13) +
'Please provide the name of a current user in ' + DB_NAME() + ' you wish to script.'
RAISERROR(@errStatement, 16, 1)
END
ELSE
BEGIN
SET @msgStatement = '--Security creation script for user ' + @ServerUserName + CHAR(13) +
'--Created At: ' + CONVERT(varchar, GETDATE(), 112) + REPLACE(CONVERT(varchar, GETDATE(), 108), ':', '') + CHAR(13) +
'--Created By: ' + SUSER_NAME() + CHAR(13) +
'--Add User To Database' + CHAR(13) +
'USE [' + DB_NAME() + ']' + CHAR(13) +
'EXEC [sp_grantdbaccess]' + CHAR(13) +
CHAR(9) + '@loginame = ''' + @ServerUserName + ''',' + CHAR(13) +
CHAR(9) + '@name_in_db = ''' + @DatabaseUserName + '''' + CHAR(13) +
'GO' + CHAR(13) +
'--Add User To Roles'
PRINT @msgStatement
DECLARE _sysusers
CURSOR
LOCAL
FORWARD_ONLY
READ_ONLY
FOR
SELECT
[name]
FROM [dbo].[sysusers]
WHERE
[uid] IN
(
SELECT
[groupuid]
FROM [dbo].[sysmembers]
WHERE [memberuid] = @DatabaseUserID
)
OPEN _sysusers
FETCH
NEXT
FROM _sysusers
INTO @RoleName
WHILE @@FETCH_STATUS = 0
BEGIN
SET @msgStatement = 'EXEC [sp_addrolemember]' + CHAR(13) +
CHAR(9) + '@rolename = ''' + @RoleName + ''',' + CHAR(13) +
CHAR(9) + '@membername = ''' + @DatabaseUserName + ''''
PRINT @msgStatement
FETCH
NEXT
FROM _sysusers
INTO @RoleName
END
SET @msgStatement = 'GO' + CHAR(13) +
'--Set Object Specific Permissions'
PRINT @msgStatement
DECLARE _sysobjects
CURSOR
LOCAL
FORWARD_ONLY
READ_ONLY
FOR
SELECT
DISTINCT([sysobjects].[id]),
'[' + USER_NAME([sysobjects].[uid]) + '].[' + [sysobjects].[name] + ']'
FROM [dbo].[sysprotects]
INNER JOIN [dbo].[sysobjects]
ON [sysprotects].[id] = [sysobjects].[id]
WHERE [sysprotects].[uid] = @DatabaseUserID
OPEN _sysobjects
FETCH
NEXT
FROM _sysobjects
INTO
@ObjectID,
@ObjectName
WHILE @@FETCH_STATUS = 0
BEGIN
SET @msgStatement = ''
IF EXISTS(SELECT * FROM [dbo].[sysprotects] WHERE [id] = @ObjectID AND [uid] = @DatabaseUserID AND [action] = 193 AND [protecttype] = 205)
SET @msgStatement = @msgStatement + 'SELECT,'
IF EXISTS(SELECT * FROM [dbo].[sysprotects] WHERE [id] = @ObjectID AND [uid] = @DatabaseUserID AND [action] = 195 AND [protecttype] = 205)
SET @msgStatement = @msgStatement + 'INSERT,'
IF EXISTS(SELECT * FROM [dbo].[sysprotects] WHERE [id] = @ObjectID AND [uid] = @DatabaseUserID AND [action] = 197 AND [protecttype] = 205)
SET @msgStatement = @msgStatement + 'UPDATE,'
IF EXISTS(SELECT * FROM [dbo].[sysprotects] WHERE [id] = @ObjectID AND [uid] = @DatabaseUserID AND [action] = 196 AND [protecttype] = 205)
SET @msgStatement = @msgStatement + 'DELETE,'
IF EXISTS(SELECT * FROM [dbo].[sysprotects] WHERE [id] = @ObjectID AND [uid] = @DatabaseUserID AND [action] = 224 AND [protecttype] = 205)
SET @msgStatement = @msgStatement + 'EXECUTE,'
IF EXISTS(SELECT * FROM [dbo].[sysprotects] WHERE [id] = @ObjectID AND [uid] = @DatabaseUserID AND [action] = 26 AND [protecttype] = 205)
SET @msgStatement = @msgStatement + 'REFERENCES,'
IF LEN(@msgStatement) > 0
BEGIN
IF RIGHT(@msgStatement, 1) = ','
SET @msgStatement = LEFT(@msgStatement, LEN(@msgStatement) - 1)
SET @msgStatement = 'GRANT' + CHAR(13) +
CHAR(9) + @msgStatement + CHAR(13) +
CHAR(9) + 'ON ' + @ObjectName + CHAR(13) +
CHAR(9) + 'TO ' + @DatabaseUserName
PRINT @msgStatement
END
SET @msgStatement = ''
IF EXISTS(SELECT * FROM [dbo].[sysprotects] WHERE [id] = @ObjectID AND [uid] = @DatabaseUserID AND [action] = 193 AND [protecttype] = 206)
SET @msgStatement = @msgStatement + 'SELECT,'
IF EXISTS(SELECT * FROM [dbo].[sysprotects] WHERE [id] = @ObjectID AND [uid] = @DatabaseUserID AND [action] = 195 AND [protecttype] = 206)
SET @msgStatement = @msgStatement + 'INSERT,'
IF EXISTS(SELECT * FROM [dbo].[sysprotects] WHERE [id] = @ObjectID AND [uid] = @DatabaseUserID AND [action] = 197 AND [protecttype] = 206)
SET @msgStatement = @msgStatement + 'UPDATE,'
IF EXISTS(SELECT * FROM [dbo].[sysprotects] WHERE [id] = @ObjectID AND [uid] = @DatabaseUserID AND [action] = 196 AND [protecttype] = 206)
SET @msgStatement = @msgStatement + 'DELETE,'
IF EXISTS(SELECT * FROM [dbo].[sysprotects] WHERE [id] = @ObjectID AND [uid] = @DatabaseUserID AND [action] = 224 AND [protecttype] = 206)
SET @msgStatement = @msgStatement + 'EXECUTE,'
IF EXISTS(SELECT * FROM [dbo].[sysprotects] WHERE [id] = @ObjectID AND [uid] = @DatabaseUserID AND [action] = 26 AND [protecttype] = 206)
SET @msgStatement = @msgStatement + 'REFERENCES,'
IF LEN(@msgStatement) > 0
BEGIN
IF RIGHT(@msgStatement, 1) = ','
SET @msgStatement = LEFT(@msgStatement, LEN(@msgStatement) - 1)
SET @msgStatement = 'DENY' + CHAR(13) +
CHAR(9) + @msgStatement + CHAR(13) +
CHAR(9) + 'ON ' + @ObjectName + CHAR(13) +
CHAR(9) + 'TO ' + @DatabaseUserName
PRINT @msgStatement
END
FETCH
NEXT
FROM _sysobjects
INTO
@ObjectID,
@ObjectName
END
CLOSE _sysobjects
DEALLOCATE _sysobjects
PRINT 'GO'
END
