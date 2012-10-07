--Written By Bradley Morris
--In Query Analyzer be sure to go to
--Query -> Current Connection Options -> Advanced (Tab)
--and set Maximum characters per column
--to a high number, such as 10000, so
--that all the code will be displayed.



DECLARE @DatabaseRoleName [sysname]
--SET @DatabaseRoleName = '{Database Role Name}'
SET @DatabaseRoleName = 'ProdOpsMonitor'

SET NOCOUNT ON
DECLARE
@errStatement [varchar](8000),
@msgStatement [varchar](8000),
@DatabaseRoleID [smallint],
@IsApplicationRole [bit],
@ObjectID [int],
@ObjectName [sysname]

SELECT
@DatabaseRoleID = [uid],
@IsApplicationRole = CAST([isapprole] AS bit)
FROM [dbo].[sysusers]
WHERE
[name] = @DatabaseRoleName
AND
(
[issqlrole] = 1
OR [isapprole] = 1
)
AND [name] NOT IN
(
'public',
'INFORMATION_SCHEMA',
'db_owner',
'db_accessadmin',
'db_securityadmin',
'db_ddladmin',
'db_backupoperator',
'db_datareader',
'db_datawriter',
'db_denydatareader',
'db_denydatawriter'
)

IF @DatabaseRoleID IS NULL
BEGIN
IF @DatabaseRoleName IN 
(
'public',
'INFORMATION_SCHEMA',
'db_owner',
'db_accessadmin',
'db_securityadmin',
'db_ddladmin',
'db_backupoperator',
'db_datareader',
'db_datawriter',
'db_denydatareader',
'db_denydatawriter'
)
SET @errStatement = 'Role ' + @DatabaseRoleName + ' is a fixed database role and cannot be scripted.'
ELSE
SET @errStatement = 'Role ' + @DatabaseRoleName + ' does not exist in ' + DB_NAME() + '.' + CHAR(13) +
'Please provide the name of a current role in ' + DB_NAME() + ' you wish to script.'

RAISERROR(@errStatement, 16, 1)
END
ELSE
BEGIN
SET @msgStatement = '--Security creation script for role ' + @DatabaseRoleName + CHAR(13) +
'--Created At: ' + CONVERT(varchar, GETDATE(), 112) + REPLACE(CONVERT(varchar, GETDATE(), 108), ':', '') + CHAR(13) +
'--Created By: ' + SUSER_NAME() + CHAR(13) +
'--Add Role To Database' + CHAR(13)
IF @IsApplicationRole = 1
SET @msgStatement = @msgStatement + 'EXEC sp_addapprole' + CHAR(13) +
CHAR(9) + '@rolename = ''' + @DatabaseRoleName + '''' + CHAR(13) +
CHAR(9) + '@password = ''{Please provide the password here}''' + CHAR(13)
ELSE
BEGIN
SET @msgStatement = @msgStatement + 'EXEC sp_addrole' + CHAR(13) +
CHAR(9) + '@rolename ''' + @DatabaseRoleName + '''' + CHAR(13)
PRINT 'GO'
END
SET @msgStatement = @msgStatement + '--Set Object Specific Permissions For Role'
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
WHERE [sysprotects].[uid] = @DatabaseRoleID
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
IF EXISTS(SELECT * FROM [dbo].[sysprotects] WHERE [id] = @ObjectID AND [uid] = @DatabaseRoleID AND [action] = 193 AND [protecttype] = 205)
SET @msgStatement = @msgStatement + 'SELECT,'
IF EXISTS(SELECT * FROM [dbo].[sysprotects] WHERE [id] = @ObjectID AND [uid] = @DatabaseRoleID AND [action] = 195 AND [protecttype] = 205)
SET @msgStatement = @msgStatement + 'INSERT,'
IF EXISTS(SELECT * FROM [dbo].[sysprotects] WHERE [id] = @ObjectID AND [uid] = @DatabaseRoleID AND [action] = 197 AND [protecttype] = 205)
SET @msgStatement = @msgStatement + 'UPDATE,'
IF EXISTS(SELECT * FROM [dbo].[sysprotects] WHERE [id] = @ObjectID AND [uid] = @DatabaseRoleID AND [action] = 196 AND [protecttype] = 205)
SET @msgStatement = @msgStatement + 'DELETE,'
IF EXISTS(SELECT * FROM [dbo].[sysprotects] WHERE [id] = @ObjectID AND [uid] = @DatabaseRoleID AND [action] = 224 AND [protecttype] = 205)
SET @msgStatement = @msgStatement + 'EXECUTE,'
IF EXISTS(SELECT * FROM [dbo].[sysprotects] WHERE [id] = @ObjectID AND [uid] = @DatabaseRoleID AND [action] = 26 AND [protecttype] = 205)
SET @msgStatement = @msgStatement + 'REFERENCES,'
IF LEN(@msgStatement) > 0
BEGIN
IF RIGHT(@msgStatement, 1) = ','
SET @msgStatement = LEFT(@msgStatement, LEN(@msgStatement) - 1)
SET @msgStatement = 'GRANT' + CHAR(13) +
CHAR(9) + @msgStatement + CHAR(13) +
CHAR(9) + 'ON ' + @ObjectName + CHAR(13) +
CHAR(9) + 'TO ' + @DatabaseRoleName
PRINT @msgStatement
END
SET @msgStatement = ''
IF EXISTS(SELECT * FROM [dbo].[sysprotects] WHERE [id] = @ObjectID AND [uid] = @DatabaseRoleID AND [action] = 193 AND [protecttype] = 206)
SET @msgStatement = @msgStatement + 'SELECT,'
IF EXISTS(SELECT * FROM [dbo].[sysprotects] WHERE [id] = @ObjectID AND [uid] = @DatabaseRoleID AND [action] = 195 AND [protecttype] = 206)
SET @msgStatement = @msgStatement + 'INSERT,'
IF EXISTS(SELECT * FROM [dbo].[sysprotects] WHERE [id] = @ObjectID AND [uid] = @DatabaseRoleID AND [action] = 197 AND [protecttype] = 206)
SET @msgStatement = @msgStatement + 'UPDATE,'
IF EXISTS(SELECT * FROM [dbo].[sysprotects] WHERE [id] = @ObjectID AND [uid] = @DatabaseRoleID AND [action] = 196 AND [protecttype] = 206)
SET @msgStatement = @msgStatement + 'DELETE,'
IF EXISTS(SELECT * FROM [dbo].[sysprotects] WHERE [id] = @ObjectID AND [uid] = @DatabaseRoleID AND [action] = 224 AND [protecttype] = 206)
SET @msgStatement = @msgStatement + 'EXECUTE,'
IF EXISTS(SELECT * FROM [dbo].[sysprotects] WHERE [id] = @ObjectID AND [uid] = @DatabaseRoleID AND [action] = 26 AND [protecttype] = 206)
SET @msgStatement = @msgStatement + 'REFERENCES,'
IF LEN(@msgStatement) > 0
BEGIN
IF RIGHT(@msgStatement, 1) = ','
SET @msgStatement = LEFT(@msgStatement, LEN(@msgStatement) - 1)
SET @msgStatement = 'DENY' + CHAR(13) +
CHAR(9) + @msgStatement + CHAR(13) +
CHAR(9) + 'ON ' + @ObjectName + CHAR(13) +
CHAR(9) + 'TO ' + @DatabaseRoleName
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